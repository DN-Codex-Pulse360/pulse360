# Pulse360 M1 Account Hierarchy Intelligence Delivery Slice

## Purpose

Define the first buildable module slice for the revised Pulse360 RevOps Intelligence architecture.

M1 is the recommended first module because hierarchy truth unlocks the rest of the proposition: group revenue, coverage gaps, whitespace, planning, renewal risk, and credible Account 360 summaries.

## Linear Scope

- Parent plan: `DAN-280`
- Module sequencing: `DAN-291`
- Identity spine: `DAN-282`
- Plural enrichment: `DAN-283`
- Entity resolution and hierarchy stitching: `DAN-284`
- Weighted attributes: `DAN-285`
- Data Cloud operational profile: `DAN-287`
- Salesforce UX/action surfaces: `DAN-288`
- Governance evidence: `DAN-290`

## M1 Promise

Make the customer's biggest accounts look as large as they actually are.

The user should be able to see:

- the true commercial group
- the current CRM-covered entities
- the uncovered subsidiaries or related entities
- the group revenue or commercial footprint
- the confidence and source basis for the hierarchy
- the next coverage or planning action

## First-Slice Data Boundary

### Inputs

- Salesforce CRM Account data from `pulse360_s4.silver_salesforce.crm_account`
- CRM hierarchy edges from `pulse360_s4.silver_salesforce.crm_account_hierarchy_edge`
- First registry-source sample from `pulse360_s4.identity_resolution.registry_identity_source_sample`
- Current account export and activation fields

### Deferred Inputs

- Live national registry connectors
- Marketplace providers such as D&B, BvD, ZoomInfo, Crunchbase, or LiveRamp
- Customer-internal franchise/subsidiary masters
- Clean-room collaborative data

These are feasible follow-ons, not prerequisites for the first M1 slice.

## Required Databricks Outputs

### `pulse360_s4.identity_resolution.resolved_entity`

Purpose:
- represent CRM-safe fallback entities and deterministic registry-source entities.

M1 fields used:
- `resolved_entity_id`
- `sovereign_identity_key`
- `country_of_incorporation`
- `registered_legal_name`
- `identity_resolution_method`
- `identity_confidence`
- `crm_account_ids`
- `source_identifiers`
- `run_id`
- `run_timestamp`
- `model_version`

### `pulse360_s4.identity_resolution.weighted_attribute_resolution`

Purpose:
- explain which source contributed each visible attribute.

M1 attributes:
- `registered_legal_name`
- `annual_revenue`
- `industry`
- future: `parent_entity_id`
- future: `group_revenue_rollup`
- future: `coverage_gap_flag`

### `pulse360_s4.identity_resolution.entity_hierarchy_edge`

Purpose:
- one row per parent-child edge
- confidence and source contribution for the edge
- relationship type
- CRM coverage status
- effective dates
- run metadata

### `pulse360_s4.identity_resolution.entity_hierarchy_rollup`

Purpose:
- group-level rollup row
- known subsidiary count
- CRM-covered subsidiary count
- uncovered subsidiary count
- group revenue visible
- hierarchy confidence
- freshness status

## Data Cloud Operational Shape

Source contract:

- `docs/contracts/pulse360-m1-data-cloud-operational-profile-contract.md`

Validation:

- `scripts/validate-m1-data-cloud-operational-profile.sh`

### Summary Attributes

These can be copied to Salesforce Account when target fields exist:

- `group_revenue_rollup`
- `group_known_subsidiary_count`
- `crm_covered_subsidiary_count`
- `coverage_gap_flag`
- `identity_confidence`
- `validity_score_external`
- `last_synced_timestamp`

### Detail/Drill-Through

These should remain in Data Cloud/Databricks or related-list drill-through, not default Account fields:

- full hierarchy payload
- all source contribution rows
- all edge evidence
- all candidate/conflict records

## Salesforce Surface

Source contract:

- `docs/contracts/pulse360-m1-salesforce-action-surface-contract.md`

Validation:

- `scripts/validate-m1-salesforce-action-surface.sh`

### M1 Account Page Summary

Must show:

- group name or resolved account name
- group revenue visible
- CRM-covered entities
- uncovered entities
- hierarchy confidence/freshness
- top source evidence
- action entry point

### Planner Surface

Must show:

- accounts or groups ranked by coverage gap
- current owner/territory context
- suggested planning action
- reason the group is under-covered or mis-sized

## Actions

First-slice actions:

- create coverage task
- route to account owner
- flag hierarchy review
- open governance case for weak/conflicting match

Later actions:

- create opportunity for uncovered subsidiary
- assign specialist coverage
- trigger Account plan update

## Acceptance Criteria

1. A reviewer can distinguish CRM-safe fallback identity from deterministic registry-source identity.
2. Every visible M1 attribute has confidence, freshness, and source contribution metadata.
3. Group/hierarchy summary uses real CRM-safe IDs where Salesforce action is possible.
4. The user can identify at least one coverage or planning action from the M1 surface.
5. Raw graph detail is not dumped into Salesforce by default; Salesforce remains an altitude-3 summary/action surface.
6. Any live registry/provider absence is described as a data-source gap, not a platform infeasibility.

## First Build Tasks

1. Extend Data Cloud account mapping for M1 summary fields. `Done for first source slice: config/data-cloud/m1-account-hierarchy-operational-profile-mapping.csv`
2. Extend/validate Group Revenue Reveal and planner surface payloads against the new M1 output. `Done for first source slice: config/salesforce/m1-account-hierarchy-action-surface-matrix.csv`
3. Add runtime lineage validation for CRM account and registry sample paths.
4. Replace the registry sample with a live registry/provider connector when provider access is approved.

## Gate

M1 can move from design to build when:

- `DAN-282`, `DAN-283`, and `DAN-285` have first-slice contracts in source.
- `DAN-284` has hierarchy edge and rollup outputs defined and validated.
- `DAN-287` identifies which fields are copied to Salesforce vs held for drill-through.
- `DAN-288` names the target Salesforce surfaces and actions.
