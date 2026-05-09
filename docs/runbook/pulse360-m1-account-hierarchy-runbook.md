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
5. `sql/databricks/account_hierarchy/40_m1_account_hierarchy_activation_export.sql`
6. `sql/databricks/account_hierarchy/50_m1_account_group_rollup_export.sql`
7. `sql/databricks/account_hierarchy/60_m1_account_hierarchy_edge_export.sql`

## Validation Expectations

- `m1_account_hierarchy_activation` should preserve one Account-safe row per
  current CRM account where possible.
- `source_account_id` must remain the Salesforce Account join key.
- `account_group_id` should be deterministic: `agrp_<lower source account id>`.
- Revenue rollups must distinguish zero revenue from missing revenue evidence.
- Sovereign identifier counts can remain zero when official evidence is absent.
- Data Cloud Direct Access streams must target the `_export` tables, not the
  internal analytical tables.
- Export field names must remain at or below 40 characters before Data Cloud
  appends platform suffixes.

## Runtime Check

After the prerequisite gold outputs exist in the target Databricks workspace,
run:

```bash
./scripts/run-m1-account-hierarchy-runtime-check.sh
```

The script executes the M1 SQL run order through the Databricks SQL Statements
API and returns row counts for:

- `pulse360_s4.intelligence.m1_account_hierarchy_edge`
- `pulse360_s4.intelligence.m1_account_group_rollup`
- `pulse360_s4.intelligence.m1_account_hierarchy_activation`
- `pulse360_s4.intelligence.m1_account_hierarchy_edge_export`
- `pulse360_s4.intelligence.m1_account_group_rollup_export`
- `pulse360_s4.intelligence.m1_account_hierarchy_activation_export`

The first successful runtime validation was captured in
`docs/evidence/dan-332-m1-account-hierarchy-runtime-validation-2026-05-08.md`.

## Salesforce/Data Cloud Handoff

Use the existing Account-centered Data Cloud relationships and validation
dashboard pattern first. Do not add new DMO relationships unless a live
validation report proves the current Account join cannot render M1 hierarchy
data.

Create M1 Data Cloud streams from these export tables:

- `pulse360_s4.intelligence.m1_account_hierarchy_activation_export`
- `pulse360_s4.intelligence.m1_account_group_rollup_export`
- `pulse360_s4.intelligence.m1_account_hierarchy_edge_export`

Keep the non-export M1 tables as Databricks analytical tables. They are useful
for debugging lineage and rollup logic, but the export tables are the governed
Data Cloud handoff contract.

## Remaining Runtime Gates

The source package has validated live Databricks SQL Warehouse execution for
the M1 tables. It does not yet claim:

- live Unity Catalog lineage export for the new M1 tables;
- Data Cloud stream creation for new M1 outputs;
- Salesforce BYOM or native Agentforce runtime success.
