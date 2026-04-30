# DAN-221 Copy Field Enrichment Runtime Validation - 2026-04-29

## Scope

Validate and execute the remaining `DAN-221` runtime gate for the public
regional GPT / provenance Account fields in `pulse360-agent-target`.

This run included reviewed target-org setup changes required to prove Data
Cloud Copy Field Enrichment activation:

- Data Cloud data-space access assignment for the operator user.
- Copy Field Enrichment creation for `ssot__Account__dlm -> Account`.
- Integration permission set field and object permission repair.
- Runtime activation / sync start.

## Linear Context

- `DAN-114` remains `In Progress`.
- `DAN-220` is `Done`; the source object and Account DMO mapping gap is no
  longer the practical blocker.
- `DAN-221` remains `In Progress`; a post-refresh job did materialize, but it
  exposed duplicate/null Account DMO rows and required CRM repair.

## Repo And Live Validation

Command:

```bash
./scripts/validate-data-layer-closeout.sh
```

Result:

```text
[PASS] Pulse360 data layer closeout validation completed
```

Important live results from the validation:

- Databricks runtime check passed.
- `pulse360_s4.silver_salesforce.crm_account` returned `18` rows.
- `pulse360_s4.intelligence.datacloud_export_accounts` returned `18` rows.
- `pulse360_s4.intelligence.datacloud_activation_review_queue` returned `11`
  rows.
- Account DMO extension check reported `19/19` required attributes present.
- Data Cloud field-path check for `DC Export Accounts P360 V2` reported:
  - source missing fields: `0`
  - DMO missing mappings: `0`
  - DMO missing target fields: `0`
  - Account sync missing mappings: `0`
  - Account missing target fields: `0`

## Salesforce Account Sample

Read-only SOQL against `pulse360-agent-target` confirmed populated Account
intelligence fields on these sample Accounts before Copy Field Enrichment
activation:

| Account | Id | Observed populated fields |
| --- | --- | --- |
| Singtel Group | `001dL000024xl9FQAQ` | `Intent_Signal_Payload__c`, `AI_Narrative__c`, `AI_Model_Id__c`, `AI_Source_Refs__c` |
| NCS Pte. Ltd. | `001dL000024xlArQAI` | `Intent_Signal_Payload__c`, `AI_Model_Id__c` |
| Ayala Corporation | `001dL000024wgYRQAY` | `Intent_Signal_Payload__c`, `AI_Narrative__c`, `AI_Model_Id__c`, `AI_Source_Refs__c` |
| Ayala Corp. | `001dL000024weudQAA` | `Intent_Signal_Payload__c`, `AI_Narrative__c`, `AI_Model_Id__c`, `AI_Source_Refs__c` |
| JG Summit Holdings, Inc. | `001dL000024xj2cQAA` | `Intent_Signal_Payload__c`, `AI_Narrative__c`, `AI_Model_Id__c`, `AI_Source_Refs__c` |

The sampled records returned `LastModifiedBy.Name = Daniel Nortje`, so this
sample proves CRM field population but does not by itself prove Copy Field
Enrichment runtime provenance.

## Data Cloud DMO UI Evidence

The Data Model UI for `Account / ssot__Account__dlm` showed:

- object status: `Ready`
- mapped data streams: `2`
- mapped data lake objects: `2`
- mapped data streams included:
  - `DC Export Accounts P360 Fix`
  - `DC Export Accounts P360 V2`
- mapped data lake objects included:
  - `DC Export Accounts P360 Fix`
  - `Pulse360 Account Intelligence Export V2`

Filtered field evidence showed:

- `AI_Model_ID__c` present as `Text` with `Is Mapped = True`
- `AI_Source_Refs__c` present as `Text` with `Is Mapped = True`
- earlier full-grid evidence also showed mapped custom Account DMO fields such
  as `Unified_Profile_Id__c` and `Validity_Score_External__c`

Screenshots:

- `output/playwright/dan-221-account-dmo-details.png`
- `output/playwright/dan-221-account-dmo-ai-model-mapped.png`
- `output/playwright/dan-221-account-dmo-ai-source-refs-mapped.png`

## Copy Field Enrichment Creation

Setup search metadata identified the Copy Field Enrichment setup page:

```text
Title: Copy Field
PageUrl: /lightning/setup/CopyFieldEnrichment/home
ApiName: PlatformTools.Integrations.DataCloudEnrichments.CopyFieldEnrichment
Path: Platform Tools > Integrations > Enrichments > Copy Field
```

The initial Copy Field setup page loaded successfully in
`pulse360-agent-target` and showed `0 Items`. CLI checks aligned with the UI:

```sql
SELECT Id, Name, ActionApiName, ActionStatus, LastActionStatusDateTime,
LastActionStatusErrorCode, ManagedBy, LastModifiedDate
FROM DataAction
ORDER BY LastModifiedDate DESC
LIMIT 20
```

Result:

```text
totalSize = 0
```

```sql
SELECT Id, Name, DataActionDefinitionId, ProcessName, ExternalRequestName,
UpdatedRecordCount, ProcessedRecordCount, FailedRecordCount, SkippedRecords,
JobType, JobStatus, StartExecutionTime, EndExecutionTime, PublishDateTime
FROM DataActionJobSummary
ORDER BY StartExecutionTime DESC
LIMIT 20
```

Result:

