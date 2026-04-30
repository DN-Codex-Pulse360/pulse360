# Data Cloud Account Mapping Status Matrix

## Purpose
Clarify which Pulse360 mapping instructions are:
- `proven type-compatible`
- `logically correct but not yet live-proven`
- `not appropriate as a default direct CRM-target mapping`

This matrix is specifically about the direct Salesforce `Account` activation surface defined in:
- [activation-field-mapping.csv](/Users/danielnortje/Documents/Pulse360/config/data-cloud/activation-field-mapping.csv)
- [datacloud_to_salesforce_account_sync.schema.json](/Users/danielnortje/Documents/Pulse360/contracts/datacloud_to_salesforce_account_sync.schema.json)

It intentionally distinguishes that CRM-target layer from the broader Data Cloud DMO layer defined in:
- [dmo-account-field-mapping.csv](/Users/danielnortje/Documents/Pulse360/config/data-cloud/dmo-account-field-mapping.csv)
- [datacloud_to_salesforce_agentforce.schema.json](/Users/danielnortje/Documents/Pulse360/contracts/datacloud_to_salesforce_agentforce.schema.json)

## Classification Rules
- `Proven type-compatible`
  - the source type in the account-sync contract is compatible with the target Salesforce `Account` field metadata
  - and the field is consistent with the recovered activation/runtime design already used by the live Pulse360 CRM experience
- `Logically correct but not yet live-proven`
  - the mapping is type-compatible and directionally correct
  - but the current live Data Cloud publication path has not yet proven that this field persists end to end for the new stream/runtime slice
- `Not appropriate as a default direct CRM-target mapping`
  - the field is important to the overall contract
  - but it should not be treated as a default direct `Account` writeback requirement for CRM unless the UX explicitly needs the raw payload on `Account`

## Summary

### Proven type-compatible
- `unified_profile_id -> Account.Unified_Profile_Id__c`
- `identity_confidence -> Account.Identity_Confidence__c`
- `group_revenue_rollup -> Account.Group_Revenue_Rollup__c`
- `health_score -> Account.Health_Score__c`
- `cross_sell_propensity -> Account.Cross_Sell_Propensity__c`
- `coverage_gap_flag -> Account.Coverage_Gap_Flag__c`
- `competitor_risk_signal -> Account.Competitor_Risk_Signal__c`
- `primary_brand_name -> Account.Primary_Brand_Name__c`
- `active_product_count -> Account.Active_Product_Count__c`
- `engagement_intensity_score -> Account.Engagement_Intensity_Score__c`
- `open_opportunity_count -> Account.Open_Opportunity_Count__c`
- `last_engagement_timestamp -> Account.Last_Engagement_Timestamp__c`
- `last_synced_timestamp -> Account.DataCloud_Last_Synced__c`
- `external_legal_name -> Account.External_Legal_Name__c`
- `external_registration_number -> Account.External_Registration_Number__c`
- `is_externally_validated -> Account.Externally_Validated__c`
- `validity_score_external -> Account.Validity_Score_External__c`
- `external_subsidiaries_found -> Account.External_Subsidiaries_Found__c`
- `ai_narrative -> Account.AI_Narrative__c`
- `ai_recommended_actions -> Account.AI_Recommended_Actions__c`
- `ai_narrative_generated_at -> Account.AI_Narrative_Generated__c`
- `enrichment_run_id -> Account.Enrichment_Run_Id__c`
- `regulatory_readiness_score -> Account.Regulatory_Readiness_Score__c`
- `duplicate_exposure_count -> Account.Duplicate_Exposure_Count__c`
- `group_known_subsidiary_count -> Account.Group_Known_Subsidiary_Count__c`
- `crm_covered_subsidiary_count -> Account.CRM_Covered_Subsidiary_Count__c`
- `group_revenue_visible -> Account.Group_Revenue_Visible__c`
- `external_revenue_confirmed -> Account.External_Revenue_Confirmed__c`
- `model_id -> Account.AI_Model_Id__c`
- `prompt_version -> Account.AI_Prompt_Version__c`
- `source_refs -> Account.AI_Source_Refs__c`
- `citation_count -> Account.AI_Citation_Count__c`

