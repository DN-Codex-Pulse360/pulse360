# Contract: Databricks -> Data Cloud Pulse360 Export

## Purpose
Define the comprehensive Databricks export layer that feeds Salesforce Data Cloud for Pulse360.

This contract expands the earlier narrow enrichment handoff into a richer Pulse360 export model aligned with:
- the upstream CRM source-ingestion contract in `docs/contracts/salesforce-crm-to-databricks-account-ingestion-contract.md`
- the Data Cloud canonical model in `docs/contracts/b2b-customer360-canonical-model-v2.md`
- the standard Data Cloud subject areas for Party, Product, Sales Order, and overall Customer 360

## Point of View
The Pulse360 Data Cloud export should be rich, relationship-safe, and closer to the standard Data Cloud model than to a one-table enrichment dump.

Data Cloud should not be treated as a passive transport layer. In Pulse360 it acts as the CRM-centered operational intelligence foundation: a modern CDP-style account layer that unifies canonical CRM context with Pulse360 intelligence so Account 360, stewardship workflow, and activation can all operate from the same operational model.

The export layer should preserve:
1. CRM-safe business keys
2. party/account/contact relationships
3. hierarchy relationships
4. product/brand relationships
5. commercial and engagement context
6. intelligence extensions and activation-ready rollups
7. governance and replay metadata

## Export Design Principles
1. Data Cloud DMOs are the canonical target shape.
2. Databricks remains the intelligence and enrichment layer, not the canonical identity authority.
3. Databricks exports must retain CRM-safe keys so Data Cloud can activate enriched values back to Salesforce CRM deterministically.
4. Synthetic Databricks entity identifiers may exist internally, but they must not replace CRM-safe keys in exports intended for CRM writeback.
5. Rich relationship data is preferred over flattened convenience fields when both are available.

## Export Domains

### 1) Account Core Export
Primary target:
- `ssot__Account__dlm`

Purpose:
- carry the account-centric canonical profile baseline plus enriched account-level attributes used in Account 360 and activation

#### Minimum Required Fields
| Field | Type | Required | Role |
| --- | --- | --- | --- |
| `canonical_account_id` | string | Yes | Export-level canonical account identifier |
| `source_account_id` | string | Yes | Preferred CRM writeback key (`Account.Id`) |
| `source_account_external_id` | string | Conditional | External ID alternative when used |
| `deterministic_key` | string | Yes | Replay-safe deterministic account key |
| `account_name` | string | Yes | Account identity |
| `parent_account_id` | string | Recommended | Hierarchy baseline |
| `owner_user_id` | string | Recommended | CRM owner context |
| `industry` | string | Recommended | Firmographic context |
| `account_type` | string | Recommended | Classification |
| `billing_city` | string | Optional | Geography |
| `billing_state` | string | Optional | Geography |
| `billing_country` | string | Optional | Geography |
| `annual_revenue` | number | Optional | Commercial context |
| `number_of_employees` | integer | Optional | Firmographic context |
| `identity_confidence` | number | Recommended | Identity resolution evidence |
| `validity_score` | number | Recommended | Enrichment confidence |
| `review_flag` | boolean | Recommended | Manual review indicator |
| `unified_profile_id` | string | Recommended | Data Cloud-aligned identity output |
| `group_revenue_rollup` | number | Recommended | Hierarchy rollup output |
| `health_score` | number | Recommended | Account intelligence output |
| `cross_sell_propensity` | number | Recommended | Commercial propensity output |
| `coverage_gap_flag` | boolean | Recommended | Subsidiary/portfolio gap signal |
| `competitor_risk_signal` | number | Recommended | Competitive risk signal |
| `primary_brand_name` | string | Recommended | Brand rollup |
| `active_product_count` | integer | Recommended | Product ownership rollup |
| `engagement_intensity_score` | number | Recommended | Engagement rollup |
| `open_opportunity_count` | integer | Recommended | Commercial rollup |
| `last_engagement_timestamp` | datetime | Recommended | Last-touch context |
| `last_synced_timestamp` | datetime | Recommended | Freshness and activation visibility |
| `ingestion_metadata_label` | string | Optional | Demo/runtime freshness label |
| `run_id` | string | Yes | Replay metadata |
| `run_timestamp` | datetime | Yes | Replay metadata |
| `model_version` | string | Yes | Pipeline version |

### 2) Account Contact Export
Primary target:
- `ssot__AccountContact__dlm`

Purpose:
- preserve account-to-contact relationship structure for buying-center and person linkage

