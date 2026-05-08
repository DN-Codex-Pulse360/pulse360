-- Feature snapshot table for ICP, whitespace, routing, renewal, and entity-resolution models.
-- source_account_id remains the CRM-safe Salesforce Account activation key.
CREATE TABLE IF NOT EXISTS pulse360_s4.gold.account_feature_snapshot (
  feature_snapshot_id STRING NOT NULL COMMENT 'Deterministic feature snapshot primary key.',
  source_account_id STRING NOT NULL COMMENT 'Salesforce Account ID used as the CRM activation key.',
  snapshot_as_of TIMESTAMP NOT NULL COMMENT 'Point-in-time feature snapshot timestamp.',
  feature_set_version STRING NOT NULL COMMENT 'Versioned feature-set contract such as icp_fit_v1.',
  feature_namespace STRING NOT NULL COMMENT 'icp_fit, whitespace, intent_routing, renewal_risk, or entity_resolution.',
  point_in_time_policy STRING NOT NULL COMMENT 'Point-in-time rule used to avoid future leakage.',
  annual_revenue_usd DOUBLE,
  employee_total BIGINT,
  business_category STRING,
  classification_code STRING,
  firmographic_confidence DOUBLE,
  evidence_count BIGINT,
  has_corporate_linkage BOOLEAN,
  hierarchy_depth BIGINT,
  group_revenue_usd DOUBLE,
  coverage_gap_count BIGINT,
  engagement_signal_count BIGINT,
  support_case_count BIGINT,
  usage_signal_count BIGINT,
  source_refs_json STRING NOT NULL COMMENT 'JSON array of source refs used by the feature snapshot.',
  input_table_versions_json STRING NOT NULL COMMENT 'JSON object of source table versions or run refs.',
  feature_completeness DOUBLE NOT NULL,
  evidence_coverage DOUBLE NOT NULL,
  conflict_count BIGINT NOT NULL,
  run_id STRING NOT NULL,
  created_at TIMESTAMP NOT NULL,
  activation_eligible_flag BOOLEAN NOT NULL
)
USING DELTA
COMMENT 'Pulse360 governed account feature snapshots for model training and scoring.';
