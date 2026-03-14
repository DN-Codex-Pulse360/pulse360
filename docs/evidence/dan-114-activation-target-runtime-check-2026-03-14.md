# DAN-114 Activation Target Runtime Check - 2026-03-14

## Summary
- Re-validated the live `pulse360-dev` Data Cloud activation state after PR `#9` merged.
- Confirmed the Salesforce `Account` activation target fields are not the current blocker.
- Confirmed the existing activation target is stuck before companion setup is materialized.
- Confirmed Data Cloud mapping publish is still incomplete: `MktDataLakeMapping` remains empty and the mapping field-reference picklists still do not expose the Pulse360 activation fields.

## Runtime Snapshot
- Target org: `pulse360-dev`
- Activation target:
  - `Id`: `85UdM00000EC7IbUAL`
  - `MasterLabel`: `Pulse360 Salesforce Account Activation`
  - `ConnectionType`: `SalesforceDotCom`
  - `RunStatus`: `QUEUED`
  - `TargetStatus`: `ERROR`
  - `LastTargetStatusErrorCode`: `CREATE_FAILED`
  - `OwnedByOrg`: `Data Cloud Home (00DdM00000qbFtN)`
- Data stream:
  - `Name`: `datacloud_export_accounts Pulse360_Datab`
  - `DataStreamStatus`: `ACTIVE`
  - `ImportRunStatus`: `SUCCESS`
  - `TotalRowsProcessed`: `0`

## Child Record Checks
- `ActivationTargetPlatform` rows for activation target `85UdM00000EC7IbUAL`: `0`
- `ActivationTrgtIntOrgAccess` rows for activation target `85UdM00000EC7IbUAL`: `0`
- `ActvTgtPlatformFieldValue` rows in org: `0`

These results indicate the activation target never progressed into the platform-specific companion setup that Data Cloud normally relies on for downstream mapping and publish.

## Mapping Checks
- `MktDataLakeMapping` rows in org: `0`
- `MktDataLakeMapping.SourceFieldRef` picklist contains Pulse360 activation fields: `no`
- `MktDataLakeMapping.TargetFieldRef` picklist contains Pulse360 activation fields: `no`

This means the repo mapping contract in `config/data-cloud/activation-field-mapping.csv` is still ahead of the org runtime surface. The mapping rows cannot yet be created from the current org state because the required picklist references are not available.

## Commands Used
- `sf data query --target-org pulse360-dev --query "SELECT Id, MasterLabel, RunStatus, TargetStatus, LastPublishStatusDate, LastPublishStatusErrorMessage, LastTargetStatusDateTime, LastTargetStatusErrorCode, ConnectionType, TargetType, OwnedByOrg FROM ActivationTarget WHERE Id = '85UdM00000EC7IbUAL'" --json`
- `sf data query --target-org pulse360-dev --query "SELECT Id, Name, ActivationTargetId, AccountNumber, ManagerAccountNumber, Connection FROM ActivationTargetPlatform WHERE ActivationTargetId = '85UdM00000EC7IbUAL'" --json`
- `sf data query --target-org pulse360-dev --query "SELECT Id, ActivationTargetId, DataChangeStatus, LastDataChangeStatusDateTime, LastDataChangeStatusErrorCode FROM ActivationTrgtIntOrgAccess WHERE ActivationTargetId = '85UdM00000EC7IbUAL'" --json`
- `sf data query --target-org pulse360-dev --query "SELECT Id, ActivationTargetPlatformId, OverridenValue FROM ActvTgtPlatformFieldValue LIMIT 20" --json`
- `sf data query --target-org pulse360-dev --query "SELECT Id FROM MktDataLakeMapping LIMIT 20" --json`
- `sf sobject describe --target-org pulse360-dev --sobject MktDataLakeMapping --json`

## Current Assessment
- `DAN-114` field deployment remains complete.
- `DAN-114` mapping publish remains blocked.
- The blocker now looks like Data Cloud activation-target setup failure, not missing Salesforce source metadata.
- `DAN-61` remains blocked because activation cannot publish mapped values back into `Account`.
- `DAN-103` remains blocked until activation mappings exist and real sample values land on `Account`.

## Recommended Next Step
- Treat this as a Data Cloud runtime/setup issue and complete the missing activation-target configuration through the supported UI or vendor-guided setup path.
- After the target companion records exist, re-check:
  - `ActivationTargetPlatform`
  - `ActivationTrgtIntOrgAccess`
  - `MktDataLakeMapping`
  - activation refresh into `Account`
