# DAN-221 Copy Field Enrichment Runtime Gap Decision - 2026-04-29

## Context

The Data Cloud Copy Field Enrichment `Pulse360 Account Intelligence Copy Fields`
was created and activated in `pulse360-agent-target` for
`ssot__Account__dlm -> Account`.

The runtime batch proved the supported mapping path, but it did not close the
full activation contract:

- `ProcessedRecordCount = 47`
- `UpdatedRecordCount = 4`
- `FailedRecordCount = 43`
- `JobStatus = Partially_Completed`

The four successful rows updated target-org Accounts as `Platform Integration
User`. The failed rows reported:

```text
INVALID_CROSS_REFERENCE_KEY:invalid cross reference id:--
```

Sample failed rows carried source `id` values like `001dM00003XSkBRQA1`, while
successful target-org Accounts use `001dL...` IDs. This indicates that the
export still includes rows whose activation key does not resolve to an Account
record in `pulse360-agent-target`.

Follow-up diagnosis showed the live Databricks export is already target-org
safe:

- `pulse360_s4.intelligence.datacloud_export_accounts` has `18` rows.
- all `18` `source_account_id` values use the target-org `001dL...` Account ID
  prefix.
- `pulse360_s4.silver_salesforce.crm_account` also has `18` target-org Account
  rows.

The remaining drift is in Data Cloud materialization:

- Data Stream `DC Export Accounts P360 V2` last refreshed on
  `2026-04-20T06:29:34.000+0000` with `43` processed rows.
- Data Stream `DC Export Accounts P360 Fix` last refreshed on
  `2026-04-18T14:25:10.000+0000` with `4` processed rows.
- source object `pulse360_account_intelligence_export_v2__dll` currently
  exposes `43` stale `001dM...` activation IDs.
- `ssot__Account__dlm` currently exposes `47` Account IDs: `4` target-org-safe
  `001dL...` rows and `43` stale `001dM...` rows.

## Decision

Do not treat Copy Field Enrichment as the filter for activation eligibility.

The Databricks-to-Data Cloud export must only send rows to the Account Copy
Field path when the row has a target-org-safe Account activation ID. Rows with
missing, ambiguous, external-org, or non-resolvable CRM IDs should be routed to
the activation review queue instead of the direct Account writeback path.

Because the live Databricks export is already clean, the next runtime action is
to refresh/rebuild the Data Cloud source-object materialization from the current
18-row Databricks export, then rerun Copy Field Enrichment. Do not rerun Copy
Field against the current 47-row DMO state.

## Refresh Execution Status

The current export file was generated for the Data Cloud replacement step:

```text
data/exports/datacloud_export_accounts_current_2026-04-29.csv
```

It contains `18` data rows, `49` columns, and `18/18` `source_account_id`
values use the target-org `001dL...` Account ID prefix.

The first Data Stream `Update File` attempt accepted the upload but failed
deployment because the active V2 stream schema is still the older 44-column
shape and does not contain `run_ts`:

```text
Unable to update the data-stream - Field run_ts in datacloud_export_accounts_current_2026-04-29.csv does not exist in data stream
```

A stream-compatible file was generated from the existing V2 schema:

```text
data/exports/datacloud_export_accounts_current_2026-04-29-v2-stream.csv
```

It contains `18` data rows plus header, `44` columns, and `18/18`
`source_account_id` values use the target-org `001dL...` Account ID prefix.

The target Data Stream is:

| Attribute | Value |
| --- | --- |
| Data Stream | `DC Export Accounts P360 V2` |
| Data Stream Id | `1dsdL000000OMyfQAG` |
| DLO API Name | `pulse360_account_intelligence_export_v2__dll` |
| Supported UI action | `DataStreamReplaceFileAction` / `Update File` |

The second upload used `Full Refresh` through `Update File` and completed:

