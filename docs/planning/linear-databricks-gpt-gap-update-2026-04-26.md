# Linear Update: Databricks GenAI Runtime Gap Closure

Date: 2026-04-26

## Connector Status

Initial attempt to update Linear through the hosted Linear MCP research endpoint
failed because that OAuth path returned:

`Provided authentication token is expired. Please try signing in again.`

The direct Linear issue/comment tools were then retried and succeeded. Linear is
now updated with the post-runtime status comment and follow-up issues listed
below.

## Linear Updates Applied

- Added status comment to `DAN-286`: `2803cd41-6eed-4978-b0ae-623f8bf2d55a`
- Created `DAN-293`: Deploy Databricks firmographic GenAI runtime job
- Created `DAN-294`: Configure Databricks secret-backed Anthropic credentials
- Created `DAN-295`: Add MLflow trace logging for firmographic GenAI runs
- Created `DAN-296`: Build governed firmographic research extraction pipeline
- Created `DAN-297`: Prove Data Cloud consumption of Databricks GPT provenance outputs
- Created `DAN-298`: Publish Pulse360 S4 Databricks dashboard and capture evidence

## Databricks Runtime Deployment Update

`DAN-293` is now in progress with non-prod Databricks evidence:

- Imported notebook:
  `/Shared/pulse360/pulse360-firmographic-enrichment/dev/notebooks/databricks/firmographic_genai_enrichment_job`
- Created serverless job:
  `166785517420650` - `pulse360-firmographic-genai-enrichment job`
- Successful run:
  `458309872401849`
- Verified staging table:
  `pulse360_s4.gold.account_genai_enrichment_output_runtime`
- Latest verified generation mode:
  `source_bound_fixture`

`DAN-294` now has a live Claude credential/run update:

- Databricks secret scope:
  `pulse360-ai`
- Databricks secret key:
  `anthropic-api-key`
- Successful live Claude run:
  `789361409093`
- Latest verified generation mode:
  `batch_llm`
- Latest verified model:
  `claude-sonnet-4-20250514`
- Latest LLM result confidence:
  `0.8037`
- Latest business action confidence:
  `0.7622`
- Activation remains blocked:
  `false`

`DAN-295` now has a verified MLflow trace:

- Successful traced Databricks job run:
  `600498031946028`
- MLflow experiment:
  `/Shared/pulse360/pulse360-firmographic-enrichment/dev/mlflow/firmographic-genai-runtime`
- MLflow experiment ID:
  `1941241485805681`
- MLflow run ID:
  `2fd189415f1a409c8fb3cd36fa485e97`
- Trace status:
  `FINISHED`
- Validation result:
  `passed`
- Artifact:
  `governance/trace_summary.json`
- Latest verified table row count:
  `6`
- Latest verified table timestamp:
  `2026-04-26T04:31:52Z`

`DAN-296` now has a governed research extraction implementation and a verified
Claude run:

- Added provider-neutral research document contract:
  `contracts/firmographic_research_document.schema.json`
- Added public-report demo fixture:
  `data/samples/firmographic_research_document_sample.json`
- Added raw research table:
  `pulse360_s4.bronze_firmographic.raw_research_document`
- Added extracted fact table:
  `pulse360_s4.silver_firmographic.extracted_firmographic_fact`
- Extended unified fact table:
  `pulse360_s4.silver_firmographic.firmographic_fact`
- Extended notebook packet assembly so Claude receives source metadata,
  excerpts, confidence inputs, and account candidate context.
- Latest successful Databricks job run:
  `767020160543876`
- Latest runtime run ID:
  `genai_firmographic_batch_llm_20260426044442`
- Latest model:
  `claude-sonnet-4-20250514`
- Latest source refs:
  `4`
- Latest LLM result confidence:
  `0.8057`
- Latest business action confidence:
  `0.7634`
- Latest MLflow run:
  `1f13b2b199694e98a4021e1b89424e4c`
