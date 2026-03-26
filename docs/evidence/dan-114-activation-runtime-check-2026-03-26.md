# DAN-114 Activation Runtime Check - 2026-03-26

## Summary
- Re-validated the live `pulse360-dev` Data Cloud activation state after the March 14 recovery attempts.
- Confirmed the Salesforce `Account` activation target fields still exist in org metadata and remain aligned with the repo mapping contract.
- Confirmed the original failed activation target (`85UdM00000EC7IbUAL`) is no longer present.
- Confirmed a replacement activation target now exists and reports healthy status:
  - `Id`: `85UdM00000EGtEzUAL`
  - `MasterLabel`: `Pulse360 Salesforce Account Activation v2`
  - `RunStatus`: `SUCCESS`
  - `TargetStatus`: `ACTIVE`
- Confirmed the Data Cloud stream remains healthy and now shows processed rows:
  - `Id`: `1dsdM000000QD9hQAG`
  - `Name`: `datacloud_export_accounts Pulse360_Datab`
  - `DataStreamStatus`: `ACTIVE`
  - `ImportRunStatus`: `SUCCESS`
  - `TotalRowsProcessed`: `13`
- Confirmed through the Data Cloud UI that the replacement activation path now exposes a non-zero field mapping surface:
  - source object: `datacloud_export_accounts Pulse360_Datab`
  - target object: `Account`
  - mapped fields shown in UI: `15`
- Confirmed the Salesforce `Account` page layout now exposes a dedicated `Pulse360` section in the live record UI.
- Confirmed the activation path still does not show completed mapping/writeback evidence through the org-facing API:
  - `MktDataLakeMapping` rows: `0`
  - `ActivationTargetPlatform` rows for `85UdM00000EGtEzUAL`: `0`
  - `ActivationTrgtIntOrgAccess` rows for `85UdM00000EGtEzUAL`: `0`
  - `ActvTgtPlatformFieldValue` rows: `0`
  - sample `Account` query with populated Pulse360 activation fields: `0` rows
- Confirmed on sampled Account `Globex APAC Pte Ltd` that the visible Pulse360 fields remain blank in the live Salesforce UI:
  - `Unified Profile Id`
  - `Identity Confidence`
  - `Health Score`
  - `Cross Sell Propensity`
  - `Competitor Risk Signal`
  - `Coverage Gap Flag`
  - `Group Revenue Rollup`
  - `DataCloud Last Synced`

## Runtime Snapshot
- Target org: `pulse360-dev`
- Account target fields:
  - repo metadata check: pass
  - live org check: pass
- Current activation target:
  - `Id`: `85UdM00000EGtEzUAL`
  - `MasterLabel`: `Pulse360 Salesforce Account Activation v2`
  - `RunStatus`: `SUCCESS`
  - `TargetStatus`: `ACTIVE`
  - `ConnectionType`: `DataCloud`
  - `TargetType`: `null`
  - `LastPublishStatusDate`: `null`
  - `LastTargetStatusDateTime`: `null`
- Current data stream:
  - `Id`: `1dsdM000000QD9hQAG`
  - `Name`: `datacloud_export_accounts Pulse360_Datab`
  - `DataStreamStatus`: `ACTIVE`
  - `ImportRunStatus`: `SUCCESS`
  - `TotalRowsProcessed`: `13`
  - `LastRefreshDate`: `2026-03-14T07:08:30.000+0000`

## Mapping and Writeback Checks
- `MktDataLakeMapping` rows in org: `0`
- `ActivationTargetPlatform` rows for current target `85UdM00000EGtEzUAL`: `0`
- `ActivationTrgtIntOrgAccess` rows for current target `85UdM00000EGtEzUAL`: `0`
- `ActvTgtPlatformFieldValue` rows in org: `0`
- `Account` rows with any populated values in:
  - `Unified_Profile_Id__c`
  - `Identity_Confidence__c`
  - `Health_Score__c`
  - `Cross_Sell_Propensity__c`
  - `DataCloud_Last_Synced__c`
  - result: `0`

## UI Validation Checks
- Data Cloud mapping UI now shows `15` mapped fields from `datacloud_export_accounts Pulse360_Datab` to Salesforce `Account`.
- The active Account record page is still driven by standard `Record Detail`, so field visibility depends on the assigned Account page layout.
- The Account page layout was updated to include a visible `Pulse360` section containing the expected activation fields.
- In the live Salesforce UI, sampled Account `Globex APAC Pte Ltd` now shows the `Pulse360` section, but the displayed values remain blank.

This removes page layout placement as the primary blocker. The remaining gap is value realization into Salesforce `Account`.

