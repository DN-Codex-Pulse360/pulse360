# DAN-327 Copy Field Exception Activation Path

Date: 2026-04-30

## Decision

Keep native Data Cloud Copy Field Enrichment as the authoritative activation
path only for the proven scalar `ssot__Account__dlm -> Account` fields.

Do not reshape the current CRM long-text payload fields just to fit Copy Field.
The five payload and narrative fields stay outside native Copy Field and use a
runbook/API-backed CRM update path when they must be physically written to
`Account`.

Keep the three revenue exceptions outside native Copy Field until their
Data Cloud and CRM field types are deliberately reshaped and re-proven in a
new Copy Field job.

## Field Routing

| Source field | Account field | Activation path | Decision |
| --- | --- | --- | --- |
| `ai_narrative` | `AI_Narrative__c` | `payload_api_runbook` | Long Text target was not offered by native Copy Field. |
| `ai_recommended_actions` | `AI_Recommended_Actions__c` | `payload_api_runbook` | Long Text target was not offered by native Copy Field. |
| `source_refs` | `AI_Source_Refs__c` | `payload_api_runbook` | Long Text target was not offered by native Copy Field. |
| `hierarchy_payload` | `Hierarchy_Payload__c` | `payload_api_runbook` | Long Text target was not offered by native Copy Field. |
| `intent_signal_payload` | `Intent_Signal_Payload__c` | `payload_api_runbook` | Long Text target was not offered by native Copy Field. |
| `group_revenue_rollup` | `Group_Revenue_Rollup__c` | `schema_type_deferred` | Native Copy Field did not offer the Currency target for the Number source. |
| `group_revenue_visible` | `Group_Revenue_Visible__c` | `dmo_type_deferred` | Source-to-DMO mapping was rejected for type compatibility. |
| `external_revenue_confirmed` | `External_Revenue_Confirmed__c` | `dmo_type_deferred` | Source-to-DMO mapping was rejected for type compatibility. |

## Operating Rules

1. Native Copy Field restarts must validate only rows where
   `copy_field_required=true` in `config/data-cloud/activation-field-mapping.csv`
   and `config/data-cloud/dmo-account-field-mapping.csv`.
2. Exception fields must remain present in the Account sync contract and mapping
   files so downstream product contracts do not silently lose them.
3. Payload exception writes must be executed through an explicit CRM API or
   runbook-managed path with target-org Account IDs, provenance, run ID, and
   freshness preserved.
4. Revenue exception fields cannot be added back to native Copy Field until the
   source, DMO, and Account field types are aligned and a new Copy Field job
   proves non-null Account values.

## Validation

Run these checks before restarting native Copy Field:

```bash
./scripts/validate-data-cloud-copy-field-exceptions.sh
./scripts/validate-data-cloud-activation-key-alignment.sh
./scripts/validate-data-cloud-field-path.sh
```

The exception routing validator is the contract gate for this decision. It
fails if any accepted exception is marked as native Copy Field required or if
native required fields are not also required on the DMO mapping.

## Reopening Criteria

Reopen this decision only when one of these is true:

- Salesforce Data Cloud exposes Long Text target fields in native Copy Field.
- The CRM payload fields are intentionally replaced with Copy Field-compatible
  scalar fields.
- The revenue source, DMO, and Account fields are reshaped to compatible types
  and a new Copy Field run completes with non-null values.
