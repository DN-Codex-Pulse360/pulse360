# Spec: Salesforce Governance Case Implementation

## Purpose
Define the implementation-ready Salesforce package required to deliver the first Pulse360 stewardship workflow.

This spec translates the governance case UX contract into:
- Salesforce metadata requirements
- page and component implementation shape
- field-level ownership and type expectations
- validation expectations for repo and org deployment

## Scope
This spec covers the first-slice Salesforce build for `DS-02 Governance Case Resolution`.

In scope:
- governance case object and fields
- validation rules for stewardship decisions
- supporting Account references
- first LWC or record-page component contract
- audit and decision fields
- validator expectations

Out of scope:
- downstream merge automation implementation
- Account 360 seller page
- planner portfolio pages

## Implementation pattern

### Recommended primary object
`Governance_Case__c`

Reason:
- keeps stewardship workflow explicit and auditable
- avoids overloading standard Case semantics before the product workflow is proven
- allows a purpose-built field model for duplicate review and governed decisions

### Required related records
- `Account` as left reviewed account
- `Account` as right reviewed account
- optional reference to related surviving `Account`

## Metadata package requirements

### Required custom object
- `force-app/main/default/objects/Governance_Case__c/Governance_Case__c.object-meta.xml`
- `force-app/main/default/permissionsets/Governance_Case_Steward.permissionset-meta.xml`

### Minimum required fields on `Governance_Case__c`

#### Record identity and workflow
| API Name | Type | Purpose | System owner |
| --- | --- | --- | --- |
| `Candidate_Pair_Id__c` | Text(255) | Stable stewardship pair key | Databricks/Data Cloud |
| `Status__c` | Picklist | Workflow status | Salesforce |
| `Priority__c` | Picklist | Work prioritization | Salesforce |
| `Decision_Owner__c` | Lookup(User) | Assigned steward | Salesforce |
| `Decision_Status__c` | Picklist | Approved/rejected/deferred state | Salesforce |

#### Reviewed accounts
| API Name | Type | Purpose | System owner |
| --- | --- | --- | --- |
| `Left_Account__c` | Lookup(Account) | Left account under review | Data Cloud/Salesforce |
| `Right_Account__c` | Lookup(Account) | Right account under review | Data Cloud/Salesforce |
| `Surviving_Account__c` | Lookup(Account) | Required for approved outcome | Salesforce |
| `Merged_Account__c` | Lookup(Account) | Losing account selected for merge execution | Salesforce |

#### Evidence summary fields
| API Name | Type | Purpose | System owner |
| --- | --- | --- | --- |
| `Duplicate_Confidence__c` | Number(5,2) | Steward-visible confidence | Databricks/Data Cloud |
| `Confidence_Band__c` | Picklist | High/medium/low | Databricks/Data Cloud |
| `Recommended_Action__c` | Picklist | Approve/review/reject guidance | Databricks/Data Cloud |
| `Review_Flag__c` | Checkbox | Manual review indicator | Databricks/Data Cloud |
| `Hierarchy_Conflict_Flag__c` | Checkbox | Hierarchy inconsistency indicator | Databricks/Data Cloud |
| `Hierarchy_Impact_Summary__c` | Long Text Area | Plain-language hierarchy impact | Databricks/Data Cloud |
| `Source_Snapshot_Id__c` | Text(255) | Replay-safe source snapshot | Databricks/Data Cloud |
| `Evidence_Run_Id__c` | Text(255) | Databricks evidence run | Databricks/Data Cloud |
| `Evidence_Run_Timestamp__c` | DateTime | Evidence freshness timestamp | Databricks/Data Cloud |
| `Model_Version__c` | Text(255) | Evidence/model version | Databricks/Data Cloud |

#### Explanation payload fields
| API Name | Type | Purpose | System owner |
| --- | --- | --- | --- |
| `Top_Match_Features__c` | Long Text Area | Serialized feature list | Databricks/Data Cloud |
| `Feature_Explanations__c` | Long Text Area | Serialized explanation payload | Databricks/Data Cloud |
| `Attribute_Validity_Payload__c` | Long Text Area | Serialized field trust payload | Databricks/Data Cloud |

#### Decision and audit fields
| API Name | Type | Purpose | System owner |
| --- | --- | --- | --- |
| `Decision_Reason_Code__c` | Picklist | Structured reason taxonomy | Salesforce |
| `Decision_Reason_Text__c` | Long Text Area | Optional steward note | Salesforce |
| `Review_Followup_Required__c` | Checkbox | Follow-up requirement | Salesforce |
| `Decided_By__c` | Lookup(User) | Decision maker | Salesforce |
| `Decided_At__c` | DateTime | Decision timestamp | Salesforce |
| `Audit_Event_Id__c` | Text(255) | Audit correlation key | Salesforce |
| `Downstream_Update_Status__c` | Picklist | Post-decision update status | Salesforce/Data Cloud |
| `Merge_Execution_Status__c` | Picklist | Merge transaction state | Salesforce |
| `Merge_Executed_By__c` | Lookup(User) | Merge transaction actor | Salesforce |
| `Merge_Executed_At__c` | DateTime | Merge transaction timestamp | Salesforce |

## Picklist value expectations

### `Status__c`
- `New`
- `Ready for Review`
- `In Review`
- `Approved`
- `Rejected`
- `Deferred`
- `Closed`

### `Decision_Status__c`
- `Approved`
- `Rejected`
- `Deferred`

### `Confidence_Band__c`
- `High`
- `Medium`
- `Low`

