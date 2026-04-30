# DAN-299 Claude Runtime Promotion Readiness

Date: 2026-04-26
Scope: Databricks source preparation for Claude firmographic runtime promotion into Data Cloud / Salesforce Account activation path

## Summary

The latest Claude firmographic runtime output is present in Databricks, but it
is not yet safe to activate into Salesforce Account because it has no CRM-safe
Account anchor and is marked activation-ineligible.

The repo source has been updated so the Data Cloud Account export can consume
Claude runtime output only after activation guardrails pass. Until then, the
latest Claude runtime row is exposed to the Databricks governance review queue
as stewardship evidence.

No live Databricks views/tables or Data Cloud streams were mutated during this
step.

## Live Databricks Evidence

Querying `pulse360_s4.gold.account_genai_enrichment_output_runtime` showed:

```text
latest run_id = genai_firmographic_batch_llm_20260426044442
latest run_timestamp = 2026-04-26T04:44:42Z
generation_mode = batch_llm
model_id = claude-sonnet-4-20250514
prompt_version = pulse360-public-regional-v1
resolved_entity_id = ent_ph_sec_as096_003241
crm_account_id = null
activation_eligible_flag = false
llm_result_confidence = 0.8057
business_action_confidence = 0.7634
source_ref_count = 4
unsupported_claim_count = 0
insufficient_evidence_flag = false
```

Runtime anchor summary:

```text
batch_llm / claude-sonnet-4-20250514 / activation_eligible=false / missing_crm_anchor = 4 rows
source_bound_fixture / gpt-design-placeholder / activation_eligible=false / missing_crm_anchor = 3 rows
```

Current Account export summary remains the existing public-regional/default
data set:

```text
model_id = gpt-5.4
prompt_version = pulse360-public-regional-v1
enrichment_run_id = run_public_regional_20260328
row_count = 6

model_id = gpt-5.4
prompt_version = pulse360-default-v1
enrichment_run_id = run_default_20260420_050241
row_count = 37
```

## Source Changes

`sql/databricks/gold/10_account_export_base.sql` now includes:

- `firmographic_source_refs`: converts governed firmographic facts into
  Data Cloud-friendly source reference objects.
- `eligible_genai_runtime`: selects only latest runtime rows with:
  - `activation_eligible_flag = true`
  - non-null `crm_account_id`
  - `business_action_confidence >= 0.70`
  - `llm_result_confidence >= 0.80`
  - no unsupported claims
  - no insufficient-evidence flag
- Account export AI fields prefer `eligible_genai_runtime` over the static
  regional overlay, but only after those gates pass.

`sql/databricks/governance_evidence/10_account_intelligence_governance_evidence.sql`
now includes latest runtime rows from
`pulse360_s4.gold.account_genai_enrichment_output_runtime` as
`firmographic_genai_runtime` evidence.

`sql/databricks/governance_evidence/20_activation_eligibility_review_queue.sql`
continues to route blocked or unanchored evidence into the review queue.

## Validation

Local validators passed:

```text
bash scripts/validate-databricks-salesforce-sql-pack.sh
bash scripts/validate-databricks-governance-evidence-pack.sh
bash scripts/validate-contracts.sh
```

Databricks analyzer checks passed without mutating live objects:

```text
EXPLAIN sql/databricks/gold/10_account_export_base.sql
EXPLAIN sql/databricks/governance_evidence/10_account_intelligence_governance_evidence.sql
EXPLAIN sql/databricks/governance_evidence/20_activation_eligibility_review_queue.sql
```

## Live Apply Evidence

After approval, the source-backed views were applied in Databricks:

```text
sql/databricks/gold/10_account_export_base.sql
statement_id = 01f14133-b98f-1d82-ab77-1c397714185f

sql/databricks/governance_evidence/10_account_intelligence_governance_evidence.sql
statement_id = 01f14133-d6aa-139c-b747-70d3442f032f

sql/databricks/governance_evidence/20_activation_eligibility_review_queue.sql
statement_id = 01f14133-d98f-1e06-8212-efbdab980f8f
```

The latest Claude row now appears in the activation review queue:

```text
source_product = firmographic_genai_runtime
source_record_id = genai_firmographic_ent_ph_sec_as096_003241
resolved_entity_id = ent_ph_sec_as096_003241
crm_activation_key = null
crm_activation_candidate_count = 2
crm_activation_candidate_ids = ["001dM00003d4bllQAA","001dM00003gR9K2QAK"]
crm_activation_candidate_names = ["Ayala Corporation"]
activation_resolution_hint = ambiguous_crm_candidates_require_stewardship
confidence_score = 0.7634
activation_eligible_flag = false
activation_block_reasons = ["missing_crm_activation_key","source_product_not_activation_eligible"]
lineage_status = source_bound
model_id = claude-sonnet-4-20250514
prompt_version = pulse360-public-regional-v1
enrichment_run_id = genai_firmographic_batch_llm_20260426044442
source_run_timestamp = 2026-04-26T04:44:42.000Z
```

