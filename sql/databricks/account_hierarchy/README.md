# M1 Account Hierarchy Intelligence

This SQL bundle creates the first implementation slice for M1. It keeps
Databricks as the governed system of record and exposes Account-safe hierarchy
outputs for Data Cloud and Salesforce validation.

## Run Order

1. `00_create_schema.sql`
2. `10_m1_account_hierarchy_edge.sql`
3. `20_m1_account_group_rollup.sql`
4. `30_m1_account_hierarchy_activation.sql`

## Output Tables

- `pulse360_s4.intelligence.m1_account_hierarchy_edge`
- `pulse360_s4.intelligence.m1_account_group_rollup`
- `pulse360_s4.intelligence.m1_account_hierarchy_activation`

## Contract Rules

- `source_account_id` remains the CRM-safe Account join key.
- Sovereign identifiers are not used as Account join keys.
- CRM parent-child links are allowed as prototype evidence and are marked with
  `relationship_basis = crm_parent_account`.
- Source-bound external or GPT-derived hierarchy facts must carry evidence URLs
  and confidence.
