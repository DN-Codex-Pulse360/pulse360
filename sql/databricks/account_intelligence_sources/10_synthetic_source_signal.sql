CREATE OR REPLACE VIEW pulse360_s4.silver_enterprise_sources.synthetic_source_signal AS
SELECT
  source_pack_id,
  scenario_id,
  synthetic_flag,
  generation_seed,
  source_record_id,
  source_family,
  source_system_name,
  entity_key,
  expected_resolved_entity_id AS resolved_entity_id,
  crm_account_id,
  event_type,
  event_timestamp,
  business_object_id,
  source_confidence,
  source_payload,
  edge_case_tags,
  expected_activation_state,
  CASE
    WHEN source_family = 'support' AND event_type = 'sla_breach' THEN 'renewal_risk'
    WHEN source_family = 'contracts' AND event_type = 'renewal_window_open' THEN 'renewal_window'
    WHEN source_family = 'epm' AND event_type = 'forecast_gap_detected' THEN 'coverage_gap'
    WHEN source_family = 'product_telemetry' AND event_type = 'adoption_increase' THEN 'expansion_propensity'
    WHEN source_family = 'marketing_intent' AND event_type = 'topic_surge' THEN 'intent_signal'
    WHEN source_family = 'internal_hierarchy' AND event_type = 'subsidiary_mapping' THEN 'hierarchy_gap'
    WHEN source_family = 'erp' AND event_type = 'invoice_posted' THEN 'commercial_activity'
    ELSE 'source_signal'
  END AS normalized_signal_type,
  CASE
    WHEN source_confidence >= 0.90 THEN 'high'
    WHEN source_confidence >= 0.75 THEN 'medium'
    ELSE 'low'
  END AS source_reliability_band,
  concat('synthetic_source_signal_run_', date_format(current_timestamp(), 'yyyyMMddHHmmss')) AS run_id,
  current_timestamp() AS run_timestamp,
  'synthetic-source-signal-v1' AS model_version
FROM pulse360_s4.bronze_enterprise_sources.synthetic_enterprise_source_sample
WHERE synthetic_flag = true;
