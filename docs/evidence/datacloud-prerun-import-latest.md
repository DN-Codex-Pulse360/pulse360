# Databricks -> Data Cloud Pre-run Import Evidence

- Run timestamp (UTC): 2026-03-09 06:47:46 UTC
- run_id: run_20260309_064746
- Workflow: prototype pre-run import connector contract (DAN-62)

## Commands Executed
- `RUN_ID=run_20260309_064746 ./scripts/build-duplicate-candidate-pairs.sh`
- `RUN_ID=run_20260309_064746 ./scripts/build-firmographic-enrichment.sh`
- `RUN_ID=run_20260309_064746 ./scripts/build-governance-ops-metrics.sh`
- `RUN_ID=run_20260309_064746 ./scripts/build-datacloud-export-accounts.sh`
- `./scripts/validate-data-cloud-stream-runtime.sh`
- `./scripts/validate-data-cloud-insights-config.sh`
- `./scripts/validate-contracts.sh`
- `./scripts/validate-canonical-exports.sh`
- `./scripts/validate-datacloud-connector-contract.sh`

## Stream Runtime Snapshot
- duplicate_candidate_pairs rows: 3
- firmographic_enrichment rows: 3
- governance_ops_metrics rows: 1
- datacloud_export_accounts rows: 3
- export last_synced_timestamp: 2026-03-09T06:49:02.874Z
- ingestion_metadata_label: Databricks Enrichment — Last ingested: 2026-03-09 06:49:02 UTC
