CREATE OR REPLACE VIEW pulse360_s4.gold.account_genai_enrichment_output AS
WITH facts AS (
  SELECT *
  FROM pulse360_s4.silver_firmographic.firmographic_fact
),
packet AS (
  SELECT
    'firmographic_packet_ent_ph_sec_as096_003241' AS evidence_packet_id,
    'ent_ph_sec_as096_003241' AS resolved_entity_id,
    CAST(NULL AS STRING) AS crm_account_id,
    array_sort(collect_set(source_id)) AS source_refs,
    AVG(source_confidence) AS source_reliability_score,
    CAST(0.80 AS DOUBLE) AS evidence_coverage_score,
    CAST(0.75 AS DOUBLE) AS corroboration_score,
    CAST(0.90 AS DOUBLE) AS freshness_score,
    least(AVG(source_confidence), CAST(0.84 AS DOUBLE)) AS extraction_certainty_score,
    CAST(0.10 AS DOUBLE) AS conflict_penalty,
    CAST(1.00 AS DOUBLE) AS schema_validation_score,
    CAST(1.00 AS DOUBLE) AS citation_binding_score,
    CAST(0.80 AS DOUBLE) AS actionability_score,
    CAST(0.20 AS DOUBLE) AS crm_anchor_score,
    CAST(1.00 AS DOUBLE) AS policy_safety_score,
    max(run_id) AS source_run_id,
    max(run_timestamp) AS source_run_timestamp
  FROM facts
),
scored AS (
  SELECT
    *,
    greatest(
      CAST(0 AS DOUBLE),
      least(
        CAST(1 AS DOUBLE),
        (
          0.20 * source_reliability_score
          + 0.20 * evidence_coverage_score
          + 0.15 * corroboration_score
          + 0.15 * freshness_score
          + 0.15 * extraction_certainty_score
          + 0.10 * citation_binding_score
          + 0.05 * schema_validation_score
          - conflict_penalty
        )
      )
    ) AS llm_result_confidence
  FROM packet
)
SELECT
  concat('genai_firmographic_', resolved_entity_id) AS genai_enrichment_id,
  evidence_packet_id,
  resolved_entity_id,
  crm_account_id,
  'Ayala Corporation has a coverage gap because governed firmographic evidence shows external group scale while the current CRM-safe anchor is not yet available for this group profile. The revenue and group coverage statements are limited to supplied source facts and should stay in review until a Salesforce Account anchor or approved External ID is established.' AS ai_narrative,
  to_json(
    array(
      named_struct(
        'rank', 1,
        'action_type', 'flag_hierarchy_review',
        'target', 'Ayala Corporation coverage gap review',
        'target_record_id', CAST(NULL AS STRING),
        'reasoning', 'The evidence packet contains external revenue and subsidiary-count facts, but no CRM-safe activation key. Route to stewardship before CRM activation.',
        'estimated_revenue_impact', 'Improved group coverage accuracy before seller activation',
        'confidence', CAST(0.74 AS DOUBLE),
        'source_ids', source_refs
      )
    )
  ) AS ai_recommended_actions,
  llm_result_confidence,
  (
    0.60 * llm_result_confidence
    + 0.20 * actionability_score
    + 0.10 * crm_anchor_score
    + 0.10 * policy_safety_score
  ) AS business_action_confidence,
  to_json(
    named_struct(
      'source_reliability_score', source_reliability_score,
      'evidence_coverage_score', evidence_coverage_score,
      'corroboration_score', corroboration_score,
      'freshness_score', freshness_score,
      'extraction_certainty_score', extraction_certainty_score,
      'conflict_penalty', conflict_penalty,
      'schema_validation_score', schema_validation_score,
      'citation_binding_score', citation_binding_score,
      'actionability_score', actionability_score,
      'crm_anchor_score', crm_anchor_score,
      'policy_safety_score', policy_safety_score
    )
  ) AS confidence_components,
  0 AS unsupported_claim_count,
  false AS insufficient_evidence_flag,
  to_json(source_refs) AS source_refs,
  'genai-design-placeholder' AS model_id,
  'pulse360-firmographic-evidence-v1' AS prompt_version,
  concat('llm_fixture_run_', date_format(current_timestamp(), 'yyyyMMddHHmmss')) AS llm_run_id,
  sha2(concat(evidence_packet_id, ':input'), 256) AS llm_input_hash,
  sha2(concat(evidence_packet_id, ':output'), 256) AS llm_output_hash,
  CAST(0 AS DOUBLE) AS llm_cost_estimate,
  'source_bound_fixture' AS generation_mode,
  false AS activation_eligible_flag,
  concat('genai_firmographic_fixture_run_', date_format(current_timestamp(), 'yyyyMMddHHmmss')) AS run_id,
  current_timestamp() AS run_timestamp,
  'genai-firmographic-enrichment-output-v1' AS model_version
FROM scored;
