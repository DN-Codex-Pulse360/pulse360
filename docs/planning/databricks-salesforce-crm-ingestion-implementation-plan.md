# Databricks Salesforce CRM Ingestion Implementation Plan

## Goal
Turn the newly validated Databricks bronze Salesforce ingestion into a CRM-key-safe Pulse360 data pipeline that can support DS-01, DS-02, and DS-03 and activate enriched account values back into Salesforce CRM deterministically.

## Live Baseline
Validated live in Databricks on `2026-03-10`:
- catalog: `pulse360_s4`
- bronze schema: `bronze_salesforce`
- pipeline: `pulse360-salesforce-extract`
- confirmed tables:
  - `account`
  - `contact`
  - `opportunity`
  - `opportunitycontactrole`
  - `opportunitylineitem`
  - `product2`
- confirmed ingestion semantics:
  - primary key: `Id`
  - incremental sequence key: `SystemModstamp`
  - apply changes mode: `TYPE1`

Reference evidence:
- `docs/evidence/databricks-salesforce-bronze-ingestion-validation-2026-03-10.md`

## Design Decision
`bronze_salesforce` is now the authoritative upstream CRM landing zone for Pulse360.

All downstream account enrichment intended for Salesforce CRM activation must inherit its account match key from this bronze ingestion path.

Specifically:
- `source_account_id` in activation-safe exports must resolve to `bronze_salesforce.account.Id`
- synthetic Databricks entity IDs may still exist internally, but never as the sole CRM writeback key

## Target Data Zones

### Bronze
Purpose:
- preserve raw Salesforce source fidelity
- preserve native keys and `SystemModstamp`

Existing tables:
- `pulse360_s4.bronze_salesforce.account`
- `pulse360_s4.bronze_salesforce.contact`
- `pulse360_s4.bronze_salesforce.opportunity`
- `pulse360_s4.bronze_salesforce.opportunitycontactrole`
- `pulse360_s4.bronze_salesforce.opportunitylineitem`
- `pulse360_s4.bronze_salesforce.product2`

### Silver
Purpose:
- normalize names
- standardize relationship keys
- create reusable account/person/product/commercial structures

Target tables:
- `pulse360_s4.silver_salesforce.crm_account`
- `pulse360_s4.silver_salesforce.crm_contact`
- `pulse360_s4.silver_salesforce.crm_opportunity`
- `pulse360_s4.silver_salesforce.crm_opportunity_contact_role`
- `pulse360_s4.silver_salesforce.crm_product`
- `pulse360_s4.silver_salesforce.crm_opportunity_line_item`
- `pulse360_s4.silver_salesforce.crm_account_contact_bridge`
- `pulse360_s4.silver_salesforce.crm_account_hierarchy_edge`

### Gold
Purpose:
- build Pulse360 intelligence products and Data Cloud-ready exports

Target tables:
- `pulse360_s4.gold.duplicate_candidate_pairs`
- `pulse360_s4.gold.entity_hierarchy_graph`
- `pulse360_s4.gold.firmographic_enrichment`
- `pulse360_s4.gold.governance_ops_metrics`
- `pulse360_s4.gold.account_core_export`
- `pulse360_s4.gold.account_contact_export`
- `pulse360_s4.gold.individual_export`
- `pulse360_s4.gold.product_brand_export`
- `pulse360_s4.gold.commercial_intent_export`
- `pulse360_s4.gold.opportunity_product_export`
- `pulse360_s4.gold.engagement_export`
- `pulse360_s4.gold.datacloud_export_accounts`

## Silver Table Design

### `crm_account`
Source:
- `bronze_salesforce.account`

Minimum normalized fields:
- `crm_account_id`
- `crm_parent_account_id`
- `crm_account_name`
- `crm_account_type`
- `crm_industry`
- `crm_account_number`
- `crm_website`
- `crm_owner_id`
- `crm_billing_city`
- `crm_billing_state`
- `crm_billing_country`
- `crm_shipping_city`
- `crm_shipping_state`
- `crm_shipping_country`
- `crm_annual_revenue`
- `crm_number_of_employees`
- `crm_account_source`
- `crm_rating`
- `crm_description`
- `crm_duns_number`
- `crm_created_at`
- `crm_last_modified_at`
- `crm_system_modstamp`
- `source_system`

Key rule:
- `crm_account_id = account.Id`

### `crm_contact`
Source:
- `bronze_salesforce.contact`

Minimum normalized fields:
- `crm_contact_id`
- `crm_account_id`
- `crm_contact_first_name`
- `crm_contact_last_name`
- `crm_contact_name`
- `crm_contact_email`
- `crm_contact_phone`
- `crm_contact_mobile_phone`
- `crm_contact_title`
- `crm_contact_department`
- `crm_contact_lead_source`
- `crm_individual_id`
- `crm_contact_created_at`
- `crm_contact_last_modified_at`
- `crm_contact_system_modstamp`
- `source_system`

Key rule:
- `crm_contact_id = contact.Id`

### `crm_opportunity`
Source:
- `bronze_salesforce.opportunity`

Minimum normalized fields:
- `crm_opportunity_id`
- `crm_account_id`
- `crm_owner_id`
- `crm_opportunity_name`
- `crm_stage_name`
- `crm_amount`
- `crm_probability`
- `crm_expected_revenue`
- `crm_close_date`
- `crm_forecast_category`
- `crm_opportunity_type`
- `crm_is_closed`
- `crm_is_won`
- `crm_pricebook2_id`
- `crm_created_at`
- `crm_last_modified_at`
- `crm_system_modstamp`
- `source_system`

