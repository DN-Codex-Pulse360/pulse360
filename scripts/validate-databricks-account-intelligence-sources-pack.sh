#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

search_fixed() {
  local needle="$1"
  shift

  if command -v rg >/dev/null 2>&1; then
    rg -Fq "$needle" "$@"
  else
    grep -Fq -- "$needle" "$@"
  fi
}

required_files=(
  "contracts/synthetic_enterprise_source_pack.schema.json"
  "contracts/account_intelligence_ai_enrichment_output.schema.json"
  "data/samples/synthetic_enterprise_source_pack_sample.json"
  "data/samples/account_intelligence_ai_enrichment_output_sample.json"
  "config/data-cloud/databricks-activation-review-queue-field-mapping.csv"
  "sql/databricks/account_intelligence_sources/00_create_schemas.sql"
  "sql/databricks/account_intelligence_sources/05_synthetic_enterprise_source_sample.sql"
  "sql/databricks/account_intelligence_sources/10_synthetic_source_signal.sql"
  "sql/databricks/account_intelligence_sources/20_account_ai_enrichment_output.sql"
  "sql/databricks/account_intelligence_sources/README.md"
)

for path in "${required_files[@]}"; do
  [[ -f "$path" ]] || fail "Missing account intelligence source package artifact: $path"
done
pass "Account intelligence source package artifacts exist"

python3 -m json.tool contracts/synthetic_enterprise_source_pack.schema.json >/dev/null \
  || fail "Invalid synthetic enterprise source pack schema JSON"
python3 -m json.tool contracts/account_intelligence_ai_enrichment_output.schema.json >/dev/null \
  || fail "Invalid account intelligence AI enrichment output schema JSON"
python3 -m json.tool data/samples/synthetic_enterprise_source_pack_sample.json >/dev/null \
  || fail "Invalid synthetic enterprise source pack sample JSON"
python3 -m json.tool data/samples/account_intelligence_ai_enrichment_output_sample.json >/dev/null \
  || fail "Invalid account intelligence AI enrichment sample JSON"
pass "Account intelligence source JSON artifacts parse"

for token in \
  "source_pack_id" \
  "synthetic_flag" \
  "generation_seed" \
  "source_records" \
  "expected_ground_truth" \
  "source_family" \
  "erp" \
  "epm" \
  "support" \
  "contracts" \
  "product_telemetry" \
  "marketing_intent" \
  "internal_hierarchy" \
  "edge_case_tags"; do
  search_fixed "$token" contracts/synthetic_enterprise_source_pack.schema.json data/samples/synthetic_enterprise_source_pack_sample.json \
    || fail "Synthetic enterprise source contract/sample missing token: $token"
done
pass "Synthetic enterprise source pack preserves source metadata and ground truth"

for token in \
  "ai_enrichment_id" \
  "source_record_ids" \
  "source_families" \
  "inferred_signals" \
  "recommended_actions" \
  "llm_result_confidence" \
  "business_action_confidence" \
  "confidence_components" \
  "cross_source_coverage_score" \
  "crm_anchor_score" \
  "ground_truth_alignment_score" \
  "activation_state" \
  "activation_block_reasons" \
  "llm_input_hash" \
  "llm_output_hash" \
  "synthetic_fixture"; do
  search_fixed "$token" contracts/account_intelligence_ai_enrichment_output.schema.json data/samples/account_intelligence_ai_enrichment_output_sample.json \
    || fail "Account intelligence AI enrichment contract/sample missing token: $token"
done
pass "Account intelligence AI enrichment output preserves confidence and activation fields"

for token in \
  "pulse360_s4.bronze_enterprise_sources.synthetic_enterprise_source_sample" \
  "pulse360_s4.silver_enterprise_sources.synthetic_source_signal" \
  "pulse360_s4.gold_account_intelligence.account_ai_enrichment_output" \
  "source_confidence" \
  "normalized_signal_type" \
  "source_reliability_band" \
  "support_risk_present" \
  "subsidiary_gap_requires_stewardship" \
  "llm_result_confidence_below_threshold" \
  "business_action_confidence" \
  "confidence_components" \
  "synthetic-ai-enrichment-fixture" \
  "pulse360-account-intelligence-evidence-v1"; do
  search_fixed "$token" sql/databricks/account_intelligence_sources \
    || fail "Account intelligence source SQL missing token: $token"
done
pass "Account intelligence source SQL emits governed AI enrichment output"

for token in \
  "source_product,source_product__c" \
  "review_queue_id,review_queue_id__c" \
  "resolved_entity_id,resolved_entity_id__c" \
  "activation_block_reasons,activation_block_reasons__c" \
  "source_run_timestamp,source_run_timestamp__c"; do
  search_fixed "$token" config/data-cloud/databricks-activation-review-queue-field-mapping.csv \
    || fail "Data Cloud activation review mapping missing token: $token"
done
pass "Data Cloud activation review mapping includes synthetic evidence fields"

for forbidden in \
  "CompanyData" \
  "BoldData" \
  "Infobel" \
  "docs.companydata" \
  "bizsearch.infobelpro"; do
  if grep -Riq "$forbidden" \
    contracts/synthetic_enterprise_source_pack.schema.json \
    contracts/account_intelligence_ai_enrichment_output.schema.json \
    data/samples/synthetic_enterprise_source_pack_sample.json \
    data/samples/account_intelligence_ai_enrichment_output_sample.json \
    sql/databricks/account_intelligence_sources; then
    fail "Account intelligence source pack must not hardwire paid-provider reference: $forbidden"
  fi
done
pass "Account intelligence source pack avoids hardwired paid-provider references"

pass "Databricks account intelligence source pack validation completed"