#### Minimum Required Fields
| Field | Type | Required | Role |
| --- | --- | --- | --- |
| `account_contact_id` | string | Yes | Relationship row key |
| `source_account_id` | string | Yes | Account linkage |
| `source_contact_id` | string | Yes | Contact linkage |
| `contact_role` | string | Optional | Role semantics |
| `is_primary_contact` | boolean | Optional | Primary designation |
| `source_system` | string | Yes | Provenance |
| `run_id` | string | Yes | Replay metadata |
| `run_timestamp` | datetime | Yes | Replay metadata |
| `model_version` | string | Yes | Pipeline version |

### 3) Individual / Person Export
Primary target:
- `ssot__Individual__dlm`

Purpose:
- preserve person-level identity and contactability context where Pulse360 needs more than account-only modeling

#### Minimum Required Fields
| Field | Type | Required | Role |
| --- | --- | --- | --- |
| `individual_id` | string | Yes | Person key |
| `source_contact_id` | string | Yes | CRM contact source key |
| `source_account_id` | string | Recommended | Account linkage |
| `first_name` | string | Optional | Identity |
| `last_name` | string | Yes | Identity |
| `full_name` | string | Yes | Identity |
| `email` | string | Recommended | Reachability |
| `phone` | string | Optional | Reachability |
| `mobile_phone` | string | Optional | Reachability |
| `title` | string | Optional | Role context |
| `department` | string | Optional | Role context |
| `lead_source` | string | Optional | Acquisition context |
| `mailing_city` | string | Optional | Geography |
| `mailing_state` | string | Optional | Geography |
| `mailing_country` | string | Optional | Geography |
| `run_id` | string | Yes | Replay metadata |
| `run_timestamp` | datetime | Yes | Replay metadata |
| `model_version` | string | Yes | Pipeline version |

### 4) Hierarchy Relationship Export
Primary targets:
- Account parent-child relationship structures in Data Cloud
- downstream hierarchy-aware account views and rollups

Purpose:
- preserve enterprise parent-child graph and rollup-safe account relationships

#### Minimum Required Fields
| Field | Type | Required | Role |
| --- | --- | --- | --- |
| `hierarchy_edge_id` | string | Yes | Relationship row key |
| `parent_account_id` | string | Yes | Parent CRM/canonical account |
| `child_account_id` | string | Yes | Child CRM/canonical account |
| `relationship_type` | string | Yes | Parent-child semantics |
| `hierarchy_depth` | integer | Optional | Depth context |
| `hierarchy_path` | string | Optional | Traceability |
| `group_revenue_rollup` | number | Optional | Rollup output |
| `uncovered_subsidiary_flag` | boolean | Optional | Coverage gap signal |
| `run_id` | string | Yes | Replay metadata |
| `run_timestamp` | datetime | Yes | Replay metadata |
| `model_version` | string | Yes | Pipeline version |

### 5) Product and Brand Export
Primary targets:
- `ssot__GoodsProduct__dlm`
- `ssot__MasterProduct__dlm`
- `ssot__Brand__dlm`
- related product/brand bridge structures

Purpose:
- preserve commercial product context, brand relationships, and account-linked product ownership needed for Account 360 and cross-sell

#### Minimum Required Fields
| Field | Type | Required | Role |
| --- | --- | --- | --- |
| `canonical_account_id` | string | Yes | Account linkage |
| `product_id` | string | Yes | Product key |
| `master_product_id` | string | Recommended | Product family/master |
| `bundle_product_id` | string | Optional | Bundle context |
| `brand_id` | string | Recommended | Brand key |
| `brand_name` | string | Recommended | Brand display |
| `relationship_type` | string | Yes | Product-brand/account semantics |
| `product_name` | string | Recommended | Product display |
| `product_code` | string | Recommended | Commercial key |
| `product_family` | string | Optional | Product grouping |
| `product_class` | string | Optional | Product taxonomy |
| `is_active` | boolean | Yes | Validity |
| `source_system` | string | Yes | Provenance |
| `run_id` | string | Yes | Replay metadata |
| `run_timestamp` | datetime | Yes | Replay metadata |
| `model_version` | string | Yes | Pipeline version |

### 6) Commercial Intent Export
Primary targets:
- `ssot__Opportunity__dlm`
- `ssot__OpportunityProduct__dlm`
- future sales order DMOs where available

Purpose:
- preserve opportunity and product-level commercial context around the account

