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
- Confirmed the activation path still does not show completed mapping/writeback evidence through the org-facing API:
  - `MktDataLakeMapping` rows: `0`
  - `ActivationTargetPlatform` rows for `85UdM00000EGtEzUAL`: `0`
  - `ActivationTrgtIntOrgAccess` rows for `85UdM00000EGtEzUAL`: `0`
  - `ActvTgtPlatformFieldValue` rows: `0`
  - sample `Account` query with populated Pulse360 activation fields: `0` rows

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
- Despite that improvement, the API-visible evidence still does not show completed mapping configuration or Account writeback.
- `DAN-114` should remain open until the Data Cloud UI or a deeper platform-native validation proves:
  - non-zero mapping configuration
  - a valid match-key setup
  - successful writeback into sample Salesforce `Account` records

## Recommended Next Step
- Validate the replacement target directly in the Data Cloud UI:
  - confirm the match key is `source_account_id -> Account.Id`
  - confirm the mapping page shows non-zero field mappings
  - confirm the publish state is healthy
  - capture a screenshot of at least one `Account` record with populated Pulse360 activation fields
- If the UI confirms mapping exists while the public API still shows zero rows, treat the remaining gap as an observability/documentation issue rather than a setup blocker and attach UI evidence to `DAN-114`, `DAN-61`, and `DAN-103`.
