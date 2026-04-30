# DAN-220 Data Cloud DMO Extension Runbook

## Purpose
Close the remaining Data Cloud modeling gap for the Pulse360 `Account` DMO in `pulse360-dev`.

This runbook is intentionally UI-first because the missing work is org-locked Data Cloud setup, not standard Salesforce source deployment.

## Current Runtime Baseline
As of 2026-04-10:
- DataStream `datacloud_export_accounts Pulse360_Datab` is healthy
- Data Lake Object `datacloud_export_accounts Pulse360_Datab` is active with `52` fields and `38` records
- source object `datacloud_export_accounts_Pulse360_Datab__dll` is still missing required field `hierarchy_payload`
- DMO `ssot__Account__dlm` is still missing required fields:
  - `External_Revenue_Confirmed__c`
  - `Hierarchy_Payload__c`
- a live DMO save attempt using those exact field names currently fails with duplicate-name validation for:
  - `Custom__external_revenue_confirmed`
  - `Custom__hierarchy_payload`
- Salesforce `Account` has the target CRM field surface
- the remaining blocker spans both the source-object publication surface and the queryable `ssot__Account__dlm` target field surface

Update as of 2026-04-13:
- source object `datacloud_export_accounts_Pulse360_Datab__dll` now exposes `hierarchy_payload`
- DMO `ssot__Account__dlm` now exposes:
  - `External_Revenue_Confirmed__c`
  - `Hierarchy_Payload__c`
- focused validators now report no missing source-object or DMO fields
- direct Salesforce `Account` realization checks now use the narrower Copy Field Enrichment sync contract rather than the full export payload contract

Update as of 2026-04-17 for `pulse360-agent-target`:
- a fresh file-upload stream for `datacloud_export_accounts Pulse360_Datab` was created successfully and processed sample rows
- source object `datacloud_export_accounts_Pulse360_Datab__dll` now exists in the target org and exposes the Pulse360 source fields
- the full missing Pulse360 custom `Account` DMO field set was saved successfully through the Data Model UI
- however, those saved DMO fields still do not materialize in `sf sobject describe --sobject ssot__Account__dlm`
- the Data Stream mapping canvas loads the Pulse360 source fields, but the target-entity pane still does not materialize `Account` as a selectable target object
- treat this as a runtime publication or Data Cloud UI-state blocker, not a source-contract blocker

Use these repo artifacts as the source of truth:
- [dmo-account-extension-attributes.csv](/Users/danielnortje/Documents/Pulse360/config/data-cloud/dmo-account-extension-attributes.csv)
- [dmo-account-field-mapping.csv](/Users/danielnortje/Documents/Pulse360/config/data-cloud/dmo-account-field-mapping.csv)
- [datacloud-to-salesforce-agentforce-contract.md](/Users/danielnortje/Documents/Pulse360/docs/contracts/datacloud-to-salesforce-agentforce-contract.md)
- [validate-data-cloud-dmo-extension.sh](/Users/danielnortje/Documents/Pulse360/scripts/validate-data-cloud-dmo-extension.sh)
- [validate-data-cloud-field-path.sh](/Users/danielnortje/Documents/Pulse360/scripts/validate-data-cloud-field-path.sh)

## Goal
Bring the live `Account` DMO to a state where:
- the source object exposes the full required export contract
- all required extension attributes exist on `ssot__Account__dlm`
- the DLO to DMO mapping can be completed for the public regional GPT/provenance slice
- the DMO field surface no longer blocks `DAN-221` writeback proof

## Preconditions
1. The operator has Data Cloud admin access in `pulse360-dev`.
2. The source object remains healthy and continues to expose the full source contract.
3. The operator is prepared to make Data Cloud configuration changes in the UI.

## Required DMO Attributes
Create or confirm the fields in:
- [dmo-account-extension-attributes.csv](/Users/danielnortje/Documents/Pulse360/config/data-cloud/dmo-account-extension-attributes.csv)

Important type rule:
- Data Cloud DMO UI currently exposes `Text`, not Salesforce-style `Long Text Area`
- for `AI_Narrative__c`, `AI_Recommended_Actions__c`, `AI_Source_Refs__c`, and `Hierarchy_Payload__c`, use `Text`

