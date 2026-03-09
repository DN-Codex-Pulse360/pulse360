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

## MCP Baseline
Official-first preference:
- GitHub: official GitHub MCP server
- Linear: hosted Linear MCP
- Notion: hosted Notion MCP
- Databricks: managed/external Databricks MCP capability
- Salesforce: official hosted MCP when available; fallback API integration otherwise

Least-privilege requirements:
- Separate credentials per system
- Minimal OAuth scopes
- Explicit tool allowlist
- Auditable logs for tool calls

## Active Connectivity Baseline (2026-03-08)
| System | Integration Path | Auth Mode | Validation | Fallback |
| --- | --- | --- | --- | --- |
| GitHub | `gh` CLI + API | OAuth token via `gh auth` | Repo API and PR flows succeeded | GitHub MCP server |
| Linear | Hosted Linear MCP | Workspace OAuth/session | Issues/milestones/comments managed from Codex | Linear web UI |
| Notion | Hosted Notion MCP | Workspace OAuth/session | Pages created/updated from Codex | Notion web UI |
| Salesforce | `sf` CLI (`pulse360-dev`) | Web OAuth login | `sf org display` + app availability query succeeded | Direct REST OAuth |
| Databricks | `databricks` CLI | PAT token config | `workspace ls /` + `unity-catalog metastores list` succeeded | Databricks UI/API |

## Command Evidence
- `sf org display --target-org pulse360-dev --verbose --json`
- `sf data query --target-org pulse360-dev --query "SELECT Label, DeveloperName, NamespacePrefix FROM AppDefinition WHERE Label IN ('Data Cloud','Agentforce Studio','Sales','Service') ORDER BY Label" --result-format json`
- `databricks workspace ls /`
- `databricks unity-catalog metastores list`
- `./scripts/check-databricks-lineage-runtime.sh` (requires configured lineage table names)
- `./scripts/build-datacloud-export-accounts.sh`
- `./scripts/validate-data-cloud-stream-runtime.sh`
- `./scripts/validate-data-cloud-insights-config.sh`

## Data Cloud Stream Baseline (DAN-59)
- Stream manifest: `config/data-cloud/stream-manifest.yaml`
- Salesforce stream: `salesforce_account_stream` (Account source, near-real-time)
- Databricks stream: `databricks_enrichment_stream` (source table `pulse360_s4.intelligence.datacloud_export_accounts`)
- Last-ingested label field: `ingestion_metadata_label`
- Runtime verification:
  - non-zero rows in duplicate/enrichment/governance/export source tables
  - export `last_synced_timestamp` populated
  - ingestion label prefix `Databricks Enrichment — Last ingested:`
