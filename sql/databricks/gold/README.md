# Databricks Gold Export SQL

These SQL files create the CRM-key-safe gold export path for Pulse360.

## Order
Run the files in this order:

1. `00_create_schemas.sql`
2. `10_account_export_base.sql`
3. `20_account_core_export.sql`
4. `30_datacloud_export_accounts.sql`

## Output Views
- `pulse360_s4.gold.account_export_base`
- `pulse360_s4.gold.account_core_export`
- `pulse360_s4.intelligence.datacloud_export_accounts`

## Design Rules
- `source_account_id` is sourced from `pulse360_s4.silver_salesforce.crm_account.crm_account_id`
- the downstream table name `pulse360_s4.intelligence.datacloud_export_accounts` is preserved
- `pulse360_s4.intelligence.datacloud_export_accounts` is intentionally materialized as a table because that object already exists as a managed Delta table in the workspace
- activation fields expected by Data Cloud and Salesforce Account mapping are exposed directly on the export view

## Notes
- This is a prototype-safe derived export built from live CRM bronze and silver layers.
- Product-linked fields degrade gracefully when `crm_opportunity_line_item` has no business rows.
- `account_core_export` preserves the canonical export shape used by contract validation.