```text
DataStreamStatus = ACTIVE
ImportRunStatus = SUCCESS
LastRefreshDate = 2026-04-29T12:31:51.000+0000
LastDataChangeStatusDateTime = 2026-04-29T12:31:54.000+0000
TotalRowsProcessed = 18
LastNumberOfRowsAddedCount = 18
```

The activation-key validator now passes:

```text
[PASS] Data Cloud activation keys resolve to target-org Account records
source_object_total_size = 18
source_object_valid_activation_id_count = 18
source_object_missing_activation_id_count = 0
dmo_total_size = 22
dmo_valid_activation_id_count = 18
dmo_missing_activation_id_count = 0
```

Copy Field Enrichment was then stopped and restarted to force a fresh full
sync. A new post-refresh job materialized:

```text
Id = 1A5dL0000001B9VSAU
JobStatus = Completed
ProcessedRecordCount = 22
UpdatedRecordCount = 22
FailedRecordCount = 0
SkippedRecords = 0
StartExecutionTime = 2026-04-29T13:08:55.000+0000
EndExecutionTime = 2026-04-29T13:09:57.000+0000
ExecutionDetails = 750dL00000nfXLZQA2
```

The completed status did not prove successful realization. Post-job Account
verification showed `18` modified Accounts, but sampled mapped fields were
cleared to null:

```text
total = 18
model_count = 0
legal_count = 0
health_count = 0
```

Root cause moved again: the refreshed source object and CSV are correct, but
`ssot__Account__dlm` now contains duplicate/null rows for some target-org-safe
activation IDs. A focused query returned enriched rows and duplicate null rows
for the same IDs, including `001dL000024xl9FQAQ`,
`001dL000024wgYRQAY`, `001dL000024weudQAA`, and
`001dL000024xj2cQAA`; `001dL000024xlArQAI` appeared as a null DMO row in that
sample. The source object `pulse360_account_intelligence_export_v2__dll`
returned the expected 18 non-null rows.

Copy Field Enrichment was stopped again and the setup page showed:

```text
Sync Status = Sync inactive
Sync Date Time = None
```

A source-backed repair CSV was generated:

```text
data/exports/account_copy_field_repair_2026-04-29.csv
```

The repair excluded the six unsupported native Copy Field fields and restored
the 28 supported Account fields via Bulk API:

```text
Bulk job Id = 750dL00000nfZlZQAU
processedRecords = 18
successfulRecords = 18
failedRecords = 0
```

Post-repair verification passed:

```text
total = 18
model_count = 18
legal_count = 18
health_count = 18
synced_count = 18
```

Safety note: an unrelated Salesforce setup tab appeared to apply
`System Administrator` profile access to `Slack Customer Insights` while the
browser session was being recovered. That should be reviewed separately and is
not part of the `DAN-221` activation path.

## Required Contract Rule

For direct `ssot__Account__dlm -> Account` Copy Field writeback:

- the activation key must be a Salesforce Account Id from the target org
- the ID must resolve before the row enters the direct writeback export
- the source object and Account DMO must expose one authoritative row per
  activation-safe Account ID
- unresolved rows must remain observable in the review queue with blocker
  reasons such as `missing_target_org_account_id`,
  `external_org_account_id`, or `ambiguous_activation_candidate`

This rule is now enforced in source by:

- `scripts/validate-data-cloud-activation-key-alignment.sh`
- `scripts/validate-data-layer-closeout.sh`

The validator initially passed after the Data Cloud refresh and CRM repair for
activation-key resolvability:

```text
source_object_missing_activation_id_count = 0
dmo_missing_activation_id_count = 0
```

However, that guard was not sufficient by itself for Copy Field restart safety:
the same run also reported `dmo_total_size = 22` and
`dmo_distinct_activation_id_count = 18`. Direct Account Copy Field writeback
must require DMO row uniqueness in addition to CRM-safe activation IDs.

The guard has now been strengthened. Current result:

