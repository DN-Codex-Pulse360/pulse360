# DAN-59 Data Cloud Stream Configuration and Health Evidence

- Issue: `DAN-59`
- Scope: Salesforce account stream + Databricks enrichment stream configuration and verification
- Evidence refresh timestamp (UTC): `2026-03-10T06:22:00Z`
- Evidence run ID: `run_20260310_02`

## Stream Configuration Baseline
Source of truth: `config/data-cloud/stream-manifest.yaml`

Configured streams:
1. Salesforce account stream
   - source object: `Account`
   - target object: `Account`
   - mode: `near_real_time`
   - expected latency: `5` minutes
   - verification controls: `oauth_connection_valid`, `stream_status_active`, `recent_rows_detected`
2. Databricks enrichment stream
   - source table: `pulse360_s4.intelligence.datacloud_export_accounts`
   - mode: `batch_pre_run`
   - expected latency: `15` minutes
   - ingestion metadata label field: `ingestion_metadata_label`
   - required run metadata fields: `run_id`, `run_timestamp`, `model_version`

## Databricks Runtime and Contract Verification
Execution path:
- `RUN_ID=run_20260310_02 ./scripts/run-datacloud-prerun-import.sh`
- `./scripts/validate-data-cloud-stream-runtime.sh` (executed with current Databricks host/token/warehouse env)

Verified runtime snapshot:
- duplicate_candidate_pairs rows: `3`
- firmographic_enrichment rows: `3`
- governance_ops_metrics rows: `1`
- datacloud_export_accounts rows: `3`
- export last_synced_timestamp: `2026-03-10T01:03:51.927Z`
- ingestion_metadata_label: `Databricks Enrichment — Last ingested: 2026-03-10 01:03:51 UTC`

## Mapping to Contract Fields
Validation sources:
- `config/data-cloud/activation-field-mapping.csv`
- `scripts/validate-data-cloud-stream-runtime.sh`
- `contracts/databricks_to_datacloud.schema.json`

Validated mapping outcomes:
- required activation fields are present in mapping (`unified_profile_id`, `identity_confidence`, `group_revenue_rollup`, `health_score`, `cross_sell_propensity`, `coverage_gap_flag`, `competitor_risk_signal`, and sync metadata fields).
- runtime checks confirm:
  - `identity_confidence` bounded `0-100`
  - `last_synced_timestamp` populated
  - `ingestion_metadata_label` populated
  - run metadata fields (`run_id`, `run_timestamp`, `model_version`) populated

## Salesforce Data Cloud Stream Runtime Status
Validation sources:
- Salesforce UI page: `https://orgfarm-2587d03c12-dev-ed.develop.lightning.force.com/lightning/o/DataStream/list?filterName=All_DataStreams`
- runtime validator: `scripts/validate-salesforce-data-cloud-stream-runtime.sh`
- direct query: `sf data query --query "SELECT Id, Name, DataStreamStatus, ImportRunStatus, LastRefreshDate, TotalRowsProcessed FROM DataStream ORDER BY LastModifiedDate DESC LIMIT 15"`

Observed status (2026-03-10, post Databricks connector + stream creation):
- `DataStream` records in org: `7`
- UI view `Recently Viewed` shows active ingest streams:
  - `Account_Home`
  - `Contact_Home`
  - `Lead_Home`
  - `Opportunity_Home`
  - `OpportunityContactRole_Home`
  - `User_Home`
  - `datacloud_export_accounts Pulse360_Datab`
- Runtime validator result:
  - `./scripts/validate-salesforce-data-cloud-stream-runtime.sh` -> PASS
  - Stream count snapshot confirms `DataStreamStatus=ACTIVE` and `ImportRunStatus=SUCCESS` across listed streams.
  - Databricks stream record:
    - `Id=1dsdM000000QD9hQAG`
    - `LastRefreshDate=2026-03-10T04:47:11.000+0000`
    - `TotalRowsProcessed=3`

Interpretation:
- Databricks-side stream contract and export health are passing.
- Salesforce stream deployment proof is now present (non-zero active streams visible in UI and runtime query).

## Acceptance Mapping (DAN-59)
- Salesforce account stream and Databricks enrichment stream configured: **satisfied** (manifest + active Salesforce streams + Databricks stream runtime checks).
- Databricks stream labelled with last-ingested metadata: **satisfied**.
- Stream health and ingestion verification documented: **satisfied** (Databricks + Salesforce runtime checks).
- Mapping to contract fields validated: **satisfied**.

## Out-of-Scope Gap (Tracked Separately)
The following items are not DAN-59 stream-plumbing scope and are tracked in `DAN-114` / `DAN-61`:
- Salesforce Account activation target fields are not yet present in org metadata:
  - `Unified_Profile_Id__c`
  - `Identity_Confidence__c`
  - `Group_Revenue_Rollup__c`
  - `Health_Score__c`
  - `Cross_Sell_Propensity__c`
  - `Coverage_Gap_Flag__c`
  - `Competitor_Risk_Signal__c`
  - `DataCloud_Last_Synced__c`
- Data Cloud mapping row object (`MktDataLakeMapping`) currently returns zero rows, indicating mapping publish is not complete.