#### Minimum Required Fields
| Field | Type | Required | Role |
| --- | --- | --- | --- |
| `opportunity_id` | string | Yes | Opportunity key |
| `source_account_id` | string | Yes | Account linkage |
| `source_contact_id` | string | Optional | Contact linkage |
| `owner_user_id` | string | Recommended | Sales ownership |
| `opportunity_name` | string | Yes | Display identity |
| `stage_name` | string | Yes | Lifecycle state |
| `amount` | number | Recommended | Commercial magnitude |
| `probability` | number | Recommended | Commercial likelihood |
| `expected_revenue` | number | Optional | Forecast context |
| `close_date` | date | Yes | Time context |
| `opportunity_type` | string | Optional | Classification |
| `forecast_category` | string | Optional | Forecast rollups |
| `is_closed` | boolean | Yes | Lifecycle state |
| `is_won` | boolean | Yes | Outcome state |
| `pricebook_id` | string | Optional | Pricing context |
| `run_id` | string | Yes | Replay metadata |
| `run_timestamp` | datetime | Yes | Replay metadata |
| `model_version` | string | Yes | Pipeline version |

### 7) Opportunity Product Export
Primary targets:
- `ssot__OpportunityProduct__dlm`
- product-level intent and commercial rollups

#### Minimum Required Fields
| Field | Type | Required | Role |
| --- | --- | --- | --- |
| `opportunity_line_item_id` | string | Yes | Line item key |
| `opportunity_id` | string | Yes | Opportunity linkage |
| `product_id` | string | Yes | Product linkage |
| `pricebook_entry_id` | string | Optional | Pricing linkage |
| `product_code` | string | Recommended | Commercial key |
| `quantity` | number | Yes | Commercial quantity |
| `unit_price` | number | Recommended | Commercial unit value |
| `list_price` | number | Optional | List price context |
| `total_price` | number | Recommended | Total commercial value |
| `service_date` | date | Optional | Time context |
| `run_id` | string | Yes | Replay metadata |
| `run_timestamp` | datetime | Yes | Replay metadata |
| `model_version` | string | Yes | Pipeline version |

### 8) Engagement Export
Primary targets:
- engagement DMOs and extension datasets linked to canonical account/person/product context

Purpose:
- preserve account-linked behavioral, commercial, and service engagement context for health, propensity, and risk scoring

#### Minimum Required Fields
| Field | Type | Required | Role |
| --- | --- | --- | --- |
| `canonical_account_id` | string | Yes | Account linkage |
| `engagement_id` | string | Yes | Engagement key |
| `engagement_type` | string | Yes | Event type |
| `engagement_timestamp` | datetime | Yes | Event time |
| `channel` | string | Optional | Channel |
| `source_contact_id` | string | Optional | Person linkage |
| `product_id` | string | Optional | Product linkage |
| `brand_id` | string | Optional | Brand linkage |
| `related_opportunity_id` | string | Optional | Commercial linkage |
| `engagement_score` | number | Recommended | Intensity metric |
| `source_system` | string | Yes | Provenance |
| `run_id` | string | Yes | Replay metadata |
| `run_timestamp` | datetime | Yes | Replay metadata |
| `model_version` | string | Yes | Pipeline version |

### 9) Intelligence Extension Export
Primary targets:
- Pulse360-specific extension datasets linked to canonical Data Cloud entities

Purpose:
- preserve explainability, governance, and review context that should not overwrite canonical core data but must remain activatable and auditable

Stewardship-first rule:
- the first execution slice must export decision-grade duplicate, validity, and hierarchy evidence using CRM-safe account linkage so DS-02 governance cases can be rendered without reconstructing logic in Salesforce

#### Minimum Required Fields
| Field | Type | Required | Role |
| --- | --- | --- | --- |
| `entity_id` | string | Yes | Extension entity key |
| `source_account_id` | string | Yes | CRM-safe account linkage |
| `candidate_pair_id` | string | Recommended | Stable stewardship pair key |
| `related_account_id` | string | Recommended | Opposite account in the duplicate pair |
| `duplicate_confidence` | number | Optional | Duplicate recommendation evidence |
| `confidence_band` | string | Optional | Human-usable stewardship confidence band |
| `top_match_features` | json | Optional | Ranked factors that drove duplicate confidence |
| `validity_score` | number | Optional | Attribute validity evidence |
| `review_flag` | boolean | Optional | Review signal |
| `review_reason` | string | Optional | Explainability |
| `attribute_name` | string | Optional | Field-level stewardship evidence |
| `attribute_value` | string | Optional | Field-level stewardship evidence |
| `hierarchy_conflict_flag` | boolean | Optional | Indicates hierarchy inconsistency risk |
| `hierarchy_impact_summary` | string | Optional | Plain-language hierarchy consequence |
| `governance_case_id` | string | Optional | Governance linkage |
| `recommended_action` | string | Optional | Stewardship guidance such as approve, reject, or review |
| `run_id` | string | Yes | Replay metadata |
| `run_timestamp` | datetime | Yes | Replay metadata |
| `model_version` | string | Yes | Pipeline version |