### Not appropriate as a default direct CRM-target mapping
- `hierarchy_payload -> Account.Hierarchy_Payload__c`

## Row-By-Row Notes

### Proven type-compatible rows
These are the current direct-CRM mappings that remain sound.

| Source field | Source type | Account target | Account field type | Status | Reason |
| --- | --- | --- | --- | --- | --- |
| `unified_profile_id` | `string` | `Unified_Profile_Id__c` | `Text` | proven type-compatible | String-to-text and part of the stable Account sync contract. |
| `identity_confidence` | `number` | `Identity_Confidence__c` | `Number(5,2)` | proven type-compatible | Numeric score maps cleanly to numeric CRM field. |
| `group_revenue_rollup` | `number` | `Group_Revenue_Rollup__c` | `Currency(18,2)` | proven type-compatible | Numeric revenue value is compatible with the currency target field used by CRM. |
| `health_score` | `number` | `Health_Score__c` | `Number(5,2)` | proven type-compatible | Numeric score-to-score mapping. |
| `cross_sell_propensity` | `number` | `Cross_Sell_Propensity__c` | `Number(5,2)` | proven type-compatible | Numeric score-to-score mapping. |
| `coverage_gap_flag` | `boolean` | `Coverage_Gap_Flag__c` | `Checkbox` | proven type-compatible | Boolean-to-checkbox mapping. |
| `competitor_risk_signal` | `number` | `Competitor_Risk_Signal__c` | `Number(5,2)` | proven type-compatible | Numeric score-to-score mapping. |
| `primary_brand_name` | `string` | `Primary_Brand_Name__c` | `Text` | proven type-compatible | Text-to-text mapping. |
| `active_product_count` | `integer` | `Active_Product_Count__c` | `Number(18,0)` | proven type-compatible | Integer-to-whole-number mapping. |
| `engagement_intensity_score` | `number` | `Engagement_Intensity_Score__c` | `Number(5,2)` | proven type-compatible | Numeric score-to-score mapping. |
| `open_opportunity_count` | `integer` | `Open_Opportunity_Count__c` | `Number(18,0)` | proven type-compatible | Integer-to-whole-number mapping. |
| `last_engagement_timestamp` | `date-time` | `Last_Engagement_Timestamp__c` | `DateTime` | proven type-compatible | DateTime-to-DateTime mapping. |
| `last_synced_timestamp` | `date-time` | `DataCloud_Last_Synced__c` | `DateTime` | proven type-compatible | DateTime-to-DateTime mapping. |
| `external_legal_name` | `string` | `External_Legal_Name__c` | `Text` | proven type-compatible | Text-to-text mapping. Prior type-mismatch incidents came from malformed CSV inference, not from this intended pair. |
| `external_registration_number` | `string` | `External_Registration_Number__c` | `Text` | proven type-compatible | Text-to-text mapping. |
| `is_externally_validated` | `boolean` | `Externally_Validated__c` | `Checkbox` | proven type-compatible | Boolean-to-checkbox mapping. |
| `validity_score_external` | `number` | `Validity_Score_External__c` | `Number(3,0)` | proven type-compatible | Numeric score-to-score mapping. |
| `external_subsidiaries_found` | `integer` | `External_Subsidiaries_Found__c` | `Number(5,0)` | proven type-compatible | Integer-to-whole-number mapping. |
| `ai_narrative` | `string` | `AI_Narrative__c` | `LongTextArea` | proven type-compatible | String payload fits the long-text CRM field. |
| `ai_recommended_actions` | `string` | `AI_Recommended_Actions__c` | `LongTextArea` | proven type-compatible | String payload fits the long-text CRM field. |
| `ai_narrative_generated_at` | `date-time` | `AI_Narrative_Generated__c` | `DateTime` | proven type-compatible | DateTime-to-DateTime mapping. |
| `enrichment_run_id` | `string` | `Enrichment_Run_Id__c` | `Text` | proven type-compatible | Text-to-text mapping. |
| `regulatory_readiness_score` | `number` | `Regulatory_Readiness_Score__c` | `Number(3,0)` | proven type-compatible | Numeric score-to-score mapping. |
| `duplicate_exposure_count` | `integer` | `Duplicate_Exposure_Count__c` | `Number(8,0)` | proven type-compatible | Integer-to-whole-number mapping. |
| `group_known_subsidiary_count` | `integer` | `Group_Known_Subsidiary_Count__c` | `Number(5,0)` | proven type-compatible | Integer-to-whole-number mapping. |
| `crm_covered_subsidiary_count` | `integer` | `CRM_Covered_Subsidiary_Count__c` | `Number(5,0)` | proven type-compatible | Integer-to-whole-number mapping. |
| `group_revenue_visible` | `number` | `Group_Revenue_Visible__c` | `Number(18,2)` | proven type-compatible | Numeric revenue-to-number mapping. |
| `external_revenue_confirmed` | `number` | `External_Revenue_Confirmed__c` | `Number(18,2)` | proven type-compatible | Numeric revenue-to-number mapping. |
| `model_id` | `string` | `AI_Model_Id__c` | `Text` | proven type-compatible | Text-to-text mapping. |
| `prompt_version` | `string` | `AI_Prompt_Version__c` | `Text` | proven type-compatible | Text-to-text mapping. |
| `source_refs` | `string` | `AI_Source_Refs__c` | `LongTextArea` | proven type-compatible | Serialized provenance payload fits the long-text CRM field. |
| `citation_count` | `integer` | `AI_Citation_Count__c` | `Number(5,0)` | proven type-compatible | Integer-to-whole-number mapping. |
| `intent_signal_payload` | `string` | `Intent_Signal_Payload__c` | `LongTextArea` | proven type-compatible | Type intent is correct and is now live-validated in the V2 stream path through both Data Cloud mapping review and Salesforce Account query results. |

