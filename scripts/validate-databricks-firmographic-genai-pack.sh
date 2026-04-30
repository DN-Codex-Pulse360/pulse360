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
  "contracts/firmographic_research_document.schema.json"
  "contracts/firmographic_evidence_packet.schema.json"
  "contracts/genai_firmographic_enrichment_output.schema.json"
  "data/samples/firmographic_research_document_sample.json"
  "data/samples/firmographic_evidence_packet_sample.json"
  "data/samples/genai_firmographic_enrichment_output_sample.json"
  "notebooks/databricks/firmographic_genai_enrichment_job.py"
  "sql/databricks/firmographic_enrichment/00_create_bronze_schema.sql"
  "sql/databricks/firmographic_enrichment/01_create_silver_schema.sql"
  "sql/databricks/firmographic_enrichment/02_create_gold_schema.sql"
  "sql/databricks/firmographic_enrichment/05_raw_research_document_sample.sql"
  "sql/databricks/firmographic_enrichment/10_firmographic_evidence_sample.sql"
  "sql/databricks/firmographic_enrichment/15_extracted_firmographic_fact.sql"
  "sql/databricks/firmographic_enrichment/20_firmographic_fact.sql"
  "sql/databricks/firmographic_enrichment/30_account_genai_enrichment_output.sql"
  "sql/databricks/firmographic_enrichment/README.md"
  "docs/planning/pulse360-databricks-firmographic-provider-genai-design-2026-04-25.md"
)

for path in "${required_files[@]}"; do
  [[ -f "$path" ]] || fail "Missing firmographic/GPT package artifact: $path"
done
pass "Firmographic/GPT package artifacts exist"

python3 -m json.tool contracts/firmographic_research_document.schema.json >/dev/null \
  || fail "Invalid firmographic research document schema JSON"
python3 -m json.tool contracts/firmographic_evidence_packet.schema.json >/dev/null \
  || fail "Invalid firmographic evidence schema JSON"
python3 -m json.tool contracts/genai_firmographic_enrichment_output.schema.json >/dev/null \
  || fail "Invalid Gen AI enrichment output schema JSON"
python3 -m json.tool data/samples/firmographic_research_document_sample.json >/dev/null \
  || fail "Invalid firmographic research document sample JSON"
python3 -m json.tool data/samples/firmographic_evidence_packet_sample.json >/dev/null \
  || fail "Invalid firmographic evidence sample JSON"
python3 -m json.tool data/samples/genai_firmographic_enrichment_output_sample.json >/dev/null \
  || fail "Invalid Gen AI enrichment sample JSON"
pass "Firmographic/GPT JSON artifacts parse"

for token in \
  "research_document_id" \
  "source_type" \
  "source_url" \
  "document_date" \
  "accessed_at" \
  "license_or_use_basis" \
  "extracted_facts" \
  "approval_status"; do
  search_fixed "$token" contracts/firmographic_research_document.schema.json data/samples/firmographic_research_document_sample.json \
    || fail "Firmographic research document contract/sample missing token: $token"
done
pass "Firmographic research document contract preserves source governance metadata"

for token in \
  "firmographic_facts" \
  "license_or_contract_reference" \
  "source_confidence" \
  "freshness_status" \
  "source_refs"; do
  search_fixed "$token" contracts/firmographic_evidence_packet.schema.json data/samples/firmographic_evidence_packet_sample.json \
    || fail "Firmographic evidence contract/sample missing token: $token"
done
pass "Firmographic evidence packet preserves source-bound facts"

for token in \
  "llm_result_confidence" \
  "business_action_confidence" \
  "confidence_components" \
  "source_reliability_score" \
  "evidence_coverage_score" \
  "corroboration_score" \
  "freshness_score" \
  "extraction_certainty_score" \
  "conflict_penalty" \
  "schema_validation_score" \
  "citation_binding_score" \
  "actionability_score" \
  "crm_anchor_score" \
  "policy_safety_score" \
  "unsupported_claim_count" \
  "activation_eligible_flag"; do
  search_fixed "$token" contracts/genai_firmographic_enrichment_output.schema.json data/samples/genai_firmographic_enrichment_output_sample.json \
    || fail "Gen AI enrichment output contract/sample missing token: $token"
done
pass "Gen AI enrichment output preserves confidence components"

for token in \
  "pulse360_s4.bronze_firmographic.raw_research_document" \
  "pulse360_s4.silver_firmographic.extracted_firmographic_fact" \
  "pulse360_s4.bronze_firmographic" \
  "pulse360_s4.silver_firmographic" \
  "pulse360_s4.gold.account_genai_enrichment_output" \
  "license_or_use_basis" \
  "source_excerpt" \
  "extraction_confidence" \
  "approval_status" \
  "llm_result_confidence" \
  "business_action_confidence" \
  "source_bound_fixture" \
  "activation_eligible_flag"; do
  search_fixed "$token" sql/databricks/firmographic_enrichment \
    || fail "Firmographic/GPT SQL missing token: $token"
done
pass "Firmographic/GPT SQL emits source-bound confidence fields"

for token in \
  "ANTHROPIC_API_KEY" \
  "dbutils.secrets.get" \
  "anthropic-api-key" \
  "tool_choice" \
  "input_schema" \
  "json_schema" \
  "pulse360_s4.gold.account_genai_enrichment_output_runtime" \
  "source_bound_fixture" \
  "batch_llm" \
  "llm_input_hash" \
  "llm_output_hash" \
  "activation_eligible_flag" \
  "mlflow.set_experiment" \
  "mlflow.log_params" \
  "mlflow.log_metrics" \
  "trace_summary.json" \
  "PULSE360_MLFLOW_EXPERIMENT_PATH"; do
  search_fixed "$token" notebooks/databricks/firmographic_genai_enrichment_job.py \
    || fail "Firmographic/GPT runtime notebook missing token: $token"
done
pass "Firmographic/GPT runtime notebook supports live GPT and fixture modes"

for forbidden in \
  "CompanyData" \
  "BoldData" \
  "Infobel" \
  "docs.companydata" \
  "bizsearch.infobelpro"; do
  if grep -Riq "$forbidden" \
    contracts/firmographic_research_document.schema.json \
    contracts/firmographic_evidence_packet.schema.json \
    contracts/genai_firmographic_enrichment_output.schema.json \
    data/samples/firmographic_research_document_sample.json \
    data/samples/firmographic_evidence_packet_sample.json \
    data/samples/genai_firmographic_enrichment_output_sample.json \
    notebooks/databricks/firmographic_genai_enrichment_job.py \
    sql/databricks/firmographic_enrichment \
    docs/planning/pulse360-databricks-firmographic-provider-genai-design-2026-04-25.md; then
    fail "Firmographic/GPT package must not hardwire paid-provider reference: $forbidden"
  fi
done
pass "Firmographic/GPT package avoids hardwired paid-provider references"

"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/validate-firmographic-genai-design.sh"
pass "Firmographic/GPT design validator passed"

pass "Databricks firmographic/GPT pack validation completed"
