# Pulse360 MCP Upgrade Plan (2026-04-09)

## Goal

Update Pulse360's MCP posture to reflect the newer first-party Salesforce and Databricks MCP options without losing the project-specific runtime diagnostics already built in the repo.

## Current Pulse360 State

- official hosted baseline in active use:
  - GitHub
  - Linear
  - Notion
- official CLI fallback in active use:
  - Salesforce `sf`
  - Databricks `databricks`
- custom local MCP in repo:
  - `services/salesforce_data_cloud_mcp`
- no custom Databricks MCP exists in Pulse360 today

## Recommended Update

### 1. Keep official-first as the default

- prefer official Salesforce MCP surfaces for generic platform workflows
- prefer official Databricks MCP surfaces for workspace, catalog, and SQL workflows
- continue using vendor CLIs where the MCP path is not yet wired into the operator environment

### 2. Keep the Pulse360 Salesforce/Data Cloud MCP, but narrow its purpose

Retain the local server only for project-specific runtime checks that are not yet cleanly covered by first-party MCP:

- compare export contract -> Data Cloud source object
- compare export contract -> DMO mapping surface
- compare export contract -> Salesforce Account target surface
- report live field-path gaps end to end

This keeps the custom service as a diagnostic shim, not a general Salesforce control plane.

### 3. Do not add a custom Databricks MCP yet

Pulse360 does not currently have evidence of a Databricks-specific automation gap that justifies another custom MCP server.

The right sequence is:
- wire the official Databricks MCP path first
- validate whether it covers:
  - workspace browsing
  - Unity Catalog inspection
  - SQL execution
  - job orchestration
  - assistant/tool workflows
- only design a custom Databricks MCP if a real project-specific gap remains

### 4. Treat custom MCPs as a security exception path

Custom MCPs remain:
- blocked by default for standard workflow use
- allowed for explicit operator-driven evaluation
- subject to provenance, scope, dependency, and egress review

## Pulse360-Specific Recommendation

### Keep custom

- `pulse360_salesforce_data_cloud`
  - because it encodes Pulse360-specific comparison logic and Data Cloud runtime checks

### Replace with first-party where possible

- generic Salesforce schema/admin/code tasks
- generic Databricks workspace/catalog/query tasks

### Avoid building for now

- a second custom Databricks MCP service

## Success Criteria

Pulse360 is in a better MCP position when:

1. official Salesforce MCP covers generic Salesforce workflows
2. official Databricks MCP covers generic Databricks workflows
3. the local Pulse360 MCP is used only for project-specific validation that first-party tools do not reproduce
4. security documentation clearly separates approved baseline from custom exception tooling