## Mapping Picklist Surface Check
Queried the `MktDataLakeMapping` describe result for the expected Pulse360 source and Salesforce target fields.

Result:
- required Pulse360 source field references were not returned by the org-facing `SourceFieldRef` picklist check
- required Salesforce `Account` target field references were not returned by the org-facing `TargetFieldRef` picklist check

This keeps the repo mapping contract ahead of the currently visible mapping surface, even though the replacement activation target is now marked healthy.

## Commands Used
- `TARGET_ORG=pulse360-dev bash ./scripts/validate-salesforce-account-activation-fields.sh`
- `sf data query --target-org pulse360-dev --query "SELECT Id, MasterLabel, RunStatus, TargetStatus, LastPublishStatusDate, LastPublishStatusErrorMessage, LastTargetStatusDateTime, LastTargetStatusErrorCode, ConnectionType, TargetType, OwnedByOrg FROM ActivationTarget WHERE MasterLabel = 'Pulse360 Salesforce Account Activation'" --json`
- `sf data query --target-org pulse360-dev --query "SELECT Id, MasterLabel, RunStatus, TargetStatus, LastTargetStatusErrorCode, ConnectionType, TargetType, CreatedDate FROM ActivationTarget ORDER BY CreatedDate DESC LIMIT 20" --json`
- `sf data query --target-org pulse360-dev --query "SELECT Id, MasterLabel, RunStatus, TargetStatus, ConnectionType, TargetType, LastPublishStatusDate, LastTargetStatusDateTime FROM ActivationTarget WHERE Id = '85UdM00000EGtEzUAL'" --json`
- `sf data query --target-org pulse360-dev --query "SELECT Id, Name, DataStreamStatus, ImportRunStatus, TotalRowsProcessed, LastRefreshDate FROM DataStream WHERE Name = 'datacloud_export_accounts Pulse360_Datab'" --json`
- `sf data query --target-org pulse360-dev --query "SELECT Id FROM MktDataLakeMapping LIMIT 20" --json`
- `sf data query --target-org pulse360-dev --query "SELECT Id, Name, ActivationTargetId, AccountNumber, ManagerAccountNumber, Connection FROM ActivationTargetPlatform WHERE ActivationTargetId = '85UdM00000EGtEzUAL'" --json`
- `sf data query --target-org pulse360-dev --query "SELECT Id, ActivationTargetId, DataChangeStatus, LastDataChangeStatusDateTime, LastDataChangeStatusErrorCode FROM ActivationTrgtIntOrgAccess WHERE ActivationTargetId = '85UdM00000EGtEzUAL'" --json`
- `sf data query --target-org pulse360-dev --query "SELECT Id, ActivationTargetPlatformId, OverridenValue FROM ActvTgtPlatformFieldValue LIMIT 20" --json`
- `sf data query --target-org pulse360-dev --query "SELECT Id, Name, Unified_Profile_Id__c, Identity_Confidence__c, Health_Score__c, Cross_Sell_Propensity__c, DataCloud_Last_Synced__c FROM Account WHERE Unified_Profile_Id__c != null OR Identity_Confidence__c != null OR Health_Score__c != null OR Cross_Sell_Propensity__c != null OR DataCloud_Last_Synced__c != null LIMIT 20" --json`
- `sf sobject describe --target-org pulse360-dev --sobject MktDataLakeMapping --json`

## Current Assessment
- The repo-side implementation for `DAN-114` remains intact.
- The org is no longer in the exact March 14 failure shape because the original failed target appears to have been replaced with a new target that reports `ACTIVE/SUCCESS`.
- The Data Cloud UI now proves that non-zero mapping configuration exists, and the Salesforce UI now proves the target fields are visible on the Account page.
- Despite that improvement, neither the org-facing API nor the sampled live Account record shows actual activated values yet.
- `DAN-114` should remain open until the Data Cloud UI or a deeper platform-native validation proves:
  - successful writeback into sample Salesforce `Account` records
  - repeatable end-to-end value flow from Databricks export to Salesforce Account field population

## Recommended Next Step
- Treat the remaining work as activation realization troubleshooting rather than metadata deployment.
- Next validation pass should focus on why values are not landing in `Account`:
  - confirm the activation target run history is healthy for the current mapping
  - verify the mapped source rows contain non-null values for the exported Pulse360 fields
  - verify the match key resolves to the intended Salesforce `Account.Id`
  - identify whether the activation run is skipping rows, matching zero Accounts, or writing nulls through
- Once at least one Account shows populated Pulse360 values in the live UI, update `DAN-114`, `DAN-61`, and `DAN-103` with the successful screenshot and move toward closeout.
