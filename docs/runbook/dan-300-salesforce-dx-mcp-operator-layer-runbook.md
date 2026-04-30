# DAN-300 Salesforce DX MCP Operator Layer Runbook

Date: 2026-04-26

## Purpose

This runbook defines the Salesforce DX MCP operator layer for Pulse360 source
delivery. It exists so Codex can use first-party Salesforce tooling for
read-only inspection, contract validation, deploy validation, Apex tests, and
code analysis without turning every Salesforce operation into a bespoke CLI
workflow.

The operator layer is not a substitute for the repo rules in `AGENTS.md`.
Deployments, permission changes, seeded data loads, and org configuration
changes remain approval-gated.

## Approved Scope

The MCP registration is scoped to the non-production target org alias:

```bash
pulse360-agent-target
```

Register or repair the MCP with:

```bash
codex mcp add salesforce_dx -- npx -y @salesforce/mcp --orgs pulse360-agent-target --toolsets orgs,metadata,data,testing,code-analysis --no-telemetry
```

Confirm registration:

```bash
codex mcp list
```

Expected registration shape:

```text
salesforce_dx  npx  -y @salesforce/mcp --orgs pulse360-agent-target --toolsets orgs,metadata,data,testing,code-analysis --no-telemetry
```

## Guardrails

- Use approved non-production orgs only.
- Keep the MCP scoped to explicit org aliases. Do not use broad all-org access
  for normal Pulse360 work.
- Do not use non-GA Salesforce MCP tools unless a specific task is reviewed and
  approved.
- Start with read-only and validation-first operations.
- Treat Salesforce CRM execution as separate from Databricks intelligence and
  Salesforce Data Cloud operational context.
- Never store Salesforce tokens, Databricks tokens, OpenAI keys, Anthropic keys,
  or other secrets in repo files.
- If MCP tools are registered but not visible to the active Codex session,
  restart or reload Codex and retry before changing the registration.

## Supported Operator Tasks

Read-only tasks:

- list org aliases and auth state
- run scoped SOQL queries
- inspect source-backed metadata
- retrieve scoped metadata for drift checks

Validation tasks:

- run deploy validation against source metadata
- run Apex tests
- run Salesforce Code Analyzer where available
- capture validation evidence in `docs/evidence`

Approval-gated tasks:

- real metadata deploys
- permission set assignments
- seeded data loads
- org configuration mutations
- Data Cloud setup mutations

## Health Check

Before cross-system work, run:

```bash
./scripts/check-codex-operator-health.sh
```

For deeper MCP coverage:

```bash
PULSE360_HEALTH_FULL_MCP=1 ./scripts/check-codex-operator-health.sh
```

## Read-Only Proof Pattern

Use MCP tools when they are visible in the active Codex session. If the MCP is
registered but the tool surface has not loaded, use Salesforce CLI as a fallback
and record that limitation in evidence.

Fallback SOQL example:

```bash
sf data query \
  -o pulse360-agent-target \
  -q "SELECT Id, Name, Status__c, Decision_Status__c, Recommended_Action__c FROM Governance_Case__c LIMIT 3" \
  --json
```

This proves:

- the target alias is authenticated
- Salesforce data access works
- the expected governance object and fields exist in the org

## Deploy Validation Pattern

Use check-only validation before any real deploy:

```bash
sf project deploy validate \
  --source-dir force-app/main/default/objects/Governance_Case__c \
  --target-org pulse360-agent-target \
  --test-level RunLocalTests \
  --json
```

Current Salesforce CLI versions reject `NoTestRun` for `sf project deploy
validate`. Use one of the accepted values instead:

- `RunLocalTests`
- `RunSpecifiedTests`
- `RunRelevantTests`
- `RunAllTestsInOrg`

## Evidence Requirements

Every operator-layer proof should capture:

- command or MCP operation used
- target org alias
- read-only versus mutation status
- validation result
- test counts and failures, where applicable
- whether MCP tools were directly used or Salesforce CLI fallback was required
- links to Linear issue updates

Do not paste raw auth output or tokens into evidence notes.