```text
totalSize = 0
```

The first create attempt exposed a data-space permission blocker. The current
user already had `GenieAdmin` / `Data Cloud Architect`, but the Copy Field
wizard still could not access the default data space. Assigning
`DataCloudActManager` / `Data Cloud Activation Manager` resolved the blocker:

| Artifact | Value |
| --- | --- |
| User Id | `005dL00001kPRA6QAO` |
| Permission Set | `DataCloudActManager` |
| Permission Set Id | `0PSdL00000ViMSnWAN` |
| Assignment Id | `0PadL00000hUQp8SAG` |

Salesforce Help notes that enhanced data-space security associates the default
data space with standard Data Cloud permission sets except Data Cloud
Architect, which explains why `GenieAdmin` alone was not sufficient:
https://help.salesforce.com/s/articleView?id=sf.c360_a_enrich_your_org_with_data_and_insights.htm

Copy Field Enrichment created:

| Attribute | Value |
| --- | --- |
| Label | `Pulse360 Account Intelligence Copy Fields` |
| Initial API name | `Pulse360_Account_Intelligence_Copy_Fields` |
| Setup record path | `/lightning/setup/CopyFieldEnrichment/1AidL00000J12bC/view` |
| Source data space | `default` |
| Source DMO | `Account` / `ssot__Account__dlm` |
| Target object | `Account` |

## Supported Field Mapping

The wizard accepted `28` supported mappings from the
`config/data-cloud/activation-field-mapping.csv` source contract.

| Source DMO field | Target Account field |
| --- | --- |
| `AI_Citation_Count__c` | `AI_Citation_Count__c` |
| `Validity_Score_External__c` | `Validity_Score_External__c` |
| `Externally_Validated__c` | `Externally_Validated__c` |
| `CRM_Covered_Subsidiary_Count__c` | `CRM_Covered_Subsidiary_Count__c` |
| `Coverage_Gap_Flag__c` | `Coverage_Gap_Flag__c` |
| `AI_Model_ID__c` | `AI_Model_Id__c` |
| `Identity_Confidence__c` | `Identity_Confidence__c` |
| `External_Subsidiaries_Found__c` | `External_Subsidiaries_Found__c` |
| `Open_Opportunity_Count__c` | `Open_Opportunity_Count__c` |
| `Health_Score__c` | `Health_Score__c` |
| `AI_Narrative_Generated__c` | `AI_Narrative_Generated__c` |
| `Group_Known_Subsidiary_Count__c` | `Group_Known_Subsidiary_Count__c` |
| `Active_Product_Count__c` | `Active_Product_Count__c` |
| `Competitor_Risk_Signal__c` | `Competitor_Risk_Signal__c` |
| `Unified_Profile_Id__c` | `Unified_Profile_Id__c` |
| `Last_Synced_Timestamp__c` | `DataCloud_Last_Synced__c` |
| `Duplicate_Exposure_Count__c` | `Duplicate_Exposure_Count__c` |
| `Last_Engagement_Timestamp__c` | `Last_Engagement_Timestamp__c` |
| `External_Registration_Number__c` | `External_Registration_Number__c` |
| `Enrichment_Run_ID__c` | `Enrichment_Run_Id__c` |
| `Cross_Sell_Propensity__c` | `Cross_Sell_Propensity__c` |
| `Regulatory_Readiness_Score__c` | `Regulatory_Readiness_Score__c` |
| `Engagement_Intensity_Score__c` | `Engagement_Intensity_Score__c` |
| `Primary_Brand_Name__c` | `Primary_Brand_Name__c` |
| `AI_Prompt_Version__c` | `AI_Prompt_Version__c` |
| `Group_Revenue_Visible__c` | `Group_Revenue_Visible__c` |
| `External_Revenue_Confirmed__c` | `External_Revenue_Confirmed__c` |
| `External_Legal_Name__c` | `External_Legal_Name__c` |

Screenshot:

- `output/playwright/dan-221-copy-field-28-mapped-before-sync.png`

## Unsupported Field Gap

Six contract fields could not be included in the active Copy Field Enrichment
because the wizard did not offer compatible Account targets:

| Source field | Target field | Observed blocker |
| --- | --- | --- |
| `Intent_Signal_Payload__c` | `Intent_Signal_Payload__c` | Long Text target not offered |
| `AI_Recommended_Actions__c` | `AI_Recommended_Actions__c` | Long Text target not offered |
| `AI_Source_Refs__c` | `AI_Source_Refs__c` | Long Text target not offered |
| `AI_Narrative__c` | `AI_Narrative__c` | Long Text target not offered |
| `Hierarchy_Payload__c` | `Hierarchy_Payload__c` | Long Text target not offered |
| `Group_Revenue_Rollup__c` | `Group_Revenue_Rollup__c` | Target Currency field not offered for source Number |

This means native Copy Field Enrichment currently proves the supported
structured field set but does not satisfy the full 34-field CSV activation
contract. The six incompatible fields require an alternate activation path,
schema adjustment, or runbook-managed exception.

## Integration Permission Repair

The first `Start Sync` attempt exposed the platform permission modal:

```text
Incorrect permissions detected.
```

The linked integration permission set was:

| Attribute | Value |
| --- | --- |
| Label | `Customer 360 Data Platform Integration` |
| Name | `sfdc_a360` |
| Id | `0PSdL00000ViMKlWAN` |
| Type | `Session` |
| License | `Cloud Integration User` |