## Manual Steps

### 1. Confirm the source object field surface is healthy
Open the Data Stream and Data Lake Object for `datacloud_export_accounts Pulse360_Datab`.

Confirm:
- the stream is healthy
- preview rows exist
- the source object shows the public-regional field set
- `hierarchy_payload` is visible on `datacloud_export_accounts_Pulse360_Datab__dll`
- `Add Source Fields` does not report `No New Fields Available`

If the source object is missing fields, stop here and repair upstream ingestion first.

### 2. Open the Data Model `Account` DMO
In Data Cloud:
- go to `Data Model`
- open `Account`
- open the field/attribute management UI

### 3. Create the missing DMO attributes
Using [dmo-account-extension-attributes.csv](/Users/danielnortje/Documents/Pulse360/config/data-cloud/dmo-account-extension-attributes.csv), create any attributes that do not yet exist on `ssot__Account__dlm`.

Current queryable DMO blocker set for Milestone C closure:
- `External_Revenue_Confirmed__c`
- `Hierarchy_Payload__c`

All other required DMO extension attributes are expected to remain present. Re-confirm them instead of recreating them blindly.

Current UI nuance:
- the Account DMO field grid may not show either missing field at all
- the DMO `Edit` flow allows draft entry for both fields, but the save currently fails with:
  - `Found duplicate field names for the following fields: Custom__external_revenue_confirmed, Custom__hierarchy_payload, please fix and try again.`
- treat that error as evidence of stale or reserved DMO metadata; do not keep retrying the same save blindly

### 4. Save and publish the DMO changes
After adding the missing attributes:
- save the DMO changes
- publish or apply the updated model if the UI requires it

Observed target-org nuance on 2026-04-17:
- the save can succeed and the Data Model UI can show the new fields while `sf sobject describe ssot__Account__dlm` still does not expose them
- if that happens, stop treating field entry as the problem and investigate the Data Cloud runtime publication step or target-object selection flow in the mapping canvas

If the save fails with duplicate-name validation:
- stop field creation attempts
- investigate whether those custom field definitions already exist in hidden, unpublished, or partially deleted DMO metadata
- clear or restore that metadata state before retrying field creation

### 5. Open the DLO-to-DMO mapping canvas
Open the mapping for `datacloud_export_accounts Pulse360_Datab` into `Account`.

Use [dmo-account-field-mapping.csv](/Users/danielnortje/Documents/Pulse360/config/data-cloud/dmo-account-field-mapping.csv) as the exact mapping contract.

### 6. Complete the public regional mapping set
Confirm these business mappings are present and valid:
- `source_account_id` -> `ssot__Id__c`
- `hierarchy_payload` -> `Hierarchy_Payload__c`
- `external_legal_name` -> `External_Legal_Name__c`
- `external_registration_number` -> `External_Registration_Number__c`
- `is_externally_validated` -> `Externally_Validated__c`
- `validity_score_external` -> `Validity_Score_External__c`
- `external_subsidiaries_found` -> `External_Subsidiaries_Found__c`
- `ai_narrative` -> `AI_Narrative__c`
- `ai_recommended_actions` -> `AI_Recommended_Actions__c`
- `ai_narrative_generated_at` -> `AI_Narrative_Generated__c`
- `enrichment_run_id` -> `Enrichment_Run_ID__c`
- `regulatory_readiness_score` -> `Regulatory_Readiness_Score__c`
- `duplicate_exposure_count` -> `Duplicate_Exposure_Count__c`
- `group_known_subsidiary_count` -> `Group_Known_Subsidiary_Count__c`
- `crm_covered_subsidiary_count` -> `CRM_Covered_Subsidiary_Count__c`
- `group_revenue_visible` -> `Group_Revenue_Visible__c`
- `external_revenue_confirmed` -> `External_Revenue_Confirmed__c`
- `model_id` -> `AI_Model_ID__c`
- `prompt_version` -> `AI_Prompt_Version__c`
- `source_refs` -> `AI_Source_Refs__c`
- `citation_count` -> `AI_Citation_Count__c`

### 7. Save or publish the mapping
Expected outcome:
- the mapping canvas reflects the new DMO fields
- the DMO no longer reports missing target fields for required mappings

