# Pulse360 Salesforce And Data Cloud MCP

Read-only MCP service for inspecting Salesforce CRM and Data Cloud runtime state in the Pulse360 build.

## Positioning

This service is not meant to replace first-party Salesforce MCP options as they mature.

Pulse360 keeps this local service because it provides project-specific diagnostics that are still valuable even if generic Salesforce MCP capability is available:

- contract-to-source-object comparison
- contract-to-DMO comparison
- contract-to-Account comparison
- live Data Cloud field-path status reporting

For generic Salesforce workflows, the preferred direction is:

- official Salesforce Hosted MCP when available
- official Salesforce DX MCP server for developer workflows

For Databricks, Pulse360 does not currently ship a custom local MCP server. The preferred direction there is the official Databricks MCP capability rather than a second project-specific custom server.

## Scope

This is the Phase 1 MCP surface described in:

- [salesforce-data-cloud-mcp-implementation-spec-2026-03-29.md](/Users/danielnortje/Documents/Pulse360/docs/planning/salesforce-data-cloud-mcp-implementation-spec-2026-03-29.md)
- [mcp-operational-contract.md](/Users/danielnortje/Documents/Pulse360/docs/contracts/mcp-operational-contract.md)
- [mcp-security-assessment.md](/Users/danielnortje/Documents/Pulse360/docs/security/mcp-security-assessment.md)

The service is intentionally read-only. It does not expose deploy, update, or mutation tools.

## Security Status

The service is now implemented in source for review, local validation, and future integration work.
It remains blocked from standard build/test workflow usage until the custom-server security boundary is approved in
[mcp-security-assessment.md](/Users/danielnortje/Documents/Pulse360/docs/security/mcp-security-assessment.md)
and tracked work such as `DAN-223` is complete.

Manual local evaluation is allowed when explicitly requested by the operator. That does not change the blocked-by-default workflow policy.

## Tool Surface

- `describe_sobject`
- `list_account_fields`
- `list_dmo_fields`
- `list_data_streams`
- `get_data_stream_status`
- `list_activation_targets`
- `query_soql`
- `query_dmo`
- `compare_export_contract_to_source_object`
- `compare_export_contract_to_account`
- `compare_export_contract_to_dmo`
- `report_live_field_path_status`
- `report_unmapped_fields`

## Defaults

The service uses these repo-aware defaults unless overridden in tool arguments or environment variables:

- default org alias: `pulse360-agent-target`
- default DMO: `ssot__Account__dlm`
- default source object: `pulse360_account_intelligence_export_v2__dll`
- default data stream: `DC Export Accounts P360 V2`
- account mapping: `config/data-cloud/activation-field-mapping.csv`
- DMO mapping: `config/data-cloud/dmo-account-field-mapping.csv`
- source contract: `contracts/databricks_to_datacloud.schema.json`
- account/DMO contract: `contracts/datacloud_to_salesforce_agentforce.schema.json`

Supported environment variables:

- `PULSE360_DEFAULT_ORG_ALIAS`
- `PULSE360_DEFAULT_DMO_NAME`
- `PULSE360_DEFAULT_SOURCE_OBJECT`
- `PULSE360_DEFAULT_DATA_STREAM_NAME`

## Run

From the repo root:

```bash
PYTHONPATH=services/salesforce_data_cloud_mcp/src \
python3 -m pulse360_salesforce_data_cloud_mcp --transport stdio
```

Or after installing the package in a virtual environment:

```bash
cd services/salesforce_data_cloud_mcp
python3 -m pip install -e .
pulse360-salesforce-data-cloud-mcp --transport stdio
```

To register the local stdio server with Codex:

```bash
bash scripts/register-salesforce-data-cloud-mcp.sh
codex mcp get pulse360_salesforce_data_cloud
```

## Validation

Run:

```bash
bash scripts/validate-salesforce-data-cloud-mcp.sh
```

This checks Python syntax, loads the server, and confirms the expected read-only tools are registered.
