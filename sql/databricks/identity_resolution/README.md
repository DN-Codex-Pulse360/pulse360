# Databricks Identity Resolution SQL

These SQL files create the first source-backed identity and weighted-attribute layer for the revised Pulse360 RevOps Intelligence architecture.

## Order

Run the files in this order:

1. `00_create_schema.sql`
2. `05_registry_identity_source_sample.sql`
3. `10_identity_source_xref_base.sql`
4. `20_resolved_entity.sql`
5. `30_weighted_attribute_resolution.sql`
6. `40_entity_hierarchy_edge.sql`
7. `50_entity_hierarchy_rollup.sql`
8. `60_m1_account_hierarchy_operational_profile.sql`

## Output Views

- `pulse360_s4.identity_resolution.identity_source_xref_base`
- `pulse360_s4.identity_resolution.registry_identity_source_sample`
- `pulse360_s4.identity_resolution.resolved_entity`
- `pulse360_s4.identity_resolution.weighted_attribute_resolution`
- `pulse360_s4.identity_resolution.entity_hierarchy_edge`
- `pulse360_s4.identity_resolution.entity_hierarchy_rollup`
- `pulse360_s4.identity_resolution.m1_account_hierarchy_operational_profile`

## Design Rules

- The first slice is intentionally CRM-safe and fallback-oriented.
- `resolved_entity.crm_account_ids` preserves Salesforce `Account.Id` values for activation.
- `sovereign_identity_key` is `CRM_SAFE_FALLBACK|Account.Id` for CRM-only rows and country/id/name based for the first registry sample.
- `registry_identity_source_sample` demonstrates the deterministic sovereign-ID source adapter shape before a live national registry connector is added.
- Provider IDs and sovereign identifiers must be attributes or anchors according to `contracts/sovereign_identity_spine.schema.json`.
- Weighted attributes must carry source contribution, freshness, confidence, run ID, timestamp, and model version.
- Hierarchy edges must carry relationship type, CRM coverage status, confidence, source contribution, freshness, run ID, timestamp, and model version.
- Hierarchy rollups must separate summary fields from full drill-through payloads.
- The M1 operational profile must include CRM-safe anchor fields, but uncovered registry-only groups can have an empty `crm_anchor_account_ids` array and a null `primary_anchor_account_id` until a Salesforce Account linkage exists.

## Next Step

Add national-registry/provider/customer-internal inputs, then change `identity_resolution_method` from `crm_safe_fallback` to deterministic or probabilistic methods where evidence supports it.
