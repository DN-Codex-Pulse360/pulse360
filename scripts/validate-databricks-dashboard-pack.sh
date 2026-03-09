#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

sql_file="dashboards/databricks/s4_use_case_dashboard.sql"
doc_file="docs/dashboards/databricks-s4-use-case-dashboard.md"
demo_sql_file="dashboards/databricks/s4_use_case_dashboard_demo_mode.sql"
demo_doc_file="docs/dashboards/databricks-s4-dashboard-demo-mode.md"

[[ -f "$sql_file" ]] || fail "Missing SQL dashboard pack"
[[ -f "$doc_file" ]] || fail "Missing dashboard runbook"
[[ -f "$demo_sql_file" ]] || fail "Missing demo mode SQL dashboard pack"
[[ -f "$demo_doc_file" ]] || fail "Missing demo mode dashboard guide"

for token in \
  "DS-01" \
  "DS-02" \
  "DS-03" \
  "pulse360_s4.intelligence.crm_accounts_raw" \
  "pulse360_s4.intelligence.governance_ops_metrics" \
  "pulse360_s4.intelligence.hierarchy_entity_graph" \
  "fragmentation_signal" \
  "cases_resolved" \
  "quality_score" \
  "end_to_end_freshness_minutes" \
  "ingest_to_hierarchy_complete_minutes"; do
  rg -q "$token" "$sql_file" || fail "Missing token in SQL pack: $token"
done

for token in \
  "Verified Source Tables" \
  "Dataset-to-Table Mapping" \
  "High-Signal Widget Layout" \
  "Acceptance Mapping"; do
  rg -q "$token" "$doc_file" || fail "Missing section in dashboard runbook: $token"
done

pass "Databricks dashboard pack validated"

for token in \
  "demo_run_id" \
  "run_20260308_03" \
  "pulse360_s4.intelligence.crm_accounts_raw" \
  "pulse360_s4.intelligence.governance_ops_metrics" \
  "pulse360_s4.intelligence.hierarchy_entity_graph" \
  "end_to_end_freshness_minutes"; do
  rg -q "$token" "$demo_sql_file" || fail "Missing token in demo SQL pack: $token"
done

for token in \
  "Recommended Defaults" \
  "Demo Checklist"; do
  rg -q "$token" "$demo_doc_file" || fail "Missing section in demo dashboard guide: $token"
done

pass "Databricks demo-mode dashboard pack validated"
