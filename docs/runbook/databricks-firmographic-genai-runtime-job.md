# Databricks Firmographic GenAI Runtime Job

Date: 2026-04-26

## Workspace Assets

- Notebook path: `/Shared/pulse360/pulse360-firmographic-enrichment/dev/notebooks/databricks/firmographic_genai_enrichment_job`
- Job name: `pulse360-firmographic-genai-enrichment job`
- Job ID: `166785517420650`
- Successful run ID: `458309872401849`
- Target staging table: `pulse360_s4.gold.account_genai_enrichment_output_runtime`

## Runtime Mode

The job supports deterministic fixture mode and live Claude mode. Fixture mode
uses `generation_mode = source_bound_fixture` and writes governed,
contract-shaped rows to the runtime staging table.

Live Claude mode uses `generation_mode = batch_llm` when the Anthropic API key
is available through Databricks secrets.

## Secret Configuration

- Secret scope: `pulse360-ai`
- Secret key: `anthropic-api-key`
- Runtime lookup: `dbutils.secrets.get(scope="pulse360-ai", key="anthropic-api-key")`

Do not store provider keys in source, notebook parameters, job JSON, Linear, or
dashboard text. Rotate any key that was pasted into chat or logs.

## Verification

The successful non-prod run wrote to the runtime staging table.

Verification query:

```sql
SELECT
  count(*) AS row_count,
  max(run_timestamp) AS latest_run_timestamp,
  max(generation_mode) AS latest_generation_mode,
  max(activation_eligible_flag) AS latest_activation_eligible_flag
FROM pulse360_s4.gold.account_genai_enrichment_output_runtime;
```

Verified result on 2026-04-26:

```text
row_count = 3
latest_run_timestamp = 2026-04-26T02:57:27Z
latest_generation_mode = source_bound_fixture
latest_activation_eligible_flag = false
```

## MLflow Trace Logging

- Experiment path:
  `/Shared/pulse360/pulse360-firmographic-enrichment/dev/mlflow/firmographic-genai-runtime`
- Experiment ID:
  `1941241485805681`
- Trace artifact:
  `governance/trace_summary.json`

The runtime logs metadata, hashes, confidence metrics, validation status, and
activation decision only. It does not log provider secrets, raw prompts, raw
evidence packets, or full model responses.

Logged params include:

- provider
- model ID
- prompt version
- generation mode
- model version
- evidence packet ID
- resolved entity ID
- input/output hashes
- target table

Logged metrics include:

- LLM result confidence
- business action confidence
- unsupported claim count
- source reference count
- action count
- activation eligibility
- component confidence scores

Verified live Claude result on 2026-04-26:

```text
run_id = 789361409093
row_count = 4
latest_run_timestamp = 2026-04-26T03:53:16Z
latest_generation_mode = batch_llm
latest_model_id = claude-sonnet-4-20250514
latest_llm_result_confidence = 0.8037
latest_business_action_confidence = 0.7622
latest_activation_eligible_flag = false
```

Verified MLflow trace result on 2026-04-26:

```text
databricks_job_run_id = 600498031946028
mlflow_run_id = 2fd189415f1a409c8fb3cd36fa485e97
mlflow_status = FINISHED
mlflow_run_name = genai_firmographic_batch_llm_20260426043152
generation_mode = batch_llm
model_id = claude-sonnet-4-20250514
validation_result = passed
llm_result_confidence = 0.8037
business_action_confidence = 0.7622
activation_eligible = 0.0
artifact = governance/trace_summary.json
```

The Databricks SQL verification after the traced run returned:

```text
row_count = 6
latest_run_timestamp = 2026-04-26T04:31:52Z
latest_generation_mode = batch_llm
latest_model_id = claude-sonnet-4-20250514
latest_llm_result_confidence = 0.8037
latest_business_action_confidence = 0.7622
latest_activation_eligible_flag = false
```

## Governed Research Extraction

The runtime now has a provider-neutral research intake path before GenAI
narrative generation. The path is designed to model the structure of
firmographic provider evidence without hardwiring paid vendor endpoints.

