# DAN-59 Data Cloud Stream Configuration and Health Evidence

- Issue: `DAN-59`
- Scope: Salesforce account stream + Databricks enrichment stream configuration and verification
- Evidence run timestamp (UTC): `2026-03-09T06:49:02.874Z`
- Evidence run ID: `run_20260309_064746`

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

## Stream Health and Ingestion Verification
Execution path:
- `./scripts/run-datacloud-prerun-import.sh`
- embedded validation: `./scripts/validate-data-cloud-stream-runtime.sh`

Verified runtime snapshot:
- duplicate_candidate_pairs rows: `3`
- firmographic_enrichment rows: `3`
- governance_ops_metrics rows: `1`
- datacloud_export_accounts rows: `3`
- export last_synced_timestamp: `2026-03-09T06:49:02.874Z`
- ingestion_metadata_label: `Databricks Enrichment — Last ingested: 2026-03-09 06:49:02 UTC`

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

## Acceptance Mapping (DAN-59)
- Salesforce account stream and Databricks enrichment stream configured: satisfied.
- Databricks stream labelled with last-ingested metadata: satisfied.
- Stream health and ingestion verification documented: satisfied.
- Mapping to contract fields validated: satisfied.