The permission set already had Account `Read` and `Edit`. It was repaired with:

- Account `Delete`
- Account `View All Records`
- Account `Modify All Records`
- read/edit field permissions for all 28 mapped target Account fields

Post-repair SOQL returned `29` Account `FieldPermissions` rows for
`sfdc_a360`: the existing `Account.AccountNumber` row plus the 28 mapped
target fields.

## Activation Evidence

After permission repair, the Copy Field Enrichment activation modal allowed
sync to start. Salesforce displayed this success toast:

```text
Enrichment Pulse360 Account Intelligence Copy Fields was activated and data sync started.
```

Screenshot:

- `output/playwright/dan-221-copy-field-sync-started.png`

Backend verification:

```sql
SELECT Id, Name, ActionApiName, ActionStatus, LastActionStatusErrorCode,
LastActionStatusDateTime, DataSpaceId, ManagedBy
FROM DataAction
ORDER BY LastActionStatusDateTime DESC
LIMIT 5
```

Result:

| Field | Value |
| --- | --- |
| `Id` | `3o9dL0000000IL7QAM` |
| `Name` | `Pulse360_Account_Intelligence_Copy_Fields_20xo47` |
| `ActionApiName` | `Pulse360_Account_Intelligence_Copy_Fields_20xo47` |
| `ActionStatus` | `ACTIVE` |
| `LastActionStatusErrorCode` | `null` |
| `LastActionStatusDateTime` | `2026-04-29T07:37:38.000+0000` |
| `DataSpaceId` | `0vhdL000000UlHdQAK` |
| `ManagedBy` | `DATA_CLOUD_USER` |

```sql
SELECT Id, Name, TargetApiName, TargetType, TargetStatus,
LastTargetStatusErrorCode, LastTargetStatusDateTime
FROM DataActionTarget
ORDER BY LastTargetStatusDateTime DESC
LIMIT 5
```

Result:

| Field | Value |
| --- | --- |
| `Id` | `9sqdL000000VfdBQAS` |
| `Name` | `Pulse360_Account_Intelligence_Copy_Fields_20xo47` |
| `TargetApiName` | `Pulse360_Account_Intelligence_Copy_Fields_20xo47` |
| `TargetType` | `CORE` |
| `TargetStatus` | `ACTIVE` |
| `LastTargetStatusErrorCode` | `null` |
| `LastTargetStatusDateTime` | `2026-04-29T07:37:37.000+0000` |

`DataActionJobSummary` was polled after activation with the currently described
field set:

```sql
SELECT Id, Name, DataActionDefinitionId, ProcessName, ExternalRequestName,
JobType, JobStatus, ProcessedRecordCount, UpdatedRecordCount,
FailedRecordCount, SkippedRecords, StartExecutionTime, EndExecutionTime,
ExecutionDetails
FROM DataActionJobSummary
ORDER BY CreatedDate DESC
LIMIT 10
```

Result:

```text
totalSize = 1
```

| Field | Value |
| --- | --- |
| `Id` | `1A5dL0000001B7tSAE` |
| `Name` | `Pulse360_Account_Intelligence_Copy_Fields_1777448574122` |
| `DataActionDefinitionId` | `3o9dL0000000IL7QAM` |
| `ProcessName` | `Pulse360_Account_Intelligence_Copy_Fields` |
| `ExternalRequestName` | `object_manager_enrichment_ui` |
| `JobType` | `Batch` |
| `JobStatus` | `Partially_Completed` |
| `ProcessedRecordCount` | `47` |
| `UpdatedRecordCount` | `4` |
| `FailedRecordCount` | `43` |
| `SkippedRecords` | `0` |
| `StartExecutionTime` | `2026-04-29T07:42:54.000+0000` |
| `EndExecutionTime` | `2026-04-29T07:43:56.000+0000` |
| `ExecutionDetails` | `750dL00000nebe9QAA` |

The failed-record payload shows the repeated error:

```text
INVALID_CROSS_REFERENCE_KEY:invalid cross reference id:--
```

The sampled failed rows carried source `id` values such as
`001dM00003XSkBRQA1`, while the target org Account records that updated carry
`001dL...` record IDs. This points to a remaining activation-key alignment
problem for 43 rows rather than a Copy Field mapping or permission failure for
the four matching target-org Accounts.

Follow-up source diagnosis:

- live Databricks `pulse360_s4.intelligence.datacloud_export_accounts` returned
  `18` rows, all with target-org `001dL...` Account IDs
- live Databricks `pulse360_s4.silver_salesforce.crm_account` returned `18`
  rows, all with target-org `001dL...` Account IDs
- Data Cloud source object
  `pulse360_account_intelligence_export_v2__dll` returned `43` rows, all with
  stale `001dM...` Account IDs
- Data Cloud `ssot__Account__dlm` returned `47` rows: `4` target-org-safe
  `001dL...` rows and `43` stale `001dM...` rows

This means the current Databricks export is clean. The partial Copy Field run
is caused by stale Data Cloud source/DMO materialization and should be repaired
by refreshing/rebuilding Data Cloud from the current export before another Copy
Field sync is run.

## Data Cloud Refresh Handoff

Follow-up operator work prepared the current Databricks export for the required
Data Cloud file replacement:

