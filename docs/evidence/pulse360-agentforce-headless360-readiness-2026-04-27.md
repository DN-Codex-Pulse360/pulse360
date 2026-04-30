# Pulse360 Agentforce / Headless 360 Readiness Evidence

Date: 2026-04-27
Updated: 2026-04-28
Org alias: `pulse360-agent-target`

## Objective

Validate the source-backed Agentforce and Headless 360 action layer after the
Databricks data layer was closed and scheduled.

## Source Assets

Agent metadata:

```text
force-app/main/default/aiAuthoringBundles/Pulse360_Agent/Pulse360_Agent.agent
force-app/main/default/aiAuthoringBundles/Pulse360_Agent/Pulse360_Agent.bundle-meta.xml
```

Capability gates:

```text
config/agentforce/pulse360-capability-gates.yaml
```

Runtime contracts and runbooks:

```text
docs/contracts/pulse360-agentforce-orchestrator-v1.md
docs/runbook/pulse360-agentforce-capability-gate-runbook.md
```

Headless action services:

```text
force-app/main/default/classes/Pulse360SellerOrchestratorService.cls
force-app/main/default/classes/Pulse360AgentOrchestratorService.cls
force-app/main/default/classes/Pulse360GetAccountContextAction.cls
force-app/main/default/classes/Pulse360ExecuteSellerAction.cls
force-app/main/default/classes/Pulse360GetReviewContextAction.cls
force-app/main/default/classes/Pulse360GetDataCloudReviewEvidenceAction.cls
force-app/main/default/classes/Pulse360RecordGovernanceDecisionAction.cls
```

## Validation Commands

```bash
./scripts/validate-agentforce-capability-gates.sh
./scripts/validate-agentforce-orchestrator.sh
sf project deploy start --target-org pulse360-agent-target --dry-run --source-dir force-app/main/default/aiAuthoringBundles --json
sf project deploy start --target-org pulse360-agent-target --source-dir force-app/main/default/aiAuthoringBundles --json
sf apex run test --target-org pulse360-agent-target --tests Pulse360AgentOrchestratorServiceTest,Pulse360SellerOrchestratorServiceTest,Pulse360SellerWorkspaceServiceTest,Pulse360HealthScanServiceTest --wait 10 --json
sf org list metadata --target-org pulse360-agent-target --metadata-type AiAuthoringBundle --json
sf agent validate authoring-bundle --target-org pulse360-agent-target --api-name Pulse360_Agent --json
sf agent publish authoring-bundle --target-org pulse360-agent-target --api-name Pulse360_Agent --skip-retrieve --json
sf agent activate --target-org pulse360-agent-target --api-name Pulse360_Agent --json
sf data query --target-org pulse360-agent-target --query "SELECT Id, BotDefinition.DeveloperName, VersionNumber, Status FROM BotVersion WHERE BotDefinition.DeveloperName = 'Pulse360_Agent' ORDER BY VersionNumber DESC LIMIT 5" --json
sf agent preview start --target-org pulse360-agent-target --api-name Pulse360_Agent --json
sf agent preview send --target-org pulse360-agent-target --api-name Pulse360_Agent --session-id <preview-session-id> --utterance "Summarize what you can do for Pulse360 seller account management and governance review." --json
sf agent preview end --target-org pulse360-agent-target --api-name Pulse360_Agent --session-id <preview-session-id> --json
sf project deploy start --target-org pulse360-agent-target --dry-run --source-dir force-app/main/default/aiAuthoringBundles --json
sf data query --target-org pulse360-agent-target --query "SELECT Id, ssot__Id__c, External_Legal_Name__c, Unified_Profile_Id__c, Validity_Score_External__c, Last_Synced_Timestamp__c FROM ssot__Account__dlm WHERE ssot__Id__c IN ('001dL000024wgYRQAY','001dL000024weudQAA') LIMIT 5" --json
sf apex run --target-org pulse360-agent-target
```

## Validation Results

