# Databricks Silver Salesforce Runbook

## Purpose
Apply the first `silver_salesforce` normalization layer in Databricks on top of the live Salesforce bronze ingestion.

## Repo Artifacts
- `sql/databricks/silver_salesforce/00_create_schema.sql`
- `sql/databricks/silver_salesforce/10_crm_account.sql`
- `sql/databricks/silver_salesforce/20_crm_contact.sql`
- `sql/databricks/silver_salesforce/30_crm_opportunity.sql`
- `sql/databricks/silver_salesforce/40_crm_opportunity_contact_role.sql`
- `sql/databricks/silver_salesforce/50_crm_product.sql`
- `sql/databricks/silver_salesforce/60_crm_opportunity_line_item.sql`
- `sql/databricks/silver_salesforce/70_crm_account_contact_bridge.sql`
- `sql/databricks/silver_salesforce/80_crm_account_hierarchy_edge.sql`

## Preconditions
1. Databricks bronze ingestion pipeline `pulse360-salesforce-extract` has completed successfully.
2. Bronze schema exists at `pulse360_s4.bronze_salesforce`.
3. The Databricks SQL editor or notebook has permission to create views in `pulse360_s4.silver_salesforce`.

## Execution
1. Open Databricks SQL editor or a notebook attached to the target workspace.
2. Run the SQL files in the sequence defined in `sql/databricks/silver_salesforce/README.md`.
3. Validate that the following views exist:
   - `pulse360_s4.silver_salesforce.crm_account`
   - `pulse360_s4.silver_salesforce.crm_contact`
   - `pulse360_s4.silver_salesforce.crm_opportunity`
   - `pulse360_s4.silver_salesforce.crm_opportunity_contact_role`
   - `pulse360_s4.silver_salesforce.crm_product`
   - `pulse360_s4.silver_salesforce.crm_opportunity_line_item`
   - `pulse360_s4.silver_salesforce.crm_account_contact_bridge`
   - `pulse360_s4.silver_salesforce.crm_account_hierarchy_edge`

## Validation Queries
```sql
SELECT COUNT(*) AS account_rows
FROM pulse360_s4.silver_salesforce.crm_account;

SELECT COUNT(*) AS contact_rows
FROM pulse360_s4.silver_salesforce.crm_contact;

SELECT COUNT(*) AS opportunity_rows
FROM pulse360_s4.silver_salesforce.crm_opportunity;

SELECT COUNT(*) AS product_rows
FROM pulse360_s4.silver_salesforce.crm_product;

SELECT crm_account_id, crm_account_name
FROM pulse360_s4.silver_salesforce.crm_account
LIMIT 10;
```

## Expected Outcome
1. CRM IDs remain unchanged from the bronze layer.
2. `crm_account_id` is ready to become the authoritative `source_account_id` in activation-safe exports.
3. The pipeline is ready for gold export refactoring and Data Cloud remapping.

