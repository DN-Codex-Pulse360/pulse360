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
  "contracts/datacloud_account_core_canonical_v2.schema.json"
  "contracts/datacloud_product_brand_canonical_v2.schema.json"
  "contracts/datacloud_engagement_canonical_v2.schema.json"
  "data/samples/databricks_enrichment_sample.csv"
  "data/samples/datacloud_activation_sample.json"
  "data/samples/datacloud_account_core_canonical_v2_sample.json"
  "data/samples/datacloud_product_brand_canonical_v2_sample.json"
  "data/samples/datacloud_engagement_canonical_v2_sample.json"
  "data/samples/datacloud_account_core_canonical_v2_export.csv"
  "data/samples/datacloud_account_core_canonical_v2_export.jsonl"
  "data/samples/datacloud_product_brand_canonical_v2_export.csv"
  "data/samples/datacloud_product_brand_canonical_v2_export.jsonl"
  "data/samples/datacloud_engagement_canonical_v2_export.csv"
  "data/samples/datacloud_engagement_canonical_v2_export.jsonl"
)

for f in "${required_files[@]}"; do
  [[ -f "$f" ]] || fail "Missing required file: $f"
done
pass "Required files are present"

expected_csv_header="entity_id,source_account_id,duplicate_confidence,hierarchy_parent_id,hierarchy_child_id,validity_score,review_flag,run_id,run_timestamp,model_version"
csv_header="$(head -n 1 data/samples/databricks_enrichment_sample.csv)"
[[ "$csv_header" == "$expected_csv_header" ]] || fail "CSV header mismatch"
pass "Databricks sample header matches contract"

expected_account_export_csv_header="canonical_account_id,ssot_id,source_account_id,deterministic_key,account_name,parent_account_id,industry,country_code,identity_confidence,validity_score,run_id,run_timestamp,model_version"
account_export_csv_header="$(head -n 1 data/samples/datacloud_account_core_canonical_v2_export.csv)"
[[ "$account_export_csv_header" == "$expected_account_export_csv_header" ]] || fail "Account core export CSV header mismatch"

expected_product_brand_export_csv_header="canonical_account_id,product_id,master_product_id,bundle_product_id,brand_id,brand_name,relationship_type,is_active,run_id,run_timestamp,model_version"
product_brand_export_csv_header="$(head -n 1 data/samples/datacloud_product_brand_canonical_v2_export.csv)"
[[ "$product_brand_export_csv_header" == "$expected_product_brand_export_csv_header" ]] || fail "Product brand export CSV header mismatch"

expected_engagement_export_csv_header="canonical_account_id,engagement_id,engagement_type,engagement_timestamp,channel,related_product_id,related_brand_id,related_opportunity_id,engagement_score,run_id,run_timestamp,model_version"
engagement_export_csv_header="$(head -n 1 data/samples/datacloud_engagement_canonical_v2_export.csv)"
[[ "$engagement_export_csv_header" == "$expected_engagement_export_csv_header" ]] || fail "Engagement export CSV header mismatch"
pass "Canonical export CSV headers match contract"

for key in unified_profile_id identity_confidence hierarchy_payload group_revenue_rollup cross_sell_propensity health_score coverage_gap_flag competitor_risk_signal primary_brand_name active_product_count engagement_intensity_score open_opportunity_count last_engagement_timestamp last_synced_timestamp; do
  grep -q "\"$key\"" data/samples/datacloud_activation_sample.json || fail "Missing JSON key: $key"
done
pass "Data Cloud activation sample includes required keys"

grep -q '"required"' contracts/databricks_to_datacloud.schema.json || fail "Databricks schema missing required section"
grep -q '"required"' contracts/datacloud_to_salesforce_agentforce.schema.json || fail "Activation schema missing required section"
grep -q '"canonical_account_id"' contracts/datacloud_account_core_canonical_v2.schema.json || fail "Account core v2 schema missing canonical_account_id"
grep -q '"brand_id"' contracts/datacloud_product_brand_canonical_v2.schema.json || fail "Product brand v2 schema missing brand_id"
grep -q '"engagement_type"' contracts/datacloud_engagement_canonical_v2.schema.json || fail "Engagement v2 schema missing engagement_type"
pass "Schema files include required fields declarations"

for jsonl in \
  data/samples/datacloud_account_core_canonical_v2_export.jsonl \
  data/samples/datacloud_product_brand_canonical_v2_export.jsonl \
  data/samples/datacloud_engagement_canonical_v2_export.jsonl; do
  [[ "$(wc -l < "$jsonl")" -ge 1 ]] || fail "JSONL export has no rows: $jsonl"
done

grep -q '"canonical_account_id"' data/samples/datacloud_account_core_canonical_v2_export.jsonl || fail "Account core export JSONL missing canonical_account_id"
grep -q '"brand_id"' data/samples/datacloud_product_brand_canonical_v2_export.jsonl || fail "Product brand export JSONL missing brand_id"
grep -q '"engagement_type"' data/samples/datacloud_engagement_canonical_v2_export.jsonl || fail "Engagement export JSONL missing engagement_type"
pass "Canonical export JSONL samples include required keys"

pass "Contract validation completed"
