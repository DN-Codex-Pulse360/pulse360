# Pulse360 S4 Prototype

This repository tracks implementation artifacts for the EPF v3.2.4 prototype build of the S4 Account Intelligence and Data Foundation solution.

## Scope
- EPF stages 1.1 to 2.6
- Salesforce + Data Cloud + Databricks prototype baseline
- Linear-tracked work items and Notion documentation parity
- MCP official-first baseline and security gate

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
- `docs/runbook`: DS-01/DS-02/DS-03 execution runbook
- `docs/qa`: acceptance and test checklists
- `docs/readout`: internal and customer readout templates
- `docs/planning`: release and backlog planning artifacts
- `docs/evidence`: dated validation evidence and blocker tracking
- `sql/databricks`: Databricks silver/gold SQL packages for CRM-key-safe exports
- `force-app`: Salesforce metadata for activation target fields
- `scripts`: local validation and runtime helper scripts

## Working Rule
Every completed Linear issue must update at least one Notion page and one relevant repo artifact before closure.

## Salesforce Delivery Model
- Source-driven Salesforce metadata in `force-app`
- Permission-set-first security model
- Lightning Record Pages and LWC for CRM execution surfaces
- Manifest and validation discipline for releases
- Runbook-driven handling for org-locked Data Cloud setup

See [AGENTS.md](/Users/danielnortje/Documents/Pulse360/AGENTS.md) and [salesforce-devops-operating-model.md](/Users/danielnortje/Documents/Pulse360/docs/devops/salesforce-devops-operating-model.md).

## Key Contract Note
CRM writeback scenarios require upstream Salesforce CRM Account ingestion into Databricks, with native `Account.Id` or an approved Salesforce External ID preserved through enrichment and export.
