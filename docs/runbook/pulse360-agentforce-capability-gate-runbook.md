# Pulse360 Agentforce Capability Gate Runbook

## Purpose

Use this runbook before claiming that Pulse360 has a native Agentforce runtime in a target org.

The default posture is conservative: if a gate is not proven, describe the experience as a custom Salesforce assistant/action panel with Agentforce-ready metadata and actions.

## Preflight

Run the operator health check:

```bash
./scripts/check-codex-operator-health.sh
```

Run source validators:

```bash
./scripts/validate-agentforce-capability-gates.sh
./scripts/validate-agentforce-orchestrator.sh
./scripts/validate-contracts.sh
```

## Gate Review

1. Confirm Data 360 is provisioned and available.
2. Confirm Einstein generative AI is enabled.
3. Confirm Einstein Trust Layer setup has been reviewed for masking, audit, grounding, and policy.
4. Confirm `force-app/main/default/aiAuthoringBundles/Pulse360_Agent/Pulse360_Agent.agent` is deployed to the target org.
5. Confirm `default_agent_user` exists, is active, and has intended Agentforce permissions.
   For Pulse360, the agent user must also have the source-defined
   `Pulse360_Account_Intelligence_User` and `Governance_Case_Steward`
   permission sets.
6. Confirm the authoring bundle validates, publishes, and activates as a native `Bot`.
7. Confirm at least one native preview exchange succeeds against the activated published agent.
8. Confirm the intended user can see and use the native Agentforce surface in the target page or app.
9. Confirm configured actions are available to the native runtime:
   - `Pulse360GetAccountContextAction`
   - `Pulse360ExecuteSellerAction`
   - `Pulse360GetReviewContextAction`
   - `Pulse360GetDataCloudReviewEvidenceAction`
   - `Pulse360RecordGovernanceDecisionAction`
10. Confirm citations are available through native citation-capable Apex action output or fallback `source_refs` rendering.
11. Confirm mutating actions require explicit confirmation or approval.
12. Confirm generated outputs capture audit context.

For action proof, inspect preview traces as well as the human-readable response.
A conversational answer that mentions action fields is not enough. The trace
must show the relevant Pulse360 action was available to the specialized topic
and invoked, or the Builder/Studio UI must show an equivalent native action run.
If the router uses `@utils.transition`, confirm the record-specific prompt is
not lost before the action-bearing topic runs.

Minimum trace evidence for a read action:

- `enabled_tools` includes the expected Pulse360 action.
- `tools_sent` includes the expected Pulse360 action.
- `tool_invocations[].function.name` is the expected action.
- The action output includes `__action_execution_status__ = success`.
- The output includes the expected `payloadJson` or structured fields.

For direct Data Cloud evidence, also prove the backing object and invocable
outside the conversation trace:

- Query the configured DMO/DLO object such as `ssot__Account__dlm` or
  `Pulse360_Activation_Review_Queue__dlm` and confirm rows exist for the lookup
  key.
- Execute `Pulse360GetDataCloudReviewEvidenceAction.invoke` with the same
  lookup values.
- Confirm the response has `available = true`, the expected `dataCloudSource`,
  and a grounded `payloadJson`.
- Confirm the invocable proof performs no DML.
- If the activated published-agent preview transcript corroborates the result
  but the CLI trace JSON is empty, label that evidence as preview-response
  corroboration, not strict trace proof.

If a read action returns `List has no rows for assignment to SObject`, check
record-level visibility for the agent user before changing Apex. For governance
review, `Governance_Case_Steward` grants object and field access and should
grant view-all access for the governed review queue in demo/sandbox
environments.

If a permission set deploy fails because it references missing fields, deploy
the full source object contract first, then redeploy the permission set. For
Pulse360 governance, deploy `force-app/main/default/objects/Governance_Case__c`
with `Governance_Case_Steward`.

Minimum evidence for mutating-action gates:

- For seller actions, invoke a high-risk action such as `open_opportunity`
  without approved mode and confirm the result is `ApprovalRequired` with
  `SELLER_APPROVAL_REQUIRED`.
- Confirm the blocked seller invocation performs no DML and creates no Task or
  Opportunity.
