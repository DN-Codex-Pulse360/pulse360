#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

pass() {
  echo "[PASS] $1"
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
service_root="${repo_root}/services/salesforce_data_cloud_mcp"
src_root="${service_root}/src"

[[ -d "${service_root}" ]] || fail "Missing MCP service root: ${service_root}"
[[ -f "${service_root}/pyproject.toml" ]] || fail "Missing MCP pyproject"
[[ -f "${src_root}/pulse360_salesforce_data_cloud_mcp/server.py" ]] || fail "Missing server module"
[[ -f "${src_root}/pulse360_salesforce_data_cloud_mcp/__main__.py" ]] || fail "Missing package entrypoint"
pass "MCP service files are present"

python3 -m py_compile \
  "${src_root}/pulse360_salesforce_data_cloud_mcp/__init__.py" \
  "${src_root}/pulse360_salesforce_data_cloud_mcp/__main__.py" \
  "${src_root}/pulse360_salesforce_data_cloud_mcp/comparison.py" \
  "${src_root}/pulse360_salesforce_data_cloud_mcp/config.py" \
  "${src_root}/pulse360_salesforce_data_cloud_mcp/salesforce_cli.py" \
  "${src_root}/pulse360_salesforce_data_cloud_mcp/server.py"
pass "MCP Python modules compile cleanly"

PYTHONPATH="${src_root}" python3 - <<'PY'
import asyncio
import json

from pulse360_salesforce_data_cloud_mcp import build_server

expected = {
    "compare_export_contract_to_account",
    "compare_export_contract_to_dmo",
    "compare_export_contract_to_source_object",
    "describe_sobject",
    "get_data_stream_status",
    "list_account_fields",
    "list_activation_targets",
    "list_data_streams",
    "list_dmo_fields",
    "query_dmo",
    "query_soql",
    "report_live_field_path_status",
    "report_unmapped_fields",
}

server = build_server()
tools = asyncio.run(server.list_tools())
tool_names = {tool.name for tool in tools}
missing = sorted(expected - tool_names)
unexpected = sorted(tool_names - expected)
if missing or unexpected:
    raise SystemExit(
        "Unexpected MCP tool registration: "
        + json.dumps(
            {
                "missing": missing,
                "unexpected": unexpected,
                "actual": sorted(tool_names),
            },
            indent=2,
        )
    )

print(json.dumps({"tool_count": len(tool_names), "tool_names": sorted(tool_names)}, indent=2))
PY
pass "MCP server registers the expected read-only tool surface"

if [[ "${PULSE360_MCP_SKIP_LIVE_CHECK:-0}" == "1" ]]; then
  pass "Skipped live Salesforce CLI smoke check"
else
  PYTHONPATH="${src_root}" python3 - <<'PY'
import json

from pulse360_salesforce_data_cloud_mcp.config import ServiceConfig
from pulse360_salesforce_data_cloud_mcp.salesforce_cli import SalesforceCliClient

config = ServiceConfig.load()
sf = SalesforceCliClient(default_org_alias=config.default_org_alias)
org = sf.org_display()
account = sf.describe_sobject("Account")
stream = sf.query(
    "SELECT Name, ImportRunStatus, IsNewFieldsAvailable "
    f"FROM DataStream WHERE Name = '{config.default_data_stream_name}'"
)
source = sf.describe_sobject(config.default_source_object)
dmo = sf.describe_sobject(config.default_dmo_name)
print(
    json.dumps(
        {
            "org_alias": config.default_org_alias,
            "username": org.get("username"),
            "org_id": org.get("id"),
            "data_stream_name": config.default_data_stream_name,
            "account_field_count": len(account.get("fields", [])),
            "source_object_name": source.get("name"),
            "source_object_field_count": len(source.get("fields", [])),
            "dmo_name": dmo.get("name"),
            "dmo_field_count": len(dmo.get("fields", [])),
            "data_stream_records": stream.get("records", []),
        },
        indent=2,
    )
)
PY
  pass "MCP service can reach the default Salesforce and Data Cloud surfaces through the official sf CLI"
fi

pass "Salesforce/Data Cloud MCP validation completed"
