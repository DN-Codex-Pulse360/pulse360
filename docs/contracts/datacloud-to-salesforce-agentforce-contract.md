# Contract: Data Cloud -> Salesforce/Agentforce

## Purpose
Define fields and payload needed by Salesforce UX and Agentforce actions.

In Pulse360, Data Cloud is the CRM-centered operational intelligence layer. It prepares and unifies the account context, hierarchy context, and Pulse360 extension evidence so Salesforce can execute stewardship, selling, and planning workflows from a common account model.

## Required Fields
| Field | Type | Description |
| --- | --- | --- |
| unified_profile_id | string | Data Cloud unified profile key |
| identity_confidence | number | Resolution confidence |
| source_account_id | string | CRM-safe `Account.Id` used for deterministic governance and CRM activation |
| hierarchy_payload | string | Serialized JSON group and subsidiary tree |
| intent_signal_payload | string | Serialized JSON routed-alert payload for signal-routing and SDR operating surfaces |
| group_revenue_rollup | number | Group-level revenue total |
| cross_sell_propensity | number | Calculated insight score |
| health_score | number | Account intelligence score |
| coverage_gap_flag | boolean | Subsidiary coverage gap indicator |
| competitor_risk_signal | number | Competitive pressure risk signal |
| primary_brand_name | string | Top brand affinity or ownership signal |
| active_product_count | integer | Active products linked to account |
| engagement_intensity_score | number | Composite engagement intensity score |
| open_opportunity_count | integer | Open opportunity count for account |
| last_engagement_timestamp | datetime | Most recent engagement touchpoint |
| last_synced_timestamp | datetime | Visible sync timestamp for UI |
| external_legal_name | string | Publicly confirmed legal name carried into CRM |
| external_registration_number | string | Registry or filing identifier when publicly available |
| is_externally_validated | boolean | Indicates whether public evidence confirms the entity |
| validity_score_external | number | Public-evidence confidence score |
| external_subsidiaries_found | integer | Subsidiaries found in external evidence but not fully modeled in CRM |
| ai_narrative | string | GPT-generated narrative summary serialized for CRM transport |
| ai_recommended_actions | string | JSON string of ranked actions for CRM/LWC rendering |
| ai_narrative_generated_at | datetime | GPT narrative freshness timestamp |
| enrichment_run_id | string | Links the CRM state back to a Databricks enrichment run |
| regulatory_readiness_score | number | Typed readiness score for regulatory/accountability storytelling |
| duplicate_exposure_count | integer | Count of open duplicate exposures for the account |
| group_known_subsidiary_count | integer | Count of known public group entities in scope |
| crm_covered_subsidiary_count | integer | Count of known group entities already represented in CRM |
| group_revenue_visible | number | Revenue currently visible through CRM-covered entities |
| external_revenue_confirmed | number | Revenue confirmed through public external evidence |
| model_id | string | GPT model used to create the narrative/action payload |
| prompt_version | string | Prompt template version used for generation |
| source_refs | string | JSON string of provenance references bound to the generated output |
| citation_count | integer | Count of source references rendered in the UI |

## Stewardship Slice Fields
These fields are mandatory for the first real product slice because DS-02 requires a decision-ready governance workflow, not only activated account metrics.

| Field | Type | Description |
| --- | --- | --- |
| candidate_pair_id | string | Stable duplicate pair key used in the stewardship experience |
| related_account_id | string | Opposite `Account.Id` in the candidate pair |
| duplicate_confidence | number | Duplicate confidence score shown to the steward |
| confidence_band | string | Human-usable confidence label |
| top_match_features | json | Ranked evidence factors for why the pair was flagged |
| attribute_validity_payload | json | Side-by-side field trust evidence for key conflicting attributes |
| hierarchy_impact_summary | string | Plain-language hierarchy consequence of the decision |
| hierarchy_conflict_flag | boolean | Indicates hierarchy inconsistency risk |
| review_flag | boolean | Manual review indicator |
| recommended_action | string | Pulse360 recommendation for approve, reject, or defer |
| governance_case_id | string | Governance case linkage |
| evidence_run_id | string | Evidence-producing Databricks run ID |
| evidence_run_timestamp | datetime | Evidence freshness timestamp shown in the UI |

## Rules
- Salesforce is execution surface, not source of truth.
- UI values must originate from Data Cloud or Databricks lineage-backed data.
- Activation contract is Account-centered but must include product, brand, and engagement rollups for B2B Customer 360 completeness.
- Activation mode is near real time (`<= 5` minute sync target) for DS-03 cross-sell workflows.
- Recompute triggers must include opportunity creation and governance merge approval events.
- Governance workflow fields must preserve the exact stewardship evidence payload needed to approve, reject, or defer a duplicate case without reconstructing evidence in Salesforce.
- GPT-rich fields are serialized for CRM transport, but their source contract remains typed upstream in Databricks/Data Cloud.
- `hierarchy_payload` must serialize a JSON object so Data Cloud can transport it through the `Text` DMO field surface.
- `hierarchy_payload` should expose a seller-usable group model, not only identity plumbing. The expected JSON shape is:
  - top-level group metadata: `group_id`, `parent_account_id`, `canonical_account_id`, `account_name`
  - `children` array with entity items such as:
    - `entity_id`
    - `crm_record_id` when the entity is already represented by a Salesforce `Account` record
    - `name`
    - `role`
    - `coverage_status`
    - `in_crm`
    - `signal`
    - `suggested_play`
- `source_refs` must serialize a JSON array where each item includes:
  - `source_id`
  - `source_name`
  - `source_type`
  - `source_url`
  - `document_date`
  - `accessed_at`
  - `excerpt`
  - `jurisdiction`
