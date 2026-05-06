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
  "config/openai/pulse360-gpt-enrichment-spec.json"
  "notebooks/databricks/firmographic_research_discovery_job.py"
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
python3 -m json.tool config/openai/pulse360-gpt-enrichment-spec.json >/dev/null \
  || fail "Invalid OpenAI enrichment config JSON"
pass "Firmographic/GPT JSON artifacts parse"

python3 - <<'PY'
import json
from pathlib import Path

config = json.loads(Path("config/openai/pulse360-gpt-enrichment-spec.json").read_text())
if config.get("provider") != "openai":
    raise SystemExit("OpenAI config provider must be openai")
if config.get("api") != "openai_responses":
    raise SystemExit("OpenAI config api must be openai_responses")
models = config.get("models", {})
if models.get("narrative_reasoning") != "gpt-5.5":
    raise SystemExit("OpenAI config narrative_reasoning model must be gpt-5.5")
structured = config.get("structured_outputs", {})
if structured.get("strict") is not True:
    raise SystemExit("OpenAI config must require strict Structured Outputs")
reasoning = config.get("reasoning", {})
if reasoning.get("default_effort") != "low" or reasoning.get("retry_effort") != "medium":
    raise SystemExit("OpenAI config must use low default and medium retry reasoning")
cache = config.get("prompt_caching", {})
if not cache.get("prompt_cache_key"):
    raise SystemExit("OpenAI config must include a prompt_cache_key")
PY
pass "OpenAI Responses configuration is locked"

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
  "OPENAI_API_KEY" \
  "dbutils.secrets.get" \
  "openai-api-key" \
  "https://api.openai.com/v1/responses" \
  "json_schema" \
  "gpt-5.5" \
  "reasoning" \
  "retry_reasoning_effort" \
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
pass "Firmographic/GPT runtime notebook supports OpenAI Responses and fixture modes"

for token in \
  "pulse360_s4.silver_salesforce.crm_account" \
  "pulse360_s4.bronze_firmographic.account_research_discovery" \
  "target_account_count" \
  "18" \
  "official_registry" \
  "tax_authority" \
  "filing" \
  "investor_relations" \
  "annual_report" \
  "earnings_release" \
  "stock_exchange" \
  "company_website" \
  "approval_status" \
  "approved_for_gpt"; do
  search_fixed "$token" notebooks/databricks/firmographic_research_discovery_job.py \
    || fail "Firmographic research discovery job missing token: $token"
done
pass "Firmographic research discovery job covers all-account source governance"

for token in \
  "account_gpt_firmographic_latest" \
  "gpt_field_evidence" \
  "sovereign_identifier_export" \
  "firmographic_profile_export" \
  "company_classification_export" \
  "corporate_linkage_export" \
  "firmographic_source_evidence_export"; do
  search_fixed "$token" sql/databricks/gold notebooks/databricks/firmographic_genai_enrichment_job.py \
    || fail "Firmographic GPT promotion path missing token: $token"
done
pass "Firmographic GPT output feeds the five Data Cloud export contracts"

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
