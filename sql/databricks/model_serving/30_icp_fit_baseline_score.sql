-- Deterministic baseline ICP scoring view for the first DAN-286 model path.
-- This is a source-backed scoring scaffold, not a claim that a live model endpoint exists.
CREATE OR REPLACE VIEW pulse360_s4.gold.icp_fit_baseline_score_vw AS
SELECT
  concat(
    'score_',
    lower(source_account_id),
    '_icp_fit_',
    feature_set_version
  ) AS score_id,
  source_account_id,
  feature_snapshot_id,
  'icp_fit' AS model_family,
  'pulse360_icp_fit_baseline' AS model_name,
  feature_set_version AS model_version,
  'pulse360.account_intelligence.icp_fit' AS registered_model_name,
  least(
    1.0,
    greatest(
      0.0,
      coalesce(firmographic_confidence, 0.0) * 0.45
      + coalesce(evidence_coverage, 0.0) * 0.30
      + CASE WHEN annual_revenue_usd IS NOT NULL THEN 0.15 ELSE 0.0 END
      + CASE WHEN classification_code IS NOT NULL THEN 0.10 ELSE 0.0 END
      - least(coalesce(conflict_count, 0) * 0.05, 0.20)
    )
  ) AS score,
  least(1.0, greatest(0.0, coalesce(evidence_coverage, 0.0))) AS confidence,
  CASE
    WHEN activation_eligible_flag = false THEN 'insufficient_evidence'
    WHEN coalesce(evidence_coverage, 0.0) < 0.40 THEN 'insufficient_evidence'
    WHEN coalesce(firmographic_confidence, 0.0) >= 0.80 THEN 'high'
    WHEN coalesce(firmographic_confidence, 0.0) >= 0.60 THEN 'medium'
    ELSE 'low'
  END AS score_band,
  to_json(array(
    named_struct(
      'driver_name', 'firmographic_confidence',
      'direction', 'positive',
      'weight', coalesce(firmographic_confidence, 0.0),
      'evidence_ref', feature_snapshot_id
    ),
    named_struct(
      'driver_name', 'evidence_coverage',
      'direction', 'positive',
      'weight', coalesce(evidence_coverage, 0.0),
      'evidence_ref', feature_snapshot_id
    )
  )) AS top_drivers_json,
  'Baseline ICP fit scaffold based on source-backed firmographic confidence, evidence coverage, revenue presence, classification presence, and conflict count.' AS explanation_text,
  'batch' AS serving_mode,
  'data_cloud_batch_enrichment' AS consumption_path,
  run_id,
  current_timestamp() AS scored_at,
  false AS databricks_endpoint_ready,
  false AS salesforce_byom_entitlement_verified,
  false AS data_cloud_mapping_verified,
  true AS human_review_required,
  activation_eligible_flag
FROM pulse360_s4.gold.account_feature_snapshot
WHERE feature_namespace = 'icp_fit';
