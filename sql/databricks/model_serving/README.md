# Pulse360 Model Serving SQL

This package supports `DAN-286` by defining the governed feature and score outputs needed before live Databricks model serving or Salesforce BYOM setup.

## Execution Order

1. `00_create_schema.sql`
2. `10_account_feature_snapshot.sql`
3. `20_model_score_output.sql`
4. `30_icp_fit_baseline_score.sql`

## Contract Rules

- `source_account_id` remains the Salesforce Account activation key.
- Feature snapshots must carry `snapshot_as_of`, `feature_set_version`, source refs, input table versions, quality metrics, and run metadata.
- Model outputs must carry score, confidence, score band, top drivers, explanation text, model version, run ID, and timestamp.
- `databricks_endpoint_ready`, `salesforce_byom_entitlement_verified`, and `data_cloud_mapping_verified` default to false until proven in the target runtime.
- Real-time serving is gated. Batch scoring is the default Data Cloud/Salesforce path for the first slice.

## First Model

The first planned model family is `icp_fit`.

The `icp_fit_baseline_score_vw` view is a deterministic scaffold used for validation and demo planning. It is not a claim that a live Mosaic AI Model Serving endpoint or Salesforce BYOM prediction job has been deployed.
