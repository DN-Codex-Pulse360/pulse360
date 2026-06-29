# Pulse360 Salesforce Skill

## Purpose

Guide Salesforce and Data Cloud work for the Pulse360 proactive manufacturing
signal demo.

This skill owns the activation and action layer:

- Data Cloud mapping and freshness,
- CRM-facing signal surfaces,
- seller actions,
- approval gates,
- Agentforce-ready or fallback orchestration,
- UAT evidence from Salesforce surfaces.

It does not own source-system signal calculation or Databricks lineage.

## Operating Rule

Salesforce turns trusted Databricks signals into workflow. It must not invent or
overwrite deterministic account intelligence.

Evidence fields from Databricks/Data Cloud remain read-only in CRM-facing
surfaces.

## Demo Scope

Target demo:

- fictional supplier: `Meridian Industrial Systems`,
- hero customer group: `Northstar Foods Group`,
- primary signal: `maintenance_coverage_gap`,
- seller action: route aftermarket specialist and create follow-up task,
- approval-gated action: create opportunity.

## Required Surfaces

### 1. Proactive Signal Surface

The seller should see the signal before manually asking for account context.

Acceptable implementation paths:

- signal card in an existing seller workspace,
- signal-routing workspace entry,
- Account record alert panel,
- documented fallback panel if the org cannot support native Agentforce.

The surface must show:

- signal label,
- why-now explanation,
- affected account or group,
- recommended action,
- confidence cue,
- freshness cue,
- source/evidence link or source ref summary,
- approval cue for high-risk actions.

### 2. Action Controls

Supported first-slice actions:

| Action | Behavior | Approval |
| --- | --- | --- |
| `create_task` | Create a follow-up Task on the current or target Account. | Auto-executable when source refs and CRM-safe key exist. |
| `route_specialist` | Create specialist-routing Task with signal context. | Auto-executable when target context is clear. |
| `open_entity` | Navigate to a CRM-covered account or group context. | No mutation. |
| `open_opportunity` | Prepare opportunity context without mutation. | No mutation unless confirmed. |
| `create_opportunity` | Create an Opportunity. | Explicit approval required. |
| `escalate_governance` | Route weak identity/hierarchy confidence to review. | Review required. |

### 3. Agentforce Or Fallback Explanation

If native Agentforce gates pass, Agentforce may:

- explain what changed,
- summarize evidence,
- recommend a next action,
- launch supported actions,
- enforce approval policy.

If native Agentforce gates do not pass, describe the surface as:

```text
custom Salesforce LWC/Apex action panel with Agentforce-ready contract
```

Do not call a custom panel a native Agentforce experience.

## Data Cloud Requirements

The Salesforce lane must verify or document:

- Data Cloud source object,
- DLO/DMO mapping path,
- CRM-safe `source_account_id` or approved Salesforce external ID,
- Copy Field Enrichment status when CRM writeback is part of the demo,
- `DataCloud_Last_Synced__c` or equivalent freshness field,
- whether the surface is reading directly from Data Cloud, CRM Account fields,
  or fixture/sample payloads.

The demo may proceed with a documented simulation if CRM writeback remains
blocked, but the narrative must say so explicitly.

## Required Evidence

For each Salesforce-facing demo step, capture:

- which surface was used,
- whether the data is live, fixture-backed, or simulated,
- whether the page rendered in browser,
- whether action was executed or only shown as gated,
- record IDs for any created Salesforce artifacts,
- failure or fallback reason for native Agentforce claims.

## Validation Checklist

Before claiming the Salesforce harness is ready:

- signal card or signal-routing surface is source-backed or clearly simulated,
- action types match the supported action contract,
- opportunity creation remains approval-gated,
- evidence fields are read-only,
- freshness is visible or blocker is documented,
- native Agentforce is not overclaimed,
- fallback language is present where needed,
- UAT script separates live proof from simulation.

## Recommended Local Checks

Run these after adding metadata, action surfaces, or contracts:

```bash
./scripts/validate-account-intelligence-experience.sh
./scripts/validate-agentforce-orchestrator.sh
./scripts/validate-signal-routing-workspace.sh
./scripts/validate-multi-surface-experience.sh
./scripts/validate-surface-architecture.sh
./scripts/validate-contract-completeness.sh
```

For live target-org checks:

```bash
TARGET_ORG=pulse360-agent-target ./scripts/validate-m1-account-hierarchy-readiness-gate.sh
```

## Handoff Contract From Databricks

The Salesforce lane expects:

- `source_account_id`,
- `signal_type`,
- `why_now`,
- `confidence_score`,
- `recommended_action_type`,
- `approval_required`,
- `source_refs`,
- `last_synced_timestamp` or `signal_generated_at`,
- `run_id`,
- `model_version`.

If any of these are absent, the surface must degrade to review mode rather than
presenting a confident seller action.

## Anti-Patterns

Avoid:

- seller-edited evidence fields,
- mutating CRM records from uncertain signals,
- native Agentforce claims without runtime proof,
- opportunity creation without explicit approval,
- hiding freshness or source refs,
- inventing account hierarchy or contract facts in Apex/LWC,
- treating Data Cloud stream success as equivalent to CRM writeback success.
