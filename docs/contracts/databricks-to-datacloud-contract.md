# Contract: Databricks -> Data Cloud

## Purpose
Define handoff payload required for identity resolution, hierarchy modeling, and insights.

For the full Data Cloud-aligned B2B canonical object model (Account, product, brand, engagement, and related entities), see `docs/contracts/b2b-customer360-canonical-model-v2.md`.

This v1 handoff remains valid for DS-01/02/03 continuity. Canonical v2 exports are required for enterprise model alignment across systems.

## Required Fields
| Field | Type | Description |
| --- | --- | --- |
| entity_id | string | Deterministic entity identifier |
| source_account_id | string | Original CRM account key |
| duplicate_confidence | number | Match score 0-100 |
| hierarchy_parent_id | string | Parent entity id |
| hierarchy_child_id | string | Child entity id |
| validity_score | number | Enrichment confidence 0-100 |
| review_flag | boolean | Manual review flag |
| run_id | string | Pipeline run identifier |
| run_timestamp | datetime | UTC pipeline completion timestamp |
| model_version | string | Model/pipeline version identifier |

## Rules
- No hardcoded scenario metrics.
- IDs must be deterministic across reruns.
- All records must carry run metadata.
- Canonical v2 exports must be published for:
  - account core (`account_core_export`)
  - product and brand relationships (`product_brand_export`)
  - engagement entities (`engagement_export`)

## Implemented Artifacts
- `contracts/databricks_to_datacloud.schema.json`
- `contracts/databricks_hierarchy_graph.schema.json`
- `config/data-cloud/stream-manifest.yaml`
- `contracts/datacloud_account_core_canonical_v2.schema.json`
- `contracts/datacloud_product_brand_canonical_v2.schema.json`
- `contracts/datacloud_engagement_canonical_v2.schema.json`
- `data/samples/databricks_enrichment_sample.csv`
- `data/samples/hierarchy/databricks_hierarchy_graph_sample.json`
- `data/samples/datacloud_account_core_canonical_v2_sample.json`
- `data/samples/datacloud_product_brand_canonical_v2_sample.json`
- `data/samples/datacloud_engagement_canonical_v2_sample.json`
- `data/samples/datacloud_account_core_canonical_v2_export.csv`
- `data/samples/datacloud_account_core_canonical_v2_export.jsonl`
- `data/samples/datacloud_product_brand_canonical_v2_export.csv`
- `data/samples/datacloud_product_brand_canonical_v2_export.jsonl`
- `data/samples/datacloud_engagement_canonical_v2_export.csv`
- `data/samples/datacloud_engagement_canonical_v2_export.jsonl`
- `config/databricks/unity-catalog-governance.yaml`
- `config/databricks/lineage-targets.env.sample`
- `scripts/validate-contracts.sh`
- `scripts/validate-hierarchy-and-identity.sh`
- `scripts/build-datacloud-export-accounts.sh`
- `scripts/validate-data-cloud-stream-runtime.sh`
- `scripts/validate-data-cloud-insights-config.sh`
- `scripts/validate-unity-catalog-config.sh`
- `scripts/check-databricks-lineage-runtime.sh`

## Stream Health and Ingestion Metadata (DAN-59)
- Salesforce account stream and Databricks enrichment stream are defined in `config/data-cloud/stream-manifest.yaml`.
- Databricks enrichment stream source table: `pulse360_s4.intelligence.datacloud_export_accounts`.
- Stream ingestion metadata label field: `ingestion_metadata_label`.
- Required runtime verification:
  - source tables are populated (`duplicate_candidate_pairs`, `firmographic_enrichment`, `governance_ops_metrics`, `datacloud_export_accounts`)
  - `last_synced_timestamp` is populated in export rows
  - ingestion metadata label follows `Databricks Enrichment — Last ingested: [UTC timestamp]`

## DAN-60 Evidence Snapshot (2026-03-08)
- Identity rule threshold configured at `>=90` in `config/data-cloud/identity-resolution-rules.json`.
- Key demo identity pairs meet threshold in `data/samples/datacloud_identity_resolution_sample.json`.
- Hierarchy sample demonstrates multi-level parent-child graph and supports rollup context in:
  - `data/samples/hierarchy/databricks_hierarchy_graph_sample.json`
  - `data/samples/datacloud_identity_resolution_sample.json` (`group_revenue_rollup`, `unified_profile_id`)
- Downstream Salesforce alignment is represented in:
  - `contracts/datacloud_to_salesforce_agentforce.schema.json`
  - `config/data-cloud/activation-field-mapping.csv`
  - `data/samples/datacloud_activation_sample.json`

## Connector Contract Versioning (DAN-62)
The connector contract is versioned in `config/data-cloud/stream-manifest.yaml` under `connector_contract`.

| Key | Value |
| --- | --- |
| `contract_name` | `databricks_to_datacloud` |
| `contract_version` | `1.1.0` |
| `metadata_version` | `1.0.0` |
| `prototype_mode` | `pre_run_import` |
| `pre_run_import_script` | `scripts/run-datacloud-prerun-import.sh` |
| `evidence_file` | `docs/evidence/datacloud-prerun-import-latest.md` |

Metadata fields that must be present in Databricks export rows:
- `run_id`
- `run_timestamp`
- `model_version`
- `ingestion_metadata_label`

## Prototype Pre-run Import Process (DAN-62)
For deterministic prototype repeatability, run the connector workflow before Data Cloud ingest:

```bash
RUN_ID=run_YYYYMMDD_HHMMSS ./scripts/run-datacloud-prerun-import.sh
```

What this executes:
1. Build/refresh Databricks runtime tables (`duplicate_candidate_pairs`, `firmographic_enrichment`, `governance_ops_metrics`, `datacloud_export_accounts`).
2. Validate stream health and activation mapping integrity.
3. Validate contract files and canonical export consistency.
4. Write latest audit evidence to `docs/evidence/datacloud-prerun-import-latest.md`.

## Delta Share Migration Path (Production)
Prototype mode uses `batch_pre_run` import. Production migration target is live Delta Sharing.

Migration notes:
1. Replace batch pre-run source with Delta Share provider and share objects for account core/product-brand/engagement exports.
2. Keep contract/metadata versions in `connector_contract` synchronized with published Delta Share schemas.
3. Preserve metadata fields (`run_id`, `run_timestamp`, `model_version`, `ingestion_metadata_label`) in shared tables.
4. Replace pre-run workflow evidence with scheduled ingestion audit artifacts from Delta Share jobs.
5. Re-run `./scripts/validate-datacloud-connector-contract.sh` and `./scripts/validate-data-cloud-stream-runtime.sh` after cutover.
