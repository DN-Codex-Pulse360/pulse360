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
