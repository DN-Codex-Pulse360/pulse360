#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

search_fixed() {
  local needle="$1"
  shift

  if command -v rg >/dev/null 2>&1; then
    rg -Fq "$needle" "$@"
  else
    grep -Fq -- "$needle" "$@"
  fi
}

required_files=(
  "contracts/weighted_attribute_resolution.schema.json"
  "data/samples/weighted_attribute_resolution_sample.json"
  "config/databricks/weighted-attribute-resolution-rules.json"
  "sql/databricks/firmographic_enrichment/25_weighted_attribute_resolution.sql"
)

for path in "${required_files[@]}"; do
  [[ -f "$path" ]] || fail "Missing weighted attribute artifact: $path"
done
pass "Weighted attribute artifacts exist"

python3 -m json.tool contracts/weighted_attribute_resolution.schema.json >/dev/null \
  || fail "Invalid weighted attribute schema JSON"
python3 -m json.tool data/samples/weighted_attribute_resolution_sample.json >/dev/null \
  || fail "Invalid weighted attribute sample JSON"
python3 -m json.tool config/databricks/weighted-attribute-resolution-rules.json >/dev/null \
  || fail "Invalid weighted attribute rules JSON"
pass "Weighted attribute JSON artifacts parse"

python3 - <<'PY'
import json
from pathlib import Path

schema = json.loads(Path("contracts/weighted_attribute_resolution.schema.json").read_text())
sample = json.loads(Path("data/samples/weighted_attribute_resolution_sample.json").read_text())
rules = json.loads(Path("config/databricks/weighted-attribute-resolution-rules.json").read_text())

required_schema_terms = [
    "source_contributions",
    "source_weight",
    "contribution_score",
    "survivorship_rule",
    "conflict_count",
    "license_or_contract_references",
    "freshness_status",
    "run_id",
    "model_version",
]
schema_text = json.dumps(schema)
for term in required_schema_terms:
    if term not in schema_text:
        raise SystemExit(f"Weighted attribute schema missing term: {term}")

if not sample.get("source_contributions"):
    raise SystemExit("Weighted attribute sample must include source_contributions")
if sample["source_contribution_count"] != len(sample["source_contributions"]):
    raise SystemExit("source_contribution_count must match source_contributions length")
if not sample.get("source_refs") or not sample.get("license_or_contract_references"):
    raise SystemExit("Weighted attribute sample must include source refs and license refs")
selected = [row for row in sample["source_contributions"] if row.get("selected_flag") is True]
if len(selected) != 1:
    raise SystemExit("Exactly one source contribution must be selected")
for row in sample["source_contributions"]:
    for key in ["source_id", "source_family", "source_type", "source_confidence", "source_weight", "freshness_score", "contribution_score", "license_or_contract_reference", "run_id"]:
        if key not in row:
            raise SystemExit(f"Source contribution missing {key}")
    if not 0 <= row["contribution_score"] <= 1:
        raise SystemExit("contribution_score must be between 0 and 1")

weights = rules.get("source_type_weights") or {}
for source_type in [
    "approved_registry_export",
    "approved_regulatory_filing",
    "approved_marketplace_delta_share",
    "approved_provider_export",
    "approved_customer_internal_export",
    "approved_public_pdf",
    "approved_public_url",
    "approved_clean_room_output",
    "neutral_fixture_payload",
]:
    if source_type not in weights:
        raise SystemExit(f"Missing source type weight: {source_type}")

controls = rules.get("required_controls") or {}
for key in [
    "require_source_contribution_json",
    "require_license_or_contract_reference",
    "require_freshness_status",
    "require_run_metadata",
    "require_conflict_count",
    "block_missing_source_refs",
]:
    if controls.get(key) is not True:
        raise SystemExit(f"Weighted attribute rules missing required control: {key}")
PY
pass "Weighted attribute contract and sample preserve source contribution metadata"

for token in \
  "pulse360_s4.silver_firmographic.source_contribution" \
  "pulse360_s4.silver_firmographic.weighted_attribute_resolution" \
  "source_weight" \
  "contribution_score" \
  "source_contributions_json" \
  "source_refs_json" \
  "license_or_contract_references_json" \
  "survivorship_rule" \
  "conflict_count" \
  "highest_weighted_confidence" \
  "official_source_priority" \
  "aggregate_only"; do
  search_fixed "$token" sql/databricks/firmographic_enrichment/25_weighted_attribute_resolution.sql \
    || fail "Weighted attribute SQL missing token: $token"
done
pass "Weighted attribute SQL emits contribution and survivorship fields"

for forbidden in \
  "CompanyData" \
  "BoldData" \
  "Infobel" \
  "docs.companydata" \
  "bizsearch.infobelpro"; do
  if grep -Riq "$forbidden" \
    contracts/weighted_attribute_resolution.schema.json \
    data/samples/weighted_attribute_resolution_sample.json \
    config/databricks/weighted-attribute-resolution-rules.json \
    sql/databricks/firmographic_enrichment/25_weighted_attribute_resolution.sql; then
    fail "Weighted attribute artifacts must not hardwire paid-provider reference: $forbidden"
  fi
done
pass "Weighted attribute artifacts avoid hardwired paid-provider references"

pass "Weighted attribute resolution validation completed"
