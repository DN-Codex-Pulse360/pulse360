# DAN-300 Salesforce DX MCP Operator Layer Evidence

Date: 2026-04-26

## Summary

The Pulse360 Salesforce DX MCP operator layer has been registered for the
non-production target org and validated with both Salesforce CLI fallback
evidence and direct Salesforce DX MCP tool calls. After restarting/reloading
Codex, the Salesforce DX MCP tool surface became available in the active
session.

## Configuration Proven

Registered MCP:

```bash
salesforce_dx
```

Registration command:

```bash
codex mcp add salesforce_dx -- npx -y @salesforce/mcp --orgs pulse360-agent-target --toolsets orgs,metadata,data,testing,code-analysis --no-telemetry
```

Confirmed registration shape:

```text
salesforce_dx  npx  -y @salesforce/mcp --orgs pulse360-agent-target --toolsets orgs,metadata,data,testing,code-analysis --no-telemetry
```

Package check:

```text
@salesforce/mcp version: 0.30.7
binary: sf-mcp-server
description: MCP Server for interacting with Salesforce instances
```

Salesforce CLI check:

```text
@salesforce/cli/2.125.2
```

## Target Org Scope

The registration is constrained to:

```text
pulse360-agent-target
```

The target org is connected through Salesforce CLI. Raw org auth output was not
captured here because it can include sensitive credentials.

## Read-Only Salesforce Data Proof

Fallback command used before the restarted session exposed MCP tools:

```bash
sf data query -o pulse360-agent-target -q "SELECT Id, Name, Status__c, Decision_Status__c, Recommended_Action__c FROM Governance_Case__c LIMIT 3" --json
```

Result:

```text
status: success
records returned: 1
sample record:
  Name: GC-00000
  Status__c: Approved
  Decision_Status__c: Approved
  Recommended_Action__c: Approve Merge
```

Interpretation:

- Salesforce target-org access is working.
- `Governance_Case__c` exists in the target org.
- The stewardship fields required by the Databricks feedback loop are queryable.
- This was read-only; no Salesforce data was mutated.

Direct Salesforce DX MCP proof after restart:

```text
tool: mcp__salesforce_dx__.run_soql_query
target alias: pulse360-agent-target
query: SELECT Id, Name, Status__c, Decision_Status__c, Recommended_Action__c FROM Governance_Case__c LIMIT 3
records returned: 1
sample record:
  Name: GC-00000
  Status__c: Approved
  Decision_Status__c: Approved
  Recommended_Action__c: Approve Merge
```

Interpretation:

- The Salesforce DX MCP `data` toolset is visible and operational.
- The MCP can query the target org directly without CLI fallback.
- This was read-only; no Salesforce data was mutated.

## Deploy Validation Proof

An initial validation attempt using `--test-level NoTestRun` failed because this
Salesforce CLI version does not accept `NoTestRun` for `sf project deploy
validate`.

Successful validation command:

```bash
sf project deploy validate --source-dir force-app/main/default/objects/Governance_Case__c --target-org pulse360-agent-target --test-level RunLocalTests --json
```

Result:

```text
validation status: Succeeded
checkOnly: true
deploy id: 0AfdL00000Ze7JbSAJ
components validated: 39 / 39
component errors: 0
tests completed: 36 / 36
test errors: 0
```

Interpretation:

- Source-backed governance metadata validates against the target org.
- Local Apex tests pass for this validation path.
- No real deployment occurred because the operation was check-only.

## Known Gap

Closed 2026-04-26:

- Direct Salesforce DX MCP SOQL execution was proven after restart.
- Direct Salesforce DX MCP Code Analyzer rule selection was proven with
  `Apex:Recommended`.
- Direct Salesforce DX MCP Apex testing was proven with
  `GovernanceCaseDecisionStampingTest`.

Current limitation:

- Check-only deploy validation remains captured through Salesforce CLI because
  the available MCP `deploy_metadata` tool is framed as a deploy operation, not
  an explicit check-only validation operation. Real deploys remain
  approval-gated.

## Direct MCP Test Proof

Code Analyzer toolset proof:

```text
tool: mcp__salesforce_dx__.list_code_analyzer_rules
selector: Apex:Recommended
result: success
rules returned: NoTrailingWhitespace, AvoidGetHeapSizeInLoop, MinVersionForAbstractVirtualClassesWithPrivateMethod
```

Apex testing toolset proof:

```text
tool: mcp__salesforce_dx__.run_apex_test
target alias: pulse360-agent-target
test level: RunSpecifiedTests
class: GovernanceCaseDecisionStampingTest
outcome: Passed
tests ran: 3
passing: 3
failing: 0
test run id: 707dL000016oetW
```

## Runbook

Operational guidance is captured in:

```text
docs/runbook/dan-300-salesforce-dx-mcp-operator-layer-runbook.md
```
