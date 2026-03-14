# Databricks Gold Account Export Runbook

## Purpose
Apply the CRM-key-safe gold export path that feeds Pulse360 Data Cloud account enrichment and preserves `source_account_id` as Salesforce `Account.Id`.

## Repo Artifacts
- `sql/databricks/gold/00_create_schemas.sql`
- `sql/databricks/gold/10_account_export_base.sql`
- `sql/databricks/gold/20_account_core_export.sql`
- `sql/databricks/gold/30_datacloud_export_accounts.sql`

## Preconditions
1. `pulse360_s4.silver_salesforce` views already exist.
2. The Databricks user can create or replace views in `pulse360_s4.gold` and `pulse360_s4.intelligence`.

## Execution
1. Open Databricks SQL editor or a notebook.
2. Run the SQL files in the order defined in `sql/databricks/gold/README.md`.
3. Validate the resulting views:
   - `pulse360_s4.gold.account_export_base`
   - `pulse360_s4.gold.account_core_export`
   - `pulse360_s4.intelligence.datacloud_export_accounts`

## Validation Queries
```sql
SELECT source_account_id, account_name
FROM pulse360_s4.gold.account_export_base
LIMIT 10;

SELECT source_account_id, unified_profile_id, health_score, cross_sell_propensity
FROM pulse360_s4.intelligence.datacloud_export_accounts
LIMIT 10;

SELECT COUNT(*) AS export_rows
FROM pulse360_s4.intelligence.datacloud_export_accounts;
```

## Expected Outcome
1. `source_account_id` matches live Salesforce `Account.Id` values from `silver_salesforce.crm_account`
2. the activation fields required by `config/data-cloud/activation-field-mapping.csv` are exposed on `pulse360_s4.intelligence.datacloud_export_accounts`
3. the dashboard dataset name remains unchanged for `pulse360_s4.intelligence.datacloud_export_accounts`
4. the export object remains a Delta table, not a view, so it can safely replace the existing managed object
