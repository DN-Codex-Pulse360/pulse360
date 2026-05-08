# Pulse360 M1 Account Hierarchy Runbook

## Purpose

This runbook operationalizes the first implementation slice selected in the
accepted RevOps architecture: `M1 Account Hierarchy Intelligence`.

## Source Scope

- Linear parent: `DAN-330`
- Child issues: `DAN-331` to `DAN-335`
- Branch: `codex/m1-account-hierarchy-intelligence`

## Databricks Run Order

Run the prerequisite Salesforce, firmographic, and gold export assets first,
then run:

1. `sql/databricks/account_hierarchy/00_create_schema.sql`
2. `sql/databricks/account_hierarchy/10_m1_account_hierarchy_edge.sql`
3. `sql/databricks/account_hierarchy/20_m1_account_group_rollup.sql`
4. `sql/databricks/account_hierarchy/30_m1_account_hierarchy_activation.sql`

## Validation Expectations

- `m1_account_hierarchy_activation` should preserve one Account-safe row per
  current CRM account where possible.
- `source_account_id` must remain the Salesforce Account join key.
- `account_group_id` should be deterministic: `agrp_<lower source account id>`.
- Revenue rollups must distinguish zero revenue from missing revenue evidence.
- Sovereign identifier counts can remain zero when official evidence is absent.

## Salesforce/Data Cloud Handoff

Use the existing Account-centered Data Cloud relationships and validation
dashboard first. Do not add new DMO relationships unless a live validation report
proves the current Account join cannot render M1 hierarchy data.

## Runtime Gates

The source package does not claim:

- live Databricks SQL Warehouse execution;
- live Unity Catalog lineage export for the new M1 tables;
- Data Cloud stream creation for new M1 outputs;
- Salesforce BYOM or native Agentforce runtime success.
