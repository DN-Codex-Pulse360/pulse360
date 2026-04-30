#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
src_root="${repo_root}/services/salesforce_data_cloud_mcp/src"

PYTHONPATH="${src_root}" python3 - <<'PY'
import json
import sys
from csv import DictReader
from pathlib import Path

from pulse360_salesforce_data_cloud_mcp.config import ServiceConfig
from pulse360_salesforce_data_cloud_mcp.salesforce_cli import SalesforceCliClient, SalesforceCliError


def fail(message: str, summary: dict | None = None) -> None:
    if summary is not None:
        print(json.dumps(summary, indent=2))
    print(f"[FAIL] {message}", file=sys.stderr)
    raise SystemExit(1)


def load_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="") as handle:
        return list(DictReader(handle))


def nonblank(value: object) -> bool:
    return value is not None and str(value).strip() != ""


def parse_json_field(record: dict, field_name: str, errors: list[dict]) -> None:
    value = record.get(field_name)
    if not nonblank(value):
        return
    try:
        json.loads(str(value))
    except json.JSONDecodeError as exc:
        errors.append(
            {
                "activation_id": record.get("source_account_id__c"),
                "field": field_name,
                "error": str(exc),
            }
        )


def source_field_api_name(source_field: str) -> str:
    return f"{source_field}__c"


config = ServiceConfig.load()
sf = SalesforceCliClient(default_org_alias=config.default_org_alias, timeout_seconds=120)
activation_rows = load_csv(config.activation_mapping_path)
payload_rows = [
    row
    for row in activation_rows
    if row.get("target_object") == "Account"
    and row.get("activation_path") == "payload_api_runbook"
    and row.get("decision_status") == "accepted_exception"
]
payload_source_fields = [row["source_field"] for row in payload_rows]
payload_source_api_fields = [source_field_api_name(field) for field in payload_source_fields]
payload_target_fields = [row["target_field"] for row in payload_rows]

provenance_source_fields = [
    "enrichment_run_id__c",
    "ai_narrative_generated_at__c",
    "model_id__c",
    "prompt_version__c",
    "citation_count__c",
]
provenance_target_fields = [
    "Enrichment_Run_Id__c",
    "AI_Narrative_Generated__c",
    "AI_Model_Id__c",
    "AI_Prompt_Version__c",
    "AI_Citation_Count__c",
]

if not payload_rows:
    fail("No payload_api_runbook mapping rows found.")

try:
    source_describe = sf.describe_sobject(config.default_source_object)
    account_describe = sf.describe_sobject("Account")
    account_records = sf.query("SELECT Id FROM Account ORDER BY Id LIMIT 2000")
    source_records = sf.query(
        "SELECT source_account_id__c, "
        + ", ".join(payload_source_api_fields + provenance_source_fields)
        + f" FROM {config.default_source_object} ORDER BY source_account_id__c LIMIT 2000"
    )
except SalesforceCliError as exc:
    fail(
        "Payload exception activation readiness query failed.",
        {
            "org_alias": config.default_org_alias,
            "source_object": config.default_source_object,
            "error": str(exc),
        },
    )

source_live_fields = {field["name"] for field in source_describe.get("fields", [])}
account_live_fields = {field["name"] for field in account_describe.get("fields", [])}
account_ids = {
    str(record["Id"])
    for record in account_records.get("records", [])
    if record.get("Id")
}

missing_source_fields = sorted(
    field
    for field in payload_source_api_fields + provenance_source_fields
    if field not in source_live_fields
)
missing_account_fields = sorted(
    field
    for field in payload_target_fields + provenance_target_fields
    if field not in account_live_fields
)

records = source_records.get("records", [])
missing_account_ids = sorted(
    str(record.get("source_account_id__c"))
    for record in records
    if record.get("source_account_id__c") not in account_ids
)
rows_missing_payload = []
rows_missing_provenance = []
json_errors: list[dict] = []

for record in records:
    missing_payload_fields = [
        field
        for field in payload_source_api_fields
        if not nonblank(record.get(field))
    ]
    missing_provenance_fields = [
        field
        for field in provenance_source_fields
        if not nonblank(record.get(field))
    ]
    if missing_payload_fields:
        rows_missing_payload.append(
            {
                "activation_id": record.get("source_account_id__c"),
                "missing_payload_fields": missing_payload_fields,
            }
        )
    if missing_provenance_fields:
        rows_missing_provenance.append(
            {
                "activation_id": record.get("source_account_id__c"),
                "missing_provenance_fields": missing_provenance_fields,
            }
        )

    parse_json_field(record, "ai_recommended_actions__c", json_errors)
    parse_json_field(record, "source_refs__c", json_errors)
    parse_json_field(record, "hierarchy_payload__c", json_errors)
    parse_json_field(record, "intent_signal_payload__c", json_errors)

summary = {
    "dry_run_only": True,
    "org_alias": config.default_org_alias,
    "source_object": config.default_source_object,
    "payload_source_fields": payload_source_fields,
    "payload_target_fields": payload_target_fields,
    "provenance_source_fields": provenance_source_fields,
    "provenance_target_fields": provenance_target_fields,
    "source_record_count": len(records),
    "target_account_id_count": len(account_ids),
    "missing_source_fields": missing_source_fields,
    "missing_account_fields": missing_account_fields,
    "missing_account_id_count": len(missing_account_ids),
    "missing_account_ids_sample": missing_account_ids[:20],
    "rows_missing_payload_count": len(rows_missing_payload),
    "rows_missing_payload_sample": rows_missing_payload[:5],
    "rows_missing_provenance_count": len(rows_missing_provenance),
    "rows_missing_provenance_sample": rows_missing_provenance[:5],
    "json_error_count": len(json_errors),
    "json_errors_sample": json_errors[:5],
}

print(json.dumps(summary, indent=2))

if missing_source_fields:
    fail("Payload source fields are not available on the Data Cloud source object.")

if missing_account_fields:
    fail("Payload/provenance target fields are not available on Account.")

if missing_account_ids:
    fail("Payload source rows include Account IDs that do not resolve in the target org.")

if rows_missing_payload:
    fail("Payload source rows have blank payload values.")

if rows_missing_provenance:
    fail("Payload source rows are missing provenance or freshness values.")

if json_errors:
    fail("Payload source rows contain invalid JSON payload fields.")

print("[PASS] Account payload exception activation dry-run readiness validated")
PY
