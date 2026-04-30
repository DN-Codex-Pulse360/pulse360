#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

python3 - <<'PY'
import json
import os
import sys
from collections import Counter
from csv import DictReader
from pathlib import Path

sys.path.insert(0, "services/salesforce_data_cloud_mcp/src")

from pulse360_salesforce_data_cloud_mcp.config import ServiceConfig
from pulse360_salesforce_data_cloud_mcp.salesforce_cli import SalesforceCliClient, SalesforceCliError


def fail(message: str, summary: dict | None = None) -> None:
    if summary is not None:
        print(json.dumps(summary, indent=2))
    print(f"[FAIL] {message}", file=sys.stderr)
    raise SystemExit(1)


def query_records(sf: SalesforceCliClient, soql: str, label: str) -> tuple[list[dict], int]:
    try:
        payload = sf.query(soql)
    except SalesforceCliError as exc:
        fail(f"{label} query failed: {exc}")
    return payload.get("records", []), int(payload.get("totalSize", 0))


def collect_field_values(records: list[dict], field_name: str) -> set[str]:
    values: set[str] = set()
    for record in records:
        value = record.get(field_name)
        if value:
            values.add(str(value))
    return values


def duplicate_field_values(records: list[dict], field_name: str) -> list[str]:
    values = [str(record.get(field_name)) for record in records if record.get(field_name)]
    return sorted(value for value, count in Counter(values).items() if count > 1)


def load_csv(path: Path) -> list[dict]:
    with path.open(newline="") as handle:
        return list(DictReader(handle))


def copy_field_required(row: dict) -> bool:
    if "copy_field_required" in row:
        return row.get("copy_field_required", "").lower() == "true"
    return row.get("required", "").lower() == "true"


def missing_required_fields(records: list[dict], fields: list[str]) -> list[dict]:
    missing: list[dict] = []
    for record in records:
        record_missing = [
            field
            for field in fields
            if record.get(field) is None or record.get(field) == ""
        ]
        if record_missing:
            missing.append(
                {
                    "activation_id": record.get("source_account_id__c")
                    or record.get("ssot__Id__c"),
                    "source_object": record.get("ssot__DataSourceObjectId__c"),
                    "missing_fields": record_missing[:20],
                    "missing_field_count": len(record_missing),
                }
            )
    return missing


config = ServiceConfig.load()
target_org = os.environ.get("TARGET_ORG") or config.default_org_alias
source_object = os.environ.get("PULSE360_DEFAULT_SOURCE_OBJECT") or config.default_source_object
dmo_name = os.environ.get("PULSE360_DEFAULT_DMO_NAME") or config.default_dmo_name

repo_root = Path.cwd()
activation_mapping_path = repo_root / "config/data-cloud/activation-field-mapping.csv"
dmo_mapping_path = config.dmo_mapping_path

activation_rows = load_csv(activation_mapping_path)
dmo_mapping_rows = load_csv(dmo_mapping_path)
dmo_field_by_source = {
    row["source_field"]: row["target_field"]
    for row in dmo_mapping_rows
    if row["target_object"] == dmo_name
}

required_supported_source_fields = [
    row["source_field"]
    for row in activation_rows
    if row["target_object"] == "Account"
    and copy_field_required(row)
]
exception_source_fields = sorted(
    row["source_field"]
    for row in activation_rows
    if row["target_object"] == "Account"
    and row.get("decision_status") == "accepted_exception"
    and not copy_field_required(row)
)
required_source_fields = [f"{field}__c" for field in required_supported_source_fields]
required_dmo_fields = [
    dmo_field_by_source[field]
    for field in required_supported_source_fields
    if field in dmo_field_by_source
]

sf = SalesforceCliClient(default_org_alias=target_org, timeout_seconds=120)

account_records, account_total = query_records(
    sf,
    "SELECT Id, Name FROM Account ORDER BY Id LIMIT 2000",
    "Target Account",
)
target_account_ids = collect_field_values(account_records, "Id")

