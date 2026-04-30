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
  "contracts/account_intelligence_governance_evidence.schema.json"
  "contracts/databricks_activation_review_queue_to_datacloud.schema.json"
  "data/samples/account_intelligence_governance_evidence_sample.json"
  "data/samples/databricks_activation_review_queue_to_datacloud_sample.json"
  "sql/databricks/governance_evidence/00_create_gold_schema.sql"
  "sql/databricks/governance_evidence/10_account_intelligence_governance_evidence.sql"
  "sql/databricks/governance_evidence/20_activation_eligibility_review_queue.sql"
  "sql/databricks/governance_evidence/30_datacloud_activation_review_queue.sql"
  "sql/databricks/governance_evidence/40_governance_case_metrics.sql"
  "sql/databricks/governance_evidence/README.md"
)

for path in "${required_files[@]}"; do
  [[ -f "$path" ]] || fail "Missing governance evidence package artifact: $path"
done
pass "Governance evidence package artifacts exist"

python3 -m json.tool contracts/account_intelligence_governance_evidence.schema.json >/dev/null \
  || fail "Invalid governance evidence schema JSON"
python3 -m json.tool contracts/databricks_activation_review_queue_to_datacloud.schema.json >/dev/null \
  || fail "Invalid Data Cloud activation review queue schema JSON"
python3 -m json.tool data/samples/account_intelligence_governance_evidence_sample.json >/dev/null \
  || fail "Invalid governance evidence sample JSON"
python3 -m json.tool data/samples/databricks_activation_review_queue_to_datacloud_sample.json >/dev/null \
  || fail "Invalid Data Cloud activation review queue sample JSON"
pass "Governance evidence JSON artifacts parse"

for token in \
  "source_product" \
  "firmographic_genai_runtime" \
  "account_intelligence_ai_synthetic" \
  "csp_smart_city_proposition_readiness" \
  "source_refs" \
  "freshness_status" \
  "confidence_score" \
  "confidence_components" \
  "model_id" \
  "prompt_version" \
  "enrichment_run_id" \
  "activation_eligible_flag" \
  "activation_block_reasons" \
  "review_required_flag" \
  "lineage_status"; do
  search_fixed "$token" contracts/account_intelligence_governance_evidence.schema.json data/samples/account_intelligence_governance_evidence_sample.json \
    || fail "Governance evidence contract/sample missing token: $token"
done
pass "Governance evidence contract preserves required audit fields"

for token in \
  "review_queue_id" \
  "firmographic_genai_runtime" \
  "crm_activation_candidate_ids" \
  "crm_activation_candidate_names" \
  "activation_resolution_hint" \
  "target_entity_name" \
  "offering_family" \
  "target_b2b_customer_ids" \
  "target_b2b_customer_names" \
  "recommended_next_actions" \
  "review_priority" \
  "activation_block_reasons" \
  "ingestion_metadata_label" \
  "claude-sonnet-4-20250514"; do
  search_fixed "$token" contracts/databricks_activation_review_queue_to_datacloud.schema.json data/samples/databricks_activation_review_queue_to_datacloud_sample.json \
    || fail "Data Cloud activation review queue contract/sample missing token: $token"
done
pass "Data Cloud activation review queue contract preserves review handoff fields"

for token in \
  "pulse360_s4.gold.account_intelligence_governance_evidence" \
  "pulse360_s4.gold.activation_eligibility_review_queue" \
  "pulse360_s4.intelligence.datacloud_activation_review_queue" \
  "pulse360_s4.intelligence.governance_case_metrics" \
  "pulse360_s4.gold.account_genai_enrichment_output_runtime" \
  "pulse360_s4.gold_account_intelligence.account_ai_enrichment_output" \
  "pulse360_s4.gold_smart_city.smart_city_proposition_readiness" \
  "firmographic_genai_runtime" \
  "account_intelligence_ai_synthetic" \
  "csp_smart_city_proposition_readiness" \
  "missing_crm_activation_key" \
  "llm_result_confidence_below_threshold" \
  "business_action_confidence_below_threshold" \
  "unsupported_claims_present" \
  "source_product_not_activation_eligible" \
  "crm_activation_candidate_ids" \
  "crm_activation_candidate_count" \
  "ambiguous_crm_candidates_require_stewardship" \
  "crm_activation_candidate_names" \
  "target_entity_name" \
  "offering_family" \
  "target_b2b_customer_ids" \
  "target_b2b_customer_names" \
  "recommended_next_actions" \
  "review_priority" \
  "account_mapping_review" \
  "governance_review" \
  "ingestion_metadata_label" \
  "reason -> reason IS NOT NULL" \
  "source_bound" \
  "lineage_pending" \
  "blocked"; do
  search_fixed "$token" sql/databricks/governance_evidence \
    || fail "Governance evidence SQL missing token: $token"
done
pass "Governance evidence SQL preserves activation block reasons"

for token in \
  "pulse360_s4.silver_salesforce.crm_governance_case" \
  "resolved_decision_count" \
  "approved_count" \
  "deferred_count" \
  "ready_for_merge_count" \
  "average_duplicate_confidence" \
  "governance-case-feedback-metrics-v1"; do
  search_fixed "$token" sql/databricks/governance_evidence/40_governance_case_metrics.sql \
    || fail "Governance case metrics SQL missing token: $token"
done
pass "Governance case metrics SQL preserves stewardship feedback measures"

pass "Databricks governance evidence pack validation completed"
