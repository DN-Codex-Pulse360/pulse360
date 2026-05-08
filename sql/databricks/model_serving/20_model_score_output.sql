-- Model score output table for Salesforce/Data Cloud consumption.
-- Scores are advisory until downstream BYOM/Data Cloud gates are verified.
CREATE TABLE IF NOT EXISTS pulse360_s4.gold.model_score_output (
  score_id STRING NOT NULL COMMENT 'Deterministic model score primary key.',
  source_account_id STRING NOT NULL COMMENT 'Salesforce Account ID used as the CRM activation key.',
  feature_snapshot_id STRING NOT NULL COMMENT 'Feature snapshot used for this score.',
  model_family STRING NOT NULL COMMENT 'icp_fit, cross_sell_propensity, intent_routing, renewal_risk, or entity_resolution.',
  model_name STRING NOT NULL,
  model_version STRING NOT NULL,
  registered_model_name STRING NOT NULL COMMENT 'Unity Catalog or MLflow registered model name.',
  score DOUBLE NOT NULL,
  confidence DOUBLE NOT NULL,
  score_band STRING NOT NULL COMMENT 'low, medium, high, or insufficient_evidence.',
  top_drivers_json STRING NOT NULL COMMENT 'Ranked source-bound model drivers for Salesforce display.',
  explanation_text STRING NOT NULL COMMENT 'Seller/steward readable explanation.',
  serving_mode STRING NOT NULL COMMENT 'batch, near_real_time, or real_time_endpoint.',
  consumption_path STRING NOT NULL COMMENT 'Data Cloud batch, Salesforce BYOM, Flow/Apex callout, or report-only path.',
  run_id STRING NOT NULL,
  scored_at TIMESTAMP NOT NULL,
  databricks_endpoint_ready BOOLEAN NOT NULL,
  salesforce_byom_entitlement_verified BOOLEAN NOT NULL,
  data_cloud_mapping_verified BOOLEAN NOT NULL,
  human_review_required BOOLEAN NOT NULL,
  activation_eligible_flag BOOLEAN NOT NULL
)
USING DELTA
COMMENT 'Pulse360 source-bound model score outputs for Data Cloud and Salesforce activation.';