source_records, source_total = query_records(
    sf,
    "SELECT source_account_id__c, "
    + ", ".join(required_source_fields)
    + f" FROM {source_object} ORDER BY source_account_id__c LIMIT 2000",
    "Data Cloud source object",
)
source_ids = collect_field_values(source_records, "source_account_id__c")
duplicate_source_ids = duplicate_field_values(source_records, "source_account_id__c")

dmo_records, dmo_total = query_records(
    sf,
    "SELECT ssot__Id__c, ssot__Name__c, ssot__DataSourceObjectId__c, "
    + ", ".join(required_dmo_fields)
    + f" FROM {dmo_name} ORDER BY ssot__Id__c LIMIT 2000",
    "Account DMO",
)
dmo_ids = collect_field_values(dmo_records, "ssot__Id__c")
duplicate_dmo_ids = duplicate_field_values(dmo_records, "ssot__Id__c")

missing_source_ids = sorted(source_ids - target_account_ids)
missing_dmo_ids = sorted(dmo_ids - target_account_ids)
valid_source_ids = sorted(source_ids & target_account_ids)
valid_dmo_ids = sorted(dmo_ids & target_account_ids)
source_missing_required_fields = missing_required_fields(
    [record for record in source_records if record.get("source_account_id__c") in valid_source_ids],
    required_source_fields,
)
dmo_missing_required_fields = missing_required_fields(
    [record for record in dmo_records if record.get("ssot__Id__c") in valid_dmo_ids],
    required_dmo_fields,
)

summary = {
    "org_alias": target_org,
    "source_object": source_object,
    "dmo_name": dmo_name,
    "target_account_total_size": account_total,
    "target_account_id_count": len(target_account_ids),
    "source_object_total_size": source_total,
    "source_object_distinct_activation_id_count": len(source_ids),
    "source_object_duplicate_activation_id_count": len(duplicate_source_ids),
    "source_object_duplicate_activation_ids_sample": duplicate_source_ids[:20],
    "source_object_valid_activation_id_count": len(valid_source_ids),
    "source_object_missing_activation_id_count": len(missing_source_ids),
    "source_object_missing_activation_ids_sample": missing_source_ids[:20],
    "source_object_required_supported_field_count": len(required_source_fields),
    "copy_field_required_source_fields": required_supported_source_fields,
    "copy_field_exception_source_fields": exception_source_fields,
    "source_object_rows_missing_required_supported_fields_count": len(source_missing_required_fields),
    "source_object_rows_missing_required_supported_fields_sample": source_missing_required_fields[:5],
    "dmo_total_size": dmo_total,
    "dmo_distinct_activation_id_count": len(dmo_ids),
    "dmo_duplicate_activation_id_count": len(duplicate_dmo_ids),
    "dmo_duplicate_activation_ids_sample": duplicate_dmo_ids[:20],
    "dmo_valid_activation_id_count": len(valid_dmo_ids),
    "dmo_missing_activation_id_count": len(missing_dmo_ids),
    "dmo_missing_activation_ids_sample": missing_dmo_ids[:20],
    "dmo_required_supported_field_count": len(required_dmo_fields),
    "dmo_rows_missing_required_supported_fields_count": len(dmo_missing_required_fields),
    "dmo_rows_missing_required_supported_fields_sample": dmo_missing_required_fields[:5],
}

print(json.dumps(summary, indent=2))

if missing_source_ids or missing_dmo_ids:
    fail(
        "Data Cloud direct Account activation contains IDs that do not resolve "
        "to target-org Account records.",
    )

if duplicate_source_ids or duplicate_dmo_ids:
    fail(
        "Data Cloud direct Account activation contains duplicate activation IDs; "
        "Copy Field writeback requires one authoritative source/DMO row per "
        "target Account.",
    )

if source_missing_required_fields or dmo_missing_required_fields:
    fail(
        "Data Cloud direct Account activation has null required supported "
        "writeback fields; Copy Field restart requires populated source and DMO "
        "values for the supported mapping set.",
    )

print(
    "[PASS] Data Cloud activation keys resolve uniquely to target-org Account "
    "records with populated supported writeback fields"
)
PY
