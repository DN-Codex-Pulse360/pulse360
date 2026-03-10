# Databricks Implementation Patterns for S4

## 1. Data zones and tables

### Bronze (raw)
- `bronze.crm_accounts_raw`
- `bronze.crm_contacts_raw`
- `bronze.crm_revenue_raw`

### Silver (normalized)
- `silver.accounts_standardized`
- `silver.account_identity_features`
- `silver.revenue_standardized`

### Gold (intelligence products)
- `gold.duplicate_candidate_pairs`
- `gold.entity_hierarchy_graph`
- `gold.firmographic_enrichment`
- `gold.governance_ops_metrics`
- `gold.datacloud_export_accounts`

## 2. Required fields for handoff tables

### `gold.duplicate_candidate_pairs`
- `left_account_id`
- `right_account_id`
- `duplicate_confidence_score`
- `feature_explanations`
- `run_id`
- `run_ts`

### `gold.entity_hierarchy_graph`
- `entity_id`
- `parent_entity_id`
- `hierarchy_depth`
- `legal_name`
- `validity_score`
- `source_registry`
- `run_id`
- `run_ts`

### `gold.firmographic_enrichment`
- `account_or_entity_id`
- `attribute_name`
- `attribute_value`
- `validity_score`
- `review_required_flag`
- `source_name`
- `run_id`
- `run_ts`

## 3. Job pattern
1. `job_ingest_crm_snapshot` (daily)
2. `job_build_identity_features` (daily)
3. `job_detect_duplicates` (daily)
4. `job_stitch_hierarchy` (daily)
5. `job_enrich_firmographics` (daily)
6. `job_publish_datacloud_export` (daily)

Use one orchestration job with explicit task dependencies and retry policy.

## 4. Governance and lineage pattern
1. Register all tables in Unity Catalog.
2. Use consistent catalog.schema.table naming.
3. Log model version and source snapshot ID.
4. Keep lineage screenshot/export prepared for demo.

## 5. Data Cloud handoff contract (prototype)
1. Export stable account/entity IDs.
2. Export confidence and validity fields as numeric values.
3. Include ingestion label field and run timestamp.
4. Keep a single latest snapshot table and one immutable history table.

## 6. Demo hardening checklist
1. Freeze demo input snapshot at least 24 hours before presentation.
2. Re-run pipeline once after freeze and verify record counts.
3. Validate top 5 showcased entities manually.
4. Confirm dashboards load in browser without notebook edits.
