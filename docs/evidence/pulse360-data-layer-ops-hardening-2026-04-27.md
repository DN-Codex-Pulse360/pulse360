# Pulse360 Data Layer Ops Hardening Evidence

Date: 2026-04-27
Databricks workspace: `dbc-7f0ce7bb-56ca`

## Objective

Move the data-layer closeout checks from ad hoc operator validation into a
scheduled Databricks-native control, and capture Unity Catalog lineage evidence
for the prototype demo path.

## Scheduled Validation Job

Source notebook:

```text
notebooks/databricks/data_layer_closeout_validation_job.py
```

Workspace notebook:

```text
/Shared/pulse360/pulse360-data-layer-closeout/dev/notebooks/databricks/data_layer_closeout_validation_job
```

Source job definition:

```text
config/databricks/data-layer-closeout-validation-job.json
```

Databricks job:

| Field | Value |
| --- | --- |
| Job name | `pulse360-data-layer-closeout-validation job` |
| Job ID | `322688762770254` |
| Schedule | Every 6 hours |
| Run ID | `691816729114756` |
| Run result | `SUCCESS` |
| Run URL | `https://dbc-7f0ce7bb-56ca.cloud.databricks.com/?o=7474651143548099#job/322688762770254/run/691816729114756` |

## Failure Alert Routing

Failure email routing was added to the three scheduled Databricks jobs that keep
the data layer operational:

| Job | Job ID | Failure alert |
| --- | ---: | --- |
| `pulse360-salesforce-extract job` | `779306185996717` | `dnortje@danielnortje.com` |
| `pulse360-salesforce-governance-feedback job` | `464900392375563` | `dnortje@danielnortje.com` |
| `pulse360-data-layer-closeout-validation job` | `322688762770254` | `dnortje@danielnortje.com` |

Source-backed job definitions:

```text
config/databricks/salesforce-extract-job.json
config/databricks/salesforce-governance-feedback-job.json
config/databricks/data-layer-closeout-validation-job.json
```

## Databricks Validation Audit

The notebook writes validation evidence to:

```text
pulse360_s4.ops.data_layer_validation_runs
```

Latest run:

| Field | Value |
| --- | --- |
| Run ID | `data_layer_closeout_20260427_123039_377fc047` |
| Run timestamp | `2026-04-27T12:30:39.351Z` |
| Checks | 19 |
| Passed | 19 |
| Failed | 0 |

Key runtime checks:

| Check | Result |
| --- | --- |
| Bronze Account IDs | `total=18;current=18;stale=0` |
| Bronze Contact IDs | `total=20;current=20;stale=0` |
| Bronze Opportunity IDs | `total=31;current=31;stale=0` |
| Bronze Product IDs | `total=17;current=17;stale=0` |
| Silver Account IDs | `total=18;current=18;stale=0` |
| Gold Data Cloud export IDs | `total=18;current=18;stale=0` |
| Manila CSP action rows | `3` |
| Required Account export columns | No missing columns |
| Required activation review queue columns | No missing columns |

## Unity Catalog Lineage Evidence

Lineage was captured through the Databricks table lineage API.

| Asset | Upstream evidence | Downstream evidence |
| --- | --- | --- |
| `pulse360_s4.silver_salesforce.crm_account` | `pulse360_s4.bronze_salesforce.account` | `crm_account_hierarchy_edge`, `crm_opportunity`, `activation_eligibility_review_queue`, `account_export_base`, S4 dashboard |
| `pulse360_s4.gold.account_export_base` | `crm_account`, `crm_contact`, `crm_opportunity`, `crm_product`, `crm_governance_case`, `account_genai_enrichment_output_runtime`, `firmographic_fact` | `intelligence.datacloud_export_accounts`, `gold.account_core_export` |
| `pulse360_s4.intelligence.datacloud_export_accounts` | `gold.account_export_base` | S4 dashboard `01f14106fbcf1dea8543a28217628f38` |
| `pulse360_s4.gold.activation_eligibility_review_queue` | `account_intelligence_governance_evidence`, `registry_identity_source_sample`, `crm_account` | `intelligence.datacloud_activation_review_queue`, S4 dashboard |
| `pulse360_s4.intelligence.datacloud_activation_review_queue` | `bronze_smart_city.smart_city_b2b_customer_sample`, `gold.activation_eligibility_review_queue` | None yet; Data Cloud direct-access stream is the downstream consumer outside Unity Catalog lineage. |

## Result

The Databricks data layer is now operationally hardened for the prototype:

- source refresh jobs are scheduled
- governance feedback refresh is scheduled
- closeout validation is scheduled
- validation results persist in Unity Catalog
- core Account export and activation review queue lineage is visible

Remaining production hardening is final client-demo screenshots from the Unity
Catalog lineage UI and optional routing of Databricks job failures into Slack or
the enterprise incident channel.
