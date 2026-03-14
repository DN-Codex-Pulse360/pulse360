# Contract: Pulse360 Stewardship Slice

## Purpose
Define the first execution-ready Pulse360 product slice as a build contract across Databricks, Data Cloud, Salesforce, and the governance workflow.

This contract translates the stewardship slice from product definition into:
- the minimum intelligence payload
- the minimum action loop
- the acceptance bar for execution
- the backlog breakdown needed to ship the first real slice

## Product objective
Pulse360 should help a data steward resolve account truth faster and more defensibly.

The slice is successful when a steward can open one governance case and answer:
1. Are these records the same business entity?
2. Which attributes should be trusted?
3. What hierarchy consequence follows from the decision?
4. What is the right action now?

## Scope
This slice covers the first end-to-end stewardship workflow for `DS-02 Governance Case Resolution` and the supporting evidence needed from `DS-01 Fragmentation Discovery`.

Included:
- duplicate candidate evidence
- attribute validity evidence
- hierarchy implication evidence
- CRM-safe identity preservation
- steward-facing approve/reject/defer actions
- audit and governance metrics

Excluded from the first slice:
- seller-facing health and propensity experiences
- planner-facing portfolio workspace
- broad commercial scoring beyond what supports stewardship decisions

## Slice design principles
1. `crm_account_id` is mandatory end to end for all records that participate in workflow or downstream activation.
2. Scores without explanations are not acceptable for steward workflow.
3. Attribute trust must be explicit at field level for conflicting values.
4. Governance decisions must create audit evidence and feed downstream truth updates.
5. Daily batch is acceptable for the first slice; opaque or non-traceable outputs are not.

## End-to-end operating model

### Databricks role
- detect likely duplicate account pairs
- compute confidence and top match features
- compute attribute-level validity and review flags
- combine CRM evidence with other trusted enterprise data and approved third-party reference data where it improves trustworthiness
- use external models or LLM-assisted techniques only as bounded evidence-generation support with explicit provenance, never as the final decision authority
- expose hierarchy implication markers
- attach lineage, run metadata, source provenance, and model version

Interpretation:
- Databricks is enabling enterprise data stewardship by assembling and scoring the evidence package.
- Final stewardship decisions remain human decisions executed in workflow.

### Data Cloud role
- preserve stewardship payloads as linked extension data
- act as the CRM-centered operational account foundation for Account 360 and stewardship workflow
- keep account-safe linkage for Salesforce experience consumption
- unify canonical account context with Pulse360 stewardship extensions
- support recompute or refresh when governance decisions are approved

### Salesforce role
- show the stewardship case in the execution surface
- present pair evidence, trust signals, and hierarchy implications
- capture approve, reject, and defer decisions with reasons
- maintain auditability of the decision event
- serve as the transactional stewardship surface where the governed human decision is recorded

## Minimum stewardship data contract

### A. Duplicate candidate payload
Primary source:
- `gold.duplicate_candidate_pairs`

Purpose:
- provide decision-grade evidence that two CRM account records may represent the same business entity

#### Required fields
| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `candidate_pair_id` | string | Yes | Stable row key for the stewardship case payload |
| `left_account_id` | string | Yes | CRM-safe left `Account.Id` |
| `right_account_id` | string | Yes | CRM-safe right `Account.Id` |
| `duplicate_confidence_score` | number | Yes | Match confidence from `0-100` |
| `confidence_band` | string | Yes | Human-usable band such as `high`, `medium`, `low` |
| `top_match_features` | json | Yes | Ranked explanation factors driving confidence |
| `feature_explanations` | json | Yes | Human-readable explanation snippets |
| `recommended_action` | string | Recommended | System suggestion such as `approve_merge`, `review`, `reject_match` |
| `review_required_flag` | boolean | Yes | Whether manual review is required |
| `run_id` | string | Yes | Pipeline run ID |
| `run_ts` | datetime | Yes | Pipeline run timestamp |
| `source_snapshot_id` | string | Recommended | Reproducible source snapshot identifier |
| `model_version` | string | Yes | Duplicate model/rules version |

### B. Attribute validity payload
Primary source:
- `gold.firmographic_enrichment`

Purpose:
- show which conflicting attributes appear trustworthy enough to survive a merge or stay under review

#### Required fields
| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `candidate_pair_id` | string | Yes | Join key back to duplicate evidence |
| `account_id` | string | Yes | CRM-safe `Account.Id` for the current attribute row |
| `attribute_name` | string | Yes | Compared attribute such as `legal_name`, `website`, `domain`, `billing_country` |
| `attribute_value` | string | Yes | Proposed or observed value |
| `validity_score` | number | Yes | Trust score from `0-100` |
| `review_required_flag` | boolean | Yes | Whether steward review is required for this field |
| `source_name` | string | Recommended | Evidence provenance |
| `source_priority` | integer | Optional | Tie-break support for conflicting sources |
| `explanation_text` | string | Recommended | Human-readable reason why the value is trusted or suspect |
| `run_id` | string | Yes | Pipeline run ID |
| `run_ts` | datetime | Yes | Pipeline run timestamp |

