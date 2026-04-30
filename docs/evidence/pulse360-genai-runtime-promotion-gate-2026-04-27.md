# Evidence: GenAI Runtime Promotion Gate (2026-04-27)

## Scope

Close the data-layer gap between live Claude firmographic runtime output and
the canonical Databricks to Data Cloud Account export without bypassing
Salesforce stewardship.

## Implemented

The live Databricks SQL workspace was updated from source with:

- `sql/databricks/silver_salesforce/90_crm_governance_case.sql`
- `sql/databricks/gold/10_account_export_base.sql`
- `sql/databricks/gold/20_account_core_export.sql`
- `sql/databricks/gold/30_datacloud_export_accounts.sql`
- `sql/databricks/governance_evidence/10_account_intelligence_governance_evidence.sql`
- `sql/databricks/governance_evidence/20_activation_eligibility_review_queue.sql`
- `sql/databricks/governance_evidence/30_datacloud_activation_review_queue.sql`
- `sql/databricks/governance_evidence/40_governance_case_metrics.sql`

The promotion rule is now explicit:

1. live GenAI rows may override Account export AI fields only when they have a
   CRM-safe Account anchor, or a Salesforce `Governance_Case__c` approval
   selects a surviving Account for the Data Cloud review row
2. confidence thresholds still apply:
   - `business_action_confidence >= 0.70`
   - `llm_result_confidence >= 0.80`
3. unsupported and insufficient-evidence guards must be clear

## Live Validation

Databricks runtime validation passed after publishing:

| Asset | Row Count |
| --- | ---: |
| `pulse360_s4.silver_salesforce.crm_account` | 43 |
| `pulse360_s4.silver_salesforce.crm_governance_case` | 1 |
| `pulse360_s4.identity_resolution.resolved_entity` | 44 |
| `pulse360_s4.identity_resolution.entity_hierarchy_rollup` | 3 |
| `pulse360_s4.identity_resolution.m1_account_hierarchy_operational_profile` | 3 |
| `pulse360_s4.gold.account_genai_enrichment_output` | 1 |
| `pulse360_s4.gold_smart_city.smart_city_proposition_readiness` | 9 |
| `pulse360_s4.intelligence.datacloud_export_accounts` | 43 |
| `pulse360_s4.intelligence.datacloud_activation_review_queue` | 11 |
| `pulse360_s4.intelligence.governance_case_metrics` | 1 |

The current Account export still has no promoted Claude rows:

```text
model_id = claude-sonnet-4-20250514
account_export_rows = 0
```

The current model distribution remains:

| Model | Prompt Version | Rows |
| --- | --- | ---: |
| `gpt-5.4` | `pulse360-default-v1` | 37 |
| `gpt-5.4` | `pulse360-public-regional-v1` | 6 |

## Current Blocker

The promotion gate is installed, but the Salesforce governance-feedback bronze
table has not yet picked up the Data Cloud review identifier fields:

```text
missing from pulse360_s4.bronze_salesforce.governance_case__c:
- Source_Product__c
- Data_Cloud_Review_Queue_Id__c
- Data_Cloud_Source_Record_Id__c
- Target_Entity_Name__c
- Market__c
- Offering_Family__c
```

The latest Claude runtime rows therefore remain review-only:

| Source Record | CRM Key | Candidate Count | Resolution Hint | Activation Eligible |
| --- | --- | ---: | --- | --- |
| `genai_firmographic_ent_ph_sec_as096_003241` | null | 2 | `ambiguous_crm_candidates_require_stewardship` | false |
| `genai_firmographic_ent_unknown` | null | 0 | `create_or_map_crm_account_required` | false |

## Next Required Operator Step

Refresh or edit the Databricks Salesforce governance-feedback ingestion
pipeline so `Governance_Case__c` includes the Data Cloud review fields listed
above. Then create or update a Salesforce governance case for:

```text
Data_Cloud_Source_Record_Id__c = genai_firmographic_ent_ph_sec_as096_003241
Source_Product__c = firmographic_genai_runtime
Decision_Status__c = Approved
Surviving_Account__c = <selected CRM-safe Account Id>
Downstream_Update_Status__c = Queued
```

After the ingestion pipeline runs, reapply the Databricks gold and governance
SQL and refresh the Data Cloud streams. At that point the Claude row can enter
the canonical Account export only if all confidence and provenance gates still
pass.