| Artifact | Value |
| --- | --- |
| Prepared CSV | `data/exports/datacloud_export_accounts_current_2026-04-29.csv` |
| Generated timestamp | `2026-04-29T11:55:41.580534+00:00` |
| CSV row count | `18` data rows plus header |
| CSV column count | `49` |
| `source_account_id` prefix check | `18/18` rows use target-org `001dL...` Account IDs |

The Salesforce Data Stream UI for `DC Export Accounts P360 V2`
(`1dsdL000000OMyfQAG`) exposes a supported `Update File` action. UI API
inspection identified the action as:

```text
apiName = DataStreamReplaceFileAction
type = ProductivityAction
```

The Data Stream record page showed:

- `Update File`
- `Delete Data Stream`
- `Update Status`
- Data Lake Object Name: `Pulse360 Account Intelligence Export V2`
- Object API Name: `pulse360_account_intelligence_export_v2__dll`
- fields mapped: `7/49`
- status: `READY`

The first `Update File` attempt uploaded the 49-column CSV but failed deploy
because the active V2 Data Stream schema does not contain the newer `run_ts`
field:

```text
Unable to update the data-stream - Field run_ts in datacloud_export_accounts_current_2026-04-29.csv does not exist in data stream
```

A stream-compatible file was then generated from the existing 44-column V2
schema:

```text
data/exports/datacloud_export_accounts_current_2026-04-29-v2-stream.csv
```

It contains `18` data rows plus header, `44` columns, and `18/18`
`source_account_id` values use target-org `001dL...` Account IDs.

The second `Update File` attempt used `Full Refresh` and completed
successfully:

| Data Stream | Id | Last refresh | Total rows processed |
| --- | --- | --- | --- |
| `DC Export Accounts P360 V2` | `1dsdL000000OMyfQAG` | `2026-04-29T12:31:51.000+0000` | `18` |

Backend status after refresh:

```text
DataStreamStatus = ACTIVE
ImportRunStatus = SUCCESS
LastDataChangeStatusDateTime = 2026-04-29T12:31:54.000+0000
LastDataChangeStatusErrorCode = null
LastNumberOfRowsAddedCount = 18
TotalNumberOfRowsAdded = 18
```

Operator safety note: while browser automation was recovering from an
unrelated Salesforce setup tab, the UI appeared to apply `System Administrator`
profile access to `Slack Customer Insights`. That access change is outside
`DAN-221`; it should be reviewed separately and was not reversed in this run.

New validator:

```bash
./scripts/validate-data-cloud-activation-key-alignment.sh
```

Post-refresh result:

```text
[PASS] Data Cloud activation keys resolve to target-org Account records
target_account_total_size = 18
source_object_total_size = 18
source_object_distinct_activation_id_count = 18
source_object_valid_activation_id_count = 18
source_object_missing_activation_id_count = 0
dmo_total_size = 22
dmo_distinct_activation_id_count = 18
dmo_valid_activation_id_count = 18
dmo_missing_activation_id_count = 0
```

Copy Field Enrichment was re-opened after the refresh. The setup page still
showed `Sync active` with Sync Date Time `04/29/2026, 12:42:55 AM`, which is
the earlier partial run. Clicking the visible setup control issued the
Salesforce UI action `ui-vda-components-controller.CopyFieldDetail.activateCopyField`
and temporarily showed `Activation in progress`, but after reload the page
returned to `Sync active` with the same old Sync Date Time.

`DataActionJobSummary` was polled for more than seven minutes after the
activation call. No new job row appeared. Sync History still showed only:

| Job | Sync type | Status | Start time | Records updated | Records excluded |
| --- | --- | --- | --- | --- | --- |
| `1A5dL0000001B7tSAE` | Full | Completed with Exclusions | `2026-04-29T07:42:54.000+0000` | `4` | `43` |

Post-refresh Account sample query for records modified after
`2026-04-29T12:30:00.000+0000` returned zero rows, so the refreshed Data Cloud
materialization has not yet been proven through a new Copy Field writeback job.

Post-run Account sample:

```sql
SELECT Id, Name, LastModifiedDate, LastModifiedBy.Name, AI_Model_Id__c,
AI_Citation_Count__c, External_Legal_Name__c, Primary_Brand_Name__c,
DataCloud_Last_Synced__c
FROM Account
WHERE LastModifiedDate >= 2026-04-29T07:42:54.000+0000
ORDER BY LastModifiedDate DESC
LIMIT 20
```

Result:

| Account | Id | Last modified | Last modified by | Observed values |
| --- | --- | --- | --- | --- |
| Ayala Corp. | `001dL000024weudQAA` | `2026-04-29T07:42:59.000+0000` | Platform Integration User | `AI_Model_Id__c = gpt-5.4`, `AI_Citation_Count__c = 2`, `External_Legal_Name__c = Ayala Corporation`, `Primary_Brand_Name__c = Ayala` |
| Ayala Corporation | `001dL000024wgYRQAY` | `2026-04-29T07:42:59.000+0000` | Platform Integration User | `AI_Model_Id__c = gpt-5.4`, `AI_Citation_Count__c = 2`, `External_Legal_Name__c = Ayala Corporation`, `Primary_Brand_Name__c = Ayala` |
| JG Summit Holdings, Inc. | `001dL000024xj2cQAA` | `2026-04-29T07:42:59.000+0000` | Platform Integration User | `AI_Model_Id__c = gpt-5.4`, `AI_Citation_Count__c = 2`, `External_Legal_Name__c = JG Summit Holdings, Inc.`, `Primary_Brand_Name__c = JG Summit` |
| Singtel Group | `001dL000024xl9FQAQ` | `2026-04-29T07:42:59.000+0000` | Platform Integration User | `AI_Model_Id__c = gpt-5.4`, `AI_Citation_Count__c = 2`, `External_Legal_Name__c = Singapore Telecommunications Limited`, `Primary_Brand_Name__c = Singtel` |

