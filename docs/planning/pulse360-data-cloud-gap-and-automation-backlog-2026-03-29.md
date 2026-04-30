# Pulse360 Data Cloud Gap And Automation Backlog

Date: 2026-03-29
Owner: Platform / Solution Build
Scope: Public regional data + GPT enrichment slice, downstream Data Cloud realization, and Codex automation hardening

## Summary

Update on 2026-04-26:

- the Data Cloud field path for the public-regional GenAI/provenance slice is
  now proven in the live org
- `ssot__Account__dlm` exposes the AI/provenance fields
- live DMO rows contain AI narrative, recommended actions, source refs,
  prompt/model metadata, and citation count
- matching Salesforce `Account` rows contain the activated AI/provenance fields
- the remaining gap is promotion and refresh of the new 2026-04-26 Claude
  runtime output, not the existence of the Data Cloud field path

See:
[dan-297-data-cloud-genai-provenance-proof-2026-04-26.md](/Users/danielnortje/Documents/Pulse360/docs/evidence/dan-297-data-cloud-genai-provenance-proof-2026-04-26.md)

Historical 2026-03-29 status follows.

The current Pulse360 build is in a mixed state:

- the Salesforce source-driven experience layer is deployed and working
- the Databricks export layer is now producing the new public-regional GPT/provenance fields
- the older/core enrichment path is proven through Data Cloud into Salesforce CRM
- the new GPT/provenance field set is **not yet proven on the Data Cloud Account DMO**
- Codex is automating the build as an agentic operator, but the workflow is not yet a hardened MCP-backed automation product

This document separates:

1. what Codex has already completed
2. what is still missing in Data Cloud
3. what still requires external or platform-side action
4. how to increase automation safely with a Salesforce/Data Cloud MCP approach

## Current Truth

As of 2026-03-29:

- Salesforce `Account` contains the new target fields, including:
  - `External_Legal_Name__c`
  - `AI_Narrative__c`
  - `AI_Recommended_Actions__c`
  - `AI_Narrative_Generated__c`
  - `Regulatory_Readiness_Score__c`
  - `AI_Model_Id__c`
  - `AI_Prompt_Version__c`
  - `AI_Source_Refs__c`
  - `AI_Citation_Count__c`
- Databricks `pulse360_s4.intelligence.datacloud_export_accounts` contains the new regional records and the new GPT/provenance fields for:
  - `Singtel Group`
  - `Ayala Corporation`
  - `JG Summit Holdings, Inc.`
- Data Cloud `ssot__Account__dlm` currently exposes only the older/core custom enrichment fields:
  - `Unified_Profile_Id__c`
  - `Identity_Confidence__c`
  - `Health_Score__c`
  - `Cross_Sell_Propensity__c`
- Data Cloud `ssot__Account__dlm` does **not** currently expose the new GPT/provenance fields such as:
  - `External_Legal_Name__c`
  - `AI_Narrative__c`
  - `Regulatory_Readiness_Score__c`
  - `AI_Model_Id__c`
  - `AI_Source_Refs__c`
- Data Cloud stream `datacloud_export_accounts Pulse360_Datab` last refreshed on `2026-03-29T00:32:57.000+0000`
- Current stream state:
  - `ImportRunStatus = SUCCESS`
  - `TotalRowsProcessed = 38`
  - `IsNewFieldsAvailable = false`

## What Codex Has Done

These steps were completed directly by Codex in repo, Databricks, Salesforce, or Linear:

### Source and repo work

- extended the source contracts and mapping files for the public regional and GPT/provenance slice
- added the new Salesforce `Account` fields and experience-layer components
- added and validated the public Singapore + Philippines evidence pack
- fixed the Databricks SQL mismatch by extending:
  - [10_account_export_base.sql](/Users/danielnortje/Documents/Pulse360/sql/databricks/gold/10_account_export_base.sql)
- verified contract and SQL validation scripts pass

### Salesforce org work

- deployed the new metadata to `pulse360-dev`
- assigned the new permission set needed for the account-intelligence experience
- seeded the regional demo records into Salesforce
- verified the seeded records and Health Scan runtime path

### Databricks work

- reran the `pulse360-salesforce-extract` job so the seeded records entered Bronze/Silver
- rebuilt the gold/export SQL path
- verified the real export table contains the new regional GPT/provenance rows