### `Recommended_Action__c`
- `Approve Merge`
- `Review`
- `Reject Match`

### `Decision_Reason_Code__c`
Approve reasons:
- `CLEAR_DUPLICATE_MATCH`
- `LEGAL_ENTITY_MATCH_CONFIRMED`
- `TRUSTED_ATTRIBUTE_ALIGNMENT`
- `HIERARCHY_ALIGNMENT_CONFIRMED`
- `REFERENCE_DATA_CONFIRMED`

Reject reasons:
- `DIFFERENT_LEGAL_ENTITIES`
- `INSUFFICIENT_MATCH_EVIDENCE`
- `HIERARCHY_CONFLICT_BLOCKS_MATCH`
- `TRUSTED_ATTRIBUTE_CONFLICT`
- `FALSE_POSITIVE_MODEL_OUTPUT`

Defer reasons:
- `NEEDS_EXTERNAL_REFERENCE_CHECK`
- `NEEDS_BUSINESS_OWNER_REVIEW`
- `NEEDS_HIERARCHY_VALIDATION`
- `NEEDS_DATA_REMEDIATION`
- `NEEDS_POLICY_DECISION`

### `Downstream_Update_Status__c`
- `Not Started`
- `Queued`
- `In Progress`
- `Completed`
- `Failed`

### `Merge_Execution_Status__c`
- `Not Started`
- `Ready for Merge`
- `In Progress`
- `Completed`
- `Failed`
- `Skipped`

## Page implementation contract

### Recommended record page
- `Governance_Case__c` Lightning Record Page

### Recommended primary component
- `force-app/main/default/lwc/governanceCaseReview/`

Purpose:
- render the evidence-rich stewardship case inside one guided execution surface

### LWC inputs
| Input | Source |
| --- | --- |
| `recordId` | `Governance_Case__c.Id` |
| wire record fields | `Governance_Case__c` metadata fields |
| related Account display fields | Account lookups and standard account fields |
| lookup selection controls | Salesforce-native Account record picker / lookup pattern |

### LWC display sections
1. Case header
2. Pair summary
3. Why Pulse360 flagged this
4. Attribute trust panel
5. Hierarchy impact panel
6. Decision panel
7. Audit/outcome panel

### LWC action handlers
- `handleApprove`
- `handleReject`
- `handleDefer`

### Action behavior requirements
- require `Decision_Reason_Code__c` before save
- require `Surviving_Account__c` on approve
- require `Merged_Account__c` on approve for the two-account merge path
- stamp `Decision_Status__c`, `Decided_By__c`, and `Decided_At__c`
- persist `Review_Followup_Required__c`
- leave Databricks/Data Cloud evidence fields read-only in the UI
- render Account references as record links, not raw Salesforce IDs

## Field behavior rules
1. Evidence fields populated from Databricks/Data Cloud must be read-only in Salesforce.
2. Transactional decision fields must be editable only through the governance-case workflow.
3. `Decision_Reason_Code__c` is mandatory for all final decisions.
4. `Surviving_Account__c` is mandatory when `Decision_Status__c = Approved`.
5. `Merged_Account__c` should be populated before a Salesforce merge is executed for a two-account duplicate case.
6. `Decided_By__c` and `Decided_At__c` must be set automatically on final decision.
7. `Merge_Executed_By__c` and `Merge_Executed_At__c` should be set when merge execution status moves to `Completed` or `Failed`.
8. Lookup relationships shown to stewards should use Salesforce-native navigation semantics.

## Validation rule requirements

The first-slice implementation should enforce these rules at the platform level:

1. Final decisions require `Decision_Reason_Code__c`.
2. Approved outcomes require `Surviving_Account__c`.
3. Approved outcomes require `Merged_Account__c`.
4. `Surviving_Account__c` and `Merged_Account__c` must not be the same record.

## Validation expectations

### Repo-level validation
The implementation should eventually be covered by a validator such as:
- `scripts/validate-governance-case-metadata.sh`

That validator should check for:
- presence of `Governance_Case__c` object metadata
- presence of required custom field metadata files
- presence of required validation rule metadata files
- presence of the governance case LWC bundle or equivalent Lightning page artifact
- presence of required picklist values in metadata
- presence of the UX contract and implementation spec docs

### Org-level validation
When deployed to a target org, validation should confirm:
- `Governance_Case__c` exists
- required fields exist with expected data types
- the record page or component is deployed
- steward permission set grants object, field, and tab access
- a steward can save `Approve`, `Reject`, and `Defer` decisions with correct validation behavior
- validation rules enforce stewardship requirements outside the LWC path

## QA checklist additions
The Salesforce governance-case implementation should add or satisfy checks for:
- DS-02 runs end to end with governance audit trail
- governance case UI exists and is usable by `Data Operations`
- approve/reject/defer validation rules work
- evidence freshness timestamp is visible in the UI

## Suggested implementation sequence
1. Create `Governance_Case__c` object metadata and required fields.
2. Create the `governanceCaseReview` LWC or equivalent page composition.
3. Bind the LWC to the stewardship payload fields delivered through Data Cloud/Salesforce.
4. Add repo validator coverage.
5. Add org deployment/runtime validation.

## Related artifacts
- `docs/contracts/salesforce-governance-case-ux-contract.md`
- `docs/contracts/pulse360-stewardship-slice-contract.md`
- `docs/contracts/databricks-stewardship-output-spec.md`
- `docs/contracts/datacloud-to-salesforce-agentforce-contract.md`
