#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

run_gate() {
  local label="$1"
  shift
  echo "[RUN] ${label}"
  "$@"
}

run_gate "Codex operator health" ./scripts/check-codex-operator-health.sh

run_gate "Databricks package layout" ./scripts/validate-databricks-package-layout.sh
run_gate "Databricks Salesforce SQL pack" ./scripts/validate-databricks-salesforce-sql-pack.sh
run_gate "Databricks account intelligence sources" ./scripts/validate-databricks-account-intelligence-sources-pack.sh
run_gate "Databricks identity resolution" ./scripts/validate-databricks-identity-resolution-pack.sh
run_gate "Databricks firmographic/GenAI pack" ./scripts/validate-databricks-firmographic-genai-pack.sh
run_gate "Databricks governance evidence pack" ./scripts/validate-databricks-governance-evidence-pack.sh
run_gate "Databricks CSP smart-city pack" ./scripts/validate-databricks-csp-smart-city-pack.sh
run_gate "Databricks dashboard pack" ./scripts/validate-databricks-dashboard-pack.sh
run_gate "Databricks live runtime" ./scripts/check-databricks-data-layer-runtime.sh

run_gate "Data Cloud DMO extension" ./scripts/validate-data-cloud-dmo-extension.sh
run_gate "Data Cloud field path" ./scripts/validate-data-cloud-field-path.sh
run_gate "Data Cloud activation key alignment" ./scripts/validate-data-cloud-activation-key-alignment.sh
run_gate "Salesforce/Data Cloud MCP surface" ./scripts/validate-salesforce-data-cloud-mcp.sh
run_gate "Salesforce Account activation fields" ./scripts/validate-salesforce-account-activation-fields.sh
run_gate "Canonical exports" ./scripts/validate-canonical-exports.sh
run_gate "Contracts" ./scripts/validate-contracts.sh
run_gate "Contract completeness" ./scripts/validate-contract-completeness.sh

echo "[PASS] Pulse360 data layer closeout validation completed"
