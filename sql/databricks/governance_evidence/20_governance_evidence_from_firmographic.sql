-- Demo governance evidence projection for source-backed firmographic profile attributes.
-- This view intentionally marks external audit readiness false until live lineage is captured.
CREATE OR REPLACE VIEW pulse360_s4.gold.governance_evidence_firmographic_vw AS
SELECT
  concat('gevid_', firmographic_profile_id, '_business_description') AS evidence_packet_id,
  'firmographic_attribute' AS subject_type,
  firmographic_profile_id AS subject_id,
  source_account_id,
  'business_description' AS served_attribute_name,
  sha2(coalesce(business_description, ''), 256) AS served_attribute_value_hash,
  to_json(array(named_struct(
    'source_id', firmographic_profile_id,
    'source_family', 'internet_research_or_customer_internal',
    'source_type', coalesce(primary_source_name, 'unknown'),
    'source_url', primary_source_url,
    'source_confidence', confidence,
    'source_weight', confidence,
    'freshness_status', 'unknown',
    'license_or_contract_reference', 'unknown'
  ))) AS source_contributions_json,
  to_json(array(named_struct(
    'lineage_system', 'unity_catalog',
    'upstream_table', 'pulse360_s4.silver_salesforce.crm_account',
    'downstream_table', 'pulse360_s4.gold.firmographic_profile_export',
    'lineage_status', 'pending_runtime_check'
  ))) AS lineage_refs_json,
  NULL AS model_refs_json,
  to_json(named_struct(
    'provider', 'openai',
    'model', model_version,
    'prompt_version', 'pulse360-default-v1',
    'llm_input_hash', concat('not_available:', run_id),
    'llm_output_hash', concat('not_available:', run_id),
    'citation_count', 0
  )) AS llm_audit_refs_json,
  to_json(named_struct(
    'governance_case_id', NULL,
    'reviewer_id', NULL,
    'decision_reason', NULL,
    'downstream_update_status', 'not_started'
  )) AS salesforce_audit_refs_json,
  confidence,
  'unknown' AS freshness_status,
  run_id,
  current_timestamp() AS generated_at,
  CASE
    WHEN confidence >= 0.70 AND source_account_id IS NOT NULL THEN 'passed'
    ELSE 'review_required'
  END AS validation_status,
  to_json(array('External audit readiness requires live Unity Catalog lineage and target-org audit capture.')) AS known_limitations_json,
  true AS ready_for_demo,
  false AS ready_for_external_audit,
  'Demo-ready source evidence exists; external audit requires live lineage and Salesforce/Data Cloud audit exports.' AS regulator_readiness_reason
FROM pulse360_s4.intelligence.firmographic_profile_export;