Source validators:

```text
[PASS] Agentforce capability gate validation completed
[PASS] Agentforce orchestrator validation completed
```

Agent metadata dry-run:

| Field | Value |
| --- | --- |
| Deployment ID | `0AfdL00000ZhG8bSAF` |
| Check only | `true` |
| Status | `Succeeded` |
| Component type | `AiAuthoringBundle` |
| Component full name | `Pulse360_Agent` |

Agent metadata deploy:

| Field | Value |
| --- | --- |
| Deployment ID | `0AfdL00000ZhHnqSAF` |
| Check only | `false` |
| Status | `Succeeded` |
| Component type | `AiAuthoringBundle` |
| Component full name | `Pulse360_Agent` |

Org metadata surface:

| Metadata type | Existing org entry |
| --- | --- |
| `AiAuthoringBundle` | `Pulse360_Agent_1` |
| Last modified | `2026-04-27T13:29:26.000Z` |

The deploy updated the org's existing `Pulse360_Agent_1` authoring bundle
entry. The source file developer name remains `Pulse360_Agent`.

Original bound agent user:

| Username | Active |
| --- | --- |
| `dnortje.37cf563036b7@agentforce.com` | `true` |

Published bound agent user:

| Username | Profile | Active |
| --- | --- | --- |
| `pulse360_agent@00ddl00000tqwws1696306775.ext` | `Einstein Agent User` | `true` |

The admin user could validate and deploy metadata, but native publish failed
until the authoring bundle and spec were bound to the dedicated Einstein Agent
runtime user. The dedicated user already had the generated Pulse360 Agentforce
permission sets and the Agentforce service agent user permission set group.

Apex test run:

| Field | Value |
| --- | --- |
| Test run ID | `707dL000016uA6B` |
| Outcome | `Passed` |
| Tests run | `29` |
| Passing | `29` |
| Failing | `0` |
| Pass rate | `100%` |

Post-deploy Apex test run:

| Field | Value |
| --- | --- |
| Test run ID | `707dL000016uYcg` |
| Outcome | `Passed` |
| Tests run | `29` |
| Passing | `29` |
| Failing | `0` |
| Pass rate | `100%` |

Agent script validation:

| Field | Value |
| --- | --- |
| Command | `sf agent validate authoring-bundle` |
| API name | `Pulse360_Agent` |
| Result | `success: true` |

Native Agentforce publish and activation:

| Field | Value |
| --- | --- |
| Publish command | `sf agent publish authoring-bundle --skip-retrieve` |
| Publish result | `success: true` |
| Bot developer name | `Pulse360_Agent` |
| Activation command | `sf agent activate` |
| Activation result | command exited successfully |

Published native metadata:

| Metadata type | Entry | Evidence |
| --- | --- | --- |
| `Bot` | `Pulse360_Agent` | Bot metadata exists with label `Pulse360 Agent` |
| `GenAiPlannerBundle` | `Pulse360_Agent_v2` | created and modified during publish |
| `BotVersion` | version `2` | `Status = Active` |
| `BotVersion` | version `1` | `Status = Inactive` |

Programmatic native preview:

| Field | Value |
| --- | --- |
| Preview target | activated published agent `Pulse360_Agent` |
| Test prompt | `Summarize what you can do for Pulse360 seller account management and governance review.` |
| Response status | command succeeded |
| Trace path | `.sfdx/agents/0XxdL000003Ns2nSAC/sessions/019dd2e8-6b2e-7faa-9559-f43705af57ae` |

Preview response summary:

```text
The agent responded that it supports Pulse360 seller account management by
reviewing account intelligence, interpreting account hierarchies, identifying
whitespace opportunities, and recommending next best actions. It also described
governance support for duplicate review, stewardship tasks, governance case
analysis, merge decisions, confidence signals, and evidence for decisions.
```

Native live-action source wiring:

