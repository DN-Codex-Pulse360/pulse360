# Pulse360 Salesforce DevOps Operating Model

## Purpose

Capture the Salesforce-specific operating model now adopted by the Pulse360
project. This document distills the external Salesforce skill files into
repo-native rules and delivery patterns.

## Skill Mapping

| External skill | Incorporated into Pulse360 as |
| --- | --- |
| `salesforce_devops_master.md` | Cross-skill operating rules in `AGENTS.md` |
| `salesforce_dx_mcp_toolsets.md` | DX CLI, metadata, schema-first, testing, and permission-set workflow |
| `salesforce_source_control.md` | Branching, drift control, `.forceignore`, source-first policy |
| `salesforce_release_management.md` | Manifest discipline, validate-before-deploy, rollback expectations |
| `salesforce_cicd_pipeline.md` | CI quality-gate model and future headless deployment pattern |
| `salesforce_hosted_data_cloud_mcp.md` | Data Cloud deployable vs org-locked boundary |
| `salesforce_agentforce.md` | Trust, planning separation, SDM/Data Cloud grounding |

## Design Principles Used In This Project

### 1. Source-driven Salesforce delivery

- Salesforce metadata is versioned under `force-app`.
- Changes are introduced through source, then deployed to target orgs.
- Permission sets are preferred over profile-driven access changes.

### 2. Schema-first implementation

- Object and field API names must be validated before code or seeded data creation.
- The project uses org describe checks and metadata validation scripts before relying on custom fields.

### 3. CRM execution, not CRM intelligence

- Databricks generates stewardship intelligence and evidence.
- Data Cloud provides the CRM-centered operational layer.
- Salesforce CRM hosts the transactional stewardship workflow, audit, and execution surface.

### 4. Split-mode Data Cloud delivery

- Deployable CRM metadata belongs in source control.
- Org-locked Data Cloud setup must be documented as runbooks, not treated like normal metadata deploys.

### 5. Validate-before-deploy release discipline

- Repo validators are run before deploy.
- Org deploys are explicit and tracked.
- Manifest and rollback discipline is expected for broader release hardening.

## Current Salesforce Practices Already In Use

- SFDX source format in `force-app`
- Lightning Record Page metadata
- LWC-based governance review surface
- Permission-set-based access
- Salesforce CLI deploy and org validation
- Seeded `Account` and `Governance_Case__c` fixtures for realistic stewardship testing

## Gaps Still To Close

### Salesforce UX best practice gaps

- Replace raw lookup ID rendering with real record links
- Replace free-text account ID input with native lookup editing
- Use schema imports and field helpers in the LWC

### Release engineering gaps

- Generate and commit release manifests under `manifest/`
- Add dry-run deployment validation to CI for Salesforce metadata changes
- Separate deployable metadata from org-locked Data Cloud runbooks more explicitly

### Security gaps

- Reduce permission set edit scope on read-only evidence fields
- Avoid broad admin-style object permissions for routine stewardship users

## Required Delivery Sequence

1. Update source metadata in repo
2. Run local validation scripts
3. Deploy to sandbox/dev org
4. Validate in-org behavior with realistic records
5. Capture release/runbook implications for Data Cloud or non-deployable setup

## Immediate Next Practices To Adopt

1. Add a generated Salesforce manifest for the governance-case package.
2. Add a CI step for `scripts/validate-governance-case-metadata.sh`.
3. Refactor the governance review LWC to use Salesforce-native lookup rendering.

