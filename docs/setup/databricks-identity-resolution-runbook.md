# Databricks Identity Resolution Runbook

## Purpose

Apply the first identity and weighted-attribute layer for the revised Pulse360 RevOps Intelligence architecture.

This slice is not the final sovereign identity implementation. It creates the implementation surface and contract shape while preserving the existing CRM-safe account key.

## Repo Artifacts

- `sql/databricks/identity_resolution/00_create_schema.sql`
- `sql/databricks/identity_resolution/05_registry_identity_source_sample.sql`
- `sql/databricks/identity_resolution/10_identity_source_xref_base.sql`
- `sql/databricks/identity_resolution/20_resolved_entity.sql`
- `sql/databricks/identity_resolution/30_weighted_attribute_resolution.sql`
- `sql/databricks/identity_resolution/40_entity_hierarchy_edge.sql`
- `sql/databricks/identity_resolution/50_entity_hierarchy_rollup.sql`
- `sql/databricks/identity_resolution/60_m1_account_hierarchy_operational_profile.sql`
- `contracts/sovereign_identity_spine.schema.json`
- `contracts/registry_identity_source.schema.json`
- `contracts/weighted_attribute_resolution.schema.json`
- `contracts/m1_account_hierarchy_operational_profile.schema.json`

## Preconditions

1. `pulse360_s4.silver_salesforce.crm_account` exists.
2. The Databricks user can create views in `pulse360_s4.identity_resolution`.
3. The first slice is accepted as CRM-safe fallback plus a registry-source sample, not proof of a live national registry connector.

## Execution

1. Open Databricks SQL editor or a notebook attached to the target workspace.
2. Run the SQL files in the order defined in `sql/databricks/identity_resolution/README.md`.
3. Validate that the following views exist:
   - `pulse360_s4.identity_resolution.identity_source_xref_base`
   - `pulse360_s4.identity_resolution.registry_identity_source_sample`
   - `pulse360_s4.identity_resolution.resolved_entity`
   - `pulse360_s4.identity_resolution.weighted_attribute_resolution`
   - `pulse360_s4.identity_resolution.entity_hierarchy_edge`
   - `pulse360_s4.identity_resolution.entity_hierarchy_rollup`
   - `pulse360_s4.identity_resolution.m1_account_hierarchy_operational_profile`

## Validation Queries

```sql
SELECT resolved_entity_id, sovereign_identity_key, identity_resolution_method, primary_crm_account_id
FROM pulse360_s4.identity_resolution.resolved_entity
LIMIT 10;

SELECT resolved_entity_id, attribute_name, attribute_confidence, freshness_status
FROM pulse360_s4.identity_resolution.weighted_attribute_resolution
LIMIT 10;

SELECT parent_entity_id, child_entity_id, relationship_type, child_coverage_status, hierarchy_confidence
FROM pulse360_s4.identity_resolution.entity_hierarchy_edge
LIMIT 10;

SELECT group_entity_id, known_subsidiary_count, crm_covered_subsidiary_count, uncovered_subsidiary_count, coverage_gap_flag
FROM pulse360_s4.identity_resolution.entity_hierarchy_rollup
LIMIT 10;

SELECT operational_profile_id, group_entity_id, primary_anchor_account_id, crm_anchor_account_ids, coverage_gap_flag
FROM pulse360_s4.identity_resolution.m1_account_hierarchy_operational_profile
LIMIT 10;
```

## Expected Outcome

1. CRM-derived rows preserve a Salesforce `Account.Id`.
2. Registry sample rows demonstrate deterministic sovereign-ID identity without claiming a live registry connector.
3. Every resolved entity has run metadata and source identifier metadata.
4. Every weighted attribute has source contribution, freshness, confidence, run ID, timestamp, and model version.
5. Every hierarchy edge has source contribution, freshness, confidence, run ID, timestamp, and model version.
6. Hierarchy rollups expose summary fields for Data Cloud/Salesforce and retain drill-through payloads for detail.
7. M1 operational profiles expose `primary_anchor_account_id` and `crm_anchor_account_ids` for Data Cloud linkage; uncovered registry-only groups preserve an empty anchor array rather than failing the transform.
8. The implementation is ready for national-registry, commercial-provider, and customer-internal source additions.