### C. Hierarchy implication payload
Primary source:
- `gold.entity_hierarchy_graph`

Purpose:
- tell the steward whether a merge decision changes parent-child understanding or group-level reporting

#### Required fields
| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `candidate_pair_id` | string | Yes | Join key back to duplicate evidence |
| `left_account_id` | string | Yes | CRM-safe left `Account.Id` |
| `right_account_id` | string | Yes | CRM-safe right `Account.Id` |
| `left_parent_account_id` | string | Optional | Current known parent for left account |
| `right_parent_account_id` | string | Optional | Current known parent for right account |
| `hierarchy_conflict_flag` | boolean | Yes | Whether the pair implies hierarchy inconsistency |
| `hierarchy_impact_summary` | string | Yes | Plain-language description of likely impact |
| `affected_group_count` | integer | Optional | Number of linked group nodes affected |
| `run_id` | string | Yes | Pipeline run ID |
| `run_ts` | datetime | Yes | Pipeline run timestamp |

### D. Governance action payload
Primary consumer:
- Salesforce governance case experience

Purpose:
- capture the steward decision and make it operationally auditable

#### Required fields
| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `governance_case_id` | string | Yes | Governance workflow key |
| `candidate_pair_id` | string | Yes | Pair under review |
| `decision_status` | string | Yes | `approved`, `rejected`, or `deferred` |
| `decision_reason_code` | string | Yes | Structured reason for analytics |
| `decision_reason_text` | string | Optional | Steward free text |
| `decided_by_user_id` | string | Yes | Steward identity |
| `decided_at` | datetime | Yes | Audit timestamp |
| `surviving_account_id` | string | Conditional | Required for approved merge flows |
| `review_followup_required` | boolean | Yes | Whether follow-up work remains |
| `decision_run_id` | string | Recommended | Databricks evidence run used for the decision |

## Stewardship experience contract

### Minimum UI sections
1. Pair summary
   - left and right account names
   - duplicate confidence score and confidence band
   - last evidence refresh timestamp
2. Why Pulse360 flagged this
   - top match features
   - explanation snippets
3. Attribute trust panel
   - side-by-side conflicting values
   - validity score per field
   - review required markers
4. Hierarchy impact panel
   - current parent/group context
   - hierarchy conflict flag
   - impact summary
5. Decision controls
   - approve
   - reject
   - defer
   - reason capture

### UX acceptance bar
- The steward can make a decision without leaving the case to manually assemble basic duplicate evidence.
- Low-confidence states are visible and explicit.
- Every visible score has a nearby explanation or evidence source.
- The UI always shows the evidence freshness timestamp.

## Minimum execution backlog breakdown

### `DAN-116` Identity foundation
Definition for this slice:
- guarantee `crm_account_id` survives ingestion, gold intelligence outputs, Data Cloud linkage, and governance workflow payloads
- reject any stewardship design that depends on Databricks-only synthetic account IDs for operational action

### `DAN-117` Decision intelligence blueprint
Definition for this slice:
- formalize duplicate confidence features, confidence bands, and recommendation rules
- specify which attributes receive validity scoring in the first slice
- define the minimum hierarchy implication logic needed for merge review

### `DAN-118` Steward explainability contract
Definition for this slice:
- define the explanation payload structure for duplicate, validity, and hierarchy evidence
- distinguish machine-readable fields from human-readable explanation text
- define how low-confidence and review-required states are surfaced

### `DAN-119` Steward action loop
Definition for this slice:
- define approve, reject, and defer states
- define decision reason taxonomy
- define audit trail requirements and downstream truth-update event expectations

## Acceptance criteria
1. A governance case can be rendered using `crm_account_id`-safe duplicate, validity, and hierarchy evidence.
2. The stewardship UI exposes explanations, not just scalar scores.
3. The steward can approve, reject, or defer with an auditable reason.
4. Governance metrics can measure median resolution time, throughput, backlog, and reversal rate.
5. Evidence remains reproducible through run metadata, source snapshot, and model version.

## Proof-of-value cases
Prepare `3-5` validation cases that show:
- a high-confidence pair that can be approved quickly
- a medium-confidence pair that needs field-level trust review
- a pair with hierarchy conflict that changes the recommended decision
- a rejected pair where explanation prevents a bad merge

## Measures of value

### Core operational metrics
- median resolution time
- governance backlog count
- steward decisions per day
- deferred-case rate
- reversed-merge rate

### Product quality metrics
- share of decisions with visible explanation payload
- share of cases with complete freshness metadata
- share of decisions taken without leaving the governance workflow

## Related artifacts
- `docs/contracts/databricks-stewardship-output-spec.md`
- `docs/contracts/salesforce-governance-case-ux-contract.md`
- `docs/readout/pulse360-product-slice-definition.md`
- `docs/contracts/salesforce-crm-to-databricks-account-ingestion-contract.md`
- `docs/contracts/databricks-to-datacloud-contract.md`
- `docs/contracts/datacloud-to-salesforce-agentforce-contract.md`
