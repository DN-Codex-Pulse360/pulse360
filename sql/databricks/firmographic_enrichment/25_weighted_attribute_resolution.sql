CREATE OR REPLACE VIEW pulse360_s4.silver_firmographic.source_contribution AS
WITH facts AS (
  SELECT *
  FROM pulse360_s4.silver_firmographic.firmographic_fact
  WHERE approval_status IN ('approved_for_demo', 'approved_for_processing')
),
weighted AS (
  SELECT
    concat('contrib_', sha2(concat_ws('|', source_id, fact_name, COALESCE(fact_value_normalized, '')), 256)) AS source_contribution_id,
    COALESCE(crm_account_id, resolved_entity_id, sovereign_identity_key, account_candidate_name) AS entity_anchor_id,
    crm_account_id AS source_account_id,
    resolved_entity_id,
    concat('firmographic_profile.', fact_name) AS attribute_path,
    fact_name AS attribute_name,
    fact_type,
    source_id,
    source_system,
    source_record_id,
    source_type,
    CASE
      WHEN source_type IN ('approved_registry_export', 'approved_regulatory_filing') THEN 'national_registry'
      WHEN source_type IN ('approved_marketplace_delta_share', 'approved_provider_export') THEN 'commercial_provider_marketplace'
      WHEN source_type = 'approved_customer_internal_export' THEN 'customer_internal'
      WHEN source_type IN ('approved_public_pdf', 'approved_public_url', 'manual_research_note') THEN 'internet_research'
      WHEN source_type = 'approved_clean_room_output' THEN 'clean_room_collaboration'
      WHEN source_type = 'neutral_fixture_payload' THEN 'neutral_fixture'
      ELSE 'internet_research'
    END AS source_family,
    source_url,
    document_title,
    document_date,
    accessed_at,
    fact_value,
    fact_value_normalized,
    fact_unit,
    fact_period_start,
    fact_period_end,
    source_confidence,
    field_completeness_score,
    freshness_status,
    CASE
      WHEN freshness_status = 'fresh' THEN CAST(0.90 AS DOUBLE)
      WHEN freshness_status = 'stale' THEN CAST(0.65 AS DOUBLE)
      WHEN freshness_status = 'expired' THEN CAST(0.35 AS DOUBLE)
      ELSE CAST(0.55 AS DOUBLE)
    END AS freshness_score,
    CASE
      WHEN source_type IN ('approved_registry_export', 'approved_regulatory_filing') THEN CAST(0.94 AS DOUBLE)
      WHEN source_type IN ('approved_marketplace_delta_share', 'approved_provider_export') THEN CAST(0.90 AS DOUBLE)
      WHEN source_type = 'approved_customer_internal_export' THEN CAST(0.88 AS DOUBLE)
      WHEN source_type IN ('approved_public_pdf', 'approved_public_url') THEN CAST(0.86 AS DOUBLE)
      WHEN source_type = 'approved_clean_room_output' THEN CAST(0.82 AS DOUBLE)
      WHEN source_type = 'neutral_fixture_payload' THEN CAST(0.78 AS DOUBLE)
      ELSE CAST(0.70 AS DOUBLE)
    END AS source_weight,
    source_excerpt,
    raw_payload_ref,
    license_or_contract_reference,
    last_refreshed_at,
    run_id,
    run_timestamp,
    model_version
  FROM facts
),
scored AS (
  SELECT
    *,
    greatest(
      CAST(0 AS DOUBLE),
      least(
        CAST(1 AS DOUBLE),
        0.45 * COALESCE(source_confidence, CAST(0 AS DOUBLE))
        + 0.25 * source_weight
        + 0.15 * freshness_score
        + 0.15 * COALESCE(field_completeness_score, CAST(0 AS DOUBLE))
      )
    ) AS contribution_score
  FROM weighted
)
SELECT
  source_contribution_id,
  entity_anchor_id,
  source_account_id,
  resolved_entity_id,
  attribute_path,
  attribute_name,
  fact_type,
  source_id,
  source_system,
  source_record_id,
  source_type,
  source_family,
  source_url,
  document_title,
  document_date,
  accessed_at,
  fact_value,
  fact_value_normalized,
  fact_unit,
  fact_period_start,
  fact_period_end,
  source_confidence,
  source_weight,
  freshness_score,
  field_completeness_score,
  contribution_score,
  freshness_status,
  source_excerpt,
  raw_payload_ref,
  license_or_contract_reference,
  last_refreshed_at,
  run_id,
  run_timestamp,
  model_version