Observed target-org blocker on 2026-04-17:
- the mapping canvas loaded the Pulse360 source-field list correctly
- the target-entity pane remained empty with `No objects selected`
- `Select Objects` and `Update target entities` did not materialize `Account` as a mapping target despite the Account DMO existing in the org
- stop and escalate instead of guessing through hidden UI state if this repeats

Observed source-type blocker on 2026-04-18:
- the file-upload sample at [databricks_enrichment_sample.csv](/Users/danielnortje/Documents/Pulse360/data/samples/databricks_enrichment_sample.csv) had a malformed JG Summit row where `external_legal_name` was left unquoted as `JG Summit Holdings, Inc.`
- that comma shifted the row one column to the right and caused downstream values to land in the wrong source columns
- affected source fields included `ai_narrative_generated_at`, `citation_count`, `regulatory_readiness_score`, `validity_score_external`, `model_id`, and `prompt_version`
- when the mapping canvas shows `Cannot map source and target data types should be same`, inspect the source CSV row shape and inferred DLO field types before assuming the DMO fields are wrong
- after correcting the CSV, prefer creating a fresh file-upload stream and DLO instead of reusing a source object whose field types may already be poisoned by malformed input

Recovery update on 2026-04-18 for `pulse360-agent-target`:
- the corrected sample CSV was used to create a fresh file-upload stream `DC Export Accounts P360 Fix`
- the fresh source object `dc_export_accounts_p360_fix__dll` materialized with the expected field types
- `Account` became selectable in the mapping canvas and the DMO contract was completed to `38/48` mapped fields
- `validate-data-cloud-dmo-extension.sh` now reports `missing_required_count = 0`
- `validate-data-cloud-field-path.sh` now reports zero missing source, DMO, and `Account` target fields when pointed at the recovered stream/source object
- the remaining validator nuance is that Data Cloud file-upload streams do not populate `MktDataLakeMapping` source picklists reliably, so `validate-data-cloud-field-path.sh` now treats live stream/DLO registration as the authoritative registration signal
- the Salesforce `Account` activation fields were present in metadata earlier, but they were not queryable for the target user until `Pulse360_Account_Intelligence_User` and `Governance_Case_Steward` were assigned in the org
- the recovered path is now the canonical dev-instance runtime source for Pulse360 in `pulse360-agent-target`
- the legacy stream `datacloud_export_accounts Pulse360_Datab` and its original data lake object were unmapped from `Account` and deleted after the recovered path was validated
- the live Databricks export path was then rebuilt from repo SQL in the connected workspace and a fresh `43`-row export was generated from `pulse360_s4.intelligence.datacloud_export_accounts`
- that live export was uploaded into `DC Export Accounts P360 Fix`, which completed with `ImportRunStatus = SUCCESS`, `LastRefreshDate = 2026-04-18T05:09:24.000+0000`, and `TotalRowsProcessed = 43`
- the refreshed source object exposed `run_id__c = run_20260418_050206` and `enrichment_run_id__c = run_default_20260418_050206`, and the Account DMO exposed `Enrichment_Run_ID__c = run_default_20260418_050206`, proving the recovered Data Cloud path is now fed by a fresh live Databricks export rather than only the corrected rescue sample

If mapping fails on type mismatch:
- confirm every data row in the uploaded CSV has the same column count as the header
- verify type-sensitive source values:
  - `ai_narrative_generated_at` should be ISO `DateTime`
  - `citation_count` should be numeric
  - `regulatory_readiness_score` should be numeric
  - `validity_score_external` should be numeric
  - `is_externally_validated` should be boolean
- if the current source object was inferred from malformed data, create a fresh stream from the corrected file before retrying the remaining mappings

### 8. Run the focused validation
From the repo:

```bash
./scripts/validate-data-cloud-dmo-extension.sh
./scripts/validate-data-cloud-field-path.sh
```

Expected outcome:
- `validate-data-cloud-dmo-extension.sh` reports:
  - `missing_required_count = 0`
- `validate-data-cloud-field-path.sh` reports:
  - `source_object.missing_field_count = 0`
  - `dmo.missing_target_field_count = 0`
  - `dmo.missing_mapping_count = 0`

