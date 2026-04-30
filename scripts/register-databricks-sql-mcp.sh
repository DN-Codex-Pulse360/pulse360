#!/usr/bin/env bash
set -euo pipefail

server_name="${PULSE360_DATABRICKS_SQL_MCP_NAME:-databricks_sql}"
workspace_host="${PULSE360_DATABRICKS_WORKSPACE_HOST:-}"
token_env_var="${PULSE360_DATABRICKS_TOKEN_ENV_VAR:-DATABRICKS_TOKEN}"

if [[ -z "${workspace_host}" && -f "${HOME}/.databrickscfg" ]]; then
  workspace_host="$(
    awk -F= '
      /^[[:space:]]*host[[:space:]]*=/ {
        value=$2
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
        print value
        exit
      }
    ' "${HOME}/.databrickscfg"
  )"
fi

if [[ -z "${workspace_host}" ]]; then
  echo "Missing Databricks workspace host. Set PULSE360_DATABRICKS_WORKSPACE_HOST." >&2
  exit 1
fi

workspace_host="${workspace_host%/}"
mcp_url="${workspace_host}/api/2.0/mcp/sql"

if codex mcp get "${server_name}" >/dev/null 2>&1; then
  codex mcp remove "${server_name}" >/dev/null
fi

codex mcp add "${server_name}" \
  --url "${mcp_url}" \
  --bearer-token-env-var "${token_env_var}" >/dev/null

codex mcp get "${server_name}"