FROM scored;

CREATE OR REPLACE VIEW pulse360_s4.silver_firmographic.weighted_attribute_resolution AS
WITH contributions AS (
  SELECT *
  FROM pulse360_s4.silver_firmographic.source_contribution
),
ranked AS (
  SELECT
    *,
    row_number() OVER (
      PARTITION BY entity_anchor_id, attribute_path
      ORDER BY contribution_score DESC, last_refreshed_at DESC, source_id ASC
    ) AS contribution_rank
  FROM contributions
),
aggregated AS (
  SELECT
    entity_anchor_id,
    attribute_path,
    COUNT(*) AS source_contribution_count,
    COUNT(DISTINCT COALESCE(fact_value_normalized, fact_value, '')) AS distinct_value_count,
    array_sort(collect_set(source_id)) AS source_refs,
    array_sort(collect_set(license_or_contract_reference)) AS license_or_contract_references,
    to_json(
      collect_list(
        named_struct(
          'source_id', source_id,
          'source_family', source_family,
          'source_system', source_system,
          'source_type', source_type,
          'source_record_id', source_record_id,
          'source_url', source_url,
          'source_confidence', source_confidence,
          'source_weight', source_weight,
          'freshness_score', freshness_score,
          'field_completeness_score', field_completeness_score,
          'contribution_score', contribution_score,
          'selected_flag', CASE WHEN contribution_rank = 1 THEN true ELSE false END,
          'rejection_reason', CASE
            WHEN contribution_rank = 1 THEN CAST(NULL AS STRING)
            ELSE 'Lower weighted contribution score than selected source.'
          END,
          'source_excerpt', source_excerpt,
          'license_or_contract_reference', license_or_contract_reference,
          'run_id', run_id
        )
      )
    ) AS source_contributions_json
  FROM ranked
  GROUP BY entity_anchor_id, attribute_path
),
top_contribution AS (
  SELECT *
  FROM ranked
  WHERE contribution_rank = 1
)
SELECT
  concat('wattr_', sha2(concat_ws('|', t.entity_anchor_id, t.attribute_path), 256)) AS attribute_resolution_id,
  t.entity_anchor_id,
  t.source_account_id,
  t.resolved_entity_id,
  t.attribute_path,
  t.attribute_name,
  t.fact_type,
  t.fact_value AS winning_value,
  t.fact_value_normalized AS winning_value_normalized,
  t.fact_unit,
  t.source_id AS winning_source_id,
  t.source_family AS winning_source_family,
  CASE
    WHEN t.source_family = 'national_registry' THEN 'official_source_priority'
    WHEN t.source_family = 'clean_room_collaboration' THEN 'aggregate_only'
    ELSE 'highest_weighted_confidence'
  END AS survivorship_rule,
  CASE
    WHEN a.source_contribution_count = 1 THEN 'single_source'
    WHEN a.distinct_value_count <= 1 THEN 'corroborated'
    ELSE 'conflict_review_required'
  END AS resolution_status,
  t.contribution_score AS confidence,
  t.freshness_status,
  a.source_contribution_count,
  greatest(CAST(0 AS BIGINT), a.distinct_value_count - 1) AS conflict_count,
  a.source_contributions_json,
  to_json(a.source_refs) AS source_refs_json,
  to_json(a.license_or_contract_references) AS license_or_contract_references_json,
  current_timestamp() AS last_resolved_at,
  concat('weighted_attribute_run_', date_format(current_timestamp(), 'yyyyMMddHHmmss')) AS run_id,
  'weighted-attribute-resolution-v1' AS model_version
FROM top_contribution t
JOIN aggregated a
  ON t.entity_anchor_id = a.entity_anchor_id
  AND t.attribute_path = a.attribute_path;
