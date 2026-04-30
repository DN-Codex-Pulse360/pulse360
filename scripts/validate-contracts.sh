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
  "contracts/sovereign_identity_spine.schema.json"
  "contracts/registry_identity_source.schema.json"
  "contracts/weighted_attribute_resolution.schema.json"
  "contracts/m1_account_hierarchy_operational_profile.schema.json"
  "contracts/m1_account_hierarchy_action_pack.schema.json"
  "contracts/agentforce_capability_gate.schema.json"
  "contracts/firmographic_evidence_packet.schema.json"
  "contracts/genai_firmographic_enrichment_output.schema.json"
  "contracts/synthetic_enterprise_source_pack.schema.json"
  "contracts/csp_smart_city_proposition_signal.schema.json"
  "contracts/account_intelligence_ai_enrichment_output.schema.json"
  "contracts/account_intelligence_governance_evidence.schema.json"
  "data/samples/registry_identity_source_sample.json"
  "data/samples/sovereign_identity_spine_sample.json"
  "data/samples/weighted_attribute_resolution_sample.json"
  "data/samples/m1_account_hierarchy_operational_profile_sample.json"
  "data/samples/m1_account_hierarchy_action_pack_sample.json"
  "data/samples/agentforce_capability_gate_sample.json"
  "data/samples/firmographic_evidence_packet_sample.json"
  "data/samples/genai_firmographic_enrichment_output_sample.json"
  "data/samples/synthetic_enterprise_source_pack_sample.json"
  "data/samples/csp_smart_city_proposition_signal_sample.json"
  "data/samples/account_intelligence_ai_enrichment_output_sample.json"
  "data/samples/account_intelligence_governance_evidence_sample.json"
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
  "config/openai/pulse360-gpt-enrichment-spec.json"
  "data/samples/regional_public_examples/regional_public_examples_manifest.json"
  "data/samples/regional_public_examples/singtel_group_evidence_packet.json"
  "data/samples/regional_public_examples/ayala_corporation_evidence_packet.json"
  "data/samples/regional_public_examples/jg_summit_holdings_evidence_packet.json"
)

for f in "${required_files[@]}"; do
  [[ -f "$f" ]] || fail "Missing required file: $f"
done
pass "Required files are present"

expected_csv_header="entity_id,source_account_id,duplicate_confidence,hierarchy_parent_id,hierarchy_child_id,validity_score,review_flag,unified_profile_id,identity_confidence,hierarchy_payload,intent_signal_payload,group_revenue_rollup,cross_sell_propensity,health_score,coverage_gap_flag,competitor_risk_signal,primary_brand_name,active_product_count,engagement_intensity_score,open_opportunity_count,last_engagement_timestamp,last_synced_timestamp,external_legal_name,external_registration_number,is_externally_validated,validity_score_external,external_subsidiaries_found,ai_narrative,ai_recommended_actions,ai_narrative_generated_at,enrichment_run_id,regulatory_readiness_score,duplicate_exposure_count,group_known_subsidiary_count,crm_covered_subsidiary_count,group_revenue_visible,external_revenue_confirmed,model_id,prompt_version,source_refs,citation_count,run_id,run_timestamp,model_version"
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

for key in unified_profile_id identity_confidence source_account_id hierarchy_payload intent_signal_payload group_revenue_rollup cross_sell_propensity health_score coverage_gap_flag competitor_risk_signal primary_brand_name active_product_count engagement_intensity_score open_opportunity_count last_engagement_timestamp last_synced_timestamp external_legal_name is_externally_validated validity_score_external ai_narrative ai_recommended_actions ai_narrative_generated_at enrichment_run_id regulatory_readiness_score duplicate_exposure_count group_known_subsidiary_count crm_covered_subsidiary_count group_revenue_visible external_revenue_confirmed model_id prompt_version source_refs citation_count; do
  grep -q "\"$key\"" data/samples/datacloud_activation_sample.json || fail "Missing JSON key: $key"
done
grep -q '\\"crm_record_id\\"' data/samples/datacloud_activation_sample.json || fail "Activation sample hierarchy payload missing crm_record_id"
grep -q '\\"target_record_id\\":\\"' data/samples/datacloud_activation_sample.json || fail "Activation sample actions missing target_record_id deep link"
pass "Data Cloud activation sample includes required keys"