Key rule:
- `crm_opportunity_id = opportunity.Id`

### `crm_opportunity_contact_role`
Source:
- `bronze_salesforce.opportunitycontactrole`

Minimum normalized fields:
- `crm_opportunity_contact_role_id`
- `crm_opportunity_id`
- `crm_contact_id`
- `crm_role`
- `crm_is_primary`
- `crm_created_at`
- `crm_last_modified_at`
- `crm_system_modstamp`
- `source_system`

Current note:
- the source object is ingested but currently appears empty in the live workspace

### `crm_product`
Source:
- `bronze_salesforce.product2`

Minimum normalized fields:
- `crm_product_id`
- `crm_product_name`
- `crm_product_code`
- `crm_product_family`
- `crm_product_class`
- `crm_product_description`
- `crm_is_active`
- `crm_created_at`
- `crm_last_modified_at`
- `crm_system_modstamp`
- `source_system`

Key rule:
- `crm_product_id = product2.Id`

### `crm_opportunity_line_item`
Source:
- `bronze_salesforce.opportunitylineitem`

Minimum normalized fields:
- `crm_opportunity_line_item_id`
- `crm_opportunity_id`
- `crm_product_id`
- `crm_pricebook_entry_id`
- `crm_quantity`
- `crm_unit_price`
- `crm_total_price`
- `crm_list_price`
- `crm_service_date`
- `crm_created_at`
- `crm_last_modified_at`
- `crm_system_modstamp`
- `source_system`

Current note:
- the source object is ingested but currently appears empty in the live workspace

### Derived Silver Relationship Tables

#### `crm_account_contact_bridge`
Purpose:
- normalize `Account -> Contact` relationship rows for Data Cloud `Account Contact` export

Derived from:
- `crm_contact`

Minimum fields:
- `account_contact_id`
- `crm_account_id`
- `crm_contact_id`
- `is_primary_contact`
- `contact_role`
- `source_system`

#### `crm_account_hierarchy_edge`
Purpose:
- normalize parent-child enterprise account hierarchy

Derived from:
- `crm_account`

Minimum fields:
- `hierarchy_edge_id`
- `parent_account_id`
- `child_account_id`
- `relationship_type`
- `hierarchy_depth`
- `hierarchy_path`

## Gold Build Rules

### DS-01 Intelligence
Use `crm_account` as the account identity base for:
- duplicate detection
- hierarchy stitching
- firmographic enrichment

All DS-01 outputs must carry:
- `crm_account_id`
- `run_id`
- `run_timestamp`
- `model_version`

### DS-02 Governance
Use CRM account, contact, opportunity, and later case/service data to support:
- governance case prioritization
- data quality remediation metrics
- confidence and review workflows

### DS-03 Activation
Build `account_core_export` and `datacloud_export_accounts` so:
- `source_account_id = crm_account_id`
- all enrichment signals remain traceable to CRM source and run metadata
- downstream Data Cloud activation can safely map back to Salesforce `Account`

## Recommended Join Strategy

### Account-Centric Join Spine
Primary spine:
- `crm_account.crm_account_id`

Join rules:
- `crm_contact.crm_account_id -> crm_account.crm_account_id`
- `crm_opportunity.crm_account_id -> crm_account.crm_account_id`
- `crm_opportunity_contact_role.crm_opportunity_id -> crm_opportunity.crm_opportunity_id`
- `crm_opportunity_contact_role.crm_contact_id -> crm_contact.crm_contact_id`
- `crm_opportunity_line_item.crm_opportunity_id -> crm_opportunity.crm_opportunity_id`
- `crm_opportunity_line_item.crm_product_id -> crm_product.crm_product_id`

### Enrichment Key Rule
If a gold dataset activates back to Salesforce CRM:
- it must expose `crm_account_id`
- it must not substitute a synthetic Databricks account identifier in place of `crm_account_id`

## Immediate Build Backlog
1. Create schema `pulse360_s4.silver_salesforce`
2. Materialize the six normalized silver base tables
3. Materialize `crm_account_contact_bridge`
4. Materialize `crm_account_hierarchy_edge`
5. Re-key existing Pulse360 enrichment logic against `crm_account_id`
6. Rebuild `gold.datacloud_export_accounts` from CRM-key-safe joins
7. Re-run Data Cloud mapping using the CRM-safe account key

## Acceptance Criteria
1. Every activation-safe export row can be traced to a live Salesforce `Account.Id`
2. `source_account_id` in `gold.datacloud_export_accounts` is sourced from `crm_account_id`
3. Silver tables preserve CRM relationship integrity across account, contact, opportunity, product, and line item domains
4. Gold exports retain `run_id`, `run_timestamp`, and `model_version`
5. Data Cloud account enrichment mapping no longer depends on synthetic Databricks-origin account keys

## Current Risks
1. `opportunitycontactrole` may be empty because the source org has no role rows
2. `opportunitylineitem` may be empty because the source org has no line items
3. `Case` is not yet ingested, limiting DS-02 service/governance richness
4. Existing gold exports may still be keyed off pre-CRM-source Databricks account identifiers and will need refactoring

## Recommended Next Object
Add `Case` into the same bronze ingestion pipeline after the silver foundation is created.

