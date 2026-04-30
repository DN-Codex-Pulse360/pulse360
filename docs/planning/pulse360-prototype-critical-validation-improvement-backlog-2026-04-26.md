# Pulse360 Prototype Critical Validation Improvement Backlog

Date: 2026-04-26

## Context

The current Pulse360 build proves the governed account-intelligence spine across
Databricks, Salesforce Data Cloud, Salesforce CRM, and Databricks feedback
metrics. The broader value proposition remains larger than the implemented
prototype.

This backlog adapts the critical validation comments raised after reviewing the
prototype against the RevOps value proposition.

## Delivery Priority Reset

The delivery sequence is now:

1. Data flows and account enrichment first: Databricks -> Data Cloud ->
   Salesforce CRM -> Databricks, plus other Databricks sources and AI
   enrichment.
2. Agentforce / Headless 360 second: agents, agentic flows, agentic fields, and
   native runtime proof against the governed data foundation.
3. CRM UI and UX last: visual polish and Salesforce workspace improvements only
   after the data and agentic contracts are stable.

See `docs/planning/pulse360-delivery-priority-stack-2026-04-26.md`.

## Improvement Areas

### 1. LLM Evidence Harness For Broader Proof

The prototype should use GPT/Claude-style research agents to test unproven areas
more aggressively, while preserving source-first guardrails.

LLMs may be used to:

- discover public sovereign identifiers and registry references
- extract firmographic, hierarchy, intent, renewal-risk, and buying-committee
  evidence from approved public or synthetic sources
- produce structured facts with source URLs, document references, extraction
  timestamps, confidence scores, and competing-evidence notes
- generate test cases for activation guardrails

LLMs must not be treated as the source of truth. A row is activation-safe only
when the output is source-bound, CRM-anchored, confidence-scored, and passes the
existing Databricks activation guardrails.

Priority status: Priority 1. This should be worked before Agentforce expansion
or CRM UX polish.

### 2. Salesforce DX MCP Operator Layer

The Salesforce side needs a Salesforce DX MCP server or equivalent local MCP
operator layer. The current repo relies on Salesforce CLI, custom scripts, and
manual judgement. That works for expert operation, but it is not yet a reusable
agentic delivery surface.

The MCP layer should start read-only and validation-first:

- list orgs and auth state
- query Salesforce data with SOQL
- inspect source-backed metadata
- retrieve scoped metadata for drift checks
- validate deployment manifests
- run Apex tests
- run Salesforce Code Analyzer where available

Mutating capabilities such as deploy, permission assignment, seed data, and org
configuration must remain approval-gated.

Current status:

- Linear issue: DAN-300
- Salesforce DX MCP registration added for `pulse360-agent-target`
- toolsets: `orgs,metadata,data,testing,code-analysis`
- read-only SOQL proof completed through Salesforce CLI fallback
- check-only deploy validation completed with `RunLocalTests`
- validation result: 39 / 39 components, 36 / 36 tests, 0 errors
- direct MCP SOQL proof completed after restart
- direct MCP Code Analyzer rule discovery completed with `Apex:Recommended`
- direct MCP Apex test proof completed: `GovernanceCaseDecisionStampingTest`,
  3 / 3 passing
- remaining limitation: check-only deploy validation remains CLI-backed because
  the exposed MCP deploy tool is not an explicit check-only validation tool
- runbook: `docs/runbook/dan-300-salesforce-dx-mcp-operator-layer-runbook.md`
- evidence: `docs/evidence/dan-300-salesforce-dx-mcp-operator-layer-2026-04-26.md`

### 3. Agentforce / Headless 360 Reassessment

The previous Agentforce assessment was correct for the target org runtime state,
but too narrow architecturally. Pulse360 should now assess Agentforce through
Headless 360, Agent API, Agentforce Conversation Client API, Models API, and MCP
tooling, not only through a visible Salesforce page surface.

The new proof target should be:

- prove whether the org can invoke a native Agentforce runtime headlessly
- prove whether a custom LWC can invoke a native Agentforce session/action path
- prove whether Data Cloud/Databricks context can ground the interaction
- preserve fallback language when the implementation is only LWC/Apex-driven

Priority status: Priority 2. Start after Priority 1 produces stable governed
evidence contracts for agents to consume.

### 4. Databricks Dashboard Innovation Standard

The current dashboard is functionally valid but should move toward a decision
cockpit standard:

- proof-strip journey: Databricks evidence -> Data Cloud visible -> Salesforce
  decision -> Databricks feedback
- trust badges for source-bound, activation-safe, review-only, and blocked rows
- buyer-question tabs: "Can I trust it?", "What changed?", "What action is safe?"
- filters for source product, confidence band, run, and activation state
- concise narrative panels before raw tables
- Genie or semantic-layer readiness for analyst exploration

Priority status: Priority 3 unless the dashboard work is directly needed to
validate Priority 1 data quality. Visual polish should not lead the build.

### 5. Synthetic Enterprise Source Pack

To test the full RevOps proposition without paid data providers, build synthetic
enterprise source packs that simulate customer systems and expected ground truth.

Candidate synthetic sources:

- ERP: invoices, orders, billing entities, product ownership
- EPM: forecast, plan, quota, territory coverage, budgets
- Support: cases, severity, SLA breaches
- Contracts: entitlements, renewals, product terms
- Internal hierarchy: franchise, partner, supplier, subsidiary master
- Marketing/intent: web activity, campaigns, topic surges
- Product telemetry: adoption, usage, active users, feature exposure

Every synthetic source must include schema contracts, source-system metadata,
generation seed, expected ground truth, and known edge cases for validation.

Priority status: Priority 1. Pair this with the LLM evidence harness so the
data layer can prove RevOps scenarios without paid provider dependencies.

## Revised Prototype Classification

- Proven live: Databricks/Data Cloud/Salesforce governance review and feedback
  loop.
- LLM-testable now: sovereign identity, firmographic enrichment, hierarchy,
  ICP, intent, renewal, and buying-committee evidence.
- Synthetic-data-testable now: ERP, EPM, support, contract, product, and
  internal hierarchy scenarios.
- Platform-gated: Headless 360, native Agentforce runtime, Models API, MCP
  automation.
- Not production-proven: commercial provider feeds, BYOM model serving,
  automated retraining, merge execution, and the full six-module RevOps product.
