#!/usr/bin/env bash
set -euo pipefail

ASSESSMENT_FILE="${1:-docs/security/mcp-security-assessment.md}"

if [[ ! -f "${ASSESSMENT_FILE}" ]]; then
  echo "FAIL: Assessment file not found: ${ASSESSMENT_FILE}" >&2
  exit 1
fi

if rg -q "\| Pending \|" "${ASSESSMENT_FILE}"; then
  echo "FAIL: Pending control entries still exist in ${ASSESSMENT_FILE}" >&2
  exit 1
fi

required_integrations=(
  'GitHub (`gh` CLI/API)'
  "Linear MCP"
  "Notion MCP"
  'Salesforce (`sf` CLI)'
  "Databricks CLI"
)

for integration in "${required_integrations[@]}"; do
  if ! awk -F'|' -v integration="${integration}" '
    $0 ~ /^\|/ {
      col2=$2
      col5=$5
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", col2)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", col5)
      if (col2 == integration && col5 == "PASS (baseline)") {
        found=1
      }
    }
    END { exit(found ? 0 : 1) }
  ' "${ASSESSMENT_FILE}"; then
    echo "FAIL: Missing PASS baseline row for integration: ${integration}" >&2
    exit 1
  fi
done

if ! rg -q "Default status: \\*\\*BLOCKED\\*\\*" "${ASSESSMENT_FILE}"; then
  echo "FAIL: Non-official MCP default block policy not documented." >&2
  exit 1
fi

echo "PASS: MCP security gate validated against ${ASSESSMENT_FILE}"
