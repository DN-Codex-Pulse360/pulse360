# Databricks Data Layer Closeout Ops Runbook

Date: 2026-04-27

## Purpose

Keep the Pulse360 prototype data layer green after the initial closeout by
scheduling the Databricks-side runtime checks and retaining queryable evidence
inside Unity Catalog.

## Scheduled Jobs

| Job | Cadence | Purpose |
| --- | --- | --- |
| `pulse360-salesforce-extract job` | Every 6 hours | Refresh Salesforce Account, Contact, Opportunity, OpportunityLineItem, OpportunityContactRole, and Product2 into Databricks bronze. |
| `pulse360-salesforce-governance-feedback job` | Every 6 hours | Refresh Salesforce `Governance_Case__c` decisions back into Databricks. |
| `pulse360-data-layer-closeout-validation job` | Every 6 hours | Validate current-org IDs, required handoff columns, Manila CSP action rows, and minimum row counts. |

All three jobs route failure email notifications to
`dnortje@danielnortje.com`. Source-backed job definitions live in:

```text
config/databricks/salesforce-extract-job.json
config/databricks/salesforce-governance-feedback-job.json
config/databricks/data-layer-closeout-validation-job.json
```

## Validation Notebook

Source:

```text
notebooks/databricks/data_layer_closeout_validation_job.py
```

Workspace path:

```text
/Shared/pulse360/pulse360-data-layer-closeout/dev/notebooks/databricks/data_layer_closeout_validation_job
```

The notebook writes audit rows to:

```text
pulse360_s4.ops.data_layer_validation_runs
```

## Job Definition

Source:

```text
config/databricks/data-layer-closeout-validation-job.json
```

## Manual Runtime Gate

Run the full local closeout gate when preparing demo evidence or after changing
contracts:

```bash
./scripts/validate-data-layer-closeout.sh
```

Run the Databricks notebook job after refreshing source data:

```bash
databricks jobs run-now --job-id <pulse360-data-layer-closeout-validation-job-id>
```

## Expected Healthy State

- Bronze Salesforce Account, Contact, Opportunity, and Product2 IDs match the
  active Salesforce target org prefix.
- `silver_salesforce.crm_account` has no stale Account IDs.
- `intelligence.datacloud_export_accounts` has no stale Account IDs.
- `intelligence.datacloud_activation_review_queue` includes Manila CSP action
  rows with target B2B customer evidence.
- `pulse360_s4.ops.data_layer_validation_runs` records all checks as passed for
  the latest run.

## Lineage Evidence Targets

Capture Unity Catalog lineage for:

- `pulse360_s4.silver_salesforce.crm_account`
- `pulse360_s4.gold.account_export_base`
- `pulse360_s4.intelligence.datacloud_export_accounts`
- `pulse360_s4.gold.activation_eligibility_review_queue`
- `pulse360_s4.intelligence.datacloud_activation_review_queue`

Minimum lineage proof:

- `silver_salesforce.crm_account` has upstream bronze Salesforce `account`.
- `intelligence.datacloud_export_accounts` has upstream `gold.account_export_base`.
- `intelligence.datacloud_export_accounts` has downstream S4 dashboard usage.
- `intelligence.datacloud_activation_review_queue` has upstream activation
  eligibility and smart-city customer sample sources.
