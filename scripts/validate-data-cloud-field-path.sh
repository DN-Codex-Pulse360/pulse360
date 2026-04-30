#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
src_root="${repo_root}/services/salesforce_data_cloud_mcp/src"

PYTHONPATH="${src_root}" python3 - <<'PY'
import json
import sys

from pulse360_salesforce_data_cloud_mcp.comparison import (
    compare_required_fields_to_mapping,
    compare_required_fields_to_source_object,
    load_contract_required_fields,
    load_mapping,
)
from pulse360_salesforce_data_cloud_mcp.config import ServiceConfig
from pulse360_salesforce_data_cloud_mcp.salesforce_cli import SalesforceCliClient, SalesforceCliError


def picklist_values_by_name(describe_payload, field_name):
    for field in describe_payload.get("fields", []):
        if field.get("name") != field_name:
            continue
        values = []
        for picklist_value in field.get("picklistValues", []):
            if isinstance(picklist_value, dict):
                value = picklist_value.get("value")
            else:
                value = picklist_value
            if value is not None:
                values.append(str(value))
        return values
    return []


def copy_field_required(row):
    if "copy_field_required" in row:
        return row.get("copy_field_required", "").lower() == "true"
    return row.get("required", "").lower() == "true"

config = ServiceConfig.load()
sf = SalesforceCliClient(default_org_alias=config.default_org_alias)

source_contract_fields = load_contract_required_fields(config.source_contract_path)
account_sync_contract_fields = load_contract_required_fields(config.account_sync_contract_path)
dmo_mapping_rows = load_mapping(config.dmo_mapping_path, target_object=config.default_dmo_name)
activation_mapping_rows = load_mapping(config.activation_mapping_path, target_object="Account")
dmo_runtime_required_fields = sorted(
    row["source_field"]
    for row in dmo_mapping_rows
    if copy_field_required(row)
)
copy_field_exception_fields = sorted(
    row["source_field"]
    for row in activation_mapping_rows
    if row.get("decision_status") == "accepted_exception"
    and not copy_field_required(row)
)
default_dlo_developer_name = config.default_source_object.removesuffix("__dll")

try:
    source_payload = sf.describe_sobject(config.default_source_object)
    dmo_payload = sf.describe_sobject(config.default_dmo_name)
    account_payload = sf.describe_sobject("Account")
    mapping_payload = sf.describe_sobject("MktDataLakeMapping")
    mapping_rows = sf.query("SELECT Id FROM MktDataLakeMapping LIMIT 1")
    activation_data_sources = sf.query("SELECT Id FROM MktSgmtActvDataSource LIMIT 1")
    data_source_bundles = sf.query("SELECT Id FROM DataSourceBundle LIMIT 1")
    market_segment_activations = sf.query("SELECT Id FROM MarketSegmentActivation LIMIT 1")
    stream_payload = sf.query(
        "SELECT Name, ImportRunStatus, LastRefreshDate, TotalRowsProcessed, IsNewFieldsAvailable "
        f"FROM DataStream WHERE Name = '{config.default_data_stream_name}'"
    )
    dlo_payload = sf.query(
        "SELECT Id, Name, DataLakeObjectStatus, SyncStatus, TotalRecords, TotalNumberOfFields "
        "FROM DataLakeObjectInstance "
        f"WHERE Name = '{config.default_data_stream_name}' "
        f"OR MktDataLakeObjectDeveloperName = '{default_dlo_developer_name}'"
    )
except SalesforceCliError as exc:
    summary = {
        "org_alias": config.default_org_alias,
        "source_object_name": config.default_source_object,
        "dmo_name": config.default_dmo_name,
        "error": str(exc),
    }
    print(json.dumps(summary, indent=2))
    sys.exit(1)

source_gap = compare_required_fields_to_source_object(
    source_contract_fields,
    [field["name"] for field in source_payload.get("fields", [])],
)
dmo_gap = compare_required_fields_to_mapping(
    dmo_runtime_required_fields,
    dmo_mapping_rows,
    {field["name"] for field in dmo_payload.get("fields", [])},
)
account_gap = compare_required_fields_to_mapping(
    account_sync_contract_fields,
    activation_mapping_rows,
    {field["name"] for field in account_payload.get("fields", [])},
)
source_object_picklist_available = (
    config.default_source_object in picklist_values_by_name(mapping_payload, "SourceObjectRef")
    or any(
        value.startswith(f"{config.default_source_object}.")
        for value in picklist_values_by_name(mapping_payload, "SourceFieldRef")
    )
)
source_object_registered = (
    source_object_picklist_available
    or stream_payload.get("totalSize", 0) > 0
    or dlo_payload.get("totalSize", 0) > 0
)

summary = {
    "org_alias": config.default_org_alias,
    "configured_data_stream_name": config.default_data_stream_name,
    "data_stream": stream_payload.get("records", []),
    "data_lake_object": dlo_payload.get("records", []),
    "mapping_surface": {
        "source_object_ref_count": len(picklist_values_by_name(mapping_payload, "SourceObjectRef")),
        "source_field_ref_count": len(picklist_values_by_name(mapping_payload, "SourceFieldRef")),
        "source_object_picklist_available": source_object_picklist_available,
        "source_object_registered": source_object_registered,
    },
    "registration_surface": {
        "data_source_bundle_count": data_source_bundles.get("totalSize", 0),
        "market_segment_activation_count": market_segment_activations.get("totalSize", 0),
        "activation_data_source_count": activation_data_sources.get("totalSize", 0),
        "data_lake_mapping_count": mapping_rows.get("totalSize", 0),
    },
    "account_sync_contract_path": str(config.account_sync_contract_path),
    "copy_field": {
        "required_supported_field_count": len(dmo_runtime_required_fields),
        "exception_field_count": len(copy_field_exception_fields),
        "exception_fields": copy_field_exception_fields,
    },
    "source_object": {
        "name": source_payload.get("name"),
        "missing_field_count": source_gap["missing_field_count"],
        "missing_fields": source_gap["missing_fields"][:25],
    },
    "dmo": {
        "name": dmo_payload.get("name"),
        "missing_mapping_count": dmo_gap["missing_mapping_count"],
        "missing_target_field_count": dmo_gap["missing_target_field_count"],
        "missing_mapping_fields": dmo_gap["missing_mapping_fields"][:25],
        "missing_target_fields": dmo_gap["missing_target_fields"][:25],
    },
    "account": {
        "name": account_payload.get("name"),
        "missing_mapping_count": account_gap["missing_mapping_count"],
        "missing_target_field_count": account_gap["missing_target_field_count"],
        "missing_mapping_fields": account_gap["missing_mapping_fields"][:25],
        "missing_target_fields": account_gap["missing_target_fields"][:25],
    },
}

print(json.dumps(summary, indent=2))

if (
    source_gap["missing_field_count"] > 0
    or dmo_gap["missing_mapping_count"] > 0
    or dmo_gap["missing_target_field_count"] > 0
    or account_gap["missing_mapping_count"] > 0
    or account_gap["missing_target_field_count"] > 0
    or not summary["mapping_surface"]["source_object_registered"]
):
    sys.exit(1)
PY