## Post-Refresh Copy Field Run And Repair

The Copy Field Enrichment was stopped and restarted after the Data Stream full
refresh completed. Salesforce displayed the expected setup warnings that
stopping sync requires a future full data sync and that starting sync can
overwrite existing org data.

The new `DataActionJobSummary` row materialized:

| Field | Value |
| --- | --- |
| `Id` | `1A5dL0000001B9VSAU` |
| `Name` | `Pulse360_Account_Intelligence_Copy_Fields_1777468135287` |
| `JobStatus` | `Completed` |
| `ProcessedRecordCount` | `22` |
| `UpdatedRecordCount` | `22` |
| `FailedRecordCount` | `0` |
| `SkippedRecords` | `0` |
| `StartExecutionTime` | `2026-04-29T13:08:55.000+0000` |
| `EndExecutionTime` | `2026-04-29T13:09:57.000+0000` |
| `ExecutionDetails` | `750dL00000nfXLZQA2` |

This is not acceptable closure evidence despite the `Completed` status. A
post-job Account aggregate showed that the 18 modified Accounts had null values
for sampled mapped fields:

```text
total = 18
model_count = 0
legal_count = 0
health_count = 0
```

Sampled fields that were cleared included `AI_Model_Id__c`,
`External_Legal_Name__c`, `Primary_Brand_Name__c`,
`DataCloud_Last_Synced__c`, `Health_Score__c`, and
`Identity_Confidence__c`.

Root-cause evidence points to duplicate/null rows in `ssot__Account__dlm`, not
to the refreshed DLO or CSV. A focused DMO query for five target Accounts
returned nine rows: four enriched rows and five duplicate rows for the same
activation IDs with the mapped intelligence fields set to null. Examples:

| Account Id | DMO field state |
| --- | --- |
| `001dL000024xl9FQAQ` | one row with `AI_Model_ID__c = gpt-5.4`, `External_Legal_Name__c = Singapore Telecommunications Limited`, `Health_Score__c = 88`; one duplicate row with those fields null |
| `001dL000024wgYRQAY` | one row with `AI_Model_ID__c = gpt-5.4`, `External_Legal_Name__c = Ayala Corporation`, `Health_Score__c = 84`; one duplicate row with those fields null |
| `001dL000024weudQAA` | one row with `AI_Model_ID__c = gpt-5.4`, `External_Legal_Name__c = Ayala Corporation`, `Health_Score__c = 84`; one duplicate row with those fields null |
| `001dL000024xj2cQAA` | one row with `AI_Model_ID__c = gpt-5.4`, `External_Legal_Name__c = JG Summit Holdings, Inc.`, `Health_Score__c = 79`; one duplicate row with those fields null |
| `001dL000024xlArQAI` | one row found, with mapped intelligence fields null |

The Data Cloud source object remained correct. A direct query against
`pulse360_account_intelligence_export_v2__dll` returned 18 rows with non-null
values for the corresponding export fields, including `model_id__c`,
`external_legal_name__c`, `primary_brand_name__c`,
`last_synced_timestamp__c`, `health_score__c`, and
`identity_confidence__c`.

Because the Copy Field job cleared CRM fields, the enrichment was stopped
again. Salesforce displayed:

```text
Enrichment Pulse360 Account Intelligence Copy Fields was deactivated and data sync stopped.
```

The setup page then showed:

```text
Sync Status = Sync inactive
Sync Date Time = None
```

A source-backed repair file was generated from the stream-compatible export and
the 28 supported Copy Field mappings:

```text
data/exports/account_copy_field_repair_2026-04-29.csv
```

Unsupported fields were excluded from the repair file:

- `hierarchy_payload`
- `intent_signal_payload`
- `group_revenue_rollup`
- `ai_narrative`
- `ai_recommended_actions`
- `source_refs`

Bulk API repair result:

| Field | Value |
| --- | --- |
| Bulk job Id | `750dL00000nfZlZQAU` |
| Processed records | `18` |
| Successful records | `18` |
| Failed records | `0` |

Post-repair Account aggregate:

```text
total = 18
model_count = 18
legal_count = 18
health_count = 18
synced_count = 18
```

Post-repair sample:

