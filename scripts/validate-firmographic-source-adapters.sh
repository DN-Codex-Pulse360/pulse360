#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

schema="contracts/firmographic_source_adapter.schema.json"
sample="data/samples/firmographic_source_adapters.json"
config="config/databricks/firmographic-source-adapters.json"

[[ -f "$schema" ]] || fail "Missing source adapter schema: $schema"
[[ -f "$sample" ]] || fail "Missing source adapter sample registry: $sample"
[[ -f "$config" ]] || fail "Missing source adapter config: $config"

python3 -m json.tool "$schema" >/dev/null || fail "Invalid source adapter schema JSON"
python3 -m json.tool "$sample" >/dev/null || fail "Invalid source adapter sample JSON"
python3 -m json.tool "$config" >/dev/null || fail "Invalid source adapter config JSON"
pass "Firmographic source adapter JSON artifacts parse"

python3 - <<'PY'
import json
from pathlib import Path

required_families = {
    "national_registry",
    "commercial_provider_marketplace",
    "customer_internal",
    "internet_research",
    "clean_room_collaboration",
}
required_metadata = {"run_id", "run_timestamp", "source_retrieved_at", "license_or_contract_reference"}
forbidden = ("bolddata", "infobel", "d&b", "dun & bradstreet", "zoominfo", "companydata")

schema_text = Path("contracts/firmographic_source_adapter.schema.json").read_text().lower()
sample_text = Path("data/samples/firmographic_source_adapters.json").read_text().lower()
config_text = Path("config/databricks/firmographic-source-adapters.json").read_text().lower()
for token in forbidden:
    if token in schema_text or token in sample_text or token in config_text:
        raise SystemExit(f"Paid-provider reference must not be hardwired: {token}")

adapters = json.loads(Path("data/samples/firmographic_source_adapters.json").read_text())
if not isinstance(adapters, list) or not adapters:
    raise SystemExit("Source adapter sample registry must be a non-empty list")

families = {adapter.get("source_family") for adapter in adapters}
missing = sorted(required_families - families)
if missing:
    raise SystemExit(f"Missing source families: {', '.join(missing)}")

ids = [adapter.get("source_adapter_id") for adapter in adapters]
if len(ids) != len(set(ids)):
    raise SystemExit("Source adapter IDs must be unique")

for adapter in adapters:
    adapter_id = adapter.get("source_adapter_id")
    family = adapter.get("source_family")
    if not adapter_id or not adapter_id.startswith("src_adapter_"):
        raise SystemExit(f"Invalid adapter ID: {adapter_id}")
    if not adapter.get("license_or_use_basis"):
        raise SystemExit(f"{adapter_id} missing license_or_use_basis")
    if not adapter.get("allowed_use"):
        raise SystemExit(f"{adapter_id} missing allowed_use")
    if not adapter.get("approved_fact_types"):
        raise SystemExit(f"{adapter_id} missing approved_fact_types")
    if adapter.get("lineage_required") is not True:
        raise SystemExit(f"{adapter_id} must require lineage")

    metadata = adapter.get("run_metadata_required") or {}
    missing_metadata = sorted(required_metadata - {k for k, v in metadata.items() if v is True})
    if missing_metadata:
        raise SystemExit(f"{adapter_id} missing required run metadata flags: {', '.join(missing_metadata)}")

    if family == "commercial_provider_marketplace":
        if adapter.get("provider_or_source_id_role") != "xref_only":
            raise SystemExit(f"{adapter_id} commercial provider IDs must be xref_only")
        if adapter.get("identity_key_policy") != "xref_only":
            raise SystemExit(f"{adapter_id} commercial provider identity policy must be xref_only")
    if family == "clean_room_collaboration":
        if adapter.get("row_level_identity_allowed") is not False:
            raise SystemExit(f"{adapter_id} clean room row-level identity must be disabled by default")
        if adapter.get("identity_key_policy") != "aggregate_only":
            raise SystemExit(f"{adapter_id} clean room identity policy must be aggregate_only")
    if family == "national_registry":
        if adapter.get("identity_key_policy") != "sovereign_candidate_official_only":
            raise SystemExit(f"{adapter_id} registry identity policy must be sovereign_candidate_official_only")

config = json.loads(Path("config/databricks/firmographic-source-adapters.json").read_text())
config_families = set(config.get("source_families") or [])
if config_families != required_families:
    raise SystemExit("Databricks adapter config must enumerate the five source families")
controls = config.get("default_controls") or {}
for key in [
    "preserve_raw_payload_reference",
    "require_license_or_contract_reference",
    "require_run_metadata",
    "require_lineage",
    "commercial_provider_ids_are_xrefs_only",
    "clean_room_outputs_are_aggregate_by_default",
    "sovereign_identifiers_require_official_source",
]:
    if controls.get(key) is not True:
        raise SystemExit(f"Databricks adapter config missing required control: {key}")
PY
pass "Firmographic source adapter registry covers the five governed source families"

pass "Firmographic source adapter validation completed"
