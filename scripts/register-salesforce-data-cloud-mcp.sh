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
service_src="${repo_root}/services/salesforce_data_cloud_mcp/src"
server_name="${1:-pulse360_salesforce_data_cloud}"

default_org_alias="${PULSE360_DEFAULT_ORG_ALIAS:-pulse360-agent-target}"
default_dmo_name="${PULSE360_DEFAULT_DMO_NAME:-ssot__Account__dlm}"
default_source_object="${PULSE360_DEFAULT_SOURCE_OBJECT:-pulse360_account_intelligence_export_v2__dll}"
default_data_stream_name="${PULSE360_DEFAULT_DATA_STREAM_NAME:-DC Export Accounts P360 V2}"

command -v codex >/dev/null 2>&1 || fail "Codex CLI is not installed or not on PATH"
[[ -d "${service_src}" ]] || fail "Missing MCP service source directory: ${service_src}"

if codex mcp get "${server_name}" >/dev/null 2>&1; then
  codex mcp remove "${server_name}" >/dev/null
  pass "Removed existing Codex MCP registration: ${server_name}"
fi

codex mcp add "${server_name}" \
  --env "PYTHONPATH=${service_src}" \
  --env "PULSE360_DEFAULT_ORG_ALIAS=${default_org_alias}" \
  --env "PULSE360_DEFAULT_DMO_NAME=${default_dmo_name}" \
  --env "PULSE360_DEFAULT_SOURCE_OBJECT=${default_source_object}" \
  --env "PULSE360_DEFAULT_DATA_STREAM_NAME=${default_data_stream_name}" \
  -- \
  python3 -m pulse360_salesforce_data_cloud_mcp --transport stdio

pass "Registered ${server_name} in Codex"
codex mcp get "${server_name}"
