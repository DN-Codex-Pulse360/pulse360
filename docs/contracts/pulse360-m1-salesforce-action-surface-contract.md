# Pulse360 M1 Salesforce Action Surface Contract

## Purpose

Define how the M1 Account Hierarchy operational profile appears in Salesforce and what actions users can take from each surface.

This is an altitude-3 contract. Salesforce should show a weighted, action-ready summary by default and keep raw Databricks/Data Cloud detail behind drill-through or governance evidence views.

## Source Inputs

Primary source contract:

- `docs/contracts/pulse360-m1-data-cloud-operational-profile-contract.md`

Primary Salesforce services and components:

- `Pulse360SellerWorkspaceService.getSellerWorkspace`
- `Pulse360PlannerWorkspaceService.getPlannerWorkspace`
- `Pulse360SellerOrchestratorService.executePulse360SellerAction`
- `Pulse360AgentOrchestratorService.getPulse360DataCloudReviewEvidence`
- `Pulse360AgentOrchestratorService.recordPulse360GovernanceDecision`
- `pulse360GroupRevenueReveal`
- `pulse360SellerWorkspaceGroup`
- `pulse360RecommendedMovePanel`
- `pulse360PlannerWorkspace`
- `governanceCaseReview`

## Surface Rules

1. Account and seller surfaces show summary, confidence, freshness, and the next action first.
2. Full hierarchy graph detail stays behind group drill-through and trust/governance evidence surfaces.
3. Lookup relationships must use real Salesforce record IDs when an entity is CRM-covered.
4. Evidence fields are read-only in CRM-facing surfaces.
5. Decision and execution controls create or update Salesforce artifacts: Task, Opportunity, Governance Case decision, routing follow-up, or planner action.
6. Custom LWC/Apex helper panels must not be described as native Agentforce agents unless target-org native Agentforce runtime support has been verified.

## M1 User Journeys

| Journey | Primary surface | Default view | User action | Salesforce artifact |
| --- | --- | --- | --- | --- |
| Seller sees true group scale | `pulse360GroupRevenueReveal` | group revenue, visible revenue, known and covered subsidiaries | open entity, create task, ask assistant | Account navigation or Task |
| Seller chooses next move | `pulse360RecommendedMovePanel` | recommended play, confidence, why-now, impact | create opportunity, create task, route specialist | Opportunity or Task |
| Planner ranks coverage gaps | `pulse360PlannerWorkspace` | ranked groups, coverage gaps, planning action queue | assign owner, open account context, route follow-up | Task or planning follow-up |
| Steward validates weak hierarchy/identity | `governanceCaseReview` | evidence summary, direct Data Cloud evidence availability | approve, reject, defer | `Governance_Case__c` decision update |
| Manager checks trust before action | trust/governance support panels | sources, freshness, uncertainty | open evidence or block action | no mutation unless explicit action |

## Action Contract

Every M1 action should carry:

- `record_id`: current Salesforce Account or Governance Case ID
- `surface_context`: source UI surface
- `action_type`: normalized action intent
- `target_entity`: human-readable entity or group
- `target_record_id`: Salesforce record ID when the target is CRM-covered
- `crm_safe_execution_key`: Account or Governance Case ID used for mutation
- `recommended_play`: user-readable action label
- `reasoning`: why-now explanation
- `confidence_label`: human-readable confidence cue
- `freshness_label`: freshness cue
- `evidence_refs`: compact source IDs/citations
- `approval_required`: whether mutation needs explicit approval
- `expected_artifact`: Salesforce artifact to create or update

## Supported First-Slice Actions

| Action type | Runtime behavior | Approval |
| --- | --- | --- |
| `create_task` | Creates a Task on the current or target Account. | Auto-executable |
| `route_specialist` | Creates a specialist-routing Task with target entity and evidence context. | Auto-executable |
| `open_entity` | Navigates to a CRM-covered Account when `target_record_id` is valid. | No mutation |
| `open_opportunity` | Creates an Opportunity after explicit approval. | Approval required |
| `escalate_governance` | Opens or routes to governance review context. | Review required |
| `record_governance_decision` | Updates `Governance_Case__c` after direct Data Cloud evidence read succeeds. | Approval required |

## M1 Guardrails

- `group_entity_id` and `operational_profile_id` are never Salesforce mutation keys.
- If `target_record_id` is absent or not a valid Salesforce record ID, the action must fall back to the current Account context or become a non-mutating review action.
- Governance decisions fail closed when direct Data Cloud evidence is unavailable.
- High-risk seller mutations such as opportunity creation require approval.
- Raw hierarchy payload may support rendering, but the default action contract uses summary fields and compact source references.

## Validation

Validated by:

- `scripts/validate-m1-salesforce-action-surface.sh`
- `scripts/validate-surface-architecture.sh`
- `scripts/validate-multi-surface-experience.sh`