### Runtime and issue tracking

- verified the older/core Data Cloud-backed enrichment path still works
- confirmed the new field set is not yet modeled on the Data Cloud Account DMO
- updated `DAN-219` with the runtime evidence and current blocker

## What Is Missing In Data Cloud

This is the most important open gap.

### Missing or unproven model work

- DLO/DSO schema extension for the new GPT/provenance fields is not proven in the target org
- Account DMO extension fields for the new field set are not visible on `ssot__Account__dlm`
- source-to-DMO mapping for the new field set is not proven
- Copy Field Enrichment mapping for the new field set is not proven

### Field set still missing from visible Data Cloud DMO layer

- `External_Legal_Name__c`
- `Externally_Validated__c`
- `Validity_Score_External__c`
- `External_Subsidiaries_Found__c`
- `AI_Narrative__c`
- `AI_Recommended_Actions__c`
- `AI_Narrative_Generated__c`
- `Enrichment_Run_Id__c`
- `Regulatory_Readiness_Score__c`
- `Duplicate_Exposure_Count__c`
- `Group_Known_Subsidiary_Count__c`
- `CRM_Covered_Subsidiary_Count__c`
- `Group_Revenue_Visible__c`
- `External_Revenue_Confirmed__c`
- `AI_Model_Id__c`
- `AI_Prompt_Version__c`
- `AI_Source_Refs__c`
- `AI_Citation_Count__c`

### What this means

The pipeline currently behaves like this:

1. Databricks produces the new fields
2. Salesforce `Account` has target fields
3. some values appear downstream in CRM
4. but the DMO-layer proof is incomplete for the new field set

That means the current build is not yet strong enough to claim a fully modeled Data Cloud realization for the GPT/provenance slice.

## External / Platform-Side Steps Still Required

These steps are not yet fully handled by Codex from source and CLI alone.

### Data Cloud modeling and mapping

- inspect the Data Cloud source object for the Databricks export and confirm the new fields are present
- extend or confirm the custom Account DMO fields for the new GPT/provenance set
- map the Databricks export fields into the DMO extension fields
- publish or activate the updated mapping
- verify the DMO refresh materializes the new fields

### Copy Field Enrichment

- confirm the new DMO fields are eligible for Copy Field Enrichment
- extend the Copy Field Enrichment mapping to the new Salesforce `Account` target fields
- run or wait for the sync
- confirm writeback provenance and value realization on the live records

### UI-only or admin-only checks

- perform any Data Cloud UI steps not exposed safely through current CLI or API use
- capture screenshots of:
  - source object fields
  - DMO custom fields
  - source-to-DMO mapping
  - Copy Field Enrichment mapping
  - final CRM writeback

## Concrete Implementation Backlog

### Done

- Deploy Salesforce Account intelligence metadata and runtime components
- Seed regional public-example records in `pulse360-dev`
- Fix and validate Databricks export SQL for the new GPT/provenance slice
- Rebuild the Databricks export table with the new field set
- Verify core Data Cloud-backed enrichment continues to work
- Capture current blocker in Linear `DAN-219`

### In Progress

- Validate the full Databricks -> Data Cloud -> CRM path for the new GPT/provenance fields

### Missing In Data Cloud

- DMO extension fields for the new GPT/provenance set
- source-to-DMO mapping for those fields
- Copy Field Enrichment mapping for those fields
- repeatable validation at each layer

### External Manual Steps

- Data Cloud admin confirms the new export fields are visible at the source layer
- Data Cloud admin adds or confirms the DMO extension fields
- Data Cloud admin publishes mapping changes
- Data Cloud admin confirms or updates Copy Field Enrichment
- Platform owner captures screenshots and approval evidence

### Validation Required To Close

- prove the new fields exist on the source object
- prove the new fields exist on the DMO
- prove the new fields map into Copy Field Enrichment
- prove live Salesforce `Account` writeback for at least one seeded regional account
- prove freshness and provenance for the AI payloads

## Why Codex Is Not Yet More Automated

Codex has been effective as an execution layer, but it is not yet wrapped in a reusable automation boundary.

### What Codex is doing today

