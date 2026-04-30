# DAN-220 Data Cloud Field Path Recheck - 2026-04-10

## Purpose

Reconfirm the live Pulse360 Data Cloud blocker state after the 2026-04-09 handoff using the repo-backed validators and the local read-only Salesforce/Data Cloud MCP helper.

## Commands Run

```bash
./scripts/validate-data-cloud-dmo-extension.sh
./scripts/validate-data-cloud-field-path.sh
./scripts/validate-salesforce-data-cloud-mcp.sh
```

## Summary

As of 2026-04-10, the blocker state is unchanged from the latest handoff:

- the Data Stream is healthy and the Data Lake Object remains active
- the source object `datacloud_export_accounts_Pulse360_Datab__dll` is still missing required field `hierarchy_payload`
- the queryable `ssot__Account__dlm` surface is still missing:
  - `External_Revenue_Confirmed__c`
  - `Hierarchy_Payload__c`
- the local read-only MCP helper validates cleanly and can inspect the live org, so the current gap is operational Data Cloud publication state rather than repo-side diagnostic tooling
- the Data Cloud UI now shows the same blocker state directly:
  - `Add Source Fields` opens, but reports `No New Fields Available.`
  - the live `Account` DMO field grid does not show either missing target field
  - the DMO `Edit` dialog exposes an `Add Field` path, but a real save attempt fails with duplicate-name validation on both missing field API names

## Update - 2026-04-13

The live blocker state has now been cleared, and the repo validators were updated to match the implemented CRM sync design:

- `hierarchy_payload` is now present on source object `datacloud_export_accounts_Pulse360_Datab__dll`
- `External_Revenue_Confirmed__c` and `Hierarchy_Payload__c` are now present on `ssot__Account__dlm`
- `validate-data-cloud-dmo-extension.sh` now reports `missing_required_count = 0`
- `validate-data-cloud-field-path.sh` now reports:
  - `source_object.missing_field_count = 0`
  - `dmo.missing_mapping_count = 0`
  - `dmo.missing_target_field_count = 0`
  - `account.missing_mapping_count = 0`

Important design correction:

- the remaining `Account` mismatch from the earlier validator run was not a live Data Cloud blocker
- it was a repo-side contract mismatch caused by validating the full export payload against direct Salesforce `Account` mappings
- the repo now uses a dedicated CRM Account sync contract for Copy Field Enrichment validation, which excludes:
  - `source_account_id` as a key-only field
  - `hierarchy_payload` as a DMO/event payload field rather than a required direct `Account` sync field

Interpretation:

- `DAN-220` is no longer blocked by source-object publication or missing DMO fields
- the repo now reflects the implemented architecture: full contract for source and DMO checks, narrower CRM Account sync contract for direct Salesforce field realization checks

## Validator Results

### `validate-data-cloud-dmo-extension.sh`

Observed:

- `required_definition_count = 19`
- `present_required_count = 17`
- `missing_required_count = 2`
- missing required fields:
  - `External_Revenue_Confirmed__c`
  - `Hierarchy_Payload__c`

Interpretation:

- the repo-side DMO definition file is still ahead of the live queryable DMO API by exactly two required attributes

### `validate-data-cloud-field-path.sh`

Observed:

- Data Stream:
  - `ImportRunStatus = SUCCESS`
  - `LastRefreshDate = 2026-04-09T13:53:05.000+0000`
  - `TotalRowsProcessed = 38`
  - `IsNewFieldsAvailable = false`
- Data Lake Object:
  - `DataLakeObjectStatus = ACTIVE`
  - `SyncStatus = ACTIVE`
  - `TotalRecords = 38`
  - `TotalNumberOfFields = 52`
- source object:
  - `missing_field_count = 1`
  - missing field:
    - `hierarchy_payload`
- DMO:
  - `missing_mapping_count = 0`
  - `missing_target_field_count = 2`
  - missing target fields:
    - `External_Revenue_Confirmed__c`
    - `Hierarchy_Payload__c`
