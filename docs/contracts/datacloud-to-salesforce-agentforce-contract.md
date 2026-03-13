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
| hierarchy_payload | json | Group and subsidiary tree |
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
- CRM activation requires a deterministic CRM-side match key:
  - preferred: native Salesforce `Account.Id`
  - alternative: a dedicated Salesforce External ID field
- If neither key is present in the Data Cloud activation path, activation to CRM `Account` is considered invalid for acceptance.

## Design Constraint
Databricks enrichment alone is insufficient for CRM writeback unless the pipeline has ingested Salesforce CRM Account source data, or otherwise preserved an approved CRM match key, before publishing to Data Cloud.

## Implemented Artifacts
- `contracts/datacloud_to_salesforce_agentforce.schema.json`
- `config/data-cloud/identity-resolution-rules.json`
- `config/data-cloud/calculated-insights.yaml`
- `config/data-cloud/activation-field-mapping.csv`
- `force-app/main/default/objects/Account/fields/*.field-meta.xml`
- `data/samples/datacloud_identity_resolution_sample.json`
- `data/samples/datacloud_activation_sample.json`
- `contracts/datacloud_account_core_canonical_v2.schema.json`
- `contracts/datacloud_product_brand_canonical_v2.schema.json`
- `contracts/datacloud_engagement_canonical_v2.schema.json`
- `scripts/validate-hierarchy-and-identity.sh`
- `scripts/validate-data-cloud-insights-config.sh`
- `scripts/validate-salesforce-account-activation-fields.sh`

## Related UX Contract
The first-slice Salesforce execution surface is defined in:
- `docs/contracts/salesforce-governance-case-ux-contract.md`