- uses repo instructions in [AGENTS.md](/Users/danielnortje/Documents/Pulse360/AGENTS.md)
- executes `sf`, Databricks API/CLI, and local validation scripts directly
- reasons through failures live
- fixes source gaps when runtime checks fail

### Why this is not yet fully automated

- many actions still depend on environment-specific context
- some Data Cloud operations remain UI-first or org-specific
- there is no structured Salesforce/Data Cloud MCP in the current baseline
- repeatable guardrails and idempotent operations are not yet packaged as tools

So the current model is:

- high agent capability
- moderate repeatability
- lower standardization than a purpose-built MCP tool layer

## Why We Have Not Yet Added A Custom Salesforce MCP

We should consider it, but there is a specific repo policy reason it was not the first move.

### Current project policy

[mcp-security-assessment.md](/Users/danielnortje/Documents/Pulse360/docs/security/mcp-security-assessment.md) explicitly says:

- non-official MCP servers are blocked by default
- they require provenance, license, dependency, secret-handling, scope, and egress review before use

[salesforce-databricks-mcp-setup.md](/Users/danielnortje/Documents/Pulse360/docs/setup/salesforce-databricks-mcp-setup.md) also defines the current baseline as:

- Salesforce via official `sf` CLI
- Databricks via official CLI/API
- official-first MCP preference
- fallback API integration where no official hosted MCP exists

### Practical reason

At the time we started this slice, the biggest blockers were:

- incomplete source implementation
- missing SQL fields in Databricks
- org permission issues
- uncertain Data Cloud DMO realization

A custom MCP would not have solved those design and source gaps by itself. It would have wrapped the current operations more cleanly, but the underlying platform state would still have needed to be fixed.

### The right conclusion

Not using a custom Salesforce MCP first was a sequencing decision, not a rejection of the approach.

The project is now at the point where a structured MCP layer would be useful.

## Recommended MCP Automation Backlog

The best next move is an official-first or internally approved Salesforce/Data Cloud MCP capability that starts read-only and then expands.

### Phase 1: Read-only MCP

Goal: make environment inspection structured and repeatable.

Recommended tools:

- `describe_account_fields(org)`
- `describe_dmo_fields(org, dmo_name)`
- `list_data_streams(org)`
- `get_data_stream_status(org, stream_name)`
- `query_dmo(org, dmo_name, soql_or_sql)`
- `compare_export_contract_to_dmo(org, export_contract_id, dmo_name)`
- `list_copy_field_enrichment_mappings(org)`
- `report_unmapped_activation_fields(org)`

### Phase 2: Safe execution MCP

Goal: make repeatable operations idempotent and constrained.

Recommended tools:

- `deploy_salesforce_scope(org, manifest_or_paths)`
- `assign_permission_set(org, user, permission_set)`
- `run_databricks_extract(workspace, job_id)`
- `run_databricks_sql(workspace, warehouse_id, statement)`
- `rebuild_gold_export(workspace)`
- `seed_demo_accounts(org, fixture_set)`

### Phase 3: Data Cloud configuration MCP

Goal: reduce manual UI dependency where the APIs support it.

Recommended tools:

- `list_data_cloud_sources(org)`
- `describe_data_cloud_source_fields(org, source_name)`
- `create_or_update_dmo_extension_field(org, dmo_name, field_spec)`
- `create_or_update_source_mapping(org, source_name, dmo_name, mapping_spec)`
- `create_or_update_copy_field_enrichment(org, mapping_spec)`
- `check_connector_status(org)`

### Phase 4: Evidence and acceptance MCP

Goal: make completion auditable.

Recommended tools:

- `capture_runtime_validation_report(org, account_ids)`
- `publish_linear_validation_comment(issue_id, report)`
- `generate_release_readiness_summary(scope)`

## Recommended Execution Order

1. Finish the missing Data Cloud field-path proof for the new GPT/provenance fields.
2. Document the exact UI/manual steps still required in a tighter runbook.
3. Add read-only Salesforce/Data Cloud MCP tooling first.
4. Add safe write operations only after the read-only model is trusted.
5. Expand into Data Cloud mapping automation once security review passes.

## Decision

The next platform milestone should be:

**prove the new GPT/provenance fields at the DMO and Copy Field Enrichment layers, then formalize the workflow into an approved Salesforce/Data Cloud MCP tool layer.**
