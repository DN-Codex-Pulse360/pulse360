# DAN-297 Data Cloud GenAI Provenance Proof

Date: 2026-04-26
Org alias: `pulse360-agent-target`
Scope: Databricks -> Data Cloud -> Salesforce Account GenAI/provenance field path

## Summary

The Data Cloud consumption path for the existing public-regional
GenAI/provenance account slice is proven through live org evidence.

The live org now shows:

- Active Data Cloud streams for the Pulse360 account export.
- AI/provenance extension fields on `ssot__Account__dlm`.
- Matching AI/provenance fields on Salesforce `Account`.
- Materialized DMO rows with narrative, recommended actions, source refs,
  prompt/model metadata, citation count, and CRM-safe Account IDs.
- Matching Salesforce `Account` rows populated with the same AI/provenance
  payloads.

This proves the field path for the existing public-regional data set.

The 2026-04-26 Claude runtime output is not yet proven through Data Cloud. The
latest active Data Stream refresh predates the Claude runtime work, so the next
step is to promote or merge the Claude runtime output into the canonical
Databricks Data Cloud export and refresh the Data Cloud stream.

## Live Data Stream Evidence

`DC Export Accounts P360 V2`:

```text
DataStreamStatus = ACTIVE
ImportRunStatus = SUCCESS
LastRefreshDate = 2026-04-20T06:29:34.000+0000
TotalRowsProcessed = 43
IsNewFieldsAvailable = false
RefreshMode = FULL_REFRESH
```

`DC Export Accounts P360 Fix`:

```text
DataStreamStatus = ACTIVE
ImportRunStatus = SUCCESS
LastRefreshDate = 2026-04-18T14:25:10.000+0000
TotalRowsProcessed = 4
```

Data Lake Object evidence for `DC Export Accounts P360 Fix`:

```text
DataLakeObjectStatus = ACTIVE
SyncStatus = ACTIVE
TotalRecords = 4
TotalNumberOfFields = 48
```

## Contract And Mapping Evidence

DMO comparison against `config/data-cloud/dmo-account-field-mapping.csv`:

```text
target_object = ssot__Account__dlm
required_field_count = 34
mapped_field_count = 34
missing_mapping_count = 0
missing_target_field_count = 0
```

Salesforce Account activation comparison against
`config/data-cloud/activation-field-mapping.csv`:

```text
target_object = Account
required_field_count = 31
mapped_field_count = 31
missing_mapping_count = 0
missing_target_field_count = 0
```

Source object comparison for `dc_export_accounts_p360_fix__dll`:

```text
required_field_count = 42
live_source_field_count = 48
present_field_count = 41
missing_field_count = 1
missing_fields = intent_signal_payload
```

The missing source-object field is outside the GenAI/provenance slice. The DMO
and Salesforce Account surfaces both already expose `Intent_Signal_Payload__c`.

## Live DMO Field Evidence

`ssot__Account__dlm` has the required GenAI/provenance fields:

```text
AI_Narrative__c
AI_Recommended_Actions__c
AI_Narrative_Generated__c
Enrichment_Run_ID__c
AI_Model_ID__c
AI_Prompt_Version__c
AI_Source_Refs__c
AI_Citation_Count__c
External_Legal_Name__c
Validity_Score_External__c
Regulatory_Readiness_Score__c
Duplicate_Exposure_Count__c
Group_Known_Subsidiary_Count__c
CRM_Covered_Subsidiary_Count__c
Group_Revenue_Visible__c
External_Revenue_Confirmed__c
```

Live DMO query returned four account rows where `AI_Narrative__c` is populated.
Examples:

```text
ssot__Id__c = 001dL000024xl9FQAQ
AI_Model_ID__c = gpt-5.4
AI_Prompt_Version__c = pulse360-public-regional-v1
Enrichment_Run_ID__c = run_public_regional_20260328
AI_Citation_Count__c = 2
```

```text
ssot__Id__c = 001dL000024wgYRQAY
AI_Model_ID__c = gpt-5.4
AI_Prompt_Version__c = pulse360-public-regional-v1
Enrichment_Run_ID__c = run_public_regional_20260328
AI_Citation_Count__c = 2
```

## Live Salesforce Account Evidence

Salesforce `Account` has the required activation target fields:

```text
AI_Narrative__c
AI_Recommended_Actions__c
AI_Narrative_Generated__c
Enrichment_Run_Id__c
AI_Model_Id__c
AI_Prompt_Version__c
AI_Source_Refs__c
AI_Citation_Count__c
DataCloud_Last_Synced__c
```

The CRM-safe key path is proven because DMO `ssot__Id__c` values match live
Salesforce `Account.Id` values. Querying those Account IDs returned populated
AI/provenance fields:

```text
Account.Id = 001dL000024wgYRQAY
Name = Ayala Corporation
Enrichment_Run_Id__c = run_public_regional_20260328
AI_Model_Id__c = gpt-5.4
AI_Prompt_Version__c = pulse360-public-regional-v1
AI_Citation_Count__c = 2
DataCloud_Last_Synced__c = 2026-03-28T09:00:00.000+0000
```

```text
Account.Id = 001dL000024xl9FQAQ
Name = Singtel Group
Enrichment_Run_Id__c = run_public_regional_20260328
AI_Model_Id__c = gpt-5.4
AI_Prompt_Version__c = pulse360-public-regional-v1
AI_Citation_Count__c = 2
DataCloud_Last_Synced__c = 2026-03-28T09:00:00.000+0000
```

Other verified Account IDs:

```text
001dL000024weudQAA = Ayala Corp.
001dL000024xj2cQAA = JG Summit Holdings, Inc.
```

## Current Gap

The current Data Cloud proof is for the existing public-regional
GenAI/provenance data set, not the new Claude runtime output created on
2026-04-26.

The latest Claude runtime evidence remains in Databricks:

```text
Databricks job run = 767020160543876
runtime run_id = genai_firmographic_batch_llm_20260426044442
model_id = claude-sonnet-4-20250514
generation_mode = batch_llm
MLflow run_id = 1f13b2b199694e98a4021e1b89424e4c
source_ref_count = 4
```

Because the active Data Cloud stream last refreshed on 2026-04-20, this Claude
runtime output has not yet flowed through Data Cloud or Salesforce Account.

## Conclusion

`DAN-297` can be considered proven for the Data Cloud field path:

1. Databricks-origin GenAI/provenance fields are modeled in the contracts and
   mappings.
2. Data Cloud DMO fields exist.
3. Data Cloud DMO rows contain AI/provenance values.
4. Salesforce Account target fields exist.
5. Salesforce Account rows contain activated AI/provenance values.
6. The CRM-safe activation key is preserved through `ssot__Id__c` to
   `Account.Id`.

The remaining work is a follow-on promotion/refresh task for the new Claude
runtime output, not a blocker to the field-path proof itself.

