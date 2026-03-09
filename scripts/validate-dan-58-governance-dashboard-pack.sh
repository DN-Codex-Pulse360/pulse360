#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

evidence_file="docs/evidence/dan-58-governance-dashboard-latest.md"
hitl_file="docs/qa/hitl-validation-checklist-2026-03-09.md"
dashboard_sql="dashboards/databricks/s4_use_case_dashboard.sql"
dashboard_guide="docs/dashboards/databricks-s4-use-case-dashboard.md"

[[ -f "$dashboard_sql" ]] || fail "Missing dashboard SQL: $dashboard_sql"
[[ -f "$dashboard_guide" ]] || fail "Missing dashboard guide: $dashboard_guide"
[[ -f "$evidence_file" ]] || fail "Missing DAN-58 evidence file: $evidence_file"
[[ -f "$hitl_file" ]] || fail "Missing HITL checklist file: $hitl_file"

for token in \
  "DAN-58 Governance Analytics Dashboard Evidence" \
  "Execution and Runtime Evidence" \
  "Acceptance Mapping (DAN-58 / Milestone B)" \
  "scripts/build-governance-ops-metrics.sh" \
  "scripts/validate-governance-ops-metrics-runtime.sh" \
  "scripts/validate-databricks-dashboard-pack.sh" \
  "scripts/validate-dan-58-governance-dashboard-pack.sh"; do
  rg -Fq "$token" "$evidence_file" || fail "Missing DAN-58 evidence token: $token"
done

for token in \
  "HITL Validation Checklist" \
  "HITL Comment Drafts for Milestones A-E" \
  "Milestone D Salesforce UI Proof Checklist"; do
  rg -Fq "$token" "$hitl_file" || fail "Missing HITL checklist token: $token"
done

./scripts/validate-databricks-dashboard-pack.sh
./scripts/validate-governance-ops-metrics-runtime.sh

pass "DAN-58 governance dashboard pack validated"