- Every GPT narrative and recommended action must reference only `source_id` values present in `source_refs`.
- When an action targets a CRM-covered entity or an existing governance case, `ai_recommended_actions.target_record_id` should carry the concrete Salesforce record id so the CRM surface can deep-link directly into execution.
- `regulatory_readiness_score` must be computed from typed fields and provenance-backed flags, never from free-text parsing of `ai_narrative`.
- CRM activation requires a deterministic CRM-side match key:
  - preferred: native Salesforce `Account.Id`
  - alternative: a dedicated Salesforce External ID field
- Covered hierarchy entities should carry `crm_record_id` inside `hierarchy_payload` so seller-facing workspaces can open the correct Salesforce record instead of treating external entity keys as record ids.
- If neither key is present in the Data Cloud activation path, activation to CRM `Account` is considered invalid for acceptance.

## Agentic Field Ownership
Agentforce may create companion interpretation fields, but must not become the
source of truth for deterministic intelligence fields.

Deterministic fields must remain owned by Databricks, Data Cloud, or
deterministic Apex logic:

- identity and join keys: `source_account_id`, `resolved_entity_id`,
  `crm_activation_key`, `unified_profile_id`
- scores and bands: `confidence_score`, `duplicate_confidence`,
  `hierarchy_confidence`, `health_score`, `validity_score_external`
- eligibility and routing flags: `activation_eligible_flag`,
  `activation_block_reasons`, `review_priority`, `coverage_gap_flag`
- operational state: `downstream_update_status`, `audit_event_id`,
  `last_synced_timestamp`, `enrichment_run_id`
- evidence payloads: `source_refs`, `confidence_components`,
  `hierarchy_payload`, `attribute_validity_payload`

Agentforce can generate and persist companion fields only when the output is
clearly framed as interpretation, rationale, explanation, or action packaging.
Candidate companion fields include:

- `Agent_Recommendation__c`
- `Agent_Rationale__c`
- `Agent_Evidence_Summary__c`
- `Agent_Risk_Flags__c`
- `Agent_Confidence_Explanation__c`
- `Agent_Next_Best_Action__c`
- `Agent_Output_Status__c`
- `Agent_Last_Run_At__c`
- `Agent_Model_Id__c`
- `Agent_Prompt_Version__c`
- `Agent_Source_Refs__c`
- `Agent_Run_Id__c`

Persisted agentic fields must carry model, prompt, source reference, timestamp,
run ID, and output status metadata. Regenerating an agentic recommendation must
not overwrite deterministic scores, keys, eligibility flags, evidence payloads,
or approved governance decisions.

The detailed implementation decision is tracked in:
- `docs/planning/pulse360-agentic-field-design-2026-04-29.md`

## Realization Notes
- `Copy Field Enrichment` is the canonical CRM realization pattern for scalar `Account` fields.
- `source_account_id` is required for CRM-safe matching, but it is a key, not a direct `Account` target field.
- `hierarchy_payload` remains required in the Data Cloud export and DMO surfaces, but it is not treated as a required direct `Account` field sync unless the CRM design explicitly adds raw hierarchy payload storage on `Account`.
- Seller experience v2 explicitly opts into optional CRM-side hierarchy payload storage through `Account.Hierarchy_Payload__c` so the seller workspace can render a group view without leaving Salesforce.
- Signal Routing now explicitly opts into optional CRM-side payload storage through `Account.Intent_Signal_Payload__c` so the routed-alert workspace can render threshold, route, and drafted follow-up context before Slack activation is complete.
- Validation of the direct `Account` sync surface should therefore use the narrower CRM field-sync contract, not the full export payload contract.

## Public Regional Demo Defaults
- The first public-example slice uses named Singapore + Philippines anchors:
  - `Singtel Group`
  - `Ayala Corporation`
  - `JG Summit Holdings, Inc.`
- Public evidence should come from official annual reports, company portfolio pages, official filing or investor-relations pages, and official public careers pages.
- GPT output should be presented as a model-generated synthesis of public evidence, not as a direct company statement.

## Design Constraint
Databricks enrichment alone is insufficient for CRM writeback unless the pipeline has ingested Salesforce CRM Account source data, or otherwise preserved an approved CRM match key, before publishing to Data Cloud.

## Implemented Artifacts
- `contracts/datacloud_to_salesforce_agentforce.schema.json`
- `contracts/datacloud_to_salesforce_account_sync.schema.json`
- `config/data-cloud/identity-resolution-rules.json`
- `config/data-cloud/calculated-insights.yaml`
- `config/data-cloud/dmo-account-extension-attributes.csv`
- `config/data-cloud/dmo-account-field-mapping.csv`
- `config/data-cloud/activation-field-mapping.csv`
- `force-app/main/default/objects/Account/fields/*.field-meta.xml`
- `data/samples/datacloud_identity_resolution_sample.json`
- `data/samples/datacloud_activation_sample.json`
- `contracts/datacloud_account_core_canonical_v2.schema.json`
- `contracts/datacloud_product_brand_canonical_v2.schema.json`
- `contracts/datacloud_engagement_canonical_v2.schema.json`
- `scripts/validate-hierarchy-and-identity.sh`
- `scripts/validate-data-cloud-insights-config.sh`
- `scripts/validate-data-cloud-dmo-extension.sh`
- `scripts/validate-salesforce-account-activation-fields.sh`
- `docs/runbook/dan-220-data-cloud-dmo-extension-runbook.md`

## Related UX Contract
The first-slice Salesforce execution surface is defined in:
- `docs/contracts/salesforce-governance-case-ux-contract.md`
