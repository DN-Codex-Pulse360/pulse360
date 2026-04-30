# Salesforce, Databricks, and MCP Setup Guide

## Salesforce Setup
1. Provision persistent Enterprise Developer Org.
2. Enable Sales Cloud, Service Cloud, Agentforce, and Data Cloud trial.
3. Create Connected App for API and MCP integration.
4. Validate OAuth token and refresh flows.

## Databricks Setup
1. Provision workspace.
2. Enable Unity Catalog and create dev catalog/schema.
3. Configure compute policy for deterministic demo runs.
4. Preload outputs for duplicate detection, hierarchy stitching, enrichment, and lineage.
5. Ingest Salesforce CRM `Account` source records into Databricks before enrichment when downstream activation writes back to CRM `Account`.
6. Preserve native `Account.Id` or an approved Salesforce External ID through Databricks staging and export contracts.

## MCP Baseline
Official-first preference:
- GitHub: official GitHub MCP server
- Linear: hosted Linear MCP
- Notion: hosted Notion MCP
- Databricks: official Databricks MCP capability (`managed`, `external`, or `custom` hosted in Databricks)
- Salesforce: official hosted Salesforce MCP or Salesforce DX MCP server when available in the operator environment

Least-privilege requirements:
- Separate credentials per system
- Minimal OAuth scopes
- Explicit tool allowlist
- Auditable logs for tool calls

## Vendor MCP Direction (2026-04-09)

### Salesforce

First-party options now available or emerging:
- Salesforce Hosted MCP Servers
- Salesforce DX MCP Server
- Agentforce MCP client / tool-calling path

Pulse360 recommendation:
- use official Salesforce MCP surfaces for generic schema, CLI, and platform workflows when available
- keep Pulse360-specific Data Cloud validation in the local service until first-party coverage can reproduce the same contract and field-path checks

### Databricks

First-party options now available:
- Managed MCP on Databricks
- External MCP connections from Databricks
- Custom MCP hosted as a Databricks App

Pulse360 recommendation:
- prefer official Databricks MCP for workspace, Unity Catalog, SQL, and assistant-driven workflows
- do not build a custom Pulse360 Databricks MCP unless a project-specific gap remains after the official option is wired

### Databricks SQL MCP in Codex

Pulse360 uses the official managed Databricks SQL MCP endpoint for direct SQL
work rather than a custom project MCP server.

Register it with Codex:

```bash
scripts/register-databricks-sql-mcp.sh
```

The registration name is `databricks_sql`, and the endpoint shape is:

```text
https://<workspace-hostname>/api/2.0/mcp/sql
```

For the active development workspace, this resolves to:

```text
https://dbc-7f0ce7bb-56ca.cloud.databricks.com/api/2.0/mcp/sql
```

Authentication note:

- `codex mcp login databricks_sql --scopes sql` can fail when the Databricks
  MCP endpoint does not support dynamic client registration from Codex.
- The approved fallback is bearer-token auth through the `DATABRICKS_TOKEN`
  environment variable.
- Do not store the Databricks token in repo files or Codex config.

For an interactive terminal session, derive the token from the local Databricks
CLI profile without printing it:

```bash
export DATABRICKS_TOKEN="$(
  awk -F= '/^[[:space:]]*token[[:space:]]*=/ {
    value=$2
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
    print value
    exit
  }' ~/.databrickscfg
)"
```

After registration or environment changes, restart the Codex desktop session so
the new MCP tool set is loaded.

Validate the MCP endpoint and SQL execution path:

```bash
scripts/validate-databricks-sql-mcp.sh
```

## Pulse360 Local MCP Candidate

The repo now includes a local read-only Pulse360 MCP service at
`services/salesforce_data_cloud_mcp` for Salesforce/Data Cloud inspection.

Local evaluation workflow:
1. Validate the service:
   - `bash scripts/validate-salesforce-data-cloud-mcp.sh`
2. Register it with Codex:
   - `bash scripts/register-salesforce-data-cloud-mcp.sh`