grep -q '"required"' contracts/databricks_to_datacloud.schema.json || fail "Databricks schema missing required section"
grep -q '"sovereign_identity_key"' contracts/sovereign_identity_spine.schema.json || fail "Sovereign identity schema missing sovereign_identity_key"
grep -q '"registry_source_id"' contracts/registry_identity_source.schema.json || fail "Registry identity source schema missing registry_source_id"
grep -q '"source_identifiers"' contracts/sovereign_identity_spine.schema.json || fail "Sovereign identity schema missing source identifiers"
grep -q '"source_contributions"' contracts/weighted_attribute_resolution.schema.json || fail "Weighted attribute schema missing source contributions"
grep -q '"freshness_status"' contracts/weighted_attribute_resolution.schema.json || fail "Weighted attribute schema missing freshness status"
grep -q '"operational_profile_id"' contracts/m1_account_hierarchy_operational_profile.schema.json || fail "M1 operational profile schema missing operational_profile_id"
grep -q '"primary_anchor_account_id"' contracts/m1_account_hierarchy_operational_profile.schema.json || fail "M1 operational profile schema missing primary_anchor_account_id"
grep -q '"hierarchy_confidence"' contracts/m1_account_hierarchy_operational_profile.schema.json || fail "M1 operational profile schema missing hierarchy_confidence"
grep -q '"surface_context"' contracts/m1_account_hierarchy_action_pack.schema.json || fail "M1 action pack schema missing surface_context"
grep -q '"crm_safe_execution_key"' contracts/m1_account_hierarchy_action_pack.schema.json || fail "M1 action pack schema missing crm_safe_execution_key"
grep -q '"expected_artifact"' contracts/m1_account_hierarchy_action_pack.schema.json || fail "M1 action pack schema missing expected_artifact"
grep -q '"capability_state"' contracts/agentforce_capability_gate.schema.json || fail "Agentforce gate schema missing capability_state"
grep -q '"native_runtime_verified"' contracts/agentforce_capability_gate.schema.json || fail "Agentforce gate schema missing native_runtime_verified"
grep -q '"trust_audit_policy"' contracts/agentforce_capability_gate.schema.json || fail "Agentforce gate schema missing trust_audit_policy"
grep -q '"sovereign_identity_key"' data/samples/sovereign_identity_spine_sample.json || fail "Sovereign identity sample missing sovereign identity key"
grep -q '"registry_source_id"' data/samples/registry_identity_source_sample.json || fail "Registry identity source sample missing registry_source_id"
grep -q '"source_identifiers"' data/samples/sovereign_identity_spine_sample.json || fail "Sovereign identity sample missing source identifiers"
grep -q '"source_contributions"' data/samples/weighted_attribute_resolution_sample.json || fail "Weighted attribute sample missing source contributions"
grep -q '"freshness_status"' data/samples/weighted_attribute_resolution_sample.json || fail "Weighted attribute sample missing freshness status"
grep -q '"operational_profile_id"' data/samples/m1_account_hierarchy_operational_profile_sample.json || fail "M1 operational profile sample missing operational_profile_id"
grep -q '"primary_anchor_account_id"' data/samples/m1_account_hierarchy_operational_profile_sample.json || fail "M1 operational profile sample missing primary_anchor_account_id"
grep -q '"hierarchy_confidence"' data/samples/m1_account_hierarchy_operational_profile_sample.json || fail "M1 operational profile sample missing hierarchy_confidence"
grep -q '"surface_context"' data/samples/m1_account_hierarchy_action_pack_sample.json || fail "M1 action pack sample missing surface_context"
grep -q '"crm_safe_execution_key"' data/samples/m1_account_hierarchy_action_pack_sample.json || fail "M1 action pack sample missing crm_safe_execution_key"
grep -q '"expected_artifact"' data/samples/m1_account_hierarchy_action_pack_sample.json || fail "M1 action pack sample missing expected_artifact"
grep -q '"capability_state"' data/samples/agentforce_capability_gate_sample.json || fail "Agentforce gate sample missing capability_state"
grep -q '"native_runtime_verified"' data/samples/agentforce_capability_gate_sample.json || fail "Agentforce gate sample missing native_runtime_verified"
grep -q '"trust_audit_policy"' data/samples/agentforce_capability_gate_sample.json || fail "Agentforce gate sample missing trust_audit_policy"
grep -q '"synthetic_flag"' contracts/synthetic_enterprise_source_pack.schema.json || fail "Synthetic enterprise source schema missing synthetic_flag"
grep -q '"source_family"' contracts/synthetic_enterprise_source_pack.schema.json || fail "Synthetic enterprise source schema missing source_family"
grep -q '"expected_ground_truth"' contracts/synthetic_enterprise_source_pack.schema.json || fail "Synthetic enterprise source schema missing expected_ground_truth"
grep -q '"erp"' data/samples/synthetic_enterprise_source_pack_sample.json || fail "Synthetic enterprise source sample missing ERP record"
grep -q '"epm"' data/samples/synthetic_enterprise_source_pack_sample.json || fail "Synthetic enterprise source sample missing EPM record"
grep -q '"product_telemetry"' data/samples/synthetic_enterprise_source_pack_sample.json || fail "Synthetic enterprise source sample missing product telemetry record"
grep -q '"intelligent_parking"' contracts/csp_smart_city_proposition_signal.schema.json || fail "CSP smart-city schema missing intelligent parking offering"
grep -q '"urban_data_brokerage"' contracts/csp_smart_city_proposition_signal.schema.json || fail "CSP smart-city schema missing urban data brokerage offering"
grep -q '"connected_city_iot_platform"' contracts/csp_smart_city_proposition_signal.schema.json || fail "CSP smart-city schema missing connected city IoT offering"
grep -q '"consent_privacy_classification"' contracts/csp_smart_city_proposition_signal.schema.json || fail "CSP smart-city schema missing consent/privacy classification"
grep -q '"city_hcmc_iot_locality"' data/samples/csp_smart_city_proposition_signal_sample.json || fail "CSP smart-city sample missing HCMC IoT locality scenario"
grep -q '"municipal_open_data"' data/samples/csp_smart_city_proposition_signal_sample.json || fail "CSP smart-city sample missing municipal open data source"
grep -q '"ai_enrichment_id"' contracts/account_intelligence_ai_enrichment_output.schema.json || fail "Account intelligence AI schema missing ai_enrichment_id"
grep -q '"activation_state"' contracts/account_intelligence_ai_enrichment_output.schema.json || fail "Account intelligence AI schema missing activation_state"
grep -q '"cross_source_coverage_score"' contracts/account_intelligence_ai_enrichment_output.schema.json || fail "Account intelligence AI schema missing cross_source_coverage_score"
grep -q '"support_risk_present"' data/samples/account_intelligence_ai_enrichment_output_sample.json || fail "Account intelligence AI sample missing support risk block"
grep -q '"required"' contracts/datacloud_to_salesforce_agentforce.schema.json || fail "Activation schema missing required section"
grep -q '"canonical_account_id"' contracts/datacloud_account_core_canonical_v2.schema.json || fail "Account core v2 schema missing canonical_account_id"
grep -q '"brand_id"' contracts/datacloud_product_brand_canonical_v2.schema.json || fail "Product brand v2 schema missing brand_id"
grep -q '"engagement_type"' contracts/datacloud_engagement_canonical_v2.schema.json || fail "Engagement v2 schema missing engagement_type"
grep -q '"narrative_reasoning"' config/openai/pulse360-gpt-enrichment-spec.json || fail "GPT enrichment spec missing narrative model"
grep -q '"source_id"' contracts/databricks_to_datacloud.schema.json || fail "Databricks schema missing source reference shape"
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
grep -q 'crm_record_id' data/samples/databricks_enrichment_sample.csv || fail "Databricks enrichment sample hierarchy payload missing crm_record_id"
grep -Fq 'target_record_id"":""' data/samples/databricks_enrichment_sample.csv || fail "Databricks enrichment sample actions missing target_record_id deep link"
grep -q '"entity_key"' data/samples/regional_public_examples/regional_public_examples_manifest.json || fail "Regional manifest missing entity_key"
grep -q '"source_id"' data/samples/regional_public_examples/singtel_group_evidence_packet.json || fail "Singtel evidence packet missing source_id"
grep -q '"source_id"' data/samples/regional_public_examples/ayala_corporation_evidence_packet.json || fail "Ayala evidence packet missing source_id"
grep -q '"source_id"' data/samples/regional_public_examples/jg_summit_holdings_evidence_packet.json || fail "JG Summit evidence packet missing source_id"
pass "Canonical export JSONL samples include required keys"

"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/validate-contract-completeness.sh"
pass "Contract completeness validator passed"

"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/validate-m1-data-cloud-operational-profile.sh"
pass "M1 Data Cloud operational profile validator passed"

"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/validate-m1-salesforce-action-surface.sh"
pass "M1 Salesforce action surface validator passed"

"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/validate-agentforce-capability-gates.sh"
pass "Agentforce capability gate validator passed"

"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/validate-firmographic-genai-design.sh"
pass "Firmographic/GPT design validator passed"

"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/validate-databricks-firmographic-genai-pack.sh"
pass "Databricks firmographic/GPT pack validator passed"

"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/validate-databricks-account-intelligence-sources-pack.sh"
pass "Databricks account intelligence source pack validator passed"

"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/validate-databricks-csp-smart-city-pack.sh"
pass "Databricks CSP smart-city pack validator passed"

"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/validate-databricks-governance-evidence-pack.sh"
pass "Databricks governance evidence pack validator passed"

pass "Contract validation completed"
