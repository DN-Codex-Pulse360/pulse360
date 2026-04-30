# DAN-220 Data Cloud DLO / DMO Gap Check - 2026-03-29

## Purpose

Identify the exact layer where the new public-regional GPT/provenance fields are missing in the Pulse360 Data Cloud path.

The working question was:

- are the new fields missing on the Databricks export source object
- missing on the Data Cloud Account DMO
- or present in both places but merely unmapped

## Summary

As of 2026-03-29, the missing layer is the **Data Cloud source Data Lake Object schema itself**.

Findings:

- the live Databricks export table contains the new GPT/provenance field set
- the Data Cloud source object `datacloud_export_accounts_Pulse360_Datab__dll` contains only the older/core enrichment field set
- the visible Account DMO `ssot__Account__dlm` also contains only the older/core enrichment field set
- therefore the new field set cannot yet be proven through source -> DMO -> Copy Field Enrichment

This means the next platform step is not only DMO mapping work. It is first necessary to expose the new fields at the Data Cloud source object layer.

## Databricks Source State

The Databricks table `pulse360_s4.intelligence.datacloud_export_accounts` was verified to contain the regional rows and the new public-regional GPT/provenance fields for:

- `Singtel Group`
- `Ayala Corporation`
- `JG Summit Holdings, Inc.`

Verified fields included:

- `external_legal_name`
- `model_id`
- `prompt_version`
- `citation_count`
- `regulatory_readiness_score`

## Data Cloud Stream State

Queried `DataStream` for `datacloud_export_accounts Pulse360_Datab`.

Observed:

- `LastRefreshDate = 2026-03-29T00:32:57.000+0000`
- `ImportRunStatus = SUCCESS`
- `TotalRowsProcessed = 38`
- `IsNewFieldsAvailable = false`

Interpretation:

- Data Cloud successfully refreshed the stream
- the current imported source shape does not advertise any newly available fields

## Data Cloud Source Object State

The live Data Lake object instance for the Databricks export is:

- `Name = datacloud_export_accounts Pulse360_Datab`
- `ExternalName = datacloud_export_accounts_Pulse360_Datab__dll`
- `DataLakeObjectStatus = ACTIVE`
- `SyncStatus = ACTIVE`
- `TotalRecords = 38`
- `TotalNumberOfFields = 26`

### Actual imported source fields

Describing `datacloud_export_accounts_Pulse360_Datab__dll` returned only the following business fields:

- `source_account_id__c`
- `account_name__c`
- `unified_profile_id__c`
- `identity_confidence__c`
- `health_score__c`
- `cross_sell_propensity__c`
- `group_revenue_rollup__c`
- `coverage_gap_flag__c`
- `competitor_risk_signal__c`
- `primary_brand_name__c`
- `active_product_count__c`
- `engagement_intensity_score__c`
- `open_opportunity_count__c`
- `last_engagement_timestamp__c`
- `last_synced_timestamp__c`
- `deterministic_key__c`
- `canonical_account_id__c`
- `run_id__c`
- `run_timestamp__c`
- `model_version__c`
- `ingestion_metadata_label__c`

### Verified records in the source object

Sample rows for the regional accounts exist on the source object and show only the older/core fields:

- `Ayala Corporation`
  - `unified_profile_id__c = ucp_001dM00003d4bllQAA`
  - `identity_confidence__c = 82`
  - `health_score__c = 35`
  - `cross_sell_propensity__c = 25`
- `JG Summit Holdings, Inc.`
  - `unified_profile_id__c = ucp_001dM00003d4bnNQAQ`
  - `identity_confidence__c = 82`
  - `health_score__c = 35`
  - `cross_sell_propensity__c = 25`
- `Singtel Group`
  - `unified_profile_id__c = ucp_001dM00003d4YKtQAM`
  - `identity_confidence__c = 82`
  - `health_score__c = 35`
  - `cross_sell_propensity__c = 25`

## Visible DMO State

Describing `ssot__Account__dlm` still shows only the older/core custom enrichment fields:

- `Unified_Profile_Id__c`
- `Identity_Confidence__c`
- `Health_Score__c`
- `Cross_Sell_Propensity__c`

The following new public-regional GPT/provenance fields are not visible on the DMO:

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

## Important Interpretation

The current evidence shows this is **not yet a DMO-only problem**.

The new field set is absent before the DMO stage, because it is not currently visible on the imported Data Cloud source object.

That means the work required for `DAN-220` is:

1. confirm why the Databricks export schema expansion did not surface on `datacloud_export_accounts_Pulse360_Datab__dll`
2. refresh, extend, or recreate the source object schema if needed
3. only then extend the DMO and mapping layer

## Caution On Salesforce Account Values

Some regional Salesforce `Account` records currently show:

- `External_Legal_Name__c`
- `AI_Model_Id__c`
- `Regulatory_Readiness_Score__c`

Those values must **not** be treated as proof that the new Data Cloud field path is complete.

Reason:

- the source DLO does not currently expose the new fields
- therefore the DMO cannot yet be proven to carry them
- therefore current `Account` values could reflect seeded/demo values preserved during later record updates rather than end-to-end Data Cloud realization for the new field set

## Conclusion

The highest-signal statement for `DAN-220` is:

**the new GPT/provenance field set is currently missing from the imported Data Cloud source object schema (`datacloud_export_accounts_Pulse360_Datab__dll`), so DMO extension and Copy Field Enrichment proof cannot be completed until that source-object gap is resolved.**