Governance evidence summary:

```text
source_product = firmographic_genai_runtime
model_id = claude-sonnet-4-20250514
activation_eligible_flag = false
review_required_flag = true
lineage_status = source_bound
row_count = 2
latest_source_run_timestamp = 2026-04-26T04:44:42.000Z
```

The Account export view does not expose Claude rows yet:

```text
SELECT model_id, prompt_version, count(*)
FROM pulse360_s4.gold.account_export_base
WHERE model_id = 'claude-sonnet-4-20250514'
GROUP BY model_id, prompt_version;

result = 0 rows
```

The Account export view remains on the existing activation-safe GPT data set:

```text
gpt-5.4 / pulse360-default-v1 = 37 rows
gpt-5.4 / pulse360-public-regional-v1 = 6 rows
```

## Data Cloud-Visible Review Queue Handoff

After the review routing proof, a Data Cloud handoff table was added and
materialized in Databricks:

```text
table = pulse360_s4.intelligence.datacloud_activation_review_queue
source SQL = sql/databricks/governance_evidence/30_datacloud_activation_review_queue.sql
statement_id = 01f14135-9792-1a1e-bb67-9a9749223283
```

The supporting review queue view was refreshed with source refs and confidence
components:

```text
view = pulse360_s4.gold.activation_eligibility_review_queue
source SQL = sql/databricks/governance_evidence/20_activation_eligibility_review_queue.sql
statement_id = 01f14135-9536-1734-a3c7-800cadf5fa98
```

The Data Cloud handoff table exposes these columns:

```text
review_queue_id
source_product
source_record_id
resolved_entity_id
crm_activation_key
source_refs
crm_activation_candidate_ids
crm_activation_candidate_names
crm_activation_candidate_count
activation_resolution_hint
confidence_score
confidence_components
freshness_status
activation_eligible_flag
activation_block_reasons
lineage_status
model_id
prompt_version
enrichment_run_id
source_run_timestamp
ingestion_metadata_label
run_id
run_ts
run_timestamp
model_version
```

The latest Claude runtime row is present in the Data Cloud handoff table:

```text
review_queue_id = gov_firmographic_genai_runtime_ent_ph_sec_as096_003241
source_product = firmographic_genai_runtime
source_record_id = genai_firmographic_ent_ph_sec_as096_003241
resolved_entity_id = ent_ph_sec_as096_003241
crm_activation_key = null
crm_activation_candidate_ids = ["001dM00003d4bllQAA","001dM00003gR9K2QAK"]
crm_activation_candidate_names = ["Ayala Corporation"]
crm_activation_candidate_count = 2
activation_resolution_hint = ambiguous_crm_candidates_require_stewardship
confidence_score = 0.7634
activation_eligible_flag = false
activation_block_reasons = ["missing_crm_activation_key","source_product_not_activation_eligible"]
lineage_status = source_bound
model_id = claude-sonnet-4-20250514
prompt_version = pulse360-public-regional-v1
enrichment_run_id = genai_firmographic_batch_llm_20260426044442
source_run_timestamp = 2026-04-26T04:44:42.000Z
ingestion_metadata_label = Databricks activation review queue refresh - 2026-04-26
```

Live Data Cloud stream check:

```text
Pulse360_Activation_Review_Queue
- DataStreamStatus = ACTIVE
- ImportRunStatus = SUCCESS
- LastRefreshDate = 2026-04-26T10:15:06.000+0000
- TotalRowsProcessed = 4
```

The custom DMO exists and exposes the review fields:

```text
Pulse360_Activation_Review_Queue__dlm
field_count = 23
```

MCP query against `Pulse360_Activation_Review_Queue__dlm` returned the latest
Claude review row:

```text
review_queue_id__c = gov_firmographic_genai_runtime_ent_ph_sec_as096_003241
resolved_entity_id__c = ent_ph_sec_as096_003241
crm_activation_key__c = null
crm_activation_candidate_count__c = 2
crm_activation_candidate_ids__c = ["001dM00003d4bllQAA","001dM00003gR9K2QAK"]
activation_resolution_hint__c = ambiguous_crm_candidates_require_stewardship
activation_block_reasons__c = ["missing_crm_activation_key","source_product_not_activation_eligible"]
activation_eligible_flag__c = false
confidence_score__c = 0.7634
lineage_status__c = source_bound
model_id__c = claude-sonnet-4-20250514
prompt_version__c = pulse360-public-regional-v1
enrichment_run_id__c = genai_firmographic_batch_llm_20260426044442
```

## Current Decision

The correct next live step is not a Salesforce Account activation. The latest
Claude row should first be published into the Databricks governance/review
surface, where a steward can resolve or approve the missing CRM activation key.

After a CRM-safe `crm_account_id` exists and activation eligibility is true, the
same source-backed Account export path can promote Claude narrative, actions,
source refs, model, prompt, run metadata, and citation count into the Data Cloud
handoff table.
