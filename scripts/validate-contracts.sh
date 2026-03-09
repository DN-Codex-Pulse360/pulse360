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
  "contracts/salesforce_governance_case_lwc.schema.json"
  "contracts/salesforce_account360_hierarchy_lwc.schema.json"
  "contracts/agentforce_account_health_scan_action.schema.json"
  "contracts/salesforce_cross_sell_quick_create_action.schema.json"
  "contracts/datacloud_account_core_canonical_v2.schema.json"
  "contracts/datacloud_product_brand_canonical_v2.schema.json"
  "contracts/datacloud_engagement_canonical_v2.schema.json"
  "data/samples/databricks_enrichment_sample.csv"
  "data/samples/datacloud_activation_sample.json"
  "data/samples/salesforce_governance_case_lwc_sample.json"
  "data/samples/salesforce_account360_hierarchy_lwc_sample.json"
  "data/samples/agentforce_account_health_scan_action_sample.json"
  "data/samples/salesforce_cross_sell_quick_create_action_sample.json"
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

for key in governance_case_id run_id run_timestamp pair_confidence candidate_left candidate_right conflict_fields recommendation audit; do
  grep -q "\"$key\"" data/samples/salesforce_governance_case_lwc_sample.json || fail "Missing governance sample key: $key"
done
pass "Governance side-by-side sample includes required keys"

for key in unified_profile_id source_account_id account_name hierarchy_payload group_revenue_rollup cross_sell_propensity coverage_gap_flag last_synced_timestamp data_health_status degraded_mode_message run_id run_timestamp model_version; do
  grep -q "\"$key\"" data/samples/salesforce_account360_hierarchy_lwc_sample.json || fail "Missing account360 sample key: $key"
done
pass "Account 360 hierarchy sample includes required keys"

for key in action_name request response action_request_id source_account_id correlation_id requested_at status http_status api_latency_ms data_source response_card duplicate_evidence pair_count max_confidence confidence_band cross_sell_estimate health_score competitor_risk_signal ai_impact_summary last_synced_timestamp failure_mode is_non_blocking error_code user_message retry_disposition; do
  grep -q "\"$key\"" data/samples/agentforce_account_health_scan_action_sample.json || fail "Missing agentforce sample key: $key"
done
pass "Agentforce health scan sample includes required keys"

for key in banner source_account_id unified_profile_id cross_sell_propensity coverage_gap_flag open_opportunity_count last_synced_timestamp banner_state quick_create context_account_id contact_association linkage_type contact_record_id opportunity_payload refresh_trigger event_name is_enabled trigger_source expected_recompute_window_minutes; do
  grep -q "\"$key\"" data/samples/salesforce_cross_sell_quick_create_action_sample.json || fail "Missing cross-sell sample key: $key"
done
pass "Cross-sell quick-create sample includes required keys"

grep -q '"required"' contracts/databricks_to_datacloud.schema.json || fail "Databricks schema missing required section"
grep -q '"required"' contracts/datacloud_to_salesforce_agentforce.schema.json || fail "Activation schema missing required section"
grep -q '"pair_confidence"' contracts/salesforce_governance_case_lwc.schema.json || fail "Governance LWC schema missing pair_confidence"
grep -q '"audit_event_id"' contracts/salesforce_governance_case_lwc.schema.json || fail "Governance LWC schema missing audit_event_id"
grep -q '"data_health_status"' contracts/salesforce_account360_hierarchy_lwc.schema.json || fail "Account360 LWC schema missing data_health_status"
grep -q '"degraded_mode_message"' contracts/salesforce_account360_hierarchy_lwc.schema.json || fail "Account360 LWC schema missing degraded_mode_message"
grep -q '"ai_impact_summary"' contracts/agentforce_account_health_scan_action.schema.json || fail "Agentforce action schema missing ai_impact_summary"
grep -q '"failure_mode"' contracts/agentforce_account_health_scan_action.schema.json || fail "Agentforce action schema missing failure_mode"
grep -q '"contact_association"' contracts/salesforce_cross_sell_quick_create_action.schema.json || fail "Cross-sell schema missing contact_association"
grep -q '"event_name"' contracts/salesforce_cross_sell_quick_create_action.schema.json || fail "Cross-sell schema missing refresh event_name"
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
