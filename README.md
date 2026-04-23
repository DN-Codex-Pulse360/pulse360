# Pulse360 S4 Prototype

This repository tracks implementation artifacts for the EPF v3.2.4 prototype build of the S4 Account Intelligence and Data Foundation solution.

## Scope
- EPF stages 1.1 to 2.6
- Salesforce + Data Cloud + Databricks prototype baseline
- Linear-tracked work items and Notion documentation parity
- MCP official-first baseline and security gate

## Current Product Direction

The current product target is the revised proposition in [pulse360-revops-value-proposition.html](</Users/danielnortje/Desktop/Huron/AI CoE/Account360/pulse360-revops-value-proposition.html>).

The repo should now be read through the UX-led alignment package rather than only through the earlier runtime-first milestone framing:

- Program anchor: [pulse360-research-led-ux-realignment-program-2026-04-19.md](/Users/danielnortje/Documents/Pulse360/docs/improvements/pulse360-research-led-ux-realignment-program-2026-04-19.md)
- Research assessment: [pulse360-html-proposition-to-ux-research-2026-04-19.md](/Users/danielnortje/Documents/Pulse360/docs/qa/pulse360-html-proposition-to-ux-research-2026-04-19.md)
- UX surface spec: [pulse360-ux-surface-specification-2026-04-19.md](/Users/danielnortje/Documents/Pulse360/docs/improvements/pulse360-ux-surface-specification-2026-04-19.md)
- UX validation kit: [pulse360-ux-validation-kit-2026-04-19.md](/Users/danielnortje/Documents/Pulse360/docs/qa/pulse360-ux-validation-kit-2026-04-19.md)
- Surface-driven contract requirements: [pulse360-surface-driven-contract-requirements-2026-04-19.md](/Users/danielnortje/Documents/Pulse360/docs/contracts/pulse360-surface-driven-contract-requirements-2026-04-19.md)
- UX-derived technical bridge: [pulse360-technical-design-derived-from-ux-2026-04-19.md](/Users/danielnortje/Documents/Pulse360/docs/improvements/pulse360-technical-design-derived-from-ux-2026-04-19.md)
- Visual blueprint: [pulse360-ux-blueprint-2026-04-19.html](/Users/danielnortje/Documents/Pulse360/docs/improvements/pulse360-ux-blueprint-2026-04-19.html)

This means the intended product is no longer just an enriched Account page. The working target is a multi-surface Pulse360 experience across:

- planner workspace
- seller workspace
- signal routing workspace
- renewal and risk workspace
- supporting governance and trust flows

## Current Agentforce Reality Check

Agentforce-related source exists in this repo, but native Agentforce success is capability-gated by the target org.

- Repo-backed Agentforce metadata, actions, and orchestration can be built and deployed from source.
- A custom LWC or Apex-driven assistant surface is not the same thing as a native Agentforce runtime experience.
- Do not treat `pulse360-agent-target` as a proven native Agentforce runtime unless Builder access, runtime surface availability, and live agent interaction are explicitly verified in that org.

See [agentforce-capability-reality-check-2026-04-23.md](/Users/danielnortje/Documents/Pulse360/docs/evidence/agentforce-capability-reality-check-2026-04-23.md) and [pulse360-agentforce-org-migration-checklist-2026-04-17.md](/Users/danielnortje/Documents/Pulse360/docs/runbook/pulse360-agentforce-org-migration-checklist-2026-04-17.md).

## Linked Systems
- GitHub repo: https://github.com/DN-Codex-Pulse360/pulse360
- Linear project: https://linear.app/danielnortje/project/pulse360-65420c0a9857/overview
- Notion parent: https://www.notion.so/Pulse360-31dfe2e19eed80678c2fde2bd0b4ac40

