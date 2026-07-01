# Pulse360 Agentforce Builder Preview Runtime Evidence - 2026-07-01

## Scope

This note captures browser-validated evidence from the Salesforce Agentforce Builder preview for the Pulse360 proactive account coach.

Validated org surface:

- Salesforce setup route: `/lightning/setup/EinsteinCopilot/home`
- Agentforce Builder route: `/AgentAuthoring/agentAuthoringBuilder.app#/project?projectId=1bYdL00000072hpUAA&projectVersionId=1bZdL000000Om8LUAS`
- Active builder artifact: `Pulse360 Agent`, Version 6 (Draft)
- Agent ID shown in Builder: `0XxdL000003Ns2nSAC`
- Builder session ID for preview evidence: `97d2140e-ec2a-4afd-a975-2ff2f431c0a8`

## Builder Configuration Evidence

The Agentforce Agents setup list shows `Pulse360 Agent` as a Service Agent with Active set to true.

The Agentforce Builder shows:

- Agent name: `Pulse360 Agent`
- Developer name: `Pulse360_Agent`
- Description: internal Pulse360 Agentforce assistant for proactive account signal explanation and governed seller recommendations.
- Subagent: `Proactive Account Coach`
- Action: `Get Proactive Signal Brief`
- Action API name: `get_proactive_signal_brief`
- Reference action type: Apex
- Reference action category: Invocable Method
- Required input: `Account Id`

The Builder Problems panel showed no blocking errors for the action configuration during inspection.

## Preview Runtime Prompt

Prompt submitted in Live Test Mode:

```text
For Account Id 001dL00002HTb4cQAD, explain the proactive Northstar signal, include source evidence, freshness, confidence, and governed next moves.
```

The agent first returned an approval-style confirmation before executing the high-impact account intelligence retrieval:

```text
I'm going to pull up a summary of the proactive Northstar signal for your account, including where the information comes from, how recent and reliable it is, and suggested next steps. Would you like me to go ahead with this? Please reply "yes" to proceed or "no" to cancel.
```

After the confirmation response `yes`, the preview executed the native Agentforce action and returned a grounded account signal brief.

## Preview Runtime Result

The returned brief identified:

- Account: Northstar Foods Group
- Signal type: Maintenance coverage gap
- Signal label: Coverage-led review
- Priority: High
- Signal score: 88/100
- Routing confidence: 0.82, high
- Freshness: source evidence and generated narrative dated 2026-06-29
- Jurisdiction context: ASEAN

The evidence cited six source-change events:

- Installed base change: `Evt Product Installed Base Id 20260629 001`
- Warranty event: `Evt Service Warranty Id 20260629 002`
- Contract gap: `Evt Erp Contract Id 20260629 003`
- Spare-parts demand: `Evt Partner Spares Th 20260629 004`
- CRM hierarchy: `Evt Crm Duplicate Sg 20260629 005`
- Service case growth: `Evt Service Cases Ph 20260629 006`

The governed next moves returned by the agent were advisory and approval-gated:

- Route a service-specialist review without writing to CRM.
- Prepare an approved seller task for the CRM account team, requiring confirmation.
- Require explicit approval before any commercial mutation such as opportunity creation.

## Trace Evidence

The Builder trace showed successful execution of the native action path:

- Input step executed successfully.
- Topic Selector step executed successfully.
- Action step `get proactive signal brief` executed successfully.
- Output Evaluation `GROUNDED` executed successfully.

The trace recorded the action duration as approximately 51.24 seconds and the grounded output evaluation as approximately 1.32 seconds.

## Boundary

This validates that the active Agentforce Builder preview can route a seller-style prompt through the `Proactive Account Coach` subagent, request confirmation, execute the `get_proactive_signal_brief` Apex-backed action, and return a grounded Northstar account brief.

This does not yet prove downstream CRM mutation. The current behavior is intentionally advisory unless a future task/opportunity action is separately configured with explicit confirmation and approval policy.