## CRM Writeback Rules
1. Records intended for Salesforce CRM writeback must preserve a CRM-matchable key from source ingestion.
2. Allowed CRM writeback keys are:
   - native Salesforce `Account.Id`, carried through Databricks as `source_account_id`, or
   - a dedicated Salesforce External ID field present in both CRM and the Databricks export.
3. Databricks enrichment outputs intended for CRM activation must be built from ingested Salesforce CRM Account source data.
4. If neither native `Account.Id` nor an approved External ID is present, the export is invalid for CRM activation acceptance.

## Data Cloud Model Alignment
Pulse360 exports should align to these standard Data Cloud subject areas:
- Party / Identity
- Product
- Sales Order / Commercial
- Engagement
- Service / Governance context where relevant

Pulse360-specific intelligence outputs should be modeled as extension datasets linked to canonical Data Cloud entities rather than as a replacement for them.

## Implemented and Planned Artifacts
- `contracts/databricks_to_datacloud.schema.json`
- `contracts/databricks_hierarchy_graph.schema.json`
- `contracts/datacloud_account_core_canonical_v2.schema.json`
- `contracts/datacloud_product_brand_canonical_v2.schema.json`
- `contracts/datacloud_engagement_canonical_v2.schema.json`
- `data/samples/databricks_enrichment_sample.csv`
- `data/samples/hierarchy/databricks_hierarchy_graph_sample.json`
- `data/samples/datacloud_account_core_canonical_v2_sample.json`
- `data/samples/datacloud_product_brand_canonical_v2_sample.json`
- `data/samples/datacloud_engagement_canonical_v2_sample.json`
- `data/samples/datacloud_account_core_canonical_v2_export.csv`
- `data/samples/datacloud_account_core_canonical_v2_export.jsonl`
- `data/samples/datacloud_product_brand_canonical_v2_export.csv`
- `data/samples/datacloud_product_brand_canonical_v2_export.jsonl`
- `data/samples/datacloud_engagement_canonical_v2_export.csv`
- `data/samples/datacloud_engagement_canonical_v2_export.jsonl`
- `config/databricks/unity-catalog-governance.yaml`
- `config/databricks/lineage-targets.env.sample`
- `scripts/validate-contracts.sh`
- `scripts/validate-hierarchy-and-identity.sh`
- `scripts/validate-unity-catalog-config.sh`
- `scripts/check-databricks-lineage-runtime.sh`

## Acceptance Criteria
1. Databricks exports are rich enough to populate Account, party/contact, product/brand, engagement, and commercial context in Data Cloud.
2. CRM-safe keys are preserved for any export that participates in Salesforce CRM activation.
3. Relationship-safe exports exist for hierarchy, account-contact, opportunity, product, and engagement contexts.
4. Intelligence extension data remains explainable, auditable, and linked to canonical entities.
5. Data Cloud can activate account-centric derived values back to Salesforce CRM without relying on Databricks-origin synthetic account IDs.

## Validation Checklist
1. Validate canonical export files and schemas.
2. Validate cross-file key integrity across account, product/brand, and engagement exports.
3. Validate hierarchy relationship outputs preserve account-safe identifiers.
4. Validate activation-ready account exports preserve native CRM `Account.Id` or approved External ID.
5. Reject any CRM activation test that uses synthetic-only Databricks account identifiers as the match key.

## DAN-60 Evidence Snapshot (2026-03-08)
- Identity rule threshold configured at `>=90` in `config/data-cloud/identity-resolution-rules.json`.
- Key demo identity pairs meet threshold in `data/samples/datacloud_identity_resolution_sample.json`.
- Hierarchy sample demonstrates multi-level parent-child graph and supports rollup context in:
  - `data/samples/hierarchy/databricks_hierarchy_graph_sample.json`
  - `data/samples/datacloud_identity_resolution_sample.json` (`group_revenue_rollup`, `unified_profile_id`)
- Downstream Salesforce alignment is represented in:
  - `contracts/datacloud_to_salesforce_agentforce.schema.json`
  - `config/data-cloud/activation-field-mapping.csv`
  - `data/samples/datacloud_activation_sample.json`
