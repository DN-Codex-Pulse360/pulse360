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
- Confirmed through live Databricks SQL that the upstream CRM ingest and gold base view are current for `Globex APAC Pte Ltd`, but the materialized Data Cloud export table is stale:
  - `pulse360_s4.silver_salesforce.crm_account` contains `Globex APAC Pte Ltd` rows including sampled Salesforce ID `001dM00003aUn53QAC`
  - `pulse360_s4.gold.account_export_base` returns current Globex enrichment rows with non-null values and `run_id = run_20260326_063859`
  - `pulse360_s4.intelligence.datacloud_export_accounts` returns `0` rows for `Globex APAC Pte Ltd` and only exposes a stale `run_id = run_20260310_111329` snapshot

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

## Databricks Runtime Validation
- Unity Catalog confirms both live objects exist:
  - `pulse360_s4.gold.account_export_base` (view)
  - `pulse360_s4.intelligence.datacloud_export_accounts` (managed Delta table)
- The live materialized export table currently reflects an older snapshot:
  - sample export rows show `last_synced_timestamp = 2026-03-10T11:13:29.706Z`
  - sample export rows show `run_id = run_20260310_111329`
  - sampled names are the original developer-edition seed accounts such as `Burlington Textiles Corp of America`, `United Oil & Gas Corp.`, and `GenePoint`
- The current upstream base view is newer and includes the expected seeded Globex rows:
  - sampled rows show `source_account_id = 001dM00003aUn53QAC`
  - `account_name = Globex APAC Pte Ltd`
  - `unified_profile_id = ucp_001dM00003aUn53QAC`
  - `identity_confidence = 90`
  - `health_score = 35.0`
  - `cross_sell_propensity = 25.0`
  - `coverage_gap_flag = true`
  - `competitor_risk_signal = 18.0`
  - `last_synced_timestamp = 2026-03-26T06:38:59.859Z`
  - `run_id = run_20260326_063859`

This shows the end-to-end issue is not enrichment logic quality. The stale `pulse360_s4.intelligence.datacloud_export_accounts` table is the most likely blocker preventing Data Cloud from activating current values into Salesforce.

## Databricks Export Rebuild - 2026-03-27
- Executed the repo-backed rebuild statement from `sql/databricks/gold/30_datacloud_export_accounts.sql`.
- Rebuild statement status: `SUCCEEDED`
- Post-rebuild verification confirms `pulse360_s4.intelligence.datacloud_export_accounts` now contains the current Globex rows, including sampled Salesforce ID `001dM00003aUn53QAC`.
- Verified refreshed export values for sampled Globex row:
  - `unified_profile_id = ucp_001dM00003aUn53QAC`
  - `identity_confidence = 90.0`
  - `group_revenue_rollup = 0.0`
  - `health_score = 35.0`
  - `cross_sell_propensity = 25.0`
  - `coverage_gap_flag = true`
  - `competitor_risk_signal = 18.0`
  - `last_synced_timestamp = 2026-03-27T00:51:38.057Z`
  - `run_id = run_20260327_005138`

This closes the Databricks-side stale export blocker.

## Downstream Status After Rebuild
- Data Cloud stream `datacloud_export_accounts Pulse360_Datab` remains:
  - `DataStreamStatus = ACTIVE`
  - `ImportRunStatus = SUCCESS`
  - `TotalRowsProcessed = 0`
  - `LastRefreshDate = 2026-03-26T03:40:44.000+0000`
- Activation target `Pulse360 Salesforce Account Activation v2` remains:
  - `RunStatus = SUCCESS`
  - `TargetStatus = ACTIVE`
  - `LastPublishStatusDate = null`
  - `LastTargetStatusDateTime = null`

The Databricks export is now current, but the downstream Data Cloud stream/activation path has not yet ingested this refreshed snapshot.

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
- `databricks unity-catalog tables get --full-name pulse360_s4.intelligence.datacloud_export_accounts`
- `databricks unity-catalog tables get --full-name pulse360_s4.gold.account_export_base`
- Databricks SQL API query against `pulse360_s4.intelligence.datacloud_export_accounts` for `Globex APAC Pte Ltd` / `001dM00003aUn53QAC`
- Databricks SQL API query against `pulse360_s4.intelligence.datacloud_export_accounts` ordered by `last_synced_timestamp DESC`
- Databricks SQL API query against `pulse360_s4.silver_salesforce.crm_account` for `Globex APAC Pte Ltd` / `001dM00003aUn53QAC`
- Databricks SQL API query against `pulse360_s4.gold.account_export_base` for `Globex APAC Pte Ltd` / `001dM00003aUn53QAC`
- Databricks SQL API execution of `sql/databricks/gold/30_datacloud_export_accounts.sql`
- Databricks SQL API post-rebuild query against `pulse360_s4.intelligence.datacloud_export_accounts` for `Globex APAC Pte Ltd` / `001dM00003aUn53QAC`
- `sf data query --target-org pulse360-dev --query "SELECT Id, Name, DataStreamStatus, ImportRunStatus, TotalRowsProcessed, LastRefreshDate FROM DataStream WHERE Name = 'datacloud_export_accounts Pulse360_Datab'" --json`
- `sf data query --target-org pulse360-dev --query "SELECT Id, MasterLabel, RunStatus, TargetStatus, LastPublishStatusDate, LastTargetStatusDateTime FROM ActivationTarget WHERE MasterLabel LIKE 'Pulse360 Salesforce Account Activation%'" --json`

## Current Assessment
- The repo-side implementation for `DAN-114` remains intact.
- The org is no longer in the exact March 14 failure shape because the original failed target appears to have been replaced with a new target that reports `ACTIVE/SUCCESS`.
- The Data Cloud UI now proves that non-zero mapping configuration exists, and the Salesforce UI now proves the target fields are visible on the Account page.
- Despite that improvement, neither the org-facing API nor the sampled live Account record shows actual activated values yet.
- The stale Databricks export-table blocker has now been fixed. The live handoff table contains the current Globex rows and enrichment values.
- The remaining blocker has moved downstream: Data Cloud has not yet refreshed from the rebuilt export snapshot, so Salesforce still does not show realized values.
- `DAN-114` should remain open until the Data Cloud UI or a deeper platform-native validation proves:
  - successful writeback into sample Salesforce `Account` records
  - repeatable end-to-end value flow from Databricks export to Salesforce Account field population

## Recommended Next Step
- Treat the remaining work as a downstream Data Cloud refresh / activation realization step.
- Next execution step should be to refresh the Data Cloud stream and/or activation target so the rebuilt `pulse360_s4.intelligence.datacloud_export_accounts` snapshot is ingested.
- After that refresh:
  - confirm the Data Cloud stream `LastRefreshDate` advances past the rebuild timestamp
  - confirm processed rows are non-zero for the refreshed snapshot
  - re-check sampled Salesforce Account `001dM00003aUn53QAC` for populated Pulse360 values
- Once at least one Account shows populated Pulse360 values in the live UI, update `DAN-114`, `DAN-61`, and `DAN-103` with the successful screenshot and move toward closeout.
