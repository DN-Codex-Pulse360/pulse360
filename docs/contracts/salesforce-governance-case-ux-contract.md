# Contract: Salesforce Governance Case UX

## Purpose
Define the first operational Salesforce experience for the Pulse360 stewardship slice.

This contract is written primarily for:
- `Data Operations`

And secondarily for:
- `Sales Operations`

It turns the stewardship product slice into a build-ready Salesforce workflow contract covering:
- who the experience is for
- what the user sees
- what actions are allowed
- what must be auditable
- which system owns each field and behavior

## Product objective
Enable `Data Operations` to resolve duplicate-account governance cases inside Salesforce using trusted Pulse360 evidence, while giving `Sales Operations` enough downstream transparency to trust the resulting account model for segmentation, routing, and planning.

## Primary personas

### Primary persona: `Data Operations`
Analogous roles:
- data steward
- MDM analyst
- governance analyst
- operations analyst responsible for account quality

Core job:
- decide whether two account records should be treated as the same business entity
- determine which attributes should be trusted
- understand whether hierarchy is affected
- record a governed decision with auditability

### Secondary persona: `Sales Operations`
Analogous roles:
- revenue operations
- territory/planning analyst
- commercial operations manager

Core job:
- monitor whether account truth issues are degrading routing, territory design, segmentation, and reporting quality
- trust the governance outcome without having to repeat stewardship work

## UX scope
This contract covers the first-slice governance case experience for `DS-02 Governance Case Resolution`.

In scope:
- pre-enriched Salesforce governance case
- case layout and sections
- steward actions
- decision reason taxonomy
- audit and status semantics
- system-of-record responsibilities

Out of scope:
- automated merge execution logic beyond the approved workflow contract
- seller-facing Account 360 workspace
- planner-facing portfolio workspace

## Experience principles
1. The steward should not have to reconstruct core evidence manually.
2. Every visible score must have nearby explanation or provenance.
3. Low-confidence and incomplete-trust states must be explicit.
4. Decision controls must be structured enough for metrics and audit.
5. Salesforce records the governed transaction; it does not invent intelligence that should have come from Databricks or Data Cloud.

## Record model

### Primary record
`Governance Case`

Purpose:
- transactional stewardship object where the human decision is recorded

### Related operational context
- `Account` records under review
- Data Cloud-linked stewardship evidence
- audit fields and workflow history

## Case states

### Status values
- `New`
- `Ready for Review`
- `In Review`
- `Approved`
- `Rejected`
- `Deferred`
- `Closed`

### Status semantics
- `New`: case exists but evidence payload is not yet confirmed as ready
- `Ready for Review`: evidence payload is available and case can be worked
- `In Review`: steward is actively evaluating the case
- `Approved`: steward approves the merge or match decision
- `Rejected`: steward rejects the duplicate/match recommendation
- `Deferred`: steward cannot decide yet and requires follow-up evidence or policy review
- `Closed`: administrative finalization state after downstream follow-through is complete

## Page layout contract

### Section 1: Case header
Purpose:
- orient the steward quickly

Required fields:
- `governance_case_id`
- `case_status`
- `priority`
- `candidate_pair_id`
- `evidence_run_timestamp`
- `decision_owner`
- `created_at`
- `last_updated_at`

### Section 2: Pair summary
Purpose:
- show the core entity-resolution question immediately

Required fields:
- `left_account_id`
- `left_account_name`
- `right_account_id`
- `right_account_name`
- `duplicate_confidence`
- `confidence_band`
- `recommended_action`
- `review_flag`

UX requirement:
- this section must be visible above the fold

### Section 3: Why Pulse360 flagged this
Purpose:
- explain the duplicate recommendation clearly

Required fields:
- `top_match_features`
- `feature_explanations`
- `source_snapshot_id`
- `model_version`

UX requirement:
- explanations must be human-readable without opening a separate technical screen

### Section 4: Attribute trust panel
Purpose:
- help the steward decide which values are trustworthy

Required fields:
- `attribute_validity_payload`

Minimum field display for first slice:
- legal name
- website
- domain
- billing city
- billing state
- billing country
- parent account
- DUNS number

Per-row display requirement:
- left value
- right value
- validity score
- review-required indicator
- explanation text
- source name when available

### Section 5: Hierarchy impact panel
Purpose:
- show whether the decision affects group context

Required fields:
- `hierarchy_conflict_flag`
- `hierarchy_impact_summary`
- `left_parent_account_id`
- `right_parent_account_id`
- `affected_group_count`

UX requirement:
- hierarchy effect must be understandable in plain language, not only as graph metadata

