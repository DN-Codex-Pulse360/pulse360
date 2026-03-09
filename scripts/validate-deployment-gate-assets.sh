#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

for file in \
  docs/qa/build-deploy-verify-close-gate.md \
  docs/qa/deployed-build-audit-2026-03-09.md \
  scripts/validate-databricks-dashboard-visuals.sh \
  scripts/validate-salesforce-deployment-runtime.sh \
  scripts/validate-build-deploy-verify-close-gate.sh; do
  [[ -f "$file" ]] || fail "Missing deployment-gate asset: $file"
done

for token in \
  "Build -> Deploy -> Verify -> Evidence -> Close" \
  "validate-databricks-dashboard-visuals.sh" \
  "validate-salesforce-deployment-runtime.sh" \
  "No evidence = no Done"; do
  rg -Fq "$token" docs/qa/build-deploy-verify-close-gate.md || fail "Missing gate token in docs: $token"
done

pass "Deployment gate assets validated"
