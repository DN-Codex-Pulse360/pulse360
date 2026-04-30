#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

sql_file="dashboards/databricks/s4_use_case_dashboard.sql"
dashboard_file="dashboards/databricks/pulse360_s4_use_case_dashboard.lvdash.json"
doc_file="docs/dashboards/databricks-s4-use-case-dashboard.md"

[[ -f "$sql_file" ]] || fail "Missing SQL dashboard pack"
[[ -f "$dashboard_file" ]] || fail "Missing AI/BI dashboard JSON pack"
[[ -f "$doc_file" ]] || fail "Missing dashboard runbook"

python3 -m json.tool "$dashboard_file" >/dev/null \
  || fail "Invalid AI/BI dashboard JSON pack"

for token in \
  "DS-01" \
  "DS-02" \
  "DS-03" \
  "pulse360_s4.intelligence.duplicate_candidate_pairs" \
  "pulse360_s4.intelligence.governance_ops_metrics" \
  "pulse360_s4.identity_resolution.entity_hierarchy_edge" \
  "pulse360_s4.intelligence.datacloud_export_accounts" \
  "pulse360_s4.intelligence.governance_case_metrics" \
  "last_synced_timestamp" \
  "ds01_to_activation_minutes" \
  "resolved_decision_count" \
  "ready_for_merge_count"; do
  rg -q "$token" "$sql_file" || fail "Missing token in SQL pack: $token"
done

for token in \
  "Pulse360 S4 Account Intelligence" \
  "activation_review_queue" \
  "activation_resolution_hint" \
  "crm_activation_candidate_count" \
  "Closed Loop Feedback" \
  "governance_feedback_metrics" \
  "Salesforce Stewardship Feedback Metrics"; do
  rg -q "$token" "$dashboard_file" || fail "Missing token in dashboard JSON pack: $token"
done

for token in \
  "Recommended Lakeview Layout" \
  "Deployment Steps" \
  "Acceptance Mapping" \
  "Closed loop feedback"; do
  rg -q "$token" "$doc_file" || fail "Missing section in dashboard runbook: $token"
done

pass "Databricks dashboard pack validated"