### Not appropriate as a default direct CRM-target mapping
These fields still belong in the broader Pulse360 contract, but they should not be treated as default direct `Account` writeback requirements.

| Source field | Source type | Account target | Account field type | Status | Reason |
| --- | --- | --- | --- | --- | --- |
| `hierarchy_payload` | `string` | `Hierarchy_Payload__c` | `LongTextArea` | not appropriate as a default direct CRM-target mapping | The type is compatible, but the current architecture treats raw hierarchy payload as a source/DMO/workspace concern first. Keep it available for experiences that explicitly need it, but do not treat it as a default Account activation requirement. |

## Important Distinctions

### 1. Type correctness is not the same as live publication proof
This was the right caution earlier. For `intent_signal_payload`, that live publication proof has now been obtained in the V2 stream path.

### 2. The old type-mismatch issue was caused by malformed source data
The prior failure mode came from shifted CSV columns and poisoned source-field inference, not from the intended logical pairings themselves.

### 3. DMO mapping and direct CRM mapping are not the same layer
- DMO layer:
  - broader operational profile
  - raw payload storage is more acceptable
- direct CRM `Account` layer:
  - narrower execution-oriented sync surface
  - should avoid carrying raw payloads by default unless the UX explicitly depends on them

## Recommended Next Cleanup
- Keep [activation-field-mapping.csv](/Users/danielnortje/Documents/Pulse360/config/data-cloud/activation-field-mapping.csv) as the direct CRM contract, but treat `hierarchy_payload` as optional-by-design rather than expected-by-default.
- Keep `intent_signal_payload` in the activation contract; it is now validated in the current live Data Cloud path.
- Use this matrix when deciding whether a future mapping failure is:
  - a bad instruction
  - a source inference problem
  - a Data Cloud publication/runtime problem
