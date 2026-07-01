# Agentforce Proactive Account Coach Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a real Agentforce metadata/action slice for a proactive account coach that explains the Northstar signal and prepares governed next moves without reducing Agentforce to Task creation.

**Architecture:** Add a source-backed Agentforce topic in `Pulse360_Agent.agent` and one non-mutating Apex invocable action that returns a grounded signal brief. Keep CRM mutations out of the primary agent feature; any downstream seller action remains a separate optional effect after confirmation.

**Tech Stack:** Salesforce Agentforce metadata-style `.agent` bundle, Apex `@InvocableMethod`, shell/Python static validator, Salesforce CLI validation.

## Global Constraints

- Native Agentforce runtime must not be claimed until target-org runtime evidence exists.
- The primary Agentforce deliverable is reasoning/action orchestration, not Task creation.
- Agent output must include source refs, confidence/freshness cues, approval policy, and next recommendation.
- High-impact CRM mutation remains confirmation/approval-gated.
- The clean PR branch is `feature/proactive-signal-demo-clean`.

---

### Task 1: Agentforce Proactive Coach Validator

**Files:**
- Create: `scripts/validate-agentforce-proactive-account-coach.sh`

**Interfaces:**
- Consumes: `force-app/main/default/aiAuthoringBundles/Pulse360_Agent/Pulse360_Agent.agent`
- Consumes: `force-app/main/default/classes/Pulse360GetProactiveSignalBriefAction.cls`
- Produces: static validation gate for PR #16.

- [ ] **Step 1: Write the failing validator**

Create a shell validator that checks for:

- `topic proactive_account_coach`
- action label `Get Proactive Signal Brief`
- Apex target `apex://Pulse360GetProactiveSignalBriefAction`
- `require_user_confirmation: True`
- output fields `briefJson`, `sourceRefsJson`, `approvalPolicyJson`
- explicit runtime boundary `runtime_unproven`
- no Task-created success token as primary proof

- [ ] **Step 2: Run validator to verify it fails**

Run: `./scripts/validate-agentforce-proactive-account-coach.sh`

Expected: FAIL because the agent metadata/action files do not exist yet.

### Task 2: Proactive Signal Brief Action

**Files:**
- Create: `force-app/main/default/classes/Pulse360GetProactiveSignalBriefAction.cls`
- Create: `force-app/main/default/classes/Pulse360GetProactiveSignalBriefAction.cls-meta.xml`
- Create: `force-app/main/default/classes/Pulse360ProactiveSignalBriefTest.cls`
- Create: `force-app/main/default/classes/Pulse360ProactiveSignalBriefTest.cls-meta.xml`

**Interfaces:**
- Produces: `Pulse360GetProactiveSignalBriefAction.invoke(List<Request>) -> List<Response>`
- Response fields: `status`, `accountId`, `briefJson`, `sourceRefsJson`, `approvalPolicyJson`, `runtimeState`

- [ ] **Step 1: Write Apex test**

Test cases:

- active proactive signal returns a grounded brief with source refs and approval policy
- missing Account Id returns `blocked_missing_account_id`
- Account without source refs returns `review_required_missing_source_refs`

- [ ] **Step 2: Implement minimal Apex action**

Query only Account fields required for the brief:

- `Intent_Signal_Payload__c`
- `AI_Narrative__c`
- `AI_Recommended_Actions__c`
- `AI_Source_Refs__c`
- `Coverage_Gap_Flag__c`
- `DataCloud_Last_Synced__c`
- `AI_Narrative_Generated__c`

No DML. No Task creation.

### Task 3: Agentforce Topic Metadata

**Files:**
- Create: `force-app/main/default/aiAuthoringBundles/Pulse360_Agent/Pulse360_Agent.agent`

**Interfaces:**
- Consumes: `Pulse360GetProactiveSignalBriefAction`
- Produces: `Proactive Account Coach` topic with action orchestration instructions.

- [ ] **Step 1: Add metadata**

The topic must instruct the agent to:

- fetch the proactive signal brief before answering Northstar/account-signal questions
- summarize why-now, evidence, confidence, freshness, and approval policy
- avoid claiming native runtime until runtime evidence exists
- treat Task/opportunity creation as downstream, not the primary answer

### Task 4: Validation And PR Update

**Files:**
- Modify: `docs/harness/pulse360-proactive-signal-demo-harness.md`
- Modify: PR #16 branch only.

**Interfaces:**
- Produces: updated validation list and pushed PR.

- [ ] **Step 1: Run all relevant validators**

Run:

```bash
./scripts/validate-agentforce-proactive-account-coach.sh
./scripts/validate-proactive-signal-data-cloud-handoff.sh
./scripts/validate-proactive-signal-demo.sh
TARGET_ORG=pulse360-agent-target ./scripts/validate-salesforce-proactive-signal-demo.sh
```

- [ ] **Step 2: Push**

Run: `git push`

Expected: PR #16 updates with the Agentforce proactive coach slice.