3. Confirm registration:
   - `codex mcp get pulse360_salesforce_data_cloud`

Boundary:
- This local MCP can be used for explicit operator-driven evaluation.
- It is not part of the approved baseline workflow until the custom-server review tracked in `DAN-223` is complete.
- Official hosted integrations remain the baseline for normal build/test operation.

## Pulse360 Recommended MCP Stack

### Core approved baseline

- GitHub MCP or `gh` CLI
- Hosted Linear MCP
- Hosted Notion MCP
- Salesforce CLI and official Salesforce MCP surfaces when available
- Databricks CLI and official Databricks MCP surfaces when available

### Pulse360-specific retained custom layer

- `services/salesforce_data_cloud_mcp`
  - reason to keep: compares Pulse360 contracts against the live Data Cloud source object, DMO, and Salesforce Account field path
  - current role: operator-directed read-only diagnostics
  - future role: remain only if first-party Salesforce MCP does not cover these project-specific comparisons cleanly

### Pulse360-specific custom layer to avoid for now

- custom Databricks MCP
  - reason not to add now: Databricks has a first-party MCP path and Pulse360 has not yet shown a Databricks-specific gap that requires a second custom server

## Active Connectivity Baseline (2026-04-09)
| System | Integration Path | Auth Mode | Validation | Fallback |
| --- | --- | --- | --- | --- |
| GitHub | `gh` CLI + API | OAuth token via `gh auth` | Repo API and PR flows succeeded | GitHub MCP server |
| Linear | Hosted Linear MCP | Workspace OAuth/session | Issues/milestones/comments managed from Codex | Linear web UI |
| Notion | Hosted Notion MCP | Workspace OAuth/session | Pages created/updated from Codex | Notion web UI |
| Salesforce | `sf` CLI (`pulse360-dev`) + local Pulse360 read-only MCP | Web OAuth login | org display, Data Cloud field-path checks, and local MCP validation succeeded | Direct REST OAuth / official hosted MCP |
| Databricks | `databricks` CLI + official Databricks SQL MCP registration | PAT token config / `DATABRICKS_TOKEN` env var | `workspace ls /`, Unity Catalog list checks, and `databricks_sql` MCP registration succeeded | Databricks UI/API / SQL Statement Execution API |

## Command Evidence
- `sf org display --target-org pulse360-dev --verbose --json`
- `sf data query --target-org pulse360-dev --query "SELECT Label, DeveloperName, NamespacePrefix FROM AppDefinition WHERE Label IN ('Data Cloud','Agentforce Studio','Sales','Service') ORDER BY Label" --result-format json`
- `databricks workspace ls /`
- `databricks unity-catalog metastores list`
- `scripts/register-databricks-sql-mcp.sh`
- `scripts/validate-databricks-sql-mcp.sh`
- `codex mcp get databricks_sql`
- `./scripts/check-databricks-lineage-runtime.sh` (requires configured lineage table names)

## Codex Operator Health

Pulse360 now treats Codex operator readiness as a first-class build dependency.

Run before cross-system work:

- `./scripts/check-codex-operator-health.sh`

This validates:

- Codex login state
- hosted Linear and Notion MCP registration
- local Pulse360 MCP registration
- DNS and hosted bridge reachability
- Salesforce CLI access to the approved non-production org alias
- Databricks CLI reachability when enabled

## Hosted MCP Repair

If a hosted connector is registered but acting stale, repair it with:

- `./scripts/repair-hosted-mcp-auth.sh linear`
- `./scripts/repair-hosted-mcp-auth.sh notion`

Important distinction:

- successful `codex mcp login` proves the local hosted OAuth path is healthy
- plugin-backed tool failures against `https://chatgpt.com/backend-api/wham/apps` point to the Codex app connector session, not necessarily the hosted MCP registration itself

If the health check passes but plugin tools still fail, restart the Codex
desktop app to refresh the connector session.

See [codex-operator-setup-and-troubleshooting.md](/Users/danielnortje/Documents/Pulse360/docs/setup/codex-operator-setup-and-troubleshooting.md).