| Field | Value |
| --- | --- |
| Source file | `force-app/main/default/aiAuthoringBundles/Pulse360_Agent/Pulse360_Agent.agent` |
| Seller actions declared | `get_account_context`, `execute_seller_action` |
| Governance actions declared | `get_review_context`, `get_data_cloud_review_evidence`, `record_governance_decision` |
| Mutating action confirmation | `execute_seller_action` and `record_governance_decision` set `require_user_confirmation: True` |
| Agent Script validation | `success: true` |
| Dry-run deploy ID | `0AfdL00000ZjUIjSAN` |
| Dry-run deploy result | `Succeeded` |
| Action-wired deploy ID | `0AfdL00000ZjbwvSAB` |
| Action-wired publish result | `success: true`, bot developer name `Pulse360_Agent` |
| Active BotVersion after action publish | version `3`, `Status = Active` |

The Agent Script compiler treats `reasoning` as a reserved block name, so the
optional `Pulse360ExecuteSellerAction.reasoning` Apex input is not currently
declared in the native action schema. The invocable wrapper still supports the
field for Flow/LWC callers.

Action metadata retrieval after publish confirmed that `Pulse360_Agent_v3`
contains local Apex actions for the declared Pulse360 wrappers:

| Topic | Local actions materialized |
| --- | --- |
| `seller_account_manager` | `get_account_context`, `execute_seller_action` |
| `governance_review_manager` | `get_review_context`, `get_data_cloud_review_evidence`, `record_governance_decision` |

Live-action preview caveat:

| Field | Evidence |
| --- | --- |
| Published-agent preview session | `.sfdx/agents/0XxdL000003Ns2nSAC/sessions/019dd328-701d-708a-b6b6-5f90027616f6` |
| Authoring-bundle live-action preview session | `.sfdx/agents/Pulse360_Agent/sessions/c714c001-78ee-40d0-9ce7-07d9ed53e3bb` |
| Two-turn authoring-bundle live-action preview session | `.sfdx/agents/Pulse360_Agent/sessions/5c2a016f-4aae-40d7-9151-b4b8007789fe` |
| Result | Previews returned Pulse360 seller/governance responses |
| Limitation | Trace shows router transition tool calls, but specialized topic `tools_sent` is empty, so Apex live-action invocation is not proven |

The most likely cause is the current use of `@utils.transition` in the start
router. Transitioning routes the user to a topic, but the preview trace shows
the original record-specific prompt is not handed to the specialized topic with
its Apex tools available. A direct subagent delegation attempt using
`@subagent.<topic>` did not compile in this org's Agent Script compiler, so it
was not retained.

Live-action proof after direct Workbench and permission hardening:

| Field | Evidence |
| --- | --- |
| Direct Workbench deploy ID | `0AfdL00000ZkOzFSAV` |
| Active BotVersion | version `5`, `Status = Active` |
| Permission fix | assigned `Pulse360_Account_Intelligence_User` and `Governance_Case_Steward` to the agent user |
| Governance metadata drift fix | deployed full `Governance_Case__c` source object contract and `Governance_Case_Steward` permission set |
| Governance deploy ID | `0AfdL00000ZkTUHSA3` |
| Seller action proof session | `.sfdx/agents/Pulse360_Agent/sessions/507a4eef-cac2-4845-8b5c-8d435e8b7c42` |
| Seller action trace | `027729d2-d585-4ac9-8087-81cf8cabee0a.json` |
| Seller action invoked | `get_account_context` with `accountId = 001dL000024xj2cQAA` |
| Seller action result | `__action_execution_status__ = success`, returned `payloadJson` for JG Summit / GoTyme seller brief |
| Governance action proof session | `.sfdx/agents/Pulse360_Agent/sessions/b255c4a0-46f6-45dc-8ca6-33f8335094ed` |
| Governance action trace | `370aae9d-f1bc-436b-a3e0-b7a2656daaa1.json` |
| Governance action invoked | `get_review_context` with `governanceCaseId = a00dL000036IsSgQAK` |
| Governance action result | `__action_execution_status__ = success`, returned `payloadJson` for `GC-00000` / `PAIR-AYALA-001` |
| Direct Data Cloud object proof | `ssot__Account__dlm` returned two Ayala rows for `001dL000024wgYRQAY` and `001dL000024weudQAA` |
| Direct Data Cloud invocable proof | `Pulse360GetDataCloudReviewEvidenceAction.invoke` returned `available = true`, `dataCloudSource = ssot__Account__dlm`, two entity matches, shared unified profile `ucp_ayala_001`, and validity scores `92` / `91` |
| Direct Data Cloud invocable safety | execute anonymous run completed with `Number of DML statements: 0` |
| Published-agent direct evidence preview | `.sfdx/agents/0XxdL000003Ns2nSAC/sessions/019dd454-5dea-7e1b-97a6-ea0f2f53f943` |
| Published-agent direct evidence response | agent reported direct Data Cloud review evidence for `PAIR-AYALA-001` had `available = true` and that no decision or seller action was recorded |
| Seller mutating action blocked proof | `Pulse360ExecuteSellerAction.invoke` for `open_opportunity` with `approvalMode = requested_only` returned `status = ApprovalRequired`, `approvalState = REQUIRED`, and `errorCode = SELLER_APPROVAL_REQUIRED` |
| Seller blocked proof safety | execute anonymous run completed with `Number of DML statements: 0`; same-day query found no Opportunity or Task created for `001dL000024xj2cQAA` |
| Governance mutating action blocked proof | `Pulse360RecordGovernanceDecisionAction.invoke` with a non-current `approvedByUser` failed before decision execution; execute-anonymous surfaces the fail-closed `AuraHandledException` as a Salesforce runtime exception outside Aura context |
| Governance blocked proof safety | `GC-00000` remained unchanged after the blocked attempt: `Status__c = Approved`, `Decision_Status__c = Approved`, `Decision_Reason_Code__c = LEGAL_ENTITY_MATCH_CONFIRMED`, `Audit_Event_Id__c = P360-20260418142755-1055215077`, `LastModifiedDate = 2026-04-18T14:27:55.000+0000` |
| Approved seller mutation proof | `Pulse360ExecuteSellerAction.invoke` for `open_opportunity` with `approvalMode = approved` returned `status = Completed`, `approvalState = APPROVED`, `approvalRequired = true`, and `primaryObjectApiName = Opportunity` |
| Approved seller mutation output | created Opportunity `006dL00000NgsuuQAB` on JG Summit Holdings, Inc. (`001dL000024xj2cQAA`) named `JG Summit Holdings, Inc. - Expand rewards analytics and customer decisioning` |
| Approved seller mutation verification | Opportunity query confirmed `StageName = Prospecting`, `CloseDate = 2026-05-28`, `CreatedDate = 2026-04-28T14:14:44.000+0000`, and the Pulse360 seller brief was written to `Description` |
| Approved seller mutation safety | Apex limits showed exactly `Number of DML statements: 1` and `Number of DML rows: 1`; same-day Task query for the account returned zero rows |
| Disposable governance case seed | created `GC-00001` (`a00dL0000399UZdQAM`) with `Candidate_Pair_Id__c = PAIR-AYALA-AGENTFORCE-PROOF-20260428`, Ayala left/right accounts, `Status__c = Ready for Review`, and `Downstream_Update_Status__c = Not Started` |
| Approved governance mutation proof | `Pulse360RecordGovernanceDecisionAction.invoke` with `approvedByUser = UserInfo.getUserId()` returned `status = Completed`, `approvalState = APPROVED`, `approvalRequired = true`, and `primaryObjectApiName = Governance_Case__c` |
| Approved governance mutation output | `GC-00001` updated to `Status__c = Approved`, `Decision_Status__c = Approved`, `Decision_Reason_Code__c = LEGAL_ENTITY_MATCH_CONFIRMED`, `Surviving_Account__c = 001dL000024wgYRQAY`, `Merged_Account__c = 001dL000024weudQAA`, `Downstream_Update_Status__c = Queued` |
| Approved governance audit output | `Audit_Event_Id__c = P360-20260428143417-1642253063`, `Decided_By__c = 005dL00001kPRA6QAO`, `Decided_At__c = 2026-04-28T14:34:17.000+0000`, `LastModifiedDate = 2026-04-28T14:34:18.000+0000` |
| Approved governance mutation safety | Apex limits showed exactly `Number of DML statements: 1` and `Number of DML rows: 1`; original `GC-00000` remained unchanged with `LastModifiedDate = 2026-04-18T14:27:55.000+0000` |
| Account UI surface metadata | `Account_Record_Page` exists in the target org and contains `c:pulse360AgentPanel`; org metadata last modified `2026-04-23T13:22:05.000Z` |
| Account UI browser validation | Chrome rendered the Singtel account page with `Pulse360 Account Workspace`, `Real seller agent`, `Pulse360 Agent`, grounded seller brief, evidence/trust cues, and guarded seller action buttons |
| Governance UI surface metadata | `Governance_Case_Record_Page` exists in the target org and contains `c:pulse360GovernanceSnapshot`, `c:pulse360GovernanceMatchEvidence`, `c:pulse360GovernanceDecisionWorkspace`, and `c:pulse360GovernanceAuditOutcome`; org metadata last modified `2026-04-21T04:37:22.000Z` |
| Governance component metadata | target org contains the four governance LWC bundles above, each last modified `2026-04-21T04:37:13.000Z` |
| Navigation tabs metadata | target org contains `Pulse360_Planner`, `Governance_Case__c`, `Pulse360_Seller_V2`, `Pulse360_Renewal_Risk`, and `Pulse360_Signal_Routing` custom tabs |
| Native in-page Agentforce side panel | not claimed as live; source intentionally blocks ACC side-panel launch because this org does not expose the ACC side-panel module yet |
| Governance UI browser validation | Chrome rendered disposable case `GC-00001` with `Governance Snapshot`, `Match Evidence`, `Direct Data Cloud evidence ready`, direct validity scores `92` / `91`, decision workspace fields, and `Audit and Outcome` showing the approved decision |
| Governance UI screenshot evidence | `Screenshot 2026-04-29 at 7.05.31 AM.png`, `Screenshot 2026-04-29 at 7.05.37 AM.png`, and `Screenshot 2026-04-29 at 7.05.46 AM.png` |

