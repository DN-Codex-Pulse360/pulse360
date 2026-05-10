# Salesforce M1 Account Hierarchy Validation Runbook

## Scope

This runbook defines the Salesforce/Data Cloud validation surface for
`DAN-334`, the M1 Account Hierarchy Intelligence slice.

The M1 Databricks runtime has already produced the governed tables. This
runbook keeps the Salesforce side source-first while acknowledging that Data
Cloud Direct Access streams and generated DMO relationships remain
runbook-controlled until they can be retrieved as source metadata.

## Live Baseline

Read-only MCP checks on 2026-05-09 confirmed:

- Existing firmographic Data Cloud streams are active and refreshed.
- The current `Pulse360 Account Intelligence Validation` dashboard exists in
  Salesforce with all five firmographic validation reports.
- No M1 Data Cloud streams or M1 report/dashboard metadata exist yet.
- Account has the existing fields needed for M1 activation writeback review:
  `Group_Revenue_Rollup__c`, `Group_Known_Subsidiary_Count__c`,
  `Coverage_Gap_Flag__c`, `Group_Revenue_Visible__c`,
  `Hierarchy_Payload__c`, and `DataCloud_Last_Synced__c`.

## Data Cloud Setup

Create one M1 Direct Access stream from Databricks first:

- `pulse360_s4.intelligence.m1_account_hierarchy_activation_export`

Use `config/data-cloud/m1-account-hierarchy-dlo-dmo-setup.csv` as the setup
contract, and use
`config/data-cloud/m1-account-hierarchy-dmo-field-mapping.csv` as the
field-level DLO-to-DMO mapping guide. The expected row count is:

| Table | Expected rows | Account relationship |
| --- | ---: | --- |
| `m1_account_hierarchy_activation_export` | 18 | `source_account_id__c -> Account.Id` |

The group rollup and hierarchy edge outputs remain Databricks analytical
tables for now. They are useful for lineage, debugging, and future drill-through,
but should not become first-class Data Cloud DLOs/DMOs until a Salesforce
workflow proves that users need to query or segment directly on that grain.

Field mapping rules:

- Map every source column listed for the activation export object in
  `m1-account-hierarchy-dmo-field-mapping.csv`.
- Mark the table primary key as the primary key/key qualifier.
- Mark only `source_account_id__c` as the Account relationship key:
  `source_account_id__c -> Account.Id`.
- Keep Data Cloud field names exactly as listed in the mapping file; they are
  source-controlled to stay under the Data Cloud 40-character field-name limit.

Do not modify the five existing firmographic DMO relationships for M1. They are
already sufficient for the current firmographic validation dashboard and should
remain stable.

## Account Activation Mapping

Use `config/data-cloud/m1-account-hierarchy-activation-field-mapping.csv` for
the Account writeback review. The join key is `source_account_id -> Account.Id`.

Do not write sovereign identifiers, provider identifiers, search identifiers, or
Data Cloud generated IDs into Account relationship keys.

Recommended Account field review:

- `Group_Revenue_Rollup__c`: from `group_revenue_usd`
- `Group_Known_Subsidiary_Count__c`: from `known_child_account_count`
- `Coverage_Gap_Flag__c`: from `coverage_gap_flag`
- `Group_Revenue_Visible__c`: from `hierarchy_completeness_score`
- `Hierarchy_Payload__c`: compact JSON evidence payload
- `DataCloud_Last_Synced__c`: from `generated_at`

## Report Promotion

After the M1 activation stream and DMO are live, create or validate the report listed in
`config/salesforce/m1-account-hierarchy-validation-reports.csv` in the existing
folder:

```text
Pulse360 Account Intelligence Validation
```

Target report:

1. `Account and M1 Hierarchy Activation`

Current live report:

- Id: `00OdL00000POQZFUA5`
- DeveloperName: `Account_and_M1_Hierarchy_Activation_s6B`
- Retrieved source file:
  `force-app/main/default/reports/Pulse360_Account_Intelligence_Validation/Account_and_M1_Hierarchy_Activation_s6B.report-meta.xml`

The report must render `Account.Id` or `Account.Name` as a Salesforce record
link and expose confidence, coverage-gap, generated timestamp, and compact
evidence payload fields where available.

## Dashboard Promotion

Create a separate `M1 Account Hierarchy Validation` dashboard from the live
activation report. Keep M1 dashboard separate from the existing firmographic
dashboard until the dashboard metadata can be retrieved into source.

Recommended scorecard row:

- Activation coverage: `18`
- Coverage-gap accounts: `10`

The detail component should use the activation report listed above.

## Source Retrieval

After report and dashboard creation, retrieve the generated metadata names:

```bash
sf project retrieve start \
  --target-org pulse360-agent-target \
  --metadata "ReportFolder:Pulse360_Account_Intelligence_Validation" \
  --metadata "DashboardFolder:Pulse360_Account_Intelligence_Validation"
```

Then add the exact generated report and dashboard full names to
`config/salesforce/m1-account-hierarchy-validation-reports.csv` and extend the
Salesforce package membership.

## Validation

Run:

```bash
./scripts/validate-m1-data-cloud-salesforce-surface.sh
./scripts/validate-m1-account-hierarchy-pack.sh
```

Then use Salesforce UI or Analytics REST API to confirm the M1 report row
counts after the streams are created.
