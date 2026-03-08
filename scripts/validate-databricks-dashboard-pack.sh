#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

sql_file="dashboards/databricks/s4_use_case_dashboard.sql"
doc_file="docs/dashboards/databricks-s4-use-case-dashboard.md"

[[ -f "$sql_file" ]] || fail "Missing SQL dashboard pack"
[[ -f "$doc_file" ]] || fail "Missing dashboard runbook"

for token in \
  "DS-01" \
  "DS-02" \
  "DS-03" \
  "pulse360_s4.intelligence.duplicate_candidate_pairs" \
  "pulse360_s4.intelligence.governance_ops_metrics" \
  "pulse360_s4.intelligence.entity_hierarchy_graph" \
  "pulse360_s4.intelligence.datacloud_export_accounts" \
  "last_synced_timestamp" \
  "ds01_to_activation_minutes"; do
  rg -q "$token" "$sql_file" || fail "Missing token in SQL pack: $token"
done

for token in \
  "Recommended Lakeview Layout" \
  "Deployment Steps" \
  "Acceptance Mapping"; do
  rg -q "$token" "$doc_file" || fail "Missing section in dashboard runbook: $token"
done

pass "Databricks dashboard pack validated"