- Latest MLflow status:
  `FINISHED`
- Latest trace artifact:
  `governance/trace_summary.json`
- Activation remains blocked:
  `false`

Verified table counts after `DAN-296`:

```text
raw_research_document = 1
extracted_firmographic_fact = 2
firmographic_fact = 4
account_genai_enrichment_output_runtime = 7
```

`DAN-297` now has live Data Cloud field-path proof for the existing
public-regional GenAI/provenance data set:

- Evidence note:
  `docs/evidence/dan-297-data-cloud-genai-provenance-proof-2026-04-26.md`
- Active Data Stream:
  `DC Export Accounts P360 V2`
- Stream status:
  `ACTIVE`
- Import run status:
  `SUCCESS`
- Last refresh:
  `2026-04-20T06:29:34.000+0000`
- Rows processed:
  `43`
- Data Cloud DMO:
  `ssot__Account__dlm`
- Verified DMO AI/provenance rows:
  `4`
- Verified Salesforce Account AI/provenance rows:
  `4`
- DMO mapping gap for the account activation contract:
  `0`
- Salesforce Account mapping gap for the account-sync contract:
  `0`

Important gap:

- The 2026-04-26 Claude runtime output is still only proven in Databricks.
- The active Data Cloud stream last refreshed before the Claude runtime was
  created.
- Created follow-on task `DAN-299` to promote or merge the Claude runtime output
  into the canonical Data Cloud export and refresh Data Cloud.

## Status Comment For Existing Databricks/GPT Issues

Applied comment for `DAN-286` and related Databricks GPT/firmographic issues:
This is retained as the historical Linear comment text. It has been superseded
by the `DAN-293` through `DAN-296` completion evidence above, including the move
from OpenAI credential planning to the verified Anthropic/Claude runtime.

```text
Databricks GPT/firmographic status update - 2026-04-26

Completed since the previous gap note:
- Added a Databricks-compatible firmographic GPT enrichment runtime:
  `notebooks/databricks/firmographic_genai_enrichment_job.py`.
- Runtime supports deterministic fixture mode and live OpenAI mode when
  `OPENAI_API_KEY` is configured.
- Live mode uses the OpenAI Responses API with structured `json_schema` output
  and validates against `contracts/genai_firmographic_enrichment_output.schema.json`.
- Runtime preserves prompt/model metadata, `llm_run_id`, `llm_input_hash`,
  `llm_output_hash`, source refs, confidence components, and activation eligibility.
- Runtime writes to staging table
  `pulse360_s4.gold.account_genai_enrichment_output_runtime` so the stable demo
  fixture remains isolated until promotion is approved.
- Added package membership, docs, and validator coverage for the runtime notebook.

Validated locally:
- `python3 notebooks/databricks/firmographic_genai_enrichment_job.py --fixture-only`
- `bash scripts/validate-databricks-firmographic-genai-pack.sh`
- `bash scripts/validate-contracts.sh`
- `bash scripts/build-databricks-package-workspace.sh`
- `bash scripts/validate-databricks-package-layout.sh`

Remaining gaps:
- Import/deploy the notebook into the non-prod Databricks workspace and create/schedule the job.
- Configure `OPENAI_API_KEY` through Databricks secrets, not inline env vars.
- Add MLflow/GenAI trace logging for prompt version, evidence hash, output hash,
  validation result, confidence components, and activation decision.
- Build the governed public/internet research extraction pipeline before GPT narrative generation.
- Prove Data Cloud consumption of Databricks GPT/provenance outputs through the intended DLO/DMO path.
- Publish the Databricks AI/BI dashboard after access review and capture demo evidence.

Note: no live OpenAI call has been run yet; current validation used fixture mode only.
```

## Follow-Up Issues To Create Or Confirm

### 1. Deploy Runtime In Databricks

Issue: `DAN-293`

Title: `Deploy Databricks firmographic GPT runtime job`

