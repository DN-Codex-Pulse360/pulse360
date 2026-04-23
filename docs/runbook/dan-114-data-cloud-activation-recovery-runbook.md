# DAN-114 Data Cloud Activation Recovery Runbook

## Purpose
Recover the blocked Pulse360 Salesforce `Account` activation path in `pulse360-dev` after repo-side field deployment completed but Data Cloud activation-target setup failed to materialize.

This runbook is intentionally UI-first. Current evidence shows the public sObject/API path is not enough to finish companion setup for the activation target.

## Current Runtime Baseline
Use [dan-114-activation-target-runtime-check-2026-03-14.md](/Users/danielnortje/Documents/Pulse360/docs/evidence/dan-114-activation-target-runtime-check-2026-03-14.md) as the current baseline.

Known live state:
- activation target `85UdM00000EC7IbUAL` exists
- `RunStatus = QUEUED`
- `TargetStatus = ERROR`
- `LastTargetStatusErrorCode = CREATE_FAILED`
- `ActivationTargetPlatform` rows for the target: `0`
- `ActivationTrgtIntOrgAccess` rows for the target: `0`
- `ActvTgtPlatformFieldValue` rows in org: `0`
- `MktDataLakeMapping` rows in org: `0`

## Goal
Bring the activation path to a state where:
- the target companion records exist
- field mappings can be created and published
- activation refresh succeeds
- sample Salesforce `Account` records show populated Pulse360 activation fields

## Preconditions
1. Salesforce `Account` target fields already exist in `pulse360-dev`.
2. Databricks export surface still exposes the activation-ready fields required by [activation-field-mapping.csv](/Users/danielnortje/Documents/Pulse360/config/data-cloud/activation-field-mapping.csv).
3. The operator has Data Cloud admin access in `pulse360-dev`.
4. The operator is prepared to make Data Cloud configuration changes in the UI.

## Activation Contract To Preserve
Do not proceed if the Data Cloud source no longer preserves the CRM-safe key requirements in [datacloud-to-salesforce-agentforce-contract.md](/Users/danielnortje/Documents/Pulse360/docs/contracts/datacloud-to-salesforce-agentforce-contract.md).

Required assumptions:
- `source_account_id` remains the CRM writeback key
- the target object is Salesforce `Account`
- the activation fields remain those defined in [activation-field-mapping.csv](/Users/danielnortje/Documents/Pulse360/config/data-cloud/activation-field-mapping.csv)

## Manual Recovery Steps

### 1. Confirm the activation source object is usable in Data Cloud UI
In Data Cloud, open the activation source tied to `datacloud_export_accounts Pulse360_Datab`.

Confirm:
- the source object is visible and healthy
- preview rows exist
- `source_account_id` is present
- the Pulse360 activation fields are visible:
  - `unified_profile_id`
  - `identity_confidence`
  - `group_revenue_rollup`
  - `health_score`
  - `cross_sell_propensity`
  - `coverage_gap_flag`
  - `competitor_risk_signal`
  - `primary_brand_name`
  - `active_product_count`
  - `engagement_intensity_score`
  - `open_opportunity_count`
  - `last_engagement_timestamp`
  - `last_synced_timestamp`

If the source object preview is empty or these fields are missing, stop here and repair the upstream Data Cloud dataset before touching activation.

### 2. Inspect the failed activation target in Data Cloud UI
Locate the target named `Pulse360 Salesforce Account Activation`.

Capture:
- current status
- any visible error message beyond `CREATE_FAILED`
- target object selection
- connector / org binding
- whether the target can be edited, repaired, or must be recreated

If the UI shows a richer error than the API, record it in a new evidence note or Linear comment.

### 3. Recreate the activation target if the current target cannot self-heal
If the existing target remains in unrecoverable `ERROR` state:
- create a fresh Salesforce activation target in the Data Cloud UI
- bind it to the same Salesforce org / connection
- select Salesforce `Account` as the target object
- ensure the target is not pointed at a synthetic-only identifier path

Do not reuse Databricks-origin synthetic account IDs as the CRM match key.

### 4. Configure the CRM-safe match key
Set the match/writeback key to the CRM-safe account key.

Preferred:
- source `source_account_id`
- target Salesforce `Account.Id`

Only use an alternative key if it is an approved Salesforce External ID and the contract is updated accordingly.

### 5. Build the field mappings in the UI
Map the source fields to Salesforce `Account` using [activation-field-mapping.csv](/Users/danielnortje/Documents/Pulse360/config/data-cloud/activation-field-mapping.csv):

- `unified_profile_id` -> `Account.Unified_Profile_Id__c`
- `identity_confidence` -> `Account.Identity_Confidence__c`
- `group_revenue_rollup` -> `Account.Group_Revenue_Rollup__c`
- `health_score` -> `Account.Health_Score__c`
- `cross_sell_propensity` -> `Account.Cross_Sell_Propensity__c`
- `coverage_gap_flag` -> `Account.Coverage_Gap_Flag__c`
- `competitor_risk_signal` -> `Account.Competitor_Risk_Signal__c`
- `primary_brand_name` -> `Account.Primary_Brand_Name__c`
- `active_product_count` -> `Account.Active_Product_Count__c`
- `engagement_intensity_score` -> `Account.Engagement_Intensity_Score__c`
- `open_opportunity_count` -> `Account.Open_Opportunity_Count__c`
- `last_engagement_timestamp` -> `Account.Last_Engagement_Timestamp__c`
- `last_synced_timestamp` -> `Account.DataCloud_Last_Synced__c`

If the UI still does not expose these target fields, stop and record that the activation target metadata has not fully refreshed against Salesforce schema.

### 6. Publish the mapping
Publish or activate the mapping in Data Cloud.

Expected outcome:
- the mapping panel is no longer `0/0`
- companion activation-target records are materialized
- the target transitions out of `CREATE_FAILED`

### 7. Trigger a refresh or activation run
Run the target or refresh the connected data stream, depending on the supported UI flow.

Expected outcome:
- target status becomes healthy
- stream remains `ACTIVE`
- rows processed is greater than `0`

### 8. Verify writeback in Salesforce
Use sample `Account` records that are known to exist in the exported dataset.

Validate that at least one sample account shows populated values in:
- `Unified_Profile_Id__c`
- `Identity_Confidence__c`
- `Health_Score__c`
- `Cross_Sell_Propensity__c`
- `DataCloud_Last_Synced__c`

## Evidence To Capture
Capture screenshots or notes for:
- activation target setup page
- match-key configuration
- mapping page showing non-zero mappings
- activation run status
- sample Salesforce `Account` record with populated fields

Update:
- [dan-114-activation-target-runtime-check-2026-03-14.md](/Users/danielnortje/Documents/Pulse360/docs/evidence/dan-114-activation-target-runtime-check-2026-03-14.md) or add a new evidence note
- `DAN-114`
- `DAN-61`
- `DAN-103`

## Exit Criteria
`DAN-114` can move toward done only when all of these are true:
- `MktDataLakeMapping` is non-zero
- activation target companion rows exist
- activation run is successful
- sample Salesforce `Account` records show real activated values

## Stop Conditions
Stop and escalate instead of guessing if any of these happen:
- the Data Cloud UI still shows no source fields or no target fields
- the target cannot be created or edited in the UI
- the connector/org binding looks wrong or stale
- the target requires a hidden identifier field not available in the public API or UI
- activation publishes but writes zero rows despite valid source preview
