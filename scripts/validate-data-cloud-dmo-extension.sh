#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
src_root="${repo_root}/services/salesforce_data_cloud_mcp/src"

PYTHONPATH="${src_root}" python3 - <<'PY'
import csv
import json
import sys
from pathlib import Path

from pulse360_salesforce_data_cloud_mcp.config import ServiceConfig
from pulse360_salesforce_data_cloud_mcp.salesforce_cli import SalesforceCliClient

repo_root = Path.cwd()
definitions_path = repo_root / "config/data-cloud/dmo-account-extension-attributes.csv"

config = ServiceConfig.load()
sf = SalesforceCliClient(default_org_alias=config.default_org_alias)
dmo_payload = sf.describe_sobject(config.default_dmo_name)
live_fields = {field["name"] for field in dmo_payload.get("fields", [])}

with definitions_path.open(newline="") as handle:
    rows = list(csv.DictReader(handle))

required_rows = [row for row in rows if row.get("required", "").lower() == "true"]
missing_required = sorted(
    row["field_api_name"] for row in required_rows if row["field_api_name"] not in live_fields
)
present_required = sorted(
    row["field_api_name"] for row in required_rows if row["field_api_name"] in live_fields
)
missing_optional = sorted(
    row["field_api_name"]
    for row in rows
    if row.get("required", "").lower() != "true" and row["field_api_name"] not in live_fields
)

summary = {
    "org_alias": config.default_org_alias,
    "dmo_name": config.default_dmo_name,
    "definition_file": str(definitions_path),
    "required_definition_count": len(required_rows),
    "present_required_count": len(present_required),
    "missing_required_count": len(missing_required),
    "missing_required_fields": missing_required,
    "missing_optional_fields": missing_optional,
}

print(json.dumps(summary, indent=2))

if missing_required:
    sys.exit(1)
PY
