# Pulse360 Package Workspaces

Pulse360 now generates installable workspaces from the repo source instead of
forcing the main source tree into package-only layout.

## Salesforce

Run:

```bash
./scripts/build-salesforce-package-workspace.sh
```

This creates:

- `build/package-workspaces/salesforce/packages/account-intelligence`
- `build/package-workspaces/salesforce/packages/governance`
- `build/package-workspaces/salesforce/sfdx-project.json`

Use that generated workspace to create unlocked packages in this order:

1. `pulse360-account-intelligence`
2. `pulse360-governance`

The governance package depends on the account intelligence package because the
Governance Case UI and permission set rely on Account intelligence fields.

## Databricks

Run:

```bash
./scripts/build-databricks-package-workspace.sh
```

This creates:

- `build/package-workspaces/databricks/salesforce-ingestion`
- `build/package-workspaces/databricks/account-intelligence-export`

Each generated directory includes a `databricks.yml` bundle file plus the SQL,
contracts, validation scripts, and runbooks needed for promotion into a new
workspace.

### Databricks Pack Split

1. `pulse360-salesforce-ingestion`
   - silver Salesforce normalization SQL
   - Unity Catalog / lineage configuration
   - ingestion contract and runbook
2. `pulse360-account-intelligence-export`
   - gold export SQL
   - downstream contracts
   - dashboard SQL
   - export runbook and validations

## Combined Builder

To generate both sets together:

```bash
./scripts/build-package-workspaces.sh
```

## Validation

Run:

```bash
./scripts/validate-salesforce-package-layout.sh
./scripts/validate-databricks-package-layout.sh
```

These checks validate the generated package workspaces without requiring a Dev
Hub org or a live Databricks deployment.
