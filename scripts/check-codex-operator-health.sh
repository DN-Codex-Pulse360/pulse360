#!/usr/bin/env bash
set -euo pipefail

pass() {
  echo "[PASS] $1"
}

warn() {
  echo "[WARN] $1"
}

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target_org_alias="${PULSE360_TARGET_ORG_ALIAS:-pulse360-agent-target}"

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

check_codex_login() {
  if codex login status >/dev/null 2>&1; then
    pass "Codex CLI is logged in"
  else
    fail "Codex CLI is not logged in"
  fi
}

check_mcp_registration() {
  local name="$1"
  if codex mcp get "${name}" >/dev/null 2>&1; then
    pass "Codex MCP registration exists for ${name}"
  else
    fail "Missing Codex MCP registration for ${name}"
  fi
}

check_dns() {
  python3 - <<'PY'
import socket
hosts = ["chatgpt.com", "mcp.linear.app", "mcp.notion.com"]
for host in hosts:
    try:
        socket.gethostbyname_ex(host)
        print(f"[PASS] DNS resolved for {host}")
    except Exception as exc:  # pragma: no cover - shell helper
        print(f"[FAIL] DNS resolution failed for {host}: {exc}")
        raise SystemExit(1)
PY
}

check_http_endpoint() {
  local url="$1"
  local label="$2"
  local code

  code="$(curl -sS -o /dev/null -w '%{http_code}' -I --max-time 15 "${url}" || true)"
  if [[ "${code}" == "000" || -z "${code}" ]]; then
    fail "${label} is not reachable at ${url}"
  fi

  pass "${label} responded from ${url} with HTTP ${code}"
}

check_salesforce() {
  if [[ "${PULSE360_SKIP_SALESFORCE_CHECK:-0}" == "1" ]]; then
    warn "Skipped Salesforce CLI health check"
    return
  fi

  require_command sf
  sf org display --target-org "${target_org_alias}" --json >/dev/null
  pass "Salesforce CLI can reach target org alias ${target_org_alias}"
}

check_databricks() {
  if [[ "${PULSE360_SKIP_DATABRICKS_CHECK:-0}" == "1" ]]; then
    warn "Skipped Databricks CLI health check"
    return
  fi

  if ! command -v databricks >/dev/null 2>&1; then
    warn "Databricks CLI is not installed; skipping runtime check"
    return
  fi

  if databricks workspace ls / >/dev/null 2>&1; then
    pass "Databricks CLI can list the workspace root"
  else
    warn "Databricks CLI is installed but workspace access failed"
  fi

  if codex mcp get databricks_sql >/dev/null 2>&1; then
    pass "Codex MCP registration exists for databricks_sql"
  else
    warn "Databricks SQL MCP is not registered; run scripts/register-databricks-sql-mcp.sh when SQL MCP access is needed"
  fi
}

check_github() {
  if ! command -v gh >/dev/null 2>&1; then
    warn "GitHub CLI is not installed; skipping GitHub auth check"
    return
  fi

  if gh auth status >/dev/null 2>&1; then
    pass "GitHub CLI auth is healthy"
  else
    warn "GitHub CLI auth is not healthy"
  fi
}

check_local_mcp_validation() {
  if [[ "${PULSE360_HEALTH_FULL_MCP:-0}" == "1" ]]; then
    "${repo_root}/scripts/validate-salesforce-data-cloud-mcp.sh"
    if [[ "${PULSE360_SKIP_DATABRICKS_CHECK:-0}" != "1" ]]; then
      "${repo_root}/scripts/validate-databricks-sql-mcp.sh"
    fi
  else
    warn "Skipped deep local MCP validation; set PULSE360_HEALTH_FULL_MCP=1 to run it"
  fi
}

main() {
  require_command codex
  require_command python3
  require_command curl

  check_codex_login

  check_mcp_registration linear
  check_mcp_registration notion
  check_mcp_registration pulse360_salesforce_data_cloud

  check_dns
  check_http_endpoint "https://chatgpt.com/backend-api/wham/apps" "Codex hosted app bridge"
  check_http_endpoint "https://mcp.linear.app/mcp" "Hosted Linear MCP endpoint"
  check_http_endpoint "https://mcp.notion.com/mcp" "Hosted Notion MCP endpoint"

  check_salesforce
  check_databricks
  check_github
  check_local_mcp_validation

  pass "Codex operator health check completed"
}

main "$@"
