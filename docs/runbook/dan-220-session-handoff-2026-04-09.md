# DAN-220 Session Handoff - 2026-04-09

## Runtime State

- Live source-object path is healthy.
  - `datacloud_export_accounts_Pulse360_Datab__dll` has `40/40` required source-contract fields.
- Live `Account` DMO extension gap is reduced from `13` fields to `2`.
- Live mapping canvas shows `33` mapped fields on both the source and `Account` DMO sides.

## Current Validator Results

- `./scripts/validate-contracts.sh`
  - passes
- `./scripts/validate-data-cloud-dmo-extension.sh`
  - `17/19` required DMO attributes present
  - remaining missing required fields:
    - `External_Revenue_Confirmed__c`
    - `Hierarchy_Payload__c`
- `./scripts/validate-data-cloud-field-path.sh`
  - DMO missing target field count: `2`
  - remaining DMO missing target fields:
    - `External_Revenue_Confirmed__c`
    - `Hierarchy_Payload__c`

## What Was Completed

- Corrected repo-side DMO naming drift to match the live queryable Data Cloud API:
  - `AI_Model_ID__c`
  - `Enrichment_Run_ID__c`
- Updated:
  - `config/data-cloud/dmo-account-extension-attributes.csv`
  - `config/data-cloud/dmo-account-field-mapping.csv`
  - `docs/runbook/dan-220-data-cloud-dmo-extension-runbook.md`
- Mapped these additional live Data Cloud fields into the `Account` DMO:
  - `citation_count` -> `AI Citation Count`
  - `model_id` -> `AI Model ID`
  - `prompt_version` -> `AI Prompt Version`
  - `source_refs` -> `AI Source References`
  - `duplicate_exposure_count` -> `Duplicate Exposure Count`
  - `enrichment_run_id` -> `Enrichment Run ID`
  - `external_revenue_confirmed` -> `External Revenue Confirmed`
  - `external_subsidiaries_found` -> `External Subsidiaries Found`
  - `is_externally_validated` -> `Externally Validated`
  - `group_known_subsidiary_count` -> `Group Known Subsidiary Count`
  - `regulatory_readiness_score` -> `Regulatory Readiness Score`
  - `validity_score_external` -> `Validity Score External`

## Important Live Platform Nuance

- `AI_Model_ID__c` and `Enrichment_Run_ID__c` are now visible in the queryable DMO API surface.
- `External_Revenue_Confirmed__c` is visible on the Data Cloud `Account` DMO page, but the UI currently shows it as `Boolean`, not the intended numeric field.
- `Hierarchy_Payload__c` is visible on the Data Cloud `Account` DMO page as `Text`.
- Despite both fields appearing in the UI, the read-only/queryable DMO API still does not publish them.

## Likely Interpretation

- The remaining blocker is no longer broad schema or mapping work.
- It is a narrow Data Cloud publication/type issue affecting:
  - `External_Revenue_Confirmed__c`
  - `Hierarchy_Payload__c`

## Continuation Findings - 2026-04-09

- Recreated the live `Account` DMO fields in the UI with the intended types:
  - `External_Revenue_Confirmed__c` -> `Number`
  - `Hierarchy_Payload__c` -> `Text`
- The Data Cloud `Account` DMO page now visibly shows those corrected field types.
- The read-only/queryable DMO API still does not publish either field:
  - `sf sobject describe --target-org pulse360-dev --sobject ssot__Account__dlm --json`
  - still omits `External_Revenue_Confirmed__c`
  - still omits `Hierarchy_Payload__c`
- Live source-object proof now shows the two remaining blockers are not in the same state:
  - `external_revenue_confirmed__c` exists on `datacloud_export_accounts_Pulse360_Datab__dll`
  - `hierarchy_payload__c` does **not** exist on `datacloud_export_accounts_Pulse360_Datab__dll`
- This means:
  - `External_Revenue_Confirmed__c` still looks like a live DMO publish/materialization issue
  - `Hierarchy_Payload__c` is currently blocked by the upstream source-object surface, not just by the DMO
- Supporting validation:
  - source-contract validator remains healthy: `40/40` required source fields present
  - DMO validator still fails with missing target fields:
    - `External_Revenue_Confirmed__c`
    - `Hierarchy_Payload__c`
- Important contract nuance:
  - `hierarchy_payload` is required by `contracts/datacloud_to_salesforce_agentforce.schema.json`
  - `hierarchy_payload` is **not** currently part of `contracts/databricks_to_datacloud.schema.json`
  - the live source-object state matches that current source contract, not the downstream DMO mapping contract

## Current Stop Point

- `DAN-220` cannot be completed from the current runtime state without at least one additional approved platform change:
  - either a successful live Data Cloud publish/materialization step for `External_Revenue_Confirmed__c`
  - and an upstream export/source-object change plus stream refresh for `Hierarchy_Payload__c`
- Do not treat `Hierarchy_Payload__c` as a DMO-only issue anymore.

## Additional Runtime Progress - 2026-04-09

- Repo-side upstream fix applied:
  - `sql/databricks/gold/30_datacloud_export_accounts.sql` now serializes `hierarchy_payload` with `to_json(...)`
  - `contracts/databricks_to_datacloud.schema.json` now includes `hierarchy_payload` as a required serialized string field
  - sample payloads/contracts were aligned to the serialized transport shape
- Local repo validation after the upstream fix:
  - `./scripts/validate-contracts.sh` -> PASS
  - `./scripts/validate-databricks-salesforce-sql-pack.sh` -> PASS
- Live Databricks runtime fix applied:
  - executed the repo-backed rebuild from `sql/databricks/gold/30_datacloud_export_accounts.sql`
  - statement status: `SUCCEEDED`
  - live table `pulse360_s4.intelligence.datacloud_export_accounts` now exposes:
    - `hierarchy_payload` as `string`
    - `external_revenue_confirmed` as `double`
- Live Data Cloud stream refresh was triggered and completed:
  - stream: `datacloud_export_accounts Pulse360_Datab`
  - `ImportRunStatus = SUCCESS`
  - `LastRefreshDate = 2026-04-09T13:53:05.000+0000`
- Remaining live blocker after the successful refresh:
  - `sf sobject describe --target-org pulse360-dev --sobject datacloud_export_accounts_Pulse360_Datab__dll --json`
  - still shows `external_revenue_confirmed__c`
  - still does **not** show `hierarchy_payload__c`
- The Data Cloud UI exposes `Add Source Fields` and specifically offers:
  - `hierarchy_payload`
  - data type `Text`
- But the live `Add Source Fields` interaction is still not fully materializing through the browser automation path:
  - the field is visible in the modal
  - selection works
  - the save path is inconsistent / disabled / fails to complete cleanly through the automated click flow
- Current validator state therefore remains unchanged:
  - `./scripts/validate-data-cloud-dmo-extension.sh` still missing:
    - `External_Revenue_Confirmed__c`
    - `Hierarchy_Payload__c`

## Next Session Starting Point

1. Re-open the live `Account` DMO in Data Cloud.
2. Inspect `External_Revenue_Confirmed__c` first.
   - Confirm whether the field can be recreated or corrected from `Boolean` to `Number`.
3. Inspect `Hierarchy_Payload__c`.
   - Confirm whether it needs a re-save/republish step to surface in the queryable DMO API.
4. Re-run:
   - `./scripts/validate-data-cloud-dmo-extension.sh`
   - `./scripts/validate-data-cloud-field-path.sh`
5. If both fields become queryable, proceed directly into `DAN-221` writeback proof.

## Linear

- `DAN-220` has been commented with the live state from this session.