The authoring-bundle trace now shows the Pulse360 read tools as enabled and
sent:

```text
enabled_tools: get_account_context, get_review_context,
get_data_cloud_review_evidence, __end_session_action__
tools_sent: get_account_context, get_review_context,
get_data_cloud_review_evidence, __end_session_action__
```

The published-agent direct evidence preview saved the transcript, but the
published preview trace JSON was empty in the local CLI output. Treat the
direct Data Cloud evidence gate as proven through direct SOQL plus direct
invocable execution, and as preview-response corroborated through the activated
published agent. Keep using authoring-bundle trace evidence when the requirement
is to prove `tool_invocations[].function.name` from the preview trace.

Seller mutation execution is proven for the approved `open_opportunity` path.
Governance mutation execution is proven on disposable case `GC-00001` with the
current user approval token, direct Data Cloud evidence grounding, audit event
generation, and downstream update queueing. The seller-facing Salesforce UI
surface is visually validated on the Account page, and the governance steward
record surface is visually validated on the Governance Case page. Native
in-page Agentforce side-panel launch remains capability-gated on ACC
availability.

The action proof is trace-based, not inferred from conversational phrasing:

- seller trace shows `function.name = get_account_context`
- seller trace shows `__action_execution_status__ = success`
- governance trace shows `function.name = get_review_context`
- governance trace shows `__action_execution_status__ = success`

