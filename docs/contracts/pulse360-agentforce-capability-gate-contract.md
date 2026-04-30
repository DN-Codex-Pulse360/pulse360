# Pulse360 Agentforce Capability Gate Contract

## Purpose

Define the gates that must pass before Pulse360 can claim a native Agentforce runtime experience.

This contract keeps three things separate:

- source-backed Agentforce metadata
- custom Salesforce assistant/action panels
- native Agentforce runtime in the target org

## Official Platform Basis

Verified against official Salesforce documentation on 2026-04-24:

- Agentforce actions can target Apex, Flow, or prompt templates and can require user confirmation.
- Citations can be provided by Apex actions through Salesforce citation classes when agents are enabled.
- Einstein generative AI setup requires Data 360 and Einstein/Trust Layer configuration before org runtime use.
- Models API calls go through the Einstein Trust Layer.
- Trust Layer controls include grounding, masking, toxicity detection, audit trail/feedback, and zero-data-retention partner agreements where supported.

Reference URLs:

- https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-ref-actions.html
- https://developer.salesforce.com/docs/einstein/genai/guide/citations.html
- https://developer.salesforce.com/docs/einstein/genai/references/citations/citations-reference.html
- https://developer.salesforce.com/docs/einstein/genai/guide/org-setup.html
- https://developer.salesforce.com/docs/ai/agentforce/guide/models-api.html
- https://developer.salesforce.com/docs/ai/agentforce/guide/trust.html

## Capability States

| State | Meaning | Allowed language |
| --- | --- | --- |
| `metadata_ready` | Agentforce-related source files exist and validate. | Agentforce metadata |
| `runtime_unproven` | Native conversational runtime has not been demonstrated in the target org. | Custom assistant panel or action panel |
| `runtime_blocked` | Runtime is unavailable because org setup, entitlement, user binding, or page-surface support is missing. | Fallback Salesforce assistant/action panel |
| `runtime_verified` | Intended user can interact through a native Agentforce surface and configured actions drive responses. | Native Agentforce runtime |

## Required Gates

| Gate | Required evidence | Failure behavior |
| --- | --- | --- |
| `data_360_ready` | Data 360 provisioned and available for Trust Layer dependencies. | Do not claim native Agentforce. |
| `einstein_enabled` | Einstein generative AI is enabled in the target org. | Do not call generated response paths native Agentforce. |
| `trust_layer_configured` | Trust Layer setup reviewed for masking, audit, grounding, and policy settings. | Use custom panel or block generated response use. |
| `agent_metadata_deployed` | `AiAuthoringBundle`/agent metadata deployed to the target org. | Treat as metadata-only. |
| `agent_user_bound` | `default_agent_user` exists, is active, and has intended permissions. | Block runtime claim. |
| `native_surface_visible` | Intended user sees the native Agentforce surface in the target page/app. | Use custom LWC assistant fallback. |
| `actions_registered` | Agent actions are available through Apex/Flow/prompt targets. | Do not claim action-driving agent behavior. |
| `citations_supported` | Citation-capable action path or explicit citation fallback is available. | Show source refs in custom UI and mark native citations unavailable. |
| `approval_policy_enforced` | Mutating actions require confirmation/approval. | Block mutating actions. |
| `audit_artifacts_written` | Action output includes run/user/model/prompt/source/audit context. | Mark response as not acceptance-ready. |

## Pulse360 Gate Decisions

Current target state for `pulse360-agent-target`:

- `metadata_ready`: yes, source metadata exists in repo
- `runtime_verified`: no, not yet proven
- `fallback_surface`: custom Salesforce LWC/Apex assistant and action panels

Therefore Pulse360 must currently describe the account and governance experience as:

- source-backed Agentforce metadata plus
- custom Salesforce assistant/action surfaces plus
- Agentforce-ready Apex/Flow action contracts

It must not be described as a proven native Agentforce runtime until the gates above are demonstrated in the target org.

## Citation Contract

Every Agentforce or fallback assistant response must include one of:

- native citation references supplied by a citation-capable Apex action, or
- serialized `source_refs` rendered in the Salesforce UI, or
- an explicit statement that citation evidence is unavailable.

Minimum citation fields:

- `source_id`
- `source_name`
- `source_type`
- `source_object_api_name`
- `source_object_record_id`
- `source_url`
- `excerpt`
- `accessed_at`
- `document_date`
- `jurisdiction`

## Trust And Audit Contract

Every generated or assistant-style output must preserve:

- `user_id`
- `surface_context`
- `record_id`
- `action_type`
- `prompt_version`
- `model_id`
- `enrichment_run_id`
- `source_ids`
- `generated_at`
- `approval_required`
- `approval_state`
- `audit_event_id`
- `trust_layer_status`
- `masked_field_policy`

## Mutating Action Rules

1. Low-risk actions can prepare or create Tasks when CRM-safe Account context exists.
2. Opportunity creation requires explicit approval.
3. Governance decisions require explicit approval and direct Data Cloud evidence availability.
4. Native Agentforce `require_user_confirmation` is the target pattern when runtime is verified.
5. Fallback LWC/Apex surfaces must enforce equivalent confirmation until native runtime is verified.

## Acceptance Criteria

1. Native Agentforce is only claimed when `runtime_verified` evidence exists.
2. The fallback experience remains usable and accurately named when runtime gates fail.
3. Citations or explicit citation-unavailable notices accompany every assistant response.
4. Trust Layer setup and audit requirements are documented before any generated response is treated as production-ready.
5. Mutating actions cannot bypass approval gates.

