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

Create the M1 Direct Access streams from Databricks in this order:

1. `pulse360_s4.intelligence.m1_account_hierarchy_activation`
2. `pulse360_s4.intelligence.m1_account_group_rollup`
3. `pulse360_s4.intelligence.m1_account_hierarchy_edge`

Use `config/data-cloud/m1-account-hierarchy-dlo-dmo-setup.csv` as the setup
contract. The expected row counts are:

| Table | Expected rows | Account relationship |
| --- | ---: | --- |
| `m1_account_hierarchy_activation` | 18 | `source_account_id__c -> Account.Id` |
| `m1_account_group_rollup` | 17 | `group_anchor_source_account_id__c -> Account.Id` |
| `m1_account_hierarchy_edge` | 2 | `child_source_account_id__c -> Account.Id` |

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

After the three M1 streams and DMOs are live, create the reports listed in
`config/salesforce/m1-account-hierarchy-validation-reports.csv` in the existing
folder:

```text
Pulse360 Account Intelligence Validation
```

Target reports:

1. `Account and M1 Hierarchy Activation`
2. `Account and M1 Group Rollup`
3. `Account and M1 Hierarchy Edges`

Each report must render `Account.Id` or `Account.Name` as a Salesforce record
link and expose confidence, coverage-gap, generated timestamp, and evidence URL
or evidence summary fields where available.

## Dashboard Promotion

Create a separate `M1 Account Hierarchy Validation` dashboard after all three
M1 reports exist. Keep M1 dashboard separate from the existing firmographic dashboard
until the report metadata can be retrieved into source.

Recommended scorecard row:

- Activation coverage: `18`
- Account group coverage: `17`
- Hierarchy edges: `2`
- Coverage-gap accounts: `10`

The detail components should use the three M1 reports listed above.

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