```text
[FAIL] Data Cloud direct Account activation contains duplicate activation IDs; Copy Field writeback requires one authoritative source/DMO row per target Account.
source_object_duplicate_activation_id_count = 0
dmo_duplicate_activation_id_count = 4
dmo_duplicate_activation_ids_sample = [
  "001dL000024weudQAA",
  "001dL000024wgYRQAY",
  "001dL000024xj2cQAA",
  "001dL000024xl9FQAQ"
]
```

Follow-up diagnosis initially showed two cleanup requirements:

| Requirement | Evidence | Required fix before Copy Field restart |
| --- | --- | --- |
| Remove duplicate stale DMO contribution | `databricks_enrichment_sample.csv` contributes 4 older non-null rows that duplicate four current target Account IDs | Deactivate/unmap/delete the obsolete `DC Export Accounts P360 Fix` / `dc_export_accounts_p360_fix` contribution from the direct Account DMO path, or otherwise exclude it from Copy Field eligibility |
| Repair current V2 DMO materialization | `databricks_enrichment_live_2026-04-20.csv` contributes 18 rows with target-org-safe IDs but `0` non-null values for `AI_Model_ID__c`, `External_Legal_Name__c`, and `Health_Score__c` | Repair or republish the V2 source-to-DMO extension-field mappings so the 27 required supported Copy Field fields materialize on `ssot__Account__dlm` |

The source object itself is not the data-quality blocker:

```text
source_object_required_supported_field_count = 27
source_object_rows_missing_required_supported_fields_count = 0
dmo_required_supported_field_count = 27
dmo_rows_missing_required_supported_fields_count = 18
```

This means deleting or unmapping the old 4-row Fix stream alone is not
sufficient. It would remove duplicates, but leave 18 unique DMO rows with null
writeback fields. The V2 source-to-DMO mapping/materialization must be fixed
before any Copy Field restart.

The V2 source-to-DMO mappings were then repaired and saved through the Data
Cloud mapping UI:

```text
Successfully added mappings.
Fields mapped = 32/49
```

Post-save DMO aggregation confirmed the V2 contribution now materializes the
accepted supported fields:

```text
source_object = databricks_enrichment_live_2026-04-20.csv
rows = 18
model_count = 18
legal_count = 18
health_count = 18
```

Two V2 field pairings were rejected by the Data Cloud mapper due to source and
target type mismatch:

| Source field | Target DMO field | Observed result |
| --- | --- | --- |
| `group_revenue_visible` | `Group_Revenue_Visible__c` | `Cannot map: source and target data types should be same.` |
| `external_revenue_confirmed` | `External_Revenue_Confirmed__c` | `Cannot map: source and target data types should be same.` |

The restart-safety validator now treats those two fields as current
source-to-DMO exceptions. The supported required DMO field set is therefore 25
fields, and the null-field blocker is cleared:

```text
source_object_required_supported_field_count = 25
source_object_rows_missing_required_supported_fields_count = 0
dmo_required_supported_field_count = 25
dmo_rows_missing_required_supported_fields_count = 0
```

The obsolete `DC Export Accounts P360 Fix` Data Stream was deleted and the V2
stream was full-refreshed again from the 18-row V2-compatible file. The V2
refresh completed successfully:

```text
DataStreamStatus = ACTIVE
ImportRunStatus = SUCCESS
LastRefreshDate = 2026-04-29T14:23:19.000+0000
TotalRowsProcessed = 18
LastDataChangeStatusErrorCode = null
```

Deleting the old Data Stream did not remove the old Fix DLO or its DMO
contribution. The DLO remains active:

```text
DataLakeObjectInstance Id = 1dldL000006t7ztQAA
ExternalName = dc_export_accounts_p360_fix__dll
TotalRecords = 4
```

Direct DLO deletion is blocked until mappings are removed:

```text
To delete the Data Lake Object, remove the mappings first.
```

The broad mapping-page `Remove Mappings` action opened a `Delete "Account"?`
dependency dialog listing both `DC Export Accounts P360 Fix` and `Pulse360
Account Intelligence Export V2` as Data Lake Object dependencies. That broad
confirmation was not executed because it risks disrupting the repaired V2 DLO
mapping. The remaining cleanup must remove the old Fix DLO mapping through a
targeted Data Cloud path.