- For governance decisions, invoke with an `approvedByUser` value that does not
  match the current user and confirm the action fails before update.
- Re-query the governance case after the blocked attempt and confirm decision,
  audit, downstream, and last-modified fields did not change.
- Do not run the approved mutation path unless the operator has explicitly
  reviewed and approved the exact record, action, and expected field changes.
- After an approved mutation run, re-query the created or updated record and
  confirm the primary object, record ID, field values, DML count, and absence of
  unintended companion records.

Minimum evidence for user-facing UI gates:

- Confirm the Account FlexiPage contains `c:pulse360AgentPanel` and the target
  org has the deployed `pulse360AgentPanel` Lightning component bundle.
- Browser-render an Account record and confirm the custom Pulse360 seller
  workspace, evidence/trust cues, assistant response, and guarded action buttons
  are visible.
- Confirm the Governance Case FlexiPage contains
  `c:pulse360GovernanceSnapshot`, `c:pulse360GovernanceMatchEvidence`,
  `c:pulse360GovernanceDecisionWorkspace`, and
  `c:pulse360GovernanceAuditOutcome`.
- Browser-render a Governance Case record and confirm the steward snapshot,
  match evidence, decision workspace, and audit outcome are visible before
  claiming steward UI readiness.
- If the source intentionally blocks ACC/native side-panel launch, do not call
  the page experience a native in-page Agentforce side panel. Describe it as a
  custom Pulse360 assistant/action panel until ACC support is enabled and proven.

## Decision

Use this language:

- If every gate passes: `native Agentforce runtime verified for pulse360-agent-target`.
- If read actions and direct Data Cloud evidence are proven but mutating
  approvals have only been block-tested: `native Agentforce agent published and activated
  with trace-proven Pulse360 seller and governance read actions and direct Data
  Cloud evidence proven through SOQL/invocable execution; mutating actions are
  fail-closed but approved mutation execution remains gated`.
- If seller mutation is approved and verified but governance mutation remains
  block-tested only: `native Agentforce agent published and activated with
  trace-proven Pulse360 read actions, direct Data Cloud evidence, and approved
  seller opportunity execution; governance decision execution remains gated`.
- If seller and governance mutations are both approved and verified:
  `native Agentforce agent published and activated with trace-proven Pulse360
  read actions, direct Data Cloud evidence, approved seller opportunity
  execution, and approved governance decision execution; final UI surface
  validation remains before business-user release`.
- If seller and governance mutations are verified and the custom Account seller
  surface is browser-validated but governance record render or native in-page
  ACC side-panel support remains unproven: `native Agentforce agent published
  and activated with trace-proven Pulse360 read actions, direct Data Cloud
  evidence, approved seller opportunity execution, approved governance decision
  execution, and a visually validated custom Account seller surface; governance
  record-page browser render and native in-page ACC side-panel handoff remain
  gated`.
- If seller and governance mutations are verified and both custom Account and
  Governance Case surfaces are browser-validated, but native in-page ACC
  side-panel support remains unproven: `native Agentforce agent published and
  activated with trace-proven Pulse360 read actions, direct Data Cloud evidence,
  approved seller opportunity execution, approved governance decision execution,
  and visually validated custom Account seller and Governance Case steward
  surfaces; native in-page ACC side-panel handoff remains gated`.
- If read actions are trace-proven but direct Data Cloud evidence or mutating
  approvals remain unproven: `native Agentforce agent published and activated
  with trace-proven Pulse360 seller and governance read actions; direct Data
  Cloud evidence and mutating approval actions still gated`.
- If publish, activation, and preview pass but live actions remain unproven: `native Agentforce agent published and previewed; live-action grounding still gated`.
- If metadata exists but runtime is not demonstrated: `Agentforce metadata and custom Salesforce assistant/action panel`.
- If runtime is unavailable: `fallback Salesforce assistant/action panel`.
- If citation support is unavailable: `fallback source references rendered in Salesforce UI`.

## Evidence To Attach

- screenshots or CLI/org evidence for runtime visibility
- active agent user evidence
- action registration evidence
- sample native agent exchange
- citation output evidence
- approval prompt evidence
- audit event/output payload evidence
