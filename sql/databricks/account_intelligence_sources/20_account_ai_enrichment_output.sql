CREATE OR REPLACE VIEW pulse360_s4.gold_account_intelligence.account_ai_enrichment_output AS
WITH source_rollup AS (
  SELECT
    resolved_entity_id,
    crm_account_id,
    array_sort(collect_set(source_record_id)) AS source_record_ids,
    array_sort(collect_set(source_family)) AS source_families,
    array_sort(collect_set(normalized_signal_type)) AS signal_types,
    AVG(source_confidence) AS source_reliability_score,
    COUNT(DISTINCT source_family) AS source_family_count,
    MAX(CASE WHEN normalized_signal_type = 'renewal_risk' THEN 1 ELSE 0 END) AS has_renewal_risk,
    MAX(CASE WHEN normalized_signal_type = 'coverage_gap' THEN 1 ELSE 0 END) AS has_coverage_gap,
    MAX(CASE WHEN normalized_signal_type = 'hierarchy_gap' THEN 1 ELSE 0 END) AS has_hierarchy_gap,
    MAX(CASE WHEN normalized_signal_type = 'expansion_propensity' THEN 1 ELSE 0 END) AS has_expansion_propensity,
    MAX(CASE WHEN normalized_signal_type = 'intent_signal' THEN 1 ELSE 0 END) AS has_intent_signal,
    MAX(expected_activation_state) AS expected_activation_state,
    MAX(run_id) AS source_run_id,
    MAX(run_timestamp) AS source_run_timestamp
  FROM pulse360_s4.silver_enterprise_sources.synthetic_source_signal
  GROUP BY resolved_entity_id, crm_account_id
),
scored AS (
  SELECT
    *,
    least(CAST(1 AS DOUBLE), source_family_count / 7.0) AS cross_source_coverage_score,
    CASE WHEN crm_account_id IS NOT NULL THEN CAST(1 AS DOUBLE) ELSE CAST(0 AS DOUBLE) END AS crm_anchor_score,
    CAST(0.96 AS DOUBLE) AS freshness_score,
    CAST(0.92 AS DOUBLE) AS ground_truth_alignment_score,
    CASE
      WHEN has_renewal_risk = 1 AND has_expansion_propensity = 1 THEN CAST(0.12 AS DOUBLE)
      ELSE CAST(0.00 AS DOUBLE)
    END AS conflict_penalty,
    CAST(1.00 AS DOUBLE) AS schema_validation_score,
    CAST(1.00 AS DOUBLE) AS policy_safety_score
  FROM source_rollup
),
confidence AS (
  SELECT
    *,
    greatest(
      CAST(0 AS DOUBLE),
      least(
        CAST(1 AS DOUBLE),
        (
          0.22 * source_reliability_score
          + 0.18 * cross_source_coverage_score
          + 0.18 * crm_anchor_score
          + 0.14 * freshness_score
          + 0.14 * ground_truth_alignment_score
          + 0.07 * schema_validation_score
          + 0.07 * policy_safety_score
          - conflict_penalty
        )
      )
    ) AS llm_result_confidence
  FROM scored
)
SELECT
  concat('ai_account_intelligence_', resolved_entity_id) AS ai_enrichment_id,
  resolved_entity_id,
  crm_account_id,
  to_json(source_record_ids) AS source_record_ids,
  to_json(source_families) AS source_families,
  'Synthetic ERP, EPM, support, contract, telemetry, intent, and hierarchy records indicate a high-value renewal and expansion opportunity, but support risk and subsidiary coverage gaps require stewardship before seller activation.' AS evidence_summary,
  to_json(
    filter(
      array(
        CASE
          WHEN has_expansion_propensity = 1 OR has_intent_signal = 1 THEN named_struct(
            'signal_type', 'expansion_propensity',
            'signal_value', 'high',
            'confidence', CAST(0.86 AS DOUBLE),
            'source_record_ids', source_record_ids
          )
        END,
        CASE
          WHEN has_renewal_risk = 1 THEN named_struct(
            'signal_type', 'renewal_risk',
            'signal_value', 'medium',
            'confidence', CAST(0.82 AS DOUBLE),
            'source_record_ids', source_record_ids
          )
        END,
        CASE
          WHEN has_coverage_gap = 1 OR has_hierarchy_gap = 1 THEN named_struct(
            'signal_type', 'coverage_gap',
            'signal_value', 'subsidiary_gap_present',
            'confidence', CAST(0.91 AS DOUBLE),
            'source_record_ids', source_record_ids
          )
        END
      ),
      signal -> signal IS NOT NULL
    )
  ) AS inferred_signals,
  to_json(
    array(
      named_struct(
        'rank', 1,
        'action_type', 'route_to_stewardship',
        'target', 'Global Medical Asia coverage and renewal review',
        'target_record_id', CAST(NULL AS STRING),
        'reasoning', 'High expansion signals are present, but support risk and subsidiary coverage gaps need review before activation.',
        'confidence', CAST(0.84 AS DOUBLE),
        'source_record_ids', source_record_ids
      )
    )
  ) AS recommended_actions,
  llm_result_confidence,
  (
    0.65 * llm_result_confidence
    + 0.20 * crm_anchor_score
    + 0.15 * policy_safety_score
  ) AS business_action_confidence,
  to_json(
    named_struct(
      'source_reliability_score', source_reliability_score,
      'cross_source_coverage_score', cross_source_coverage_score,
      'crm_anchor_score', crm_anchor_score,
      'freshness_score', freshness_score,
      'ground_truth_alignment_score', ground_truth_alignment_score,
      'conflict_penalty', conflict_penalty,
      'schema_validation_score', schema_validation_score,
      'policy_safety_score', policy_safety_score
    )
  ) AS confidence_components,
  0 AS unsupported_claim_count,
  false AS insufficient_evidence_flag,
  CASE
    WHEN crm_account_id IS NULL THEN 'blocked'
    WHEN has_renewal_risk = 1 OR has_hierarchy_gap = 1 OR expected_activation_state = 'review_required' THEN 'review_required'
    WHEN llm_result_confidence >= 0.85 THEN 'activation_safe'
    ELSE 'review_required'
  END AS activation_state,
  filter(
    array(
      CASE WHEN crm_account_id IS NULL THEN 'missing_crm_activation_key' END,
      CASE WHEN has_renewal_risk = 1 THEN 'support_risk_present' END,
      CASE WHEN has_hierarchy_gap = 1 THEN 'subsidiary_gap_requires_stewardship' END,
      CASE WHEN llm_result_confidence < 0.85 THEN 'llm_result_confidence_below_threshold' END
    ),
    reason -> reason IS NOT NULL
  ) AS activation_block_reasons,
  to_json(source_record_ids) AS source_refs,
  'synthetic-ai-enrichment-fixture' AS model_id,
  'pulse360-account-intelligence-evidence-v1' AS prompt_version,
  concat('synthetic_ai_fixture_run_', date_format(current_timestamp(), 'yyyyMMddHHmmss')) AS llm_run_id,
  sha2(concat(resolved_entity_id, ':synthetic-input:', array_join(source_record_ids, '|')), 256) AS llm_input_hash,
  sha2(concat(resolved_entity_id, ':synthetic-output:', array_join(signal_types, '|')), 256) AS llm_output_hash,
  'synthetic_fixture' AS generation_mode,
  concat('account_intelligence_ai_enrichment_run_', date_format(current_timestamp(), 'yyyyMMddHHmmss')) AS run_id,
  current_timestamp() AS run_timestamp,
  'account-intelligence-ai-enrichment-output-v1' AS model_version
FROM confidence;
