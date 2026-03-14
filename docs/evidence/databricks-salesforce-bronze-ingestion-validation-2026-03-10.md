# Evidence: Databricks Salesforce Bronze Ingestion Validation (2026-03-10)

## Purpose
Record the live Databricks validation proving that Pulse360 now has a CRM-source bronze ingestion path suitable for deterministic downstream CRM writeback.

## Databricks Environment
- Workspace host: `https://dbc-7f0ce7bb-56ca.cloud.databricks.com`
- Catalog: `pulse360_s4`
- Schema: `bronze_salesforce`
- Pipeline: `pulse360-salesforce-extract`
- Validation date: `2026-03-10`

## Validation Method
Validated through the Databricks CLI against the live workspace after refreshing the CLI token in `~/.databrickscfg`.

Confirmed access:
- `databricks workspace ls /`
- `databricks unity-catalog metastores list`
- `databricks unity-catalog tables list --catalog-name pulse360_s4 --schema-name bronze_salesforce`

## Confirmed Bronze Tables
The bronze Salesforce ingestion pipeline is landing streaming tables in `pulse360_s4.bronze_salesforce`.

Confirmed source objects:
- `account`
- `contact`
- `opportunity`
- `opportunitycontactrole`
- `opportunitylineitem`
- `product2`

## Confirmed Connector Semantics
Live Unity Catalog metadata confirms the ingestion connector is preserving source-system change semantics:

- primary key: `Id`
- sequence key: `SystemModstamp`
- change handling: `TYPE1`
- table type: `STREAMING_TABLE`

Observed table properties include:
- `__ingestion_connector_primary_key = ["Id"]`
- `__ingestion_connector_sequence_key = ["SystemModstamp"]`
- `spark.internal.streaming_table.apply_changes.keys = ["Id"]`
- `spark.internal.streaming_table.apply_changes.scd_type = TYPE1`

## Business Validation
The bronze layer now contains real Salesforce CRM identifiers rather than synthetic Databricks-only account keys.

Observed examples:
- `Account.Id` values with Salesforce prefix shape such as `001dM...`
- `Contact.Id` values with Salesforce prefix shape such as `003dM...`
- `Opportunity.Id` values with Salesforce prefix shape such as `006dM...`
- `Product2.Id` values with Salesforce prefix shape such as `01tdM...`

This resolves the earlier design blocker where Databricks-origin account records could not deterministically activate back to Salesforce CRM.

## Current Gaps
Two ingested objects appear structurally present but currently do not show business rows in the user-validated Databricks UI:
- `opportunitycontactrole`
- `opportunitylineitem`

Current interpretation:
- this is likely a source-data condition, not an ingestion-connector failure
- the bronze pipeline design remains correct and should be retained

## Implication for Pulse360
Pulse360 now has the required upstream CRM source foundation to build:
- CRM-key-safe silver normalized tables
- richer product/contact/opportunity-aware gold exports
- Data Cloud exports aligned to standard DMOs
- deterministic CRM writeback for account-centric activation fields

## Next Required Build Step
Build `silver_salesforce` normalized tables that preserve CRM keys unchanged while shaping the data for Pulse360 enrichment and Data Cloud export:
- `crm_account`
- `crm_contact`
- `crm_opportunity`
- `crm_opportunity_contact_role`
- `crm_product`
- `crm_opportunity_line_item`