Description:

```text
Deploy the source-backed Databricks GPT runtime into the non-prod Databricks
workspace and create a schedulable job around it.

Acceptance criteria:
- Notebook/job is imported or synced into the non-prod Databricks workspace.
- Runs in fixture mode without API credentials.
- Runs in live mode when credentials are provided.
- Reads from `pulse360_s4.silver_firmographic.firmographic_fact`.
- Writes validated rows to `pulse360_s4.gold.account_genai_enrichment_output_runtime`.
```

### 2. Secret-Backed OpenAI Credentials

Issue: `DAN-294`

Title: `Configure Databricks secret-backed OpenAI credentials`

Description:

```text
Configure the GPT runtime to receive OpenAI credentials through Databricks
secrets or approved secret-backed job configuration, not inline environment
variables.
```

### 3. MLflow / GenAI Trace Logging

Issue: `DAN-295`

Title: `Add MLflow/GenAI trace logging for firmographic GPT runs`

Description:

```text
Track prompt version, evidence packet hash, output hash, model ID, validation
result, confidence components, and activation decision for each GPT enrichment
run. Keep trace metadata aligned to Databricks governance and audit needs.
```

### 4. Internet Research Extraction Pipeline

Issue: `DAN-296`

Title: `Add governed internet research extraction pipeline`

Description:

```text
Create a provider-neutral extraction pipeline for approved public URLs/PDFs that
stores document URL, document date, accessed timestamp, extracted facts, source
confidence, and license/use metadata before any GPT narrative generation.
```

### 5. Data Cloud Zero Copy / DMO Proof

Issue: `DAN-297`

Title: `Prove Data Cloud consumption of Databricks GPT/provenance outputs`

Description:

```text
Validate whether Data Cloud can consume the Databricks GPT/provenance outputs
through the intended DLO/DMO path. Confirm field availability, mappings,
confidence/source fields, and CRM-safe activation keys.
```

### 6. Dashboard Publish And Evidence Capture

Issue: `DAN-298`

Title: `Publish Pulse360 S4 Databricks dashboard and capture evidence`

Description:

```text
Review the draft AI/BI dashboard, publish after access review, and capture
screenshots for S4 Demo Readiness, Activation Review Queue, Scenario Evidence,
and lineage/source evidence.
```

### 7. Claude Runtime Promotion And Data Cloud Refresh

Issue: `DAN-299`

Title: `Promote Claude firmographic runtime output into Data Cloud export and refresh stream`

Status update on 2026-04-26:

```text
Completed source-backed promotion readiness work.

Live Databricks inspection shows the latest Claude runtime row is:
- run_id = genai_firmographic_batch_llm_20260426044442
- model_id = claude-sonnet-4-20250514
- resolved_entity_id = ent_ph_sec_as096_003241
- crm_account_id = null
- activation_eligible_flag = false
- llm_result_confidence = 0.8057
- business_action_confidence = 0.7634
- source_ref_count = 4

Because the row has no CRM-safe Account anchor and is not activation-eligible,
it must not be written to Salesforce Account yet.

Repo changes now make the intended path explicit:
- Account export can consume Claude runtime rows only when they have a
  non-null crm_account_id, activation_eligible_flag = true, confidence
  thresholds pass, and evidence guards are clear.
- Latest runtime rows are included in Databricks governance evidence as
  firmographic_genai_runtime.
- Blocked/unanchored runtime rows flow to activation_eligibility_review_queue
  for stewardship instead of Account writeback.

Validation passed:
- bash scripts/validate-databricks-salesforce-sql-pack.sh
- bash scripts/validate-databricks-governance-evidence-pack.sh
- bash scripts/validate-contracts.sh
- Databricks EXPLAIN checks for the changed Account export and governance SQL.

Evidence:
docs/evidence/dan-299-claude-runtime-promotion-readiness-2026-04-26.md
```