Remaining live-action gap: the direct Data Cloud evidence action
`get_data_cloud_review_evidence` is materialized and sent as an available tool,
but a successful invocation has not yet been captured in preview.

Covered behavior:

- seller account context returns a grounded action payload
- seller brief / launch-agent path creates evidence-aware Task output
- low-risk seller action execution is allowed without approval
- opportunity creation is blocked until approval
- governance evidence fails closed when direct Data Cloud evidence is unavailable
- governance decision commit requires explicit current-user approval
- review evidence can resolve accounts from candidate pair lookup
- invocable wrappers return payload JSON for Flow/action use
- Health Scan and workspace helper services handle blank or missing JSON safely

## Decision

The Headless 360 action layer is validated as a source-backed Salesforce Apex,
Flow-invocable, and LWC action surface.

Native Agentforce setup is now proven through publish, activation, basic
programmatic preview, and trace-backed live read-action invocation:

- the target org exposes the native Agentforce Studio setup navigation
- `Agentforce Agents` is reachable at `EinsteinCopilot`
- the org-level Agentforce toggle is on
- the native Agents list currently shows `Agentforce Employee Agent` and
  `HuronBot Test CSR`
- the Agentforce Asset Library is reachable for both Subagents and Actions
- `Pulse360_Agent` exists as a native `Bot`
- `Pulse360_Agent_v5` exists as a native `GenAiPlannerBundle`
- `Pulse360_Agent` BotVersion `5` is active
- a programmatic preview exchange returned a Pulse360-specific response
- seller `get_account_context` invoked successfully and returned grounded
  `payloadJson`
- governance `get_review_context` invoked successfully and returned grounded
  `payloadJson`
- approved seller `open_opportunity` execution created a verified Opportunity
- approved governance decision execution updated disposable case `GC-00001`
  with audit and downstream queue fields
- the Account page renders the custom Pulse360 seller workspace and real seller
  assistant panel in Chrome
- the Governance Case page renders the steward snapshot, match evidence,
  decision workspace, and audit/outcome surface in Chrome

The deployed Pulse360 authoring bundle is now proven as a usable native runtime
agent for read-action-grounded seller and governance preview exchanges, with
approved seller and governance mutation paths proven through direct invocable
execution.

The earlier guessed setup URL, `AgentforceAgents`, is not the correct setup
surface for this org; the working setup surface is under `EinsteinCopilot`.

The remaining gates require deeper native runtime proof:

- intended business user can see and invoke the native Agentforce surface in UI
- direct Data Cloud evidence action is invoked successfully from preview
- native citation output or fallback source references are demonstrated
- mutating seller/governance actions are demonstrated with confirmation and
  audit payload in the actual native runtime
- ACC/native in-page Agentforce side-panel support is enabled and proven, or it
  remains described as a custom Pulse360 assistant/action panel

Until the remaining deeper gates are captured, use this description:

```text
Native Agentforce agent published and activated with trace-proven Pulse360
seller and governance read actions, direct Data Cloud evidence proven through
SOQL/invocable execution, approved seller opportunity execution, approved
governance decision execution, and visually validated custom Account seller and
Governance Case steward surfaces; native in-page ACC side-panel handoff remains
gated.
```

## Next Build Slice

The next slice should finish native runtime proof and release posture:

1. Invoke `get_data_cloud_review_evidence` successfully against a candidate pair
   or account pair that maps to the Data Cloud review queue.
2. Demonstrate `execute_seller_action` with user confirmation in preview or
   Builder/Studio, starting with a prepare-only seller action.
3. Demonstrate `record_governance_decision` with explicit confirmation and
   audit payload in the native runtime.
4. Capture native citation output or fallback source references in the actual
   runtime response.
5. Decide whether to enable ACC/native in-page Agentforce side-panel support or
   keep the source-backed custom Pulse360 assistant/action panel as the
   business-user release surface.
6. Update the capability gates from `runtime_unproven` to the proven state only
   for gates with evidence.
