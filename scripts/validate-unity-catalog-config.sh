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
pass "Unity Catalog governance config includes required baseline"
