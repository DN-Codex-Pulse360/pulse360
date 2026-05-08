# DAN-103 Milestone C Acceptance Evidence - 2026-05-08

## Scope

This note records the final read-only evidence used to close the remaining
Milestone C blockers in `pulse360-agent-target`:

- `DAN-116` - CRM-safe account identity through the Databricks intelligence
  pipeline.
- `DAN-61` - calculated insights and Data Cloud activation into Salesforce
  Account.
- `DAN-103` - Milestone C activation acceptance.

No Salesforce metadata deployment, permission change, folder sharing change, or
Data Cloud configuration mutation was performed as part of this validation.

## CRM-Safe Identity

`DAN-116` is satisfied by source-controlled contracts and live MCP checks:

- Salesforce `Account` has `18` rows in scope.
- Data Cloud source object `pulse360_account_intelligence_export_v2__dll` has
  `18` rows.
- Data Cloud DMO `ssot__Account__dlm` has `18` rows.
- `source_account_id__c` in the source object is the Salesforce `Account.Id`.
- `ssot__Id__c` in `ssot__Account__dlm` is the Salesforce `Account.Id`.
- `Unified_Profile_Id__c` follows the deterministic pattern
  `ucp_<AccountId>` in Salesforce Account and Data Cloud.
- `Identity_Confidence__c` is populated on all `18` Salesforce Accounts.
- `DataCloud_Last_Synced__c` is populated on all `18` Salesforce Accounts.

Representative live checks:

```sql
SELECT Id, Name, Unified_Profile_Id__c, Identity_Confidence__c,
       DataCloud_Last_Synced__c
FROM Account
ORDER BY Id
LIMIT 200
```

```sql
SELECT source_account_id__c, unified_profile_id__c, identity_confidence__c,
       last_synced_timestamp__c
FROM pulse360_account_intelligence_export_v2__dll
ORDER BY source_account_id__c
LIMIT 200
```

Data Cloud DMO check:

```text
DMO: ssot__Account__dlm
Fields: ssot__Id__c, ssot__Name__c, Unified_Profile_Id__c,
        Identity_Confidence__c, Last_Synced_Timestamp__c
Rows: 18
```

The live row values confirm that Databricks-generated intelligence does not use
Databricks-only synthetic identifiers as the Salesforce activation key.

## Calculated Insights And Activation

`DAN-61` is satisfied for prototype/Milestone C acceptance by the current
source-controlled configuration and live runtime evidence:

- Calculated insight configuration validator passes.
- Data Cloud field path validator passes from source object to DMO to Account.
- Account payload exception activation validator passes in dry-run mode.
- `DC Export Accounts P360 V2` is `ACTIVE/SUCCESS`, last refreshed
  `2026-04-29T14:23:19Z`, with `18` processed rows.
- Data Action `Pulse360_Account_Intelligence_Copy_Fields_20xo47` is `ACTIVE`.
- Latest Copy Field job `1A5dL0000001BFxSAM` completed with `18` processed,
  `18` updated, `0` failed, and `0` skipped.
- All `18` Salesforce Accounts have populated `Unified_Profile_Id__c`,
  `Identity_Confidence__c`, `Health_Score__c`,
  `Cross_Sell_Propensity__c`, and `DataCloud_Last_Synced__c`.
- Account records show `LastModifiedBy.Name = Platform Integration User`,
  proving runtime/platform writeback rather than manual user repair.

Current implementation note:

- The active live path is Data Cloud Copy Field Enrichment from
  `ssot__Account__dlm` to Salesforce `Account`.
- The older `ActivationTarget` / `MktDataLakeMapping` objects remain empty in
  this org and are not the proven activation mechanism.
- Long text and payload exception fields remain governed by the documented
  payload exception runbook instead of native Copy Field.

## Firmographic Validation Streams

The live validation streams required by the Milestone C dashboard and reports
are active and successful:

| Stream | Rows | Expected |
| --- | ---: | --- |
| `firmographic_profile_export_Pulse360_Dat` | 18 | Yes |
| `firmographic_source_evidence_export_Puls` | 140 | Yes |
| `company_classification_export_Pulse360_D` | 11 | Yes |
| `corporate_linkage_export_Pulse360_Databr` | 2 | Yes |
| `sovereign_identifier_export_Pulse360_Dat` | 0 | Yes |

Sovereign identifier coverage remains `0` by design until official registry,
tax-authority, or filing evidence satisfies the verification gate.

## Validation Commands

The following local and live validators were used for acceptance:

```bash
./scripts/validate-databricks-salesforce-sql-pack.sh
./scripts/validate-contracts.sh
./scripts/validate-canonical-exports.sh
./scripts/validate-hierarchy-and-identity.sh
PULSE360_DEFAULT_ORG_ALIAS=pulse360-agent-target ./scripts/validate-account-payload-exception-activation.sh
TARGET_ORG=pulse360-agent-target ./scripts/validate-data-cloud-field-path.sh
./scripts/validate-data-cloud-insights-config.sh
git diff --check
```

## Acceptance Outcome

Recommended Linear outcome:

- Move `DAN-116` to Done.
- Move `DAN-61` to Done.
- Remove `DAN-116` and `DAN-61` as blockers from `DAN-103`.
- Move `DAN-103` to Done as the Milestone C acceptance record.

Residual notes:

- The live dashboard intentionally shows no sovereign identifier data until
  official evidence is present.
- Dashboard component tables are validation-oriented; a later UX iteration can
  replace raw tables with more polished scorecards without changing the Data
  Cloud relationships or report joins.