| Account | Id | Last modified | Last modified by | Observed values |
| --- | --- | --- | --- | --- |
| Ayala Corp. | `001dL000024weudQAA` | `2026-04-29T13:25:34.000+0000` | Daniel Nortje | `AI_Model_Id__c = gpt-5.4`, `External_Legal_Name__c = Ayala Corp.`, `Primary_Brand_Name__c = Unassigned Brand`, `Health_Score__c = 35`, `Identity_Confidence__c = 82` |
| Ayala Corporation | `001dL000024wgYRQAY` | `2026-04-29T13:25:34.000+0000` | Daniel Nortje | `AI_Model_Id__c = gpt-5.4`, `External_Legal_Name__c = Ayala Corporation`, `Primary_Brand_Name__c = Unassigned Brand`, `Health_Score__c = 35`, `Identity_Confidence__c = 82` |
| JG Summit Holdings, Inc. | `001dL000024xj2cQAA` | `2026-04-29T13:25:34.000+0000` | Daniel Nortje | `AI_Model_Id__c = gpt-5.4`, `External_Legal_Name__c = JG Summit Holdings, Inc.`, `Primary_Brand_Name__c = Unassigned Brand`, `Health_Score__c = 35`, `Identity_Confidence__c = 82` |
| NCS Pte. Ltd. | `001dL000024xlArQAI` | `2026-04-29T13:25:34.000+0000` | Daniel Nortje | `AI_Model_Id__c = gpt-5.4`, `External_Legal_Name__c = NCS Pte. Ltd.`, `Primary_Brand_Name__c = Unassigned Brand`, `Health_Score__c = 35`, `Identity_Confidence__c = 82` |
| Singtel Group | `001dL000024xl9FQAQ` | `2026-04-29T13:25:34.000+0000` | Daniel Nortje | `AI_Model_Id__c = gpt-5.4`, `External_Legal_Name__c = Singapore Telecommunications Limited`, `Primary_Brand_Name__c = Unassigned Brand`, `Health_Score__c = 35`, `Identity_Confidence__c = 82` |

The activation-key validator initially still passed after repair because it
only checked whether IDs resolved to target-org Account records:

```text
[PASS] Data Cloud activation keys resolve to target-org Account records
source_object_total_size = 18
source_object_valid_activation_id_count = 18
source_object_missing_activation_id_count = 0
dmo_total_size = 22
dmo_distinct_activation_id_count = 18
dmo_valid_activation_id_count = 18
dmo_missing_activation_id_count = 0
```

The guard was then strengthened to fail duplicate activation IDs as a Copy
Field restart blocker. Current result:

```text
[FAIL] Data Cloud direct Account activation contains duplicate activation IDs; Copy Field writeback requires one authoritative source/DMO row per target Account.
source_object_total_size = 18
source_object_distinct_activation_id_count = 18
source_object_duplicate_activation_id_count = 0
source_object_valid_activation_id_count = 18
source_object_missing_activation_id_count = 0
dmo_total_size = 22
dmo_distinct_activation_id_count = 18
dmo_duplicate_activation_id_count = 4
dmo_duplicate_activation_ids_sample = [
  "001dL000024weudQAA",
  "001dL000024wgYRQAY",
  "001dL000024xj2cQAA",
  "001dL000024xl9FQAQ"
]
dmo_valid_activation_id_count = 18
dmo_missing_activation_id_count = 0
```

The failing strengthened guard confirms the current blocker: CRM-safe
activation IDs are present, but the Account DMO does not yet have exactly one
authoritative row per target Account activation ID for this writeback surface.

Follow-up read-only diagnosis confirmed the DMO lineage split:

| DMO source object | Rows | `AI_Model_ID__c` count | `External_Legal_Name__c` count | `Health_Score__c` count | Interpretation |
| --- | ---: | ---: | ---: | ---: | --- |
| `databricks_enrichment_live_2026-04-20.csv` | 18 | 0 | 0 | 0 | Current V2 stream contribution; activation IDs are target-org-safe but mapped intelligence fields are null in the DMO |
| `databricks_enrichment_sample.csv` | 4 | 4 | 4 | 4 | Older Fix/sample contribution; creates the four duplicate IDs with stale but non-null values |

The corresponding Data Lake Object instances are:

| Data Lake Object | Developer name | External name | Last refresh | Records | Fields |
| --- | --- | --- | --- | ---: | ---: |
| Pulse360 Account Intelligence Export V2 | `pulse360_account_intelligence_export_v2` | `pulse360_account_intelligence_export_v2__dll` | `2026-04-29T12:31:51.000+0000` | 18 | 49 |
| DC Export Accounts P360 Fix | `dc_export_accounts_p360_fix` | `dc_export_accounts_p360_fix__dll` | `2026-04-18T14:25:10.000+0000` | 4 | 48 |

Direct DLO queries showed both DLOs contain non-null source values for their
own rows. The failure is therefore not in the uploaded V2 CSV or Databricks
export. The current V2 DLO values are not being materialized into the Account
DMO extension fields for the direct Copy Field surface.

The validator was further hardened to require populated required supported
writeback fields in both the current source object and the Account DMO. Current
result:

```text
[FAIL] Data Cloud direct Account activation contains duplicate activation IDs; Copy Field writeback requires one authoritative source/DMO row per target Account.
source_object_required_supported_field_count = 27
source_object_rows_missing_required_supported_fields_count = 0
dmo_required_supported_field_count = 27
dmo_rows_missing_required_supported_fields_count = 18
```

The DMO null-field samples all point at
`databricks_enrichment_live_2026-04-20.csv` and show 25 missing fields on each
sampled current row. The two required supported fields not missing on those
rows are fields already populated by the base Account mapping rather than the
Pulse360 intelligence extension mapping.

## V2 Mapping Repair And Fix Cleanup Attempt

The `DC Export Accounts P360 V2` mapping canvas was reopened from the Data
Stream record. Before repair, the record page showed:

