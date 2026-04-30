# Codex Operator Setup And Troubleshooting

## Purpose

This guide makes the Pulse360 Codex operator environment repeatable for
Salesforce, Databricks, GitHub, Linear, Notion, and local MCP-backed checks.

Use it when:

- setting up a new machine
- validating a degraded Codex environment
- repairing hosted MCP auth
- diagnosing why plugin tools fail while repo-local CLIs still work

## Baseline Expectations

The Pulse360 operator environment should have:

- Codex CLI installed and logged in
- Codex desktop app available
- `sf` CLI authenticated to approved non-production orgs
- `databricks` CLI configured for the dev workspace when Databricks work is in scope
- `databricks_sql` MCP registered when direct SQL MCP access is needed
- hosted MCP registrations for Linear and Notion
- GitHub access through `gh` CLI and/or the GitHub plugin
- the local `pulse360_salesforce_data_cloud` MCP registered when project-specific diagnostics are needed

## Health Check

Run:

```bash
./scripts/check-codex-operator-health.sh
```

This checks:

- Codex login state
- hosted MCP registrations
- local Pulse360 MCP registration
- DNS reachability for `chatgpt.com`, `mcp.linear.app`, and `mcp.notion.com`
- hosted app bridge reachability at `https://chatgpt.com/backend-api/wham/apps`
- Salesforce org CLI health
- Databricks CLI reachability when enabled
- Databricks SQL MCP registration when Databricks checks are enabled

Useful flags:

```bash
PULSE360_SKIP_DATABRICKS_CHECK=1 ./scripts/check-codex-operator-health.sh
PULSE360_SKIP_SALESFORCE_CHECK=1 ./scripts/check-codex-operator-health.sh
PULSE360_HEALTH_FULL_MCP=1 ./scripts/check-codex-operator-health.sh
```

## Repairing Hosted MCP OAuth

If Linear or Notion auth is stale, run:

```bash
./scripts/repair-hosted-mcp-auth.sh linear
./scripts/repair-hosted-mcp-auth.sh notion
```

This removes the stored OAuth session for the selected hosted MCP and starts the
login flow again through Codex.

## Repairing The Local Pulse360 MCP

If the project-specific Salesforce/Data Cloud MCP registration is missing or
using the wrong defaults, run:

```bash
./scripts/register-salesforce-data-cloud-mcp.sh
./scripts/validate-salesforce-data-cloud-mcp.sh
```

## Repairing Databricks SQL MCP

The official Databricks SQL MCP endpoint is registered as `databricks_sql`.

```bash
./scripts/register-databricks-sql-mcp.sh
./scripts/validate-databricks-sql-mcp.sh
codex mcp get databricks_sql
```

Codex OAuth login can fail against this endpoint if dynamic client registration
is unavailable. Use bearer-token auth through `DATABRICKS_TOKEN` instead, and
restart the Codex desktop app after changing MCP registration or environment
variables. Never write the Databricks token into repo files or Codex config.

## Known Failure Modes

### 1. Hosted MCP auth is stale

Symptoms:

- `codex mcp get linear` or `codex mcp get notion` shows registration, but tool calls fail
- login prompts reappear unexpectedly

Fix:

- run `./scripts/repair-hosted-mcp-auth.sh <server>`

### 2. The hosted app bridge is stale even though CLI auth is healthy

Symptoms:

- `codex mcp login linear` succeeds
- DNS resolution works
- direct plugin-backed tool calls still fail with requests against:
  - `https://chatgpt.com/backend-api/wham/apps`

Interpretation:

- local OAuth state is healthy
- the Codex desktop app connector session is stale or was created during a temporary network failure

Fix:

1. confirm health with `./scripts/check-codex-operator-health.sh`
2. if the hosted bridge endpoint is reachable but plugin tools still fail, restart the Codex desktop app
3. retry the plugin-backed action in a fresh thread if needed

### 3. DNS or network outage

Symptoms:

- health check fails on `chatgpt.com`, `mcp.linear.app`, or `mcp.notion.com`
- logs show DNS lookup failures

Fix:

- restore network or DNS first
- then rerun the hosted MCP OAuth repair if necessary

### 4. Salesforce is healthy but Data Cloud checks fail

Symptoms:

- `sf org display` works
- Data Cloud describe/query checks fail in `validate-salesforce-data-cloud-mcp.sh`

Fix:

- confirm org alias and Data Cloud object names
- rerun the local MCP registration with the correct defaults
- capture any org-locked gap in a runbook or evidence note instead of hiding it

## Preferred Operational Pattern

For Pulse360 work:

1. run the health check before cross-system work
2. use repo validators before deploy
3. use hosted MCPs for project tracking and documentation when healthy
4. fall back to repo evidence when a tracker connector is unavailable
5. use the official Databricks SQL MCP for direct SQL work when registered and loaded
6. run `PULSE360_HEALTH_FULL_MCP=1 ./scripts/check-codex-operator-health.sh` when proving local Salesforce/Data Cloud and Databricks MCP execution paths
7. keep Salesforce/Data Cloud-specific diagnostics in the local Pulse360 MCP only where first-party tools do not cover the need cleanly