- Salesforce `Account`:
  - `missing_mapping_count = 2`
  - missing activation-mapping source fields:
    - `hierarchy_payload`
    - `source_account_id`

Interpretation:

- `Hierarchy_Payload__c` is still blocked upstream because `hierarchy_payload` is not yet published on the source object
- `External_Revenue_Confirmed__c` remains a DMO publication or materialization issue because the upstream source field exists but the queryable DMO field still does not
- the DMO mapping contract itself is complete in repo; the blocker is missing live field publication, not missing CSV mapping rows

## MCP Validation

`validate-salesforce-data-cloud-mcp.sh` passed:

- repo structure checks
- Python module compilation
- expected read-only MCP tool registration
- live Salesforce/Data Cloud connectivity through the official `sf` CLI

Interpretation:

- the local project-specific MCP service is ready for ongoing audit and runtime comparison work
- no additional repo-side diagnostic tooling was required to reproduce the current blocker

## Data Cloud UI Recheck

Browser automation was used to inspect the live Data Cloud UI and, after explicit approval, attempt the smallest possible live DMO repair.

### Source object UI

Observed on Data Stream `datacloud_export_accounts Pulse360_Datab`:

- the `Fields` tab search for `hierarchy_payload` returns `Fields (0)`
- `Add Source Fields` opens successfully
- the modal message is:
  - `No New Fields Available.`
  - `Check back later to add fields to the data stream.`

Interpretation:

- the current blocker is not just an automation click failure
- the live Data Cloud UI itself is not offering `hierarchy_payload` as a newly publishable source field at this moment

### Account DMO UI

Observed on Data Model Object `Account` (`ssot__Account__dlm`):

- field-grid search for `External_Revenue_Confirmed__c` returns no matching rows
- field-grid search for `Hierarchy_Payload__c` returns no matching rows
- the `Edit` dialog opens and exposes:
  - existing editable field rows
  - an `Add Field` row with inputs for:
    - `Field Label`
    - `Field API Name`
    - `Data Type`
  - `Cancel` and `Save` actions
- a live save attempt using:
  - `External Revenue Confirmed` / `External_Revenue_Confirmed` / `Number`
  - `Hierarchy Payload` / `Hierarchy_Payload` / `Text`
  fails with the platform error:
  - `Found duplicate field names for the following fields: Custom__external_revenue_confirmed, Custom__hierarchy_payload, please fix and try again.`

Important control note:

- the attempted save did not commit any new field rows
- the draft edit session was cancelled after capturing the duplicate-name error

Interpretation:

- the two missing fields are absent from the current DMO UI field list, not just absent from the describe API
- the org now presents a stronger contradiction than the 2026-04-09 handoff:
  - the queryable DMO surface still does not expose the two required fields
  - but the Data Cloud edit flow also refuses to create them because their internal custom field names are already reserved
- this suggests stale, hidden, or unpublished DMO metadata rather than a simple missing-field condition

## Next Approved Platform Actions

The next progress on `DAN-220` requires explicit Data Cloud admin action in the target org:

1. Resolve why the source object UI reports `No New Fields Available` even though upstream Databricks now contains `hierarchy_payload`.
2. Resolve the `Account` DMO duplicate-name collision for:
   - `Custom__external_revenue_confirmed`
   - `Custom__hierarchy_payload`
3. After the duplicate-name blocker is cleared, recreate, restore, or republish:
   - `External_Revenue_Confirmed__c`
   - `Hierarchy_Payload__c`
4. Re-run:
   - [validate-data-cloud-dmo-extension.sh](/Users/danielnortje/Documents/Pulse360/scripts/validate-data-cloud-dmo-extension.sh)
   - [validate-data-cloud-field-path.sh](/Users/danielnortje/Documents/Pulse360/scripts/validate-data-cloud-field-path.sh)

Until those live publication steps succeed, `DAN-220` should remain open and `DAN-221` should not be treated as unblocked.
