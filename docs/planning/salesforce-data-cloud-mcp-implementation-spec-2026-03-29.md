# Salesforce And Data Cloud MCP Implementation Spec

Date: 2026-03-29
Status: Proposed
Scope: Pulse360 build and validation automation

## Purpose

Define a first-pass MCP approach that increases Codex automation for Salesforce and Data Cloud while staying inside the project's current security and operational guardrails.

This spec is intentionally conservative:

- official-first where possible
- read-only first
- least-privilege auth
- explicit separation between safe automated operations and external/manual platform steps

## Why This Exists

The current Pulse360 workflow already proves that Codex can operate across:

- Salesforce CLI
- Databricks CLI and API
- local validation scripts
- Linear

But the workflow is still an agentic operator pattern rather than a reusable automation layer. The current pain points are:

- repeated environment inspection still depends on shell parsing
- Data Cloud validation is not packaged into stable tools
- the line between "Codex can do this now" and "external admin action required" is not formalized as tooling
- org and Data Cloud operations are not yet idempotent or centrally audited as MCP tools

## Constraints

This MCP plan must align with the current repo policy:

- [mcp-security-assessment.md](/Users/danielnortje/Documents/Pulse360/docs/security/mcp-security-assessment.md)
- [mcp-operational-contract.md](/Users/danielnortje/Documents/Pulse360/docs/contracts/mcp-operational-contract.md)
- [salesforce-databricks-mcp-setup.md](/Users/danielnortje/Documents/Pulse360/docs/setup/salesforce-databricks-mcp-setup.md)

Key constraints:

- non-official MCP servers are blocked until security review passes
- official-first server selection remains the default policy
- all new tool calls need explicit read/write boundaries
- OAuth/token scope must stay least-privilege
- audit logging and failure behavior must be defined before broadening write access

## Recommended Architecture

### Phase 1

Build a read-only Salesforce/Data Cloud MCP server that wraps:

- official Salesforce CLI for describe/query/inventory flows
- direct Salesforce REST API only where the CLI does not expose the required object or endpoint

Purpose:

- eliminate brittle shell parsing for environment inspection
- make schema and runtime checks repeatable
- formalize the Data Cloud validation gap as toolable checks

### Phase 2

Add safe write operations for known repeatable tasks:

- scoped metadata deploy
- permission-set assignment
- Databricks extract trigger
- Databricks export rebuild

Purpose:

- reduce repetitive operational work
- preserve source-first execution
- keep destructive or ambiguous actions outside the default tool surface

### Phase 3

Add Data Cloud configuration operations only after:

- security review passes
- exact API capability is proven
- manual fallback remains documented

Purpose:

- automate the subset of Data Cloud setup that is actually API-safe
- avoid pretending that UI-only configuration is fully automatable when it is not

## Tooling Boundary

### What the MCP should do

- inspect org and Data Cloud state
- compare source contracts to live field surfaces
- run deterministic validation queries
- trigger pre-approved, idempotent operational steps
- report manual follow-up when a workflow crosses an external/UI-only boundary

### What the MCP should not do initially

- broad destructive metadata changes
- profile edits
- production deployments
- connector creation or auth resets without explicit approval
- silent retries or self-healing flows that change org state without audit visibility

## Proposed Tool Surface

### Phase 1: Read-only tools

- `describe_sobject(org, sobject_name)`
- `list_account_fields(org)`
- `list_dmo_fields(org, dmo_name)`
- `list_data_streams(org)`
- `get_data_stream_status(org, stream_name)`
- `list_activation_targets(org)`
- `query_soql(org, soql)`
- `query_dmo(org, dmo_name, soql)`
- `compare_export_contract_to_account(org, contract_path)`
- `compare_export_contract_to_dmo(org, dmo_name, contract_path)`
- `report_unmapped_fields(org, dmo_name, contract_path)`

### Phase 2: Safe execution tools

- `deploy_salesforce_scope(org, manifest_or_paths)`
- `assign_permission_set(org, user_id_or_username, permission_set_name)`
- `run_databricks_extract(workspace, job_id)`
- `run_databricks_sql(workspace, warehouse_id, statement_name_or_path)`
- `rebuild_pulse360_gold_export(workspace)`
- `seed_demo_fixture_set(org, fixture_name)`

### Phase 3: Data Cloud configuration tools

- `list_data_cloud_sources(org)`
- `describe_data_cloud_source_fields(org, source_name)`
- `create_dmo_extension_field(org, dmo_name, field_spec)`
- `create_source_to_dmo_mapping(org, source_name, dmo_name, mapping_spec)`
- `list_copy_field_enrichment_mappings(org)`
- `create_copy_field_enrichment_mapping(org, mapping_spec)`
- `validate_copy_field_enrichment_realization(org, account_ids, expected_fields)`

### Phase 4: Evidence tools

- `capture_runtime_validation_report(org, account_ids)`
- `publish_linear_validation_update(issue_id, summary, evidence)`
- `generate_acceptance_checkpoint(scope_name)`

## External / Manual Boundary

The MCP must explicitly report when a workflow requires external action.

Examples:

- Data Cloud UI shows fields or mappings not exposed through current API surface
- connector re-auth is required
- admin review or approval is needed
- a field exists in source/export but not in the visible DMO schema

Required behavior:

- stop
- return the exact missing step
- include the object, field set, and validation evidence that triggered the stop

## Suggested Implementation Pattern

### Runtime

- FastMCP server in Python
- official Salesforce CLI and direct REST calls wrapped behind typed tool functions
- environment-based credential injection only
- no credentials stored in repo

### Auth model

- Salesforce:
  - reuse the approved org auth path already documented in the repo
  - prefer org aliases or secure auth config over ad hoc tokens
- Databricks:
  - reuse approved PAT/config path until a better official managed route is in place

### Logging

- tool name
- target org/workspace
- read/write classification
- request timestamp
- success/failure status
- returned object identifiers where relevant

## Acceptance Criteria

Phase 1 is complete when:

- a Codex session can inspect Salesforce Account fields, Data Cloud DMO fields, stream status, and activation status without raw shell parsing
- the MCP can report that the new GPT/provenance fields are missing on `ssot__Account__dlm`
- the MCP can compare the export contract to both Salesforce `Account` and the DMO surface

Phase 2 is complete when:

- the MCP can trigger safe operational actions already proven in the repo
- write operations are logged and bounded
- the repo runbooks remain the fallback if a tool fails

Phase 3 is complete when:

- the MCP can verify or create the missing DMO and Copy Field Enrichment path for the new field set
- the MCP can prove live writeback for at least one seeded regional account

## Recommended Execution Order

1. Finish the missing Data Cloud field-path proof for the new GPT/provenance fields.
2. Build the read-only MCP first.
3. Use the read-only MCP to validate the field-path gaps repeatably.
4. Add safe execution tooling for known-good operations.
5. Add Data Cloud configuration tooling only after security review and API proof.

## Near-Term Decision

The best next automation step is:

**implement a read-only Salesforce/Data Cloud MCP that makes the current Data Cloud gap visible and repeatable, before attempting broader write automation.**
