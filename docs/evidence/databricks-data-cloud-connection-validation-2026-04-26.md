# Databricks To Data Cloud Connection Validation

Date: 2026-04-26
Org alias: `pulse360-agent-target`
Scope: Validate whether `pulse360_s4.intelligence.datacloud_activation_review_queue`
is connected to Salesforce Data Cloud

## Summary

The new Databricks review queue table exists and is populated in Databricks, but
Salesforce Data Cloud does not yet have a Data Stream or Data Lake Object for
that table.

The target org does have existing Data Cloud account export streams and Data
Lake Objects, but the observed Data Lake Objects are `Storage = LOCAL` ingest
objects. This proves data has been loaded into Data Cloud before; it does not
prove that the new review queue table is connected, nor does it prove an active
direct Databricks connection for this table.

## Databricks Table Status

The table created for Data Cloud ingestion is:

```text
pulse360_s4.intelligence.datacloud_activation_review_queue
```

It contains the latest Claude runtime review row:

```text
review_queue_id = gov_firmographic_genai_runtime_ent_ph_sec_as096_003241
source_product = firmographic_genai_runtime
model_id = claude-sonnet-4-20250514
enrichment_run_id = genai_firmographic_batch_llm_20260426044442
activation_resolution_hint = ambiguous_crm_candidates_require_stewardship
```

## Data Cloud Streams Observed

Live `DataStream` records:

```text
DC Export Accounts P360 V2
- StreamType = INGEST
- DataStreamStatus = ACTIVE
- ImportRunStatus = SUCCESS
- LastRefreshDate = 2026-04-20T06:29:34.000+0000
- TotalRowsProcessed = 43

DC Export Accounts P360 Fix
- StreamType = INGEST
- DataStreamStatus = ACTIVE
- ImportRunStatus = SUCCESS
- LastRefreshDate = 2026-04-18T14:25:10.000+0000
- TotalRowsProcessed = 4

Engagement_A4S-Behavioral Events 9984E5CD
SetupPageSearchMetadataStream_K7M3X-SetupPageSearchMetadata
```

No `DataStream` exists for:

```text
datacloud_activation_review_queue
activation review queue
firmographic_genai_runtime
```

## Data Lake Objects Observed

Live `DataLakeObjectInstance` records include:

```text
Pulse360 Account Intelligence Export V2
- ExternalName = pulse360_account_intelligence_export_v2__dll
- Storage = LOCAL
- Status = ACTIVE
- SyncStatus = ACTIVE
- TotalRecords = 43

DC Export Accounts P360 Fix
- ExternalName = dc_export_accounts_p360_fix__dll
- Storage = LOCAL
- Status = ACTIVE
- SyncStatus = ACTIVE
- TotalRecords = 4
```

No `DataLakeObjectInstance` exists for:

```text
datacloud_activation_review_queue
activation review queue
firmographic_genai_runtime
```

## Connector Metadata Checks

Read-only metadata checks found:

```text
ExternalDataSource records = 0
DataSourceBundle records = 0
DataSource object is not queryable in this org
DataConnectorStatusEvent exists but is not SOQL-queryable
```

## Follow-Up Validation After UI Setup

After creating the Direct Access stream and custom DMO in Data Cloud, MCP
validation confirmed the review queue is now connected and queryable.

Data Stream:

```text
Name = Pulse360_Activation_Review_Queue
Id = 1dsdL000000Or4nQAC
DataStreamStatus = ACTIVE
ImportRunStatus = SUCCESS
LastRefreshDate = 2026-04-26T10:15:06.000+0000
TotalRowsProcessed = 4
IsNewFieldsAvailable = false
```

DMO:

```text
Name = Pulse360_Activation_Review_Queue__dlm
field_count = 23
primary/key field = review_queue_id__c / KQ_review_queue_id__c
```

Key DMO fields observed:

```text
review_queue_id__c
resolved_entity_id__c
crm_activation_key__c
crm_activation_candidate_count__c
crm_activation_candidate_ids__c
crm_activation_candidate_names__c
activation_resolution_hint__c
activation_block_reasons__c
activation_eligible_flag__c
confidence_score__c
lineage_status__c
model_id__c
prompt_version__c
enrichment_run_id__c
```

MCP query against `Pulse360_Activation_Review_Queue__dlm` returned the latest
Claude review row:

```text
review_queue_id__c = gov_firmographic_genai_runtime_ent_ph_sec_as096_003241
resolved_entity_id__c = ent_ph_sec_as096_003241
crm_activation_key__c = null
crm_activation_candidate_count__c = 2
crm_activation_candidate_ids__c = ["001dM00003d4bllQAA","001dM00003gR9K2QAK"]
activation_resolution_hint__c = ambiguous_crm_candidates_require_stewardship
activation_block_reasons__c = ["missing_crm_activation_key","source_product_not_activation_eligible"]
activation_eligible_flag__c = false
confidence_score__c = 0.7634
lineage_status__c = source_bound
model_id__c = claude-sonnet-4-20250514
prompt_version__c = pulse360-public-regional-v1
enrichment_run_id__c = genai_firmographic_batch_llm_20260426044442
```

## Updated Conclusion

The selected table is now connected to Data Cloud as a Direct Access
accelerated stream and mapped to a custom review/stewardship DMO.

What is proven:

1. Databricks has the review queue table.
2. Data Cloud stream `Pulse360_Activation_Review_Queue` is active and refreshed.
3. Data Cloud DMO `Pulse360_Activation_Review_Queue__dlm` exists.
4. The latest Claude review row is queryable in Data Cloud.
5. The row remains review-only: `crm_activation_key__c = null` and
   `activation_eligible_flag__c = false`.

Next setup step: decide how Salesforce should surface this DMO row for
stewardship, for example by creating a Governance Case from the DMO evidence or
rendering it in a review dashboard.

## Original Conclusion

The selected table was not connected to Data Cloud yet at the first validation
checkpoint.

What is proven:

1. Databricks has the review queue table.
2. Existing account export data has previously been ingested into Data Cloud.
3. Data Cloud has active local ingest Data Lake Objects for account exports.

What is not proven:

1. A live Databricks-to-Data Cloud connector for the new review queue table.
2. A Data Cloud Data Stream for `datacloud_activation_review_queue`.
3. A Data Lake Object or DMO that exposes the Claude review queue row.

Next setup step: create a Data Cloud Data Stream or Direct Access object for
`pulse360_s4.intelligence.datacloud_activation_review_queue`, then map it to a
review/stewardship DMO.
