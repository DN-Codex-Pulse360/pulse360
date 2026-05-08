#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

cfg="config/databricks/unity-catalog-governance.yaml"
[[ -f "$cfg" ]] || fail "Missing Unity Catalog governance config"

for key in "catalog:" "schema:" "required_tables:" "required_table_links:"; do
  grep -q "$key" "$cfg" || fail "Missing key in governance config: $key"
done

grep -q "crm_accounts_raw" "$cfg" || fail "Missing required source table"
grep -q "hierarchy_entity_graph" "$cfg" || fail "Missing hierarchy table"
grep -q "account_core_export" "$cfg" || fail "Missing canonical account export table"
grep -q "product_brand_export" "$cfg" || fail "Missing canonical product brand export table"
grep -q "engagement_export" "$cfg" || fail "Missing canonical engagement export table"
grep -q "account_feature_snapshot" "$cfg" || fail "Missing account feature snapshot table"
grep -q "model_score_output" "$cfg" || fail "Missing model score output table"
grep -q "governance_evidence_packet" "$cfg" || fail "Missing governance evidence packet table"
grep -q "m1_account_hierarchy_edge" "$cfg" || fail "Missing M1 hierarchy edge table"
grep -q "m1_account_group_rollup" "$cfg" || fail "Missing M1 account group rollup table"
grep -q "m1_account_hierarchy_activation" "$cfg" || fail "Missing M1 hierarchy activation table"
pass "Unity Catalog governance config includes required baseline"