### Section 6: Decision panel
Purpose:
- record the governed human action

Actions:
- `Approve`
- `Reject`
- `Defer`

Required input fields:
- `decision_reason_code`
- `decision_reason_text` optional free text
- `surviving_account_id` when approving
- `review_followup_required`

UX requirement:
- the steward must not be able to finalize a decision without a structured reason code

### Section 7: Audit and outcome panel
Purpose:
- make the governance transaction reviewable after the fact

Required fields:
- `decision_status`
- `decided_by_user_id`
- `decided_at`
- `decision_run_id`
- `downstream_update_status`
- `audit_event_id`

## Action semantics

### Approve
Meaning:
- the steward accepts that the records represent the same business entity and approves the governed merge/match outcome

Required consequences:
- record `surviving_account_id`
- capture structured reason code
- emit downstream truth-update event
- mark case as auditable and recompute-eligible

### Reject
Meaning:
- the steward determines the records should not be treated as the same business entity

Required consequences:
- capture structured reason code
- preserve rejection for future model learning and false-positive analysis
- prevent automatic downstream merge action from this case

### Defer
Meaning:
- the steward cannot make a safe decision yet

Required consequences:
- capture structured reason code
- identify whether follow-up is data-related, policy-related, or cross-functional
- keep the case visible in backlog and SLA reporting

## Decision reason taxonomy

### Approve reason codes
- `CLEAR_DUPLICATE_MATCH`
- `LEGAL_ENTITY_MATCH_CONFIRMED`
- `TRUSTED_ATTRIBUTE_ALIGNMENT`
- `HIERARCHY_ALIGNMENT_CONFIRMED`
- `REFERENCE_DATA_CONFIRMED`

### Reject reason codes
- `DIFFERENT_LEGAL_ENTITIES`
- `INSUFFICIENT_MATCH_EVIDENCE`
- `HIERARCHY_CONFLICT_BLOCKS_MATCH`
- `TRUSTED_ATTRIBUTE_CONFLICT`
- `FALSE_POSITIVE_MODEL_OUTPUT`

### Defer reason codes
- `NEEDS_EXTERNAL_REFERENCE_CHECK`
- `NEEDS_BUSINESS_OWNER_REVIEW`
- `NEEDS_HIERARCHY_VALIDATION`
- `NEEDS_DATA_REMEDIATION`
- `NEEDS_POLICY_DECISION`

## Field ownership model

### Databricks-owned evidence fields
- `candidate_pair_id`
- `duplicate_confidence`
- `confidence_band`
- `top_match_features`
- `feature_explanations`
- `attribute_validity_payload`
- `hierarchy_conflict_flag`
- `hierarchy_impact_summary`
- `source_snapshot_id`
- `evidence_run_id`
- `evidence_run_timestamp`
- `model_version`

Rule:
- Salesforce must not derive or reinterpret these fields independently

### Data Cloud-owned operational delivery fields
- `source_account_id`
- `related_account_id`
- `unified_profile_id`
- linked hierarchy and account context needed for CRM rendering
- refresh/recompute availability after governance decision

Rule:
- Data Cloud is the CRM-centered operational intelligence layer that delivers the stewardship payload into Salesforce-ready form

### Salesforce-owned transactional fields
- `governance_case_id`
- `case_status`
- `priority`
- `decision_status`
- `decision_reason_code`
- `decision_reason_text`
- `surviving_account_id`
- `review_followup_required`
- `decided_by_user_id`
- `decided_at`
- `audit_event_id`
- `downstream_update_status`

Rule:
- Salesforce is the system of record for the governed human decision and workflow state

## Audit requirements
Every finalized case must preserve:
- who made the decision
- when the decision was made
- which evidence run was used
- which reason code was used
- what the recommended action was
- what actual decision was taken
- whether downstream update completed

## Acceptance criteria
1. A `Data Operations` user can work the case without leaving Salesforce to assemble core evidence.
2. A `Sales Operations` user can inspect the outcome and understand why the account truth changed.
3. `Approve`, `Reject`, and `Defer` each require structured reason capture.
4. Audit fields are sufficient to reconstruct the decision later.
5. The UX uses Databricks/Data Cloud evidence directly rather than recreating scoring logic in Salesforce.

## Related artifacts
- `docs/contracts/salesforce-governance-case-implementation-spec.md`
- `docs/contracts/pulse360-stewardship-slice-contract.md`
- `docs/contracts/databricks-stewardship-output-spec.md`
- `docs/contracts/datacloud-to-salesforce-agentforce-contract.md`
- `docs/readout/pulse360-product-slice-definition.md`