Live apply update on 2026-04-26:

```text
Applied the updated Databricks views after approval:
- account_export_base statement_id = 01f14133-b98f-1d82-ab77-1c397714185f
- account_intelligence_governance_evidence statement_id = 01f14133-d6aa-139c-b747-70d3442f032f
- activation_eligibility_review_queue statement_id = 01f14133-d98f-1e06-8212-efbdab980f8f

Verified latest Claude runtime row is now in the review queue:
- source_product = firmographic_genai_runtime
- resolved_entity_id = ent_ph_sec_as096_003241
- enrichment_run_id = genai_firmographic_batch_llm_20260426044442
- model_id = claude-sonnet-4-20250514
- crm_activation_key = null
- crm_activation_candidate_count = 2
- activation_resolution_hint = ambiguous_crm_candidates_require_stewardship
- activation_block_reasons =
  ["missing_crm_activation_key","source_product_not_activation_eligible"]

Verified no Claude rows appear in account_export_base:
- model_id = claude-sonnet-4-20250514 returned 0 rows.

Data Cloud export table and Data Cloud stream were intentionally not refreshed.
```

Data Cloud-visible review queue update on 2026-04-26:

```text
Added and materialized a dedicated Databricks handoff table:

pulse360_s4.intelligence.datacloud_activation_review_queue

Applied statements:
- activation_eligibility_review_queue refresh
  statement_id = 01f14135-9536-1734-a3c7-800cadf5fa98
- datacloud_activation_review_queue table
  statement_id = 01f14135-9792-1a1e-bb67-9a9749223283

Verified the latest Claude runtime row is present in the handoff table:
- review_queue_id = gov_firmographic_genai_runtime_ent_ph_sec_as096_003241
- source_product = firmographic_genai_runtime
- enrichment_run_id = genai_firmographic_batch_llm_20260426044442
- model_id = claude-sonnet-4-20250514
- crm_activation_key = null
- crm_activation_candidate_ids =
  ["001dM00003d4bllQAA","001dM00003gR9K2QAK"]
- activation_resolution_hint = ambiguous_crm_candidates_require_stewardship
- activation_block_reasons =
  ["missing_crm_activation_key","source_product_not_activation_eligible"]

Current Data Cloud stream check found no active stream yet for this new review
queue table. Existing streams are still only account export / engagement /
setup metadata streams, so Data Cloud DLO/stream setup remains the next org
configuration step.
```

Final Data Cloud validation update on 2026-04-26:

```text
Data Cloud Direct Access stream is now active and refreshed:
- Name = Pulse360_Activation_Review_Queue
- Id = 1dsdL000000Or4nQAC
- DataStreamStatus = ACTIVE
- ImportRunStatus = SUCCESS
- LastRefreshDate = 2026-04-26T10:15:06.000+0000
- TotalRowsProcessed = 4

Custom DMO exists:
- Pulse360_Activation_Review_Queue__dlm
- field_count = 23

MCP query returned the latest Claude review row:
- review_queue_id__c =
  gov_firmographic_genai_runtime_ent_ph_sec_as096_003241
- resolved_entity_id__c = ent_ph_sec_as096_003241
- crm_activation_key__c = null
- crm_activation_candidate_count__c = 2
- crm_activation_candidate_ids__c =
  ["001dM00003d4bllQAA","001dM00003gR9K2QAK"]
- activation_resolution_hint__c =
  ambiguous_crm_candidates_require_stewardship
- activation_block_reasons__c =
  ["missing_crm_activation_key","source_product_not_activation_eligible"]
- activation_eligible_flag__c = false
- model_id__c = claude-sonnet-4-20250514
- prompt_version__c = pulse360-public-regional-v1
- enrichment_run_id__c = genai_firmographic_batch_llm_20260426044442

Conclusion: the Databricks review queue is now Data Cloud-visible and queryable
as a custom review DMO. It remains blocked from Account activation.
```