Source-backed assets:

- Contract:
  `contracts/firmographic_research_document.schema.json`
- Demo fixture:
  `data/samples/firmographic_research_document_sample.json`
- Raw research table:
  `pulse360_s4.bronze_firmographic.raw_research_document`
- Extracted fact table:
  `pulse360_s4.silver_firmographic.extracted_firmographic_fact`
- Unified fact table:
  `pulse360_s4.silver_firmographic.firmographic_fact`

The research extraction layer carries document URL, document title, document
date, accessed timestamp, source/use basis, extracted facts, source excerpts,
approval status, and per-fact confidence inputs before the Claude prompt is
assembled.

Verified research extraction result on 2026-04-26:

```text
raw_research_document row_count = 1
extracted_firmographic_fact row_count = 2
firmographic_fact row_count = 4
account_genai_enrichment_output_runtime row_count = 7
latest_databricks_job_run_id = 767020160543876
latest_runtime_run_id = genai_firmographic_batch_llm_20260426044442
latest_runtime_timestamp = 2026-04-26T04:44:42Z
latest_generation_mode = batch_llm
latest_model_id = claude-sonnet-4-20250514
latest_llm_result_confidence = 0.8057
latest_business_action_confidence = 0.7634
latest_activation_eligible_flag = false
latest_source_refs =
  src_neutral_ayala_20260425_annual_revenue
  src_neutral_ayala_20260425_external_subsidiaries_found
  src_research_research_doc_ayala_integrated_report_2024_annual_revenue
  src_research_research_doc_ayala_integrated_report_2024_external_subsidiaries_found
```

Verified extracted research facts:

```text
source = Ayala Corporation Integrated Report 2024
source_type = approved_public_pdf
license_or_contract_reference = public-company-investor-report-demo-use
approval_status = approved_for_demo
annual_revenue source_confidence = 0.896
external_subsidiaries_found source_confidence = 0.876
freshness_status = fresh
```

Verified MLflow trace for the research-enriched run:

```text
mlflow_experiment_id = 1941241485805681
mlflow_run_id = 1f13b2b199694e98a4021e1b89424e4c
mlflow_status = FINISHED
generation_mode = batch_llm
model_id = claude-sonnet-4-20250514
prompt_version = pulse360-public-regional-v1
llm_result_confidence = 0.8057
business_action_confidence = 0.7634
unsupported_claim_count = 0.0
source_ref_count = 4.0
artifact = governance/trace_summary.json
```

## Notes

- The workspace supports serverless compute only; classic cluster job settings
  are rejected.
- The job was created as a serverless-native notebook job with no classic
  cluster spec.
- Earlier test runs exposed two notebook fixes:
  - Spark writes need an explicit schema because several fields are nullable.
  - Databricks treats `SystemExit: 0` as a failed notebook, so the notebook now
    calls `main(...)` directly.
- The stable demo view `pulse360_s4.gold.account_genai_enrichment_output`
  remains separate from the runtime staging table until promotion is approved.

## Activation Promotion Gate

The Account export consumes live GenAI runtime rows through
`pulse360_s4.gold.account_export_base` only when the row is activation-safe.

A runtime row is activation-safe when:

1. the row already carries a non-null `crm_account_id`, or Salesforce
   stewardship has approved the related `Governance_Case__c` review row and
   selected `Surviving_Account__c`
2. `business_action_confidence >= 0.70`
3. `llm_result_confidence >= 0.80`
4. `unsupported_claim_count = 0`
5. `insufficient_evidence_flag = false`

The Salesforce stewardship link is keyed by either:

- `Governance_Case__c.Data_Cloud_Source_Record_Id__c =
  account_genai_enrichment_output_runtime.genai_enrichment_id`, or
- `Governance_Case__c.Data_Cloud_Review_Queue_Id__c =
  concat('gov_firmographic_genai_runtime_', resolved_entity_id)`

If those Data Cloud review fields have not been picked up by the Databricks
Salesforce governance-feedback ingestion pipeline, the row remains review-only
and does not enter `pulse360_s4.intelligence.datacloud_export_accounts`.
