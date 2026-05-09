# M1 Account Hierarchy Intelligence

This SQL bundle creates the first implementation slice for M1. It keeps
Databricks as the governed system of record and exposes Account-safe hierarchy
outputs for Data Cloud and Salesforce validation.

## Run Order

1. `00_create_schema.sql`
2. `10_m1_account_hierarchy_edge.sql`
3. `20_m1_account_group_rollup.sql`
4. `30_m1_account_hierarchy_activation.sql`
5. `40_m1_account_hierarchy_activation_export.sql`
6. `50_m1_account_group_rollup_export.sql`
7. `60_m1_account_hierarchy_edge_export.sql`

## Output Tables

- `pulse360_s4.intelligence.m1_account_hierarchy_edge`
- `pulse360_s4.intelligence.m1_account_group_rollup`
- `pulse360_s4.intelligence.m1_account_hierarchy_activation`
- `pulse360_s4.intelligence.m1_account_hierarchy_activation_export`
- `pulse360_s4.intelligence.m1_account_group_rollup_export`
- `pulse360_s4.intelligence.m1_account_hierarchy_edge_export`

## Contract Rules

- `source_account_id` remains the CRM-safe Account join key.
- Sovereign identifiers are not used as Account join keys.
- CRM parent-child links are allowed as prototype evidence and are marked with
  `relationship_basis = crm_parent_account`.
- Source-bound external or GPT-derived hierarchy facts must carry evidence URLs
  and confidence.
- Data Cloud Direct Access streams should target the `_export` tables, not the
  internal analytical tables.
- Export field names must stay at or below 40 characters before Data Cloud adds
  source-object suffixes.
