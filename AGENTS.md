# Pulse360 Agent Operating Guide

This repository follows a source-driven Salesforce delivery model for the Pulse360
Account Intelligence build.

## Salesforce Skills In Use

The project is grounded in these external Salesforce skill references:

- `salesforce_devops_master.md`
- `salesforce_dx_mcp_toolsets.md`
- `salesforce_source_control.md`
- `salesforce_release_management.md`
- `salesforce_cicd_pipeline.md`
- `salesforce_hosted_data_cloud_mcp.md`
- `salesforce_agentforce.md`
- `salesforce_devops_center.md`
- `salesforce_slack_tableau_mcp.md`

These are incorporated here as project rules and delivery patterns. The repo
should not depend on those files being present at runtime.

## Core Rules

1. No production development. Build and validate in scratch orgs or sandboxes.
2. Schema first. Confirm object and field API names before writing Apex, LWC, SOQL, or DML.
3. Plan before state changes. Any deployment, permission change, seeded data load, or config mutation requires explicit review.
4. Source first. Changes must originate in repo metadata, not ad hoc org edits.
5. Prefer permission sets over profiles.
6. Keep Salesforce CRM execution separate from Databricks intelligence and Data Cloud operational context.
7. Treat Data Cloud deployment as split-mode: deployable metadata where supported, runbook-driven setup where org-locked.

## Build Modes

- Plan mode: architecture, contracts, manifests, validation design.
- Act mode: metadata edits, deployments, seeded fixtures, org validation.
- Audit mode: read-only org or repo review.

## Source Control Rules

1. Feature work starts on a branch from the active release line, never directly on `main`.
2. Before metadata edits, review current local repo state and target-org drift.
3. Resolve metadata XML conflicts structurally; never leave merge markers in XML.
4. Keep `.forceignore` current when adding new Salesforce metadata types.

## Salesforce UI Rules

1. Lookup relationships must render as actual Salesforce record links, not raw IDs.
2. Lookup edits should use Salesforce-native field controls where feasible.
3. Evidence fields from Databricks/Data Cloud are read-only in CRM.
4. Decision and merge execution fields are the editable stewardship surface.

## Release Rules

1. Generate manifests from source; do not hand-maintain package membership from memory.
2. Validate deploy before real deploy.
3. Document destructive changes and rollback before any non-trivial release.
4. Keep org-specific setup steps in runbooks when the platform does not support source deployment.

## CI/CD Rules

1. PR validation must fail on broken metadata validation or contract drift.
2. Real deployments belong behind explicit approval gates.
3. Pipeline auth should use headless Salesforce patterns, not interactive logins.

## Data Cloud Rules

1. Do not assume all Data Cloud assets are deployable through standard `sf project deploy`.
2. Document org-locked Data Cloud setup as runbooks under `docs/runbook` or `config/data-cloud`.
3. Ground CRM-facing intelligence on Data Cloud/DMO semantics, not guessed field names.

