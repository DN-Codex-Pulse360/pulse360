# Evidence: Databricks Salesforce Governance Feedback Loop (2026-04-26)

## Scope

Validate that Salesforce `Governance_Case__c` stewardship outcomes can flow back
into Databricks and be summarized for dashboard evidence without ingesting the
Data Cloud review DMO back into Databricks.

## Live Databricks Assets

- Bronze source: `pulse360_s4.bronze_salesforce.governance_case__c`
- Silver normalized view: `pulse360_s4.silver_salesforce.crm_governance_case`
- Metrics view: `pulse360_s4.intelligence.governance_case_metrics`
- Pipeline: `pulse360-salesforce-governance-feedback`
- Dashboard: `Pulse360 S4 - Use Case & Transition Dashboard`
- Dashboard ID: `01f14106fbcf1dea8543a28217628f38`

## Validation

The Databricks ingestion pipeline completed successfully and upserted one
`governance_case__c` row.

The silver feedback view returned:

| Field | Value |
| --- | --- |
| `crm_governance_case_id` | `a00dL000036IsSgQAK` |
| `crm_governance_case_name` | `GC-00000` |
| `decision_status` | `Approved` |
| `recommended_action` | `Approve Merge` |
| `duplicate_confidence` | `94.2` |
| `surviving_account_id` | `001dL000024wgYRQAY` |
| `evidence_run_id` | `run_public_regional_20260328` |
| `model_version` | `pulse360-public-regional-v1` |

The metrics view returned:

| Metric | Value |
| --- | ---: |
| `total_governance_cases` | 1 |
| `resolved_decision_count` | 1 |
| `approved_count` | 1 |
| `deferred_count` | 0 |
| `ready_for_merge_count` | 1 |
| `downstream_update_queued_count` | 1 |
| `average_duplicate_confidence` | 94.2 |

## Dashboard Update

The Databricks dashboard pack now includes a `Closed Loop Feedback` page backed by
`pulse360_s4.intelligence.governance_case_metrics`.

The page includes:

- total governance cases
- resolved decisions
- ready-for-merge count
- queued downstream updates
- average duplicate confidence
- feedback metrics table with approved, rejected, deferred, merge-completed,
  latest decision, and lineage status

The updated `.lvdash.json` was imported to the live workspace dashboard object:

| Property | Value |
| --- | --- |
| Workspace path | `/Shared/pulse360/Pulse360 S4 - Use Case & Transition Dashboard.lvdash.json` |
| Object type | `DASHBOARD` |
| Object ID | `3059249104913170` |
| Resource ID | `01f14106fbcf1dea8543a28217628f38` |

The workspace export after import contained `Closed Loop Feedback`,
`governance_feedback_metrics`, and `Salesforce Stewardship Feedback Metrics`.

Visual QA was confirmed from the Databricks dashboard screenshot captured on
2026-04-26 at 8:08 PM. The `Closed Loop Feedback` page rendered the expected
live KPI values:

| Dashboard Widget | Rendered Value |
| --- | ---: |
| Governance Cases | 1 |
| Resolved Decisions | 1 |
| Ready for Merge | 1 |
| Queued Downstream Updates | 1 |
| Avg Duplicate Confidence | 94.2 |

## Result

The bidirectional prototype loop is now source-backed and live:

1. Databricks publishes activation review evidence to Salesforce Data Cloud.
2. Data Cloud exposes the review queue through a Direct Access DMO.
3. Salesforce CRM records human stewardship outcomes on `Governance_Case__c`.
4. Databricks ingests those CRM decisions back into `bronze_salesforce`.
5. Databricks exposes normalized silver feedback and dashboard-ready metrics.
6. The Databricks S4 dashboard shows the closed-loop feedback metrics.

This feedback loop remains non-circular because Databricks ingests the CRM
transactional stewardship object, not its own Data Cloud review DMO.