## Repo Layout
- `AGENTS.md`: project operating rules for Salesforce, Data Cloud, Databricks, and release flow
- `docs/epf`: EPF gate and control documents
- `docs/setup`: setup runbooks for platforms and toolchain
- `docs/devops`: Salesforce DevOps operating model, release, and CI/CD guidance
- `docs/contracts`: integration contracts
- `docs/security`: MCP and security assessment artifacts
- `docs/setup/mcp-upgrade-plan-2026-04-09.md`: first-party vs custom MCP update path for Pulse360
- `docs/setup/codex-operator-setup-and-troubleshooting.md`: Codex, MCP, Salesforce, and Databricks operator health and repair path
- `docs/devops/codex-agent-decision-framework.md`: decision stack for Codex-driven Salesforce and Databricks work
- `docs/runbook`: DS-01/DS-02/DS-03 execution runbook
- `docs/qa`: acceptance and test checklists
- `docs/readout`: internal and customer readout templates
- `docs/improvements`: north-star, UX-led realignment, and experience design artifacts
- `docs/planning`: release and backlog planning artifacts
- `docs/evidence`: dated validation evidence and blocker tracking
- `sql/databricks`: Databricks silver/gold SQL packages for CRM-key-safe exports
- `force-app`: Salesforce metadata for activation target fields
- `config/packages`: package member lists for generated Salesforce and Databricks workspaces
- `scripts`: local validation and runtime helper scripts

## Working Rule
Every completed Linear issue must update at least one Notion page and one relevant repo artifact before closure.

## Salesforce Delivery Model
- Source-driven Salesforce metadata in `force-app`
- Permission-set-first security model
- Lightning Record Pages and LWC for CRM execution surfaces
- Manifest and validation discipline for releases
- Runbook-driven handling for org-locked Data Cloud setup

## Experience Validation
- `./scripts/validate-account-intelligence-experience.sh` validates the Account record seller workspace baseline.
- `./scripts/validate-agentforce-orchestrator.sh` validates the governance and Agentforce handoff surfaces.
- `./scripts/validate-signal-routing-workspace.sh` validates the signal-routing tab, payload contract, and permissions.
- `./scripts/validate-multi-surface-experience.sh` validates planner, seller v2, renewal-risk, health-scan, and preview-directory metadata.
- `./scripts/check-codex-operator-health.sh` validates the Codex operator baseline across hosted MCPs, the local Pulse360 MCP, Salesforce CLI, and Databricks CLI.
- `./scripts/validate-surface-architecture.sh` validates whether Salesforce surfaces match the intended page architecture or are explicitly marked as transitional.
- `./scripts/validate-contract-completeness.sh` validates whether user-facing payload contracts preserve actions, evidence, provenance, freshness, and CRM-safe deep links.

## Package Workspaces
- `./scripts/build-salesforce-package-workspace.sh` generates unlocked-package-ready Salesforce workspaces
- `./scripts/build-databricks-package-workspace.sh` generates Databricks solution pack workspaces
- `./scripts/build-package-workspaces.sh` builds both sets together
- `./scripts/validate-salesforce-package-layout.sh` and `./scripts/validate-databricks-package-layout.sh` validate the generated layouts

See [package-workspaces.md](/Users/danielnortje/Documents/Pulse360/docs/setup/package-workspaces.md).

See [AGENTS.md](/Users/danielnortje/Documents/Pulse360/AGENTS.md) and [salesforce-devops-operating-model.md](/Users/danielnortje/Documents/Pulse360/docs/devops/salesforce-devops-operating-model.md).

For Codex-specific operator and troubleshooting guidance, see [codex-operator-setup-and-troubleshooting.md](/Users/danielnortje/Documents/Pulse360/docs/setup/codex-operator-setup-and-troubleshooting.md) and [codex-agent-decision-framework.md](/Users/danielnortje/Documents/Pulse360/docs/devops/codex-agent-decision-framework.md).

## Key Contract Note
CRM writeback scenarios require upstream Salesforce CRM Account ingestion into Databricks, with native `Account.Id` or an approved Salesforce External ID preserved through enrichment and export.

## Current Acceptance Note

Technical runtime proof remains necessary, but it is no longer sufficient on its own.

Current acceptance should be read through both:

- [acceptance-checklist.md](/Users/danielnortje/Documents/Pulse360/docs/qa/acceptance-checklist.md)
- [pulse360-ux-validation-kit-2026-04-19.md](/Users/danielnortje/Documents/Pulse360/docs/qa/pulse360-ux-validation-kit-2026-04-19.md)
