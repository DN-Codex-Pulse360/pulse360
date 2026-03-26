# Evidence: Governance Case Stewardship Progress (2026-03-12)

## Scope

Checkpoint for the first real Salesforce stewardship slice under Pulse360 Account Intelligence.

Focus area:
- `DS-02 Governance Case Resolution`
- `Data Operations` stewardship workflow in Salesforce CRM

## What Was Completed

### Salesforce execution surface

- Deployed `Governance_Case__c` custom object and stewardship field model.
- Deployed `Governance Case` tab and record page.
- Deployed `governanceCaseReview` LWC as the primary review surface.

### Stewardship UX hardening

- Replaced raw lookup IDs with actual record links for Account and User references.
- Replaced free-text surviving-account entry with Salesforce-native Account record pickers.
- Reworked the review component into a console-style layout:
  - recommendation summary
  - case state
  - account pair comparison
  - decision workspace
  - evidence and audit panels

### Security and access

- Added `Governance_Case_Steward` permission set.
- Reduced steward edit scope so Databricks/Data Cloud evidence fields are read-only.
- Retained edit access only for decision and merge-path fields.

### Platform-level governance enforcement

Added validation rules on `Governance_Case__c` so governance behavior is enforced outside the LWC path:

- `Require_Reason_On_Final_Decision`
- `Require_Surviving_Account_On_Approval`
- `Require_Merged_Account_On_Approval`
- `Prevent_Same_Merge_Accounts`

## Org Validation

Target org:
- `pulse360-dev`

Successful deploy checkpoints:
- governance review and steward permission set: `0AfdM00000WfZnNSAV`
- redesigned governance review console: `0AfdM00000WfbIvSAJ`
- validation rules: `0AfdM00000WfQDtSAN`

Direct org validation confirmed:

1. rejecting without a reason fails with the expected decision-reason validation error
2. approving without surviving and merged accounts fails with the expected required-field validation errors
3. approving with the same account in both slots fails with the expected distinct-account validation error

## Seeded Test Records

Seeded Accounts:
- `Acme Industrial Holdings`
- `Acme Industrial Holding Ltd`
- `Globex APAC Holdings`
- `Globex APAC Pte Ltd`

Seeded Governance Cases:
- approve-merge example: `GC-00003`
- hierarchy-review example: `GC-00004`

## Current State Assessment

The first real stewardship slice is now credible as a Salesforce CRM workflow:

- real Account links
- real Account selection controls
- platform-enforced governance rules
- seeded record-level test cases

This is no longer just a metadata shell or UX mock.

## Remaining Gap

The major remaining gap is merge execution orchestration, not stewardship review.

Next product step:
- define and implement how a governance case in `Ready for Merge` becomes an actual Salesforce account merge transaction, with audit/status feedback into the case.

## Scope Boundary Clarification (2026-03-25)

This evidence note is sufficient to treat the first-slice Salesforce stewardship review experience as delivered for Milestone D:

- `Governance_Case__c` metadata, page, tab, LWC, permissioning, and validation rules are present in source.
- The stewardship console renders repo-backed confidence, validity, hierarchy, and audit fields from the governance case record.
- Decision stamping automation covers the first final-decision transition and prepares approved cases for merge follow-through.

The remaining open items are outside the clean Milestone D implementation boundary:

- live Data Cloud activation freshness, identity confidence propagation, and seller-facing downstream field population remain Milestone C work under `DAN-61` and `DAN-114`
- actual merge execution orchestration and post-decision downstream status feedback should be tracked as a separate follow-up issue rather than keeping `DAN-63` artificially open