```text
Fields mapped = 7/49
```

The V2 source-to-Account DMO mappings were repaired in the mapping UI and saved
successfully:

```text
Successfully added mappings.
Fields mapped = 32/49
```

Post-save DMO aggregation showed the V2 rows immediately materialized accepted
extension fields:

```text
source_object = databricks_enrichment_live_2026-04-20.csv
rows = 18
model_count = 18
legal_count = 18
health_count = 18
```

The Data Cloud mapping UI rejected these V2 field pairings because the source
and target data types did not match:

| Source field | Target DMO field | Observed result |
| --- | --- | --- |
| `group_revenue_visible` | `Group_Revenue_Visible__c` | `Cannot map: source and target data types should be same.` |
| `external_revenue_confirmed` | `External_Revenue_Confirmed__c` | `Cannot map: source and target data types should be same.` |

The activation-key validator was updated to treat those two fields as current
Data Cloud source-to-DMO exceptions, alongside the previously documented native
Copy Field exceptions. The current supported required DMO field set is now 25
fields. The validator proves the V2 source object and V2 Account DMO rows are
populated for that supported set:

```text
source_object_required_supported_field_count = 25
source_object_rows_missing_required_supported_fields_count = 0
dmo_required_supported_field_count = 25
dmo_rows_missing_required_supported_fields_count = 0
```

The obsolete `DC Export Accounts P360 Fix` Data Stream was deleted through the
Salesforce API:

```text
DataStream Id = 1dsdL000000OJvxQAG
success = true
```

The surviving V2 stream was then full-refreshed again from:

```text
data/exports/datacloud_export_accounts_current_2026-04-29-v2-stream.csv
```

The refresh completed successfully:

```text
DataStreamStatus = ACTIVE
ImportRunStatus = SUCCESS
LastRefreshDate = 2026-04-29T14:23:19.000+0000
TotalRowsProcessed = 18
LastDataChangeStatusErrorCode = null
```

However, deleting the Data Stream did not remove the old DLO or its existing
DMO contribution. `dc_export_accounts_p360_fix__dll` remains queryable through
`DataLakeObjectInstance`:

```text
DataLakeObjectInstance Id = 1dldL000006t7ztQAA
Name = DC Export Accounts P360 Fix
ExternalName = dc_export_accounts_p360_fix__dll
DataLakeObjectStatus = ACTIVE
SyncStatus = ACTIVE
TotalRecords = 4
```

Direct DLO deletion was blocked by Salesforce:

```text
To delete the Data Lake Object, remove the mappings first.
```

The Fix DLO mapping page still shows:

```text
Fields mapped = 38/48
Is Mapped = 34
```

The page-level `Remove Mappings` action opened a broader `Delete "Account"?`
dependency dialog. That dialog listed both `DC Export Accounts P360 Fix` and
`Pulse360 Account Intelligence Export V2` as Data Lake Object dependencies, so
the broad confirmation was not executed. Removing those mappings without a more
targeted DLO-only action risks disrupting the repaired V2 Account DMO mapping.

Current validation posture:

```text
[FAIL] Data Cloud direct Account activation contains duplicate activation IDs; Copy Field writeback requires one authoritative source/DMO row per target Account.
source_object_total_size = 18
source_object_distinct_activation_id_count = 18
source_object_duplicate_activation_id_count = 0
dmo_total_size = 22
dmo_distinct_activation_id_count = 18
dmo_duplicate_activation_id_count = 4
dmo_rows_missing_required_supported_fields_count = 0
```

The remaining blocker is narrow: the old Fix DLO mapping still contributes four
stale DMO rows even though the old Data Stream record has been deleted. Copy
Field Enrichment must remain stopped until that DLO mapping is removed through
a targeted Data Cloud cleanup path.

`./scripts/validate-data-layer-closeout.sh` runs cleanly through the
Databricks, DMO extension, and field-path gates, then fails intentionally at
`Data Cloud activation key alignment` with the duplicate DMO evidence above.
This is the expected closeout posture until the old Fix DLO mapping is removed.

## Decision

`DAN-221` should remain open, but its blocker has moved.

Proven:

- Account DMO and source export contracts are healthy.
- The operator now has the Data Cloud Activation Manager permission set needed
  to operate Copy Field Enrichment in the default data space.
- Native Copy Field Enrichment was created for `ssot__Account__dlm -> Account`.
- The supported field set is mapped `28/28`.
- The integration permission set was repaired for Account object access and
  mapped-field FLS.
- The initial Copy Field batch ran as `Partially_Completed`.
- Four target-org Accounts were updated by `Platform Integration User` in the
  initial batch.
- Data Cloud was refreshed from a target-org-safe 18-row file.
- A post-refresh Copy Field batch materialized and completed with
  `22` processed, `22` updated, and `0` failures.
- The post-refresh batch cleared mapped CRM fields because the Account DMO
  still contains duplicate/null rows for activation-safe Account IDs.
- Copy Field sync is now stopped again.
- The 18 affected Account records were repaired from
  `data/exports/account_copy_field_repair_2026-04-29.csv`.
- The V2 source-to-DMO mappings were repaired and saved; V2 DMO rows now
  contain the supported required field set.
- The obsolete Fix Data Stream was deleted, but its Data Lake Object and DMO
  contribution remain until the old DLO mapping is removed.

Remaining:

- Remove or supersede duplicate/null rows in `ssot__Account__dlm` so the direct
  Account writeback path has exactly one authoritative DMO row per target
  Account activation ID.
- Remove the obsolete `DC Export Accounts P360 Fix` DLO mapping without
  disrupting the repaired V2 DLO mapping.
- Decide how to handle the native Copy Field and Data Cloud type-compatibility
  exceptions that cannot map in the current schema.

## Recommended Next Step

Treat `DAN-221` as proven for Data Cloud refresh, activation-key alignment, and
the ability to trigger a native Copy Field job. Keep it open because the latest
job proved that DMO row uniqueness is now the runtime blocker.

Do not restart Copy Field Enrichment until the Account DMO duplicate/null row
condition is fixed. The next rerun should require:

- `./scripts/validate-data-cloud-activation-key-alignment.sh` passes
- `ssot__Account__dlm` row count equals the 18 distinct activation-safe Account
  IDs for this export
- `JobStatus = Completed`
- `FailedRecordCount = 0`
- expected processed and updated counts for the activation-safe row set
- post-run Salesforce Account samples retain non-null mapped intelligence
  values and are modified by `Platform Integration User`

In parallel, open a design decision for the incompatible fields:

- keep them populated by the existing CRM-side process and document them as a
  Copy Field exception
- change source/target field types to a Copy Field-compatible shape
- implement a separate runbook-driven or API-backed activation path
- align `Group_Revenue_Visible__c` and
  `External_Revenue_Confirmed__c` source-to-DMO data types before treating them
  as Data Cloud DMO-backed Copy Field values

## Final DLO Cleanup And Successful Copy Field Rerun

The old Fix DLO cleanup was completed through a targeted metadata path rather
than the broad mapping-page `Remove Mappings` action.

Targeted per-field mapping removal on the old Fix mapping page reduced the old
mapping canvas to `No objects selected`. Direct DLO deletion still failed until
the remaining unmanaged old Fix-to-Account `ObjectSourceTargetMap` was removed:

```text
ObjectSourceTargetMap:dc_export_accounts_p360_fix_map_Account_1776484304584
delete result = Succeeded
```

After that targeted metadata delete, the obsolete DLO was deleted successfully:

```text
DataLakeObjectInstance Id = 1dldL000006t7ztQAA
delete result = success
```

Only the repaired V2 DLO remains for this path:

```text
Name = Pulse360 Account Intelligence Export V2
DeveloperName = pulse360_account_intelligence_export_v2
DataLakeObjectStatus = ACTIVE
SyncStatus = ACTIVE
TotalRecords = 18
```

Activation-key validation then passed:

```text
source_object_total_size = 18
source_object_distinct_activation_id_count = 18
source_object_duplicate_activation_id_count = 0
dmo_total_size = 18
dmo_distinct_activation_id_count = 18
dmo_duplicate_activation_id_count = 0
source_object_rows_missing_required_supported_fields_count = 0
dmo_rows_missing_required_supported_fields_count = 0
```

`./scripts/validate-data-layer-closeout.sh` also completed successfully after
the runtime DMO required-field set was aligned with the fields the org exposes.
The six unsupported Account DMO fields remain documented as optional org-locked
exceptions:

- `AI_Narrative__c`
- `AI_Recommended_Actions__c`
- `AI_Source_Refs__c`
- `External_Revenue_Confirmed__c`
- `Group_Revenue_Visible__c`
- `Hierarchy_Payload__c`

Before restarting Copy Field, the enrichment definition still included two
stale mappings for fields the V2 DMO no longer exposes:

- `Group_Revenue_Visible__c`
- `External_Revenue_Confirmed__c`

Those two mappings were cleared and their rows deleted in the Copy Field editor.
The definition changed from:

```text
28 Fields * 28 Mapped
```

to:

```text
26 Fields * 26 Mapped
```

The enrichment was then saved and restarted. Salesforce showed:

```text
Enrichment Pulse360 Account Intelligence Copy Fields was activated and data sync started.
```

Backend evidence:

```text
DataAction Id = 3o9dL0000000IL7QAM
ActionStatus = ACTIVE
LastActionStatusDateTime = 2026-04-29T22:38:49.000+0000
```

The new Copy Field job completed successfully:

```text
DataActionJobSummary Id = 1A5dL0000001BFxSAM
Name = Pulse360_Account_Intelligence_Copy_Fields_1777502386443
JobStatus = Completed
ProcessedRecordCount = 18
UpdatedRecordCount = 18
FailedRecordCount = 0
SkippedRecords = 0
StartExecutionTime = 2026-04-29T22:39:46.000+0000
EndExecutionTime = 2026-04-29T22:40:48.000+0000
```

Post-run Account aggregate for records modified by the job:

```text
total = 18
model_count = 18
legal_count = 18
health_count = 18
synced_count = 18
```

Representative Account samples were modified by `Platform Integration User` at
`2026-04-29T22:39:52.000+0000` and retained non-null mapped intelligence values
for `AI_Model_Id__c`, `External_Legal_Name__c`, `Health_Score__c`, and
`DataCloud_Last_Synced__c`.

Final decision: the direct Account Copy Field path is now proven for the 26
native-compatible mappings. The remaining unsupported payload and revenue
fields are documented exceptions until their Data Cloud/CRM field types are
reshaped or covered by a separate activation path.
