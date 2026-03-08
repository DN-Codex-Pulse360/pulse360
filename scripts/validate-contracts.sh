#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

pass() {
  echo "[PASS] $1"
}

required_files=(
  "contracts/databricks_to_datacloud.schema.json"
  "contracts/datacloud_to_salesforce_agentforce.schema.json"
  "data/samples/databricks_enrichment_sample.csv"
  "data/samples/datacloud_activation_sample.json"
)

for f in "${required_files[@]}"; do
  [[ -f "$f" ]] || fail "Missing required file: $f"
done
pass "Required files are present"

expected_csv_header="entity_id,source_account_id,duplicate_confidence,hierarchy_parent_id,hierarchy_child_id,validity_score,review_flag,run_id,run_timestamp,model_version"
csv_header="$(head -n 1 data/samples/databricks_enrichment_sample.csv)"
[[ "$csv_header" == "$expected_csv_header" ]] || fail "CSV header mismatch"
pass "Databricks sample header matches contract"

for key in unified_profile_id identity_confidence hierarchy_payload group_revenue_rollup cross_sell_propensity health_score coverage_gap_flag last_synced_timestamp; do
  grep -q "\"$key\"" data/samples/datacloud_activation_sample.json || fail "Missing JSON key: $key"
done
pass "Data Cloud activation sample includes required keys"

grep -q '"required"' contracts/databricks_to_datacloud.schema.json || fail "Databricks schema missing required section"
grep -q '"required"' contracts/datacloud_to_salesforce_agentforce.schema.json || fail "Activation schema missing required section"
pass "Schema files include required fields declarations"

pass "Contract validation completed"
