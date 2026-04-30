# Contract: Pulse360 Agentforce Orchestrator V1

## Summary

`Pulse360 Agent` is the repo-backed orchestration contract for the Salesforce-native agent runtime.

V1 uses one orchestration contract with two specialized subagents and split runtime services:

- `Seller Account Manager`
- `Governance Review Manager`

The runtime is intentionally action-led. Instructions support explanation tone and low-risk follow-through, but deterministic business control lives in Apex actions, Flow-invocable wrappers, LWC entrypoints, and approval gates.

## Runtime Entry Points

The orchestration contract is invoked from Salesforce-native surfaces that already exist in source:

- Account record page via [pulse360SellerWorkspace](/Users/danielnortje/Documents/Pulse360/force-app/main/default/lwc/pulse360SellerWorkspace/pulse360SellerWorkspace.js)
- Governance Case record page via [governanceCaseReview](/Users/danielnortje/Documents/Pulse360/force-app/main/default/lwc/governanceCaseReview/governanceCaseReview.js)
- seller-side Apex and Flow via [Pulse360SellerOrchestratorService.cls](/Users/danielnortje/Documents/Pulse360/force-app/main/default/classes/Pulse360SellerOrchestratorService.cls)
- governance-side Apex and Flow via [Pulse360AgentOrchestratorService.cls](/Users/danielnortje/Documents/Pulse360/force-app/main/default/classes/Pulse360AgentOrchestratorService.cls)

Target-state rule:

- seller runtime methods live only on `Pulse360SellerOrchestratorService`
- governance runtime methods live only on `Pulse360AgentOrchestratorService`
- the governance runtime does not expose seller compatibility methods

## Org Binding

The repo-backed agent definition is portable, but its default user binding is environment-specific.

- source file: [Pulse360_Agent.agent](/Users/danielnortje/Documents/Pulse360/force-app/main/default/aiAuthoringBundles/Pulse360_Agent/Pulse360_Agent.agent)
- current binding: `default_agent_user: "dnortje.df7838b67939@agentforce.com"`

Migration rule:

- do not assume the current `default_agent_user` exists in every target org
- before deploying to a new org, confirm the bound user exists, is active, and has the intended Agentforce access
- if the target org uses a different agent user, update the metadata binding as part of the migration review rather than treating it as a portable constant

## Action API Names

These API names are the stable orchestration surface for V1:

- seller service: `getPulse360AccountContext`
- seller service: `executePulse360SellerAction`
- governance service: `getPulse360ReviewContext`
- governance service: `getPulse360DataCloudReviewEvidence`
- governance service: `recordPulse360GovernanceDecision`

Flow-invocable wrappers expose the same capabilities through:

- `Pulse360GetAccountContextAction`
- `Pulse360GetReviewContextAction`
- `Pulse360GetDataCloudReviewEvidenceAction`
- `Pulse360ExecuteSellerAction`
- `Pulse360RecordGovernanceDecisionAction`

## Subagent Boundaries

### Seller Account Manager

Purpose:

- turn activated account intelligence into a concrete seller move
- prioritize the best target entity and recommended play
- auto-execute low-risk follow-up artifacts
- pause high-risk CRM mutations for explicit approval

Grounding:

- CRM-first in V1
- uses activated Account intelligence, hierarchy payload, recommended actions, and source refs already synced into Salesforce
- can deep-link to a real Salesforce Account when `target_record_id` or `crm_record_id` is valid

### Governance Review Manager

Purpose:

- explain duplicate-review evidence
- block final decisions when live evidence is unavailable
- record structured stewardship decisions with audit semantics

Grounding:

- direct Data Cloud evidence read is mandatory in V1
- the runtime reads from the Data Cloud review surface directly rather than trusting only copied CRM fields
- writes the approved/rejected/deferred outcome back to `Governance_Case__c`

## Standard Payload Shapes

### AccountContext

- `accountId`
- `accountName`
- `hierarchyPayload`
- `primaryAction`
- `secondaryActions`
- `sourceRefs`
- `freshness`
- `healthMetrics`

### ReviewContext

- `governanceCaseId`
- `candidatePairId`
- `leftAccountId`
- `rightAccountId`
- `confidence`
- `reasoning`
- `currentStatus`
- `auditState`

### ReviewEvidence

- `entityMatches`
- `attributeValidity`
- `hierarchyImpact`
- `sourceRefs`
- `evidenceTimestamp`
- `dataCloudSource`
- `available`
- `failClosed`

### ExecutionRequest

- `subagent`
- `actionType`
- `recordId`
- `targetRecordId`
- `approvalRequired`
- `userMessage`
- `sessionId`

### ExecutionResult

- `status`
- `createdRecordIds`
- `agentSummary`
- `approvalState`
- `auditEventId`
- `errorCode`

## Approval Policy

Low-risk seller actions can auto-execute in V1:

- `create_task`
- `route_specialist`
- `launch_agent`

High-risk seller actions require approval before mutation:

- `open_opportunity`
- `create_opportunity`

Governance decisions are always approval-gated and always require a successful direct Data Cloud evidence read:

- `Approved`
- `Rejected`
- `Deferred`

## Data Strategy

The runtime must not depend on the local read-only MCP service under `services/salesforce_data_cloud_mcp`.

V1 split:

- seller orchestration is CRM-first
- governance orchestration is direct-Data-Cloud-first

If the direct Data Cloud review read fails, governance execution fails closed and the steward remains in review mode.

## Acceptance Expectations

- no copy-paste task flow for the primary seller path
- no direct record update fallback for governance decision commit
- high-risk mutations pause for approval
- governance decisions are blocked when direct Data Cloud evidence is unavailable
- the runtime remains source-backed in Apex, LWC, permission sets, and validation scripts
