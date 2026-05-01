# Databricks Gold Export SQL

These SQL files create the CRM-key-safe gold export path for Pulse360.

## Order
Run the files in this order:

1. `00_create_schemas.sql`
2. `10_account_export_base.sql`
3. `20_account_core_export.sql`
4. `30_datacloud_export_accounts.sql`
5. `40_sovereign_identifier_export.sql`
6. `50_firmographic_profile_export.sql`
7. `60_company_classification_export.sql`
8. `70_corporate_linkage_export.sql`
9. `80_firmographic_source_evidence_export.sql`

## Output Views
- `pulse360_s4.gold.account_export_base`
- `pulse360_s4.gold.account_core_export`
- `pulse360_s4.intelligence.datacloud_export_accounts`
- `pulse360_s4.intelligence.sovereign_identifier_export`
- `pulse360_s4.intelligence.firmographic_profile_export`
- `pulse360_s4.intelligence.company_classification_export`
- `pulse360_s4.intelligence.corporate_linkage_export`
- `pulse360_s4.intelligence.firmographic_source_evidence_export`

## Design Rules
- `source_account_id` is sourced from `pulse360_s4.silver_salesforce.crm_account.crm_account_id`
- the downstream table name `pulse360_s4.intelligence.datacloud_export_accounts` is preserved
- `pulse360_s4.intelligence.datacloud_export_accounts` is intentionally materialized as a table because that object already exists as a managed Delta table in the workspace
- activation fields expected by Data Cloud and Salesforce Account mapping are exposed directly on the export view
- `sovereign_identifier_export` is intentionally empty until official registry, tax, or filing identifiers are available; CRM IDs and provider IDs must not be emitted as sovereign identifiers
- firmographic profile, classification, linkage, and evidence exports provide a CRM-backed baseline for Data Cloud setup and are expected to be enriched further by GPT/provider evidence packets

## Notes
- This is a prototype-safe derived export built from live CRM bronze and silver layers.
- Product-linked fields degrade gracefully when `crm_opportunity_line_item` has no business rows.
- `account_core_export` preserves the canonical export shape used by contract validation.
- Investor-summary fields are blank in the CRM-backed baseline unless an approved investor-presentation or news evidence packet is supplied upstream.
