# Databricks Silver Salesforce SQL

These SQL files materialize the first `silver_salesforce` normalization layer on top of the live Databricks bronze Salesforce ingestion.

## Order
Run the files in this order:

1. `00_create_schema.sql`
2. `10_crm_account.sql`
3. `20_crm_contact.sql`
4. `30_crm_opportunity.sql`
5. `40_crm_opportunity_contact_role.sql`
6. `50_crm_product.sql`
7. `60_crm_opportunity_line_item.sql`
8. `70_crm_account_contact_bridge.sql`
9. `80_crm_account_hierarchy_edge.sql`

## Notes
- These are `CREATE OR REPLACE VIEW` definitions, not materialized tables.
- The views preserve CRM IDs unchanged from `pulse360_s4.bronze_salesforce`.
- `crm_account_id` is the required match key for downstream activation-safe exports.
- `crm_opportunity_contact_role` and `crm_opportunity_line_item` are included even if the current source org has no business rows yet.

## Next Step
After these views exist in Databricks:
- refactor gold exports so `source_account_id = crm_account_id`
- rebuild `gold.datacloud_export_accounts`
- re-run Data Cloud mapping and activation

