# DAN-59 Data Cloud Stream Configuration and Health Evidence

- Issue: `DAN-59`
- Scope: Salesforce account stream + Databricks enrichment stream configuration and verification
- Evidence refresh timestamp (UTC): `2026-03-10T01:03:51.927Z`
- Evidence run ID: `run_20260310_01`

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
- `RUN_ID=run_20260310_01 ./scripts/run-datacloud-prerun-import.sh`
- embedded validation: `./scripts/validate-data-cloud-stream-runtime.sh`

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
- direct query: `sf data query --target-org pulse360-dev --query "SELECT Id, Name FROM DataStream LIMIT 10"`

Observed status (2026-03-10):
- `DataStream` records in org: `0`
- `All Data Streams` list in Salesforce UI: `No items to display`

API create attempts (CLI) were rejected with platform `UNKNOWN_EXCEPTION` errors:
- ErrorId: `984362996-13826 (2081726263)`
- ErrorId: `1659890987-17426 (2081726263)`

Interpretation:
- Databricks-side stream contract and export health are passing.
- Salesforce Data Cloud stream deployment is still missing in the org and remains the open acceptance blocker for DAN-59.

## Acceptance Mapping (DAN-59)
- Salesforce account stream and Databricks enrichment stream configured: **partial** (manifest complete; Salesforce deployed stream missing).
- Databricks stream labelled with last-ingested metadata: **satisfied**.
- Stream health and ingestion verification documented: **Databricks satisfied**; Salesforce stream runtime not satisfied.
- Mapping to contract fields validated: **satisfied**.