Current closeout validation posture:

```text
./scripts/validate-data-layer-closeout.sh
```

passes through Databricks runtime, DMO extension, and field-path checks, then
fails intentionally at `Data Cloud activation key alignment` with duplicate DMO
evidence only. The V2 null-field blocker is cleared for the 25 supported
required DMO fields.

## Unsupported Field Decision

Native Copy Field Enrichment did not offer compatible Account target fields for
six fields from `config/data-cloud/activation-field-mapping.csv`:

| Field | Decision |
| --- | --- |
| `Intent_Signal_Payload__c` | Keep outside native Copy Field until a compatible payload strategy is chosen. |
| `AI_Recommended_Actions__c` | Keep outside native Copy Field until a compatible payload strategy is chosen. |
| `AI_Source_Refs__c` | Keep outside native Copy Field until a compatible payload strategy is chosen. |
| `AI_Narrative__c` | Keep outside native Copy Field until a compatible payload strategy is chosen. |
| `Hierarchy_Payload__c` | Keep outside native Copy Field until a compatible payload strategy is chosen. |
| `Group_Revenue_Rollup__c` | Resolve source Number to target Currency compatibility before native Copy Field inclusion. |

Recommended path:

1. Keep the 28 supported structured fields in native Copy Field Enrichment.
2. Keep long narrative/payload values in a separate activation path or reshape
   them into Copy Field-compatible fields if native writeback is required.
3. Align `Group_Revenue_Rollup__c` source and target semantics before adding it
   back to native Copy Field.
4. Align `Group_Revenue_Visible__c` and
   `External_Revenue_Confirmed__c` source-to-DMO data types before treating
   them as Data Cloud DMO-backed Copy Field values.

## Acceptance To Close DAN-221

`DAN-221` can close when a new post-refresh Copy Field run shows:

- `scripts/validate-data-cloud-activation-key-alignment.sh` passes
- `ssot__Account__dlm` has exactly one authoritative row per activation-safe
  Account ID for this export, with no duplicate/null row competing for the same
  `ssot__Id__c`
- the 25 required supported Copy Field source fields are non-null in the
  current source object and in the corresponding Account DMO rows
- `JobStatus = Completed`
- `FailedRecordCount = 0`
- expected processed and updated counts for activation-safe rows
- post-run Salesforce Account samples are modified by `Platform Integration
  User` and retain non-null mapped intelligence values
- the unsupported fields are either covered by a separate path or
  documented as accepted Copy Field exceptions

## Final Closeout Update

The closeout acceptance criteria are now met for the native-compatible Copy
Field scope.

Completed:

- The obsolete Fix Data Stream and DLO contribution were removed.
- The old Fix-to-Account `ObjectSourceTargetMap` was deleted without deleting
  or remapping the repaired V2 Account mapping.
- `scripts/validate-data-cloud-activation-key-alignment.sh` passes with 18 V2
  source rows, 18 Account DMO rows, and zero duplicate activation IDs.
- `scripts/validate-data-layer-closeout.sh` completes successfully.
- The Copy Field definition was corrected from `28 Fields * 28 Mapped` to
  `26 Fields * 26 Mapped` by removing stale
  `Group_Revenue_Visible__c` and `External_Revenue_Confirmed__c` mappings.
- The final Copy Field job completed with `18` processed, `18` updated,
  `0` failed, and `0` skipped records.
- Post-run Salesforce Account validation found `18/18` recently modified
  records with populated `AI_Model_Id__c`, `External_Legal_Name__c`,
  `Health_Score__c`, and `DataCloud_Last_Synced__c`.

Accepted exceptions:

- Serialized payload and narrative fields remain outside native Copy Field
  until compatible DMO/CRM field shapes are chosen.
- Revenue visible/confirmed fields remain outside native Copy Field until the
  source-to-DMO type mismatch is resolved.
