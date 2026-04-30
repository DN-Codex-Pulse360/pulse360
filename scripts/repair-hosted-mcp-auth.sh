#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

pass() {
  echo "[PASS] $1"
}

usage() {
  cat <<'EOF'
Usage:
  ./scripts/repair-hosted-mcp-auth.sh linear
  ./scripts/repair-hosted-mcp-auth.sh notion
  ./scripts/repair-hosted-mcp-auth.sh linear notion
EOF
}

[[ $# -ge 1 ]] || {
  usage
  exit 1
}

command -v codex >/dev/null 2>&1 || fail "Codex CLI is not installed or not on PATH"

for server_name in "$@"; do
  case "${server_name}" in
    linear|notion)
      ;;
    *)
      fail "Unsupported hosted MCP server: ${server_name}"
      ;;
  esac

  if codex mcp get "${server_name}" >/dev/null 2>&1; then
    pass "Found Codex MCP registration for ${server_name}"
  else
    fail "Missing Codex MCP registration for ${server_name}"
  fi

  if codex mcp logout "${server_name}" >/dev/null 2>&1; then
    pass "Removed stored OAuth session for ${server_name}"
  else
    pass "No stored OAuth session to remove for ${server_name}"
  fi

  echo "Starting OAuth login for ${server_name}..."
  codex mcp login "${server_name}"
  pass "Completed OAuth login for ${server_name}"
done
