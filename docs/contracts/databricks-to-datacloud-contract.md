# Contract: Databricks -> Data Cloud

## Purpose
Define handoff payload required for identity resolution, hierarchy modeling, and insights.

## Required Fields
| Field | Type | Description |
| --- | --- | --- |
| entity_id | string | Deterministic entity identifier |
| source_account_id | string | Original CRM account key |
| duplicate_confidence | number | Match score 0-100 |
| hierarchy_parent_id | string | Parent entity id |
| hierarchy_child_id | string | Child entity id |
| validity_score | number | Enrichment confidence 0-100 |
| review_flag | boolean | Manual review flag |
| run_id | string | Pipeline run identifier |
| run_timestamp | datetime | UTC pipeline completion timestamp |
| model_version | string | Model/pipeline version identifier |

## Rules
- No hardcoded scenario metrics.
- IDs must be deterministic across reruns.
- All records must carry run metadata.
