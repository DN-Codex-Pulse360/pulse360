# Contract: Data Cloud -> Salesforce/Agentforce

## Purpose
Define fields and payload needed by Salesforce UX and Agentforce actions.

## Required Fields
| Field | Type | Description |
| --- | --- | --- |
| unified_profile_id | string | Data Cloud unified profile key |
| identity_confidence | number | Resolution confidence |
| hierarchy_payload | json | Group and subsidiary tree |
| group_revenue_rollup | number | Group-level revenue total |
| cross_sell_propensity | number | Calculated insight score |
| health_score | number | Account intelligence score |
| coverage_gap_flag | boolean | Subsidiary coverage gap indicator |
| last_synced_timestamp | datetime | Visible sync timestamp for UI |

## Rules
- Salesforce is execution surface, not source of truth.
- UI values must originate from Data Cloud or Databricks lineage-backed data.

## Implemented Artifacts
- `contracts/datacloud_to_salesforce_agentforce.schema.json`
- `config/data-cloud/identity-resolution-rules.json`
- `config/data-cloud/calculated-insights.yaml`
- `config/data-cloud/activation-field-mapping.csv`
- `data/samples/datacloud_identity_resolution_sample.json`
- `data/samples/datacloud_activation_sample.json`
- `scripts/validate-hierarchy-and-identity.sh`
- `scripts/validate-data-cloud-insights-config.sh`