### 9. Hand off to DAN-221
Once the source object and DMO field surfaces are complete:
- proceed to Copy Field Enrichment / activation proof
- use `DAN-221` as the next runtime gate

Update on 2026-04-18:
- `pulse360-agent-target` completed the downstream runtime proof after `DAN-220`.
- The canonical recovered stream `DC Export Accounts P360 Fix` remained green with:
  - `ImportRunStatus = SUCCESS`
  - `TotalRowsProcessed = 43`
  - `source_object.missing_field_count = 0`
  - `dmo.missing_target_field_count = 0`
  - `account.missing_target_field_count = 0`
- The seeded walkthrough records then rendered correctly in CRM:
  - seller proof on `JG Summit Holdings, Inc.` (`001dL000024xj2cQAA`)
  - governance proof on `Ayala duplicate review` (`a00dL000036IsSgQAK`)
- This confirms the `DAN-220` surface is no longer just structurally valid; it is now feeding the live Salesforce record-page experience used by the Pulse360 demo path.

Update on 2026-04-20 for the parallel intent-routing stream:
- a new parallel stream `DC Export Accounts P360 V2` was created for the `intent_signal_payload` expansion
- the uploaded live export completed successfully with `43` rows and `47` fields
- the Account DMO field `Intent Signal Payload / Intent_Signal_Payload__c` was accepted in the Data Model UI
- early review-canvas hydration was inconsistent and temporarily suggested that only the primary-key mapping was materializing

Resolution update on 2026-04-21 for the parallel intent-routing stream:
- the hydrated review canvas now shows `Account -> Is Mapped (3)` with:
  - `source_account_id -> Account Id`
  - `external_legal_name -> Account Name`
  - `intent_signal_payload -> Intent Signal Payload`
- `validate-data-cloud-field-path.sh` now reports:
  - `source_object.missing_field_count = 0`
  - `dmo.missing_target_field_count = 0`
  - `dmo.missing_mapping_count = 0`
  - `account.missing_target_field_count = 0`
  - `account.missing_mapping_count = 0`
- live Salesforce Account validation confirms populated values for both:
  - `Intent_Signal_Payload__c`
  - `External_Legal_Name__c`
- treat the V2 stream as validated for the current intent-routing Account activation slice

Implementation note:
- direct CRM realization should be validated through the Copy Field Enrichment contract, not by assuming every export payload field is a direct `Account` field mapping
- specifically:
  - `source_account_id` remains required for CRM-safe matching, but is not a direct `Account` target field
  - `hierarchy_payload` remains required on source and DMO surfaces, but is not a required direct `Account` sync field unless the CRM design explicitly stores raw hierarchy payload on `Account`

## Evidence To Capture
Capture screenshots or notes for:
- the Account DMO field list
- the field creation dialog for any new attributes
- the mapping canvas showing the new fields available
- the final mapping state after save/publish
- the validator output from [validate-data-cloud-dmo-extension.sh](/Users/danielnortje/Documents/Pulse360/scripts/validate-data-cloud-dmo-extension.sh)

Update:
- `DAN-220`
- `DAN-114`
- `DAN-103`

## Exit Criteria
`DAN-220` is complete only when:
- the source object exposes all required contract fields including `hierarchy_payload`
- all required DMO attributes exist
- DLO-to-DMO mapping is complete for the required field set
- [validate-data-cloud-dmo-extension.sh](/Users/danielnortje/Documents/Pulse360/scripts/validate-data-cloud-dmo-extension.sh) reports no missing required fields
- [validate-data-cloud-field-path.sh](/Users/danielnortje/Documents/Pulse360/scripts/validate-data-cloud-field-path.sh) reports no missing source, DMO, or `Account` target fields for the validated stream/source pair

## Stop Conditions
Stop and escalate instead of guessing if any of these happen:
- the source object still does not publish `hierarchy_payload` after a confirmed refresh or source-field add
- `Add Source Fields` opens but still reports `No New Fields Available`
- the Account DMO cannot be edited in the UI
- the Account DMO save fails with duplicate-name validation for fields that still do not appear in the queryable describe surface
- the mapping canvas still does not expose the newly created DMO fields
- the DMO changes save but do not materialize in describe results
- a required field type cannot be represented in the available Data Cloud attribute types
