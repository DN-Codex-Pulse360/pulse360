#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

python3 - <<'PY'
import json
import sys
from csv import DictReader
from pathlib import Path


def load_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="") as handle:
        return list(DictReader(handle))


def by_source(rows: list[dict[str, str]]) -> dict[str, dict[str, str]]:
    return {row["source_field"]: row for row in rows}


def fail(message: str, summary: dict) -> None:
    print(json.dumps(summary, indent=2))
    print(f"[FAIL] {message}", file=sys.stderr)
    raise SystemExit(1)


activation_rows = load_csv(Path("config/data-cloud/activation-field-mapping.csv"))
dmo_rows = load_csv(Path("config/data-cloud/dmo-account-field-mapping.csv"))

activation_by_source = by_source(activation_rows)
dmo_by_source = by_source(dmo_rows)

expected_exceptions = {
    "ai_narrative": "payload_api_runbook",
    "ai_recommended_actions": "payload_api_runbook",
    "source_refs": "payload_api_runbook",
    "hierarchy_payload": "payload_api_runbook",
    "intent_signal_payload": "payload_api_runbook",
    "group_revenue_rollup": "schema_type_deferred",
    "group_revenue_visible": "dmo_type_deferred",
    "external_revenue_confirmed": "dmo_type_deferred",
}

errors: list[str] = []
for source_field, expected_path in expected_exceptions.items():
    activation = activation_by_source.get(source_field)
    dmo = dmo_by_source.get(source_field)
    if activation is None:
        errors.append(f"Missing activation mapping for {source_field}")
        continue
    if dmo is None:
        errors.append(f"Missing DMO mapping for {source_field}")
        continue
    for label, row in [("activation", activation), ("dmo", dmo)]:
        if row.get("copy_field_required", "").lower() != "false":
            errors.append(f"{label} mapping for {source_field} must set copy_field_required=false")
        if row.get("activation_path") != expected_path:
            errors.append(
                f"{label} mapping for {source_field} must use activation_path={expected_path}"
            )
        if row.get("decision_status") != "accepted_exception":
            errors.append(f"{label} mapping for {source_field} must set decision_status=accepted_exception")

native_required = sorted(
    row["source_field"]
    for row in activation_rows
    if row.get("target_object") == "Account"
    and row.get("required", "").lower() == "true"
    and row.get("copy_field_required", "").lower() == "true"
)
missing_dmo_native = [
    source_field
    for source_field in native_required
    if dmo_by_source.get(source_field, {}).get("copy_field_required", "").lower() != "true"
]

summary = {
    "expected_exception_count": len(expected_exceptions),
    "expected_exceptions": expected_exceptions,
    "native_copy_field_required_count": len(native_required),
    "native_copy_field_required_fields": native_required,
    "missing_dmo_native_fields": missing_dmo_native,
    "errors": errors,
}

if errors:
    fail("Copy Field exception routing is not aligned across mapping files.", summary)

if missing_dmo_native:
    fail("Native Copy Field required Account fields are not required on the DMO mapping.", summary)

print(json.dumps(summary, indent=2))
print("[PASS] Data Cloud Copy Field exception routing is documented in mapping files")
PY
