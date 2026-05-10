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
- `config/databricks/salesforce-extract-job.json`

## Preconditions
1. Databricks bronze ingestion pipeline `pulse360-salesforce-extract` has completed successfully.
2. Bronze schema exists at `pulse360_s4.bronze_salesforce`.
3. The Databricks SQL editor or notebook has permission to create views in `pulse360_s4.silver_salesforce`.

## Salesforce Extract Runtime Check

The source-controlled Databricks job config is `config/databricks/salesforce-extract-job.json`.
It points to:

- Databricks job: `pulse360-salesforce-extract job`
- Job ID: `779306185996717`
- Pipeline ID: `b3f7f05a-2ba0-4f0b-b16a-66f72bd4fe1e`
- Schedule: every `6` hours

Use these read-only checks before rebuilding silver or M1 gold tables:

```bash
databricks runs list --job-id 779306185996717 --limit 5
databricks pipelines get --pipeline-id b3f7f05a-2ba0-4f0b-b16a-66f72bd4fe1e
```

If a failed update reports `[SAAS_CONNECTOR_UC_CONNECTION_OAUTH_EXCHANGE_FAILED]`
or says the `OAuth token exchange failed` for UC connection `pulse360`, the
failure is connection authorization, not a Salesforce object model change. Edit
the Unity Catalog connection `pulse360`, re-authenticate the Salesforce OAuth
connection, and rerun the Databricks job or pipeline.

The 2026-05-10 investigation found failed runs resolving
`pulse360_s4.bronze_salesforce.opportunitycontactrole` after that OAuth exchange
error. Salesforce object validation succeeded for `OpportunityContactRole`, and
the object currently had zero rows, so do not create alternate silver, DLO, or
DMO structures for this symptom. Wait for a successful extract before rebuilding
downstream M1 outputs.

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

Latest observed row counts from the 2026-05-10 extract/debug pass:

| Table | Rows |
| --- | ---: |
| `pulse360_s4.bronze_salesforce.account` | 18 |
| `pulse360_s4.bronze_salesforce.contact` | 20 |
| `pulse360_s4.bronze_salesforce.opportunity` | 32 |
| `pulse360_s4.bronze_salesforce.opportunitycontactrole` | 0 |
| `pulse360_s4.bronze_salesforce.opportunitylineitem` | 0 |
| `pulse360_s4.bronze_salesforce.product2` | 17 |
| `pulse360_s4.silver_salesforce.crm_account` | 18 |
| `pulse360_s4.intelligence.m1_account_hierarchy_activation_export` | 18 |

## Expected Outcome
1. CRM IDs remain unchanged from the bronze layer.
2. `crm_account_id` is ready to become the authoritative `source_account_id` in activation-safe exports.
3. The pipeline is ready for gold export refactoring and Data Cloud remapping.
