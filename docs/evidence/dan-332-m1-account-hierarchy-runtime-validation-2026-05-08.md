# DAN-332 M1 Account Hierarchy Runtime Validation

## Summary

`DAN-332` has live Databricks runtime evidence for the M1 Account Hierarchy
SQL path. The validation executed the schema, hierarchy edge, group rollup, and
activation SQL through the Databricks SQL Statements API against warehouse
`7052914888c7e86c`.

## Scope

- Branch: `codex/m1-account-hierarchy-intelligence`
- Workspace host: `dbc-7f0ce7bb-56ca.cloud.databricks.com`
- Target catalog/schema: `pulse360_s4.intelligence`
- Runtime script: `scripts/run-m1-account-hierarchy-runtime-check.sh`

## Executed SQL

1. `sql/databricks/account_hierarchy/00_create_schema.sql`
2. `sql/databricks/account_hierarchy/10_m1_account_hierarchy_edge.sql`
3. `sql/databricks/account_hierarchy/20_m1_account_group_rollup.sql`
4. `sql/databricks/account_hierarchy/30_m1_account_hierarchy_activation.sql`

## Runtime Results

| Table | Row Count | Key Counts | Notes |
| --- | ---: | --- | --- |
| `m1_account_hierarchy_edge` | 2 | 1 parent, 1 child | Built from current corporate linkage evidence. |
| `m1_account_group_rollup` | 17 | 18 total members, 1 known child, 10 coverage gaps | Represents 17 account groups across 18 current CRM accounts. |
| `m1_account_hierarchy_activation` | 18 | 18 distinct Account join keys, 17 account groups, 10 coverage-gap accounts | Preserves one activation row for every current CRM Account. |

Additional metrics:

- Edge average confidence: `0.72`
- Rollup average hierarchy completeness score: `0.5663529411764706`
- Activation average confidence: `0.6727777777777779`
- Runtime timestamp max: `2026-05-08T13:12:16.867Z`

## Validation Commands

```bash
./scripts/validate-m1-account-hierarchy-pack.sh
./scripts/validate-databricks-package-layout.sh
git diff --check
./scripts/run-m1-account-hierarchy-runtime-check.sh
```

All commands passed after qualifying ambiguous rollup SQL references in
`20_m1_account_group_rollup.sql`.

## Caveats

- `./scripts/check-codex-operator-health.sh` is referenced by the repo operating
  guide but is not present in this worktree. This is a tooling gap, not a
  runtime validation failure.
- Data Cloud stream creation and Salesforce validation surfaces for the new M1
  outputs remain separate follow-on work under `DAN-334`.
- Salesforce demo readout and final evidence packaging remain under `DAN-335`.
