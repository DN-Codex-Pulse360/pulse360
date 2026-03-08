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
- `scripts/validate-unity-catalog-config.sh`
- `scripts/check-databricks-lineage-runtime.sh`

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
