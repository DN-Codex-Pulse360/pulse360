#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

required_files=(
  "docs/qa/deployed-build-audit-2026-03-09.md"
  "docs/qa/hitl-validation-checklist-2026-03-09.md"
  "docs/evidence/dan-58-governance-dashboard-latest.md"
  "scripts/validate-databricks-dashboard-visuals.sh"
  "scripts/validate-salesforce-deployment-runtime.sh"
)

for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || fail "Missing required gate artifact: $file"
done
pass "Gate artifacts present"

./scripts/validate-databricks-dashboard-pack.sh
./scripts/validate-dan-58-governance-dashboard-pack.sh
./scripts/validate-databricks-dashboard-visuals.sh
./scripts/validate-salesforce-deployment-runtime.sh

pass "Build -> Deploy -> Verify -> Close gate passed"
