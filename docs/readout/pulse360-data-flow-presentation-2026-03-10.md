# Pulse360 Data Flow and Design

## Slide 1: Purpose
- Explain the end-to-end Pulse360 data flow in plain language
- Show where data cleansing, deduplication, hierarchy, and enrichment belong
- Clarify what is already implemented and what still needs to move

---

## Slide 2: End-to-End Flow
1. Salesforce CRM is the source of truth for operational account, contact, opportunity, and product records.
2. Databricks ingests those records into a raw bronze layer.
3. Databricks normalizes the raw records into a silver relational layer.
4. Databricks runs intelligence logic in the gold layer.
5. Databricks exports CRM-key-safe account enrichment to Data Cloud.
6. Data Cloud maps the export into DMOs and activation-ready fields.
7. Data Cloud writes enriched values back to Salesforce `Account`.

---

## Slide 3: Source Systems
Primary source:
- Salesforce CRM

Current ingested CRM objects:
- `Account`
- `Contact`
- `Opportunity`
- `OpportunityContactRole`
- `OpportunityLineItem`
- `Product2`

Why this matters:
- real Salesforce IDs are now preserved upstream
- writeback can now use the real `Account.Id`

---

## Slide 4: Databricks Bronze
Layer:
- `pulse360_s4.bronze_salesforce`

Purpose:
- raw landing zone
- preserve source fidelity
- preserve native Salesforce keys
- preserve `SystemModstamp` for incremental refresh

Important design rule:
- no business reshaping here
- bronze should stay close to source

---

## Slide 5: Databricks Silver
Layer:
- `pulse360_s4.silver_salesforce`

Purpose:
- clean and normalize the CRM objects
- standardize account, contact, opportunity, and product relationships
- create a stable relational spine for downstream intelligence

Current silver views:
- `crm_account`
- `crm_contact`
- `crm_opportunity`
- `crm_opportunity_contact_role`
- `crm_opportunity_line_item`
- `crm_product`
- `crm_account_contact_bridge`
- `crm_account_hierarchy_edge`

Key design rule:
- `crm_account_id` must remain the real Salesforce `Account.Id`

---

## Slide 6: Databricks Gold Intelligence
This is where Pulse360 logic belongs.

The intelligence layer should:
- clean and standardize account identity signals
- detect likely duplicates and overlaps
- stitch account hierarchy relationships
- enrich account records with firmographic and commercial context
- calculate health, risk, and cross-sell signals

Inputs:
- `crm_account`
- `crm_contact`
- `crm_opportunity`
- `crm_product`
- `crm_opportunity_line_item`
- relationship views

Output rule:
- all intelligence outputs must still be able to resolve back to `crm_account_id`

---

## Slide 7: How Deduplication Works
Primary input:
- `silver_salesforce.crm_account`

Typical matching features:
- account name similarity
- website/domain match
- account number match
- DUNS match
- phone match
- billing geography similarity

Typical outputs:
- duplicate candidate pairs
- pair confidence score
- explanation of which features matched
- review flag for low-confidence or ambiguous cases

Purpose:
- improve account quality before export
- avoid fragmented account activation downstream

---

## Slide 8: How Hierarchy Stitching Works
Primary inputs:
- `crm_account`
- `crm_account_hierarchy_edge`

Logic:
- use the CRM `ParentId` baseline first
- expand parent-child edges into a hierarchy graph
- calculate depth and path attributes
- roll child context up to enterprise parent accounts

Typical outputs:
- hierarchy edges
- hierarchy graph
- group revenue rollup
- uncovered subsidiary / coverage gap signals

Purpose:
- support group-wide account views and activation
- let Data Cloud and Salesforce see enterprise context, not just leaf accounts

---

## Slide 9: How Enrichment and Scoring Work
Primary inputs:
- account core from `crm_account`
- contact/buyer signals from `crm_contact`
- commercial signals from `crm_opportunity`
- product signals from `crm_product` and `crm_opportunity_line_item`

Enrichment examples:
- primary brand assignment
- active product count
- engagement intensity
- open opportunity count
- freshness / last engagement timestamp

Scoring examples:
- identity confidence
- validity score
- health score
- cross-sell propensity
- competitor risk signal

Purpose:
- convert raw CRM records into decision-ready account intelligence

---

## Slide 10: How Gold Export Uses Intelligence
The export layer does not replace intelligence.

It does three things:
1. join intelligence outputs back onto `crm_account_id`
2. keep the account key CRM-safe for activation
3. reshape fields into a Data Cloud-friendly export

Important objects:
- `pulse360_s4.gold.account_export_base`
- `pulse360_s4.gold.account_core_export`
- `pulse360_s4.intelligence.datacloud_export_accounts`

Critical rule:
- `source_account_id = crm_account_id`

---

## Slide 11: Data Cloud
Flow inside Data Cloud:
1. Databricks export lands as a Data Lake Object
2. fields map into Data Model Objects such as `Account`
3. calculated insights and activation logic run
4. values are published back to Salesforce CRM

Important distinction:
- Data Cloud is the activation and canonical modeling layer
- Databricks is the intelligence and enrichment layer

---

## Slide 12: What Is Already Working
Implemented now:
- Salesforce CRM ingestion into Databricks bronze
- silver normalization layer
- CRM-key-safe gold account export
- Data Cloud DMO custom fields for account enrichment
- Salesforce `Account` custom fields for writeback

This means:
- the keying problem is fixed
- the architecture is now pointed in the right direction

---

## Slide 13: What Still Needs To Move
Still to rebase onto the new CRM-key-safe silver layer:
- duplicate detection logic
- hierarchy graph logic
- firmographic enrichment logic
- any remaining legacy exports using synthetic Databricks account IDs

This is the main engineering task left in Databricks.

---

## Slide 14: High-Level Design Principle
Use this rule everywhere:

- CRM is the operational source of truth
- Databricks performs cleansing, matching, hierarchy, and scoring
- Data Cloud performs canonical mapping and activation
- Salesforce CRM remains the execution surface

In short:
- clean and score in Databricks
- model and activate in Data Cloud
- surface in Salesforce

---

## Slide 15: Immediate Next Steps
1. Rebase dedupe, hierarchy, and enrichment jobs onto `silver_salesforce`
2. Regenerate `datacloud_export_accounts` from those CRM-key-safe gold outputs
3. Refresh the Data Cloud stream
4. Re-validate DLO to DMO mapping
5. Run activation to Salesforce `Account`
6. Verify live CRM field updates
