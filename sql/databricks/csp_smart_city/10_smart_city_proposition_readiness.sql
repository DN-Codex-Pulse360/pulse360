CREATE OR REPLACE VIEW pulse360_s4.gold_smart_city.smart_city_proposition_readiness AS
WITH source_rollup AS (
  SELECT
    signal_pack_id,
    scenario_id,
    target_entity_id,
    target_entity_name,
    country_code,
    market,
    target_entity_type,
    offering_family,
    first(offer_bundle) AS offer_bundle,
    collect_set(source_family) AS source_families,
    collect_set(consent_privacy_classification) AS consent_classes,
    count(*) AS signal_count,
    avg(signal_confidence) AS average_signal_confidence,
    max(CASE WHEN source_family = 'public_sector_trigger' THEN 1 ELSE 0 END) AS has_public_sector_trigger,
    max(CASE WHEN consent_privacy_classification IN ('restricted_review_required', 'blocked') THEN 1 ELSE 0 END) AS has_governance_constraint,
    array_sort(
      array_distinct(
        flatten(
          collect_list(
            coalesce(
              from_json(get_json_object(source_payload, '$.target_b2b_customer_ids'), 'ARRAY<STRING>'),
              CAST(array() AS ARRAY<STRING>)
            )
          )
        )
      )
    ) AS target_b2b_customer_ids,
    collect_list(named_struct(
      'signal_id', signal_id,
      'source_family', source_family,
      'source_system_name', source_system_name,
      'evidence_url', evidence_url,
      'signal_confidence', signal_confidence,
      'evidence_summary', evidence_summary,
      'target_b2b_customer_ids',
        coalesce(
          from_json(get_json_object(source_payload, '$.target_b2b_customer_ids'), 'ARRAY<STRING>'),
          CAST(array() AS ARRAY<STRING>)
        )
    )) AS source_refs,
    collect_list(recommended_next_action) AS recommended_next_actions
  FROM pulse360_s4.bronze_smart_city.smart_city_signal_sample
  GROUP BY
    signal_pack_id,
    scenario_id,
    target_entity_id,
    target_entity_name,
    country_code,
    market,
    target_entity_type,
    offering_family
),
scored AS (
  SELECT
    *,
    round(
      least(
        1.0,
        (average_signal_confidence * 0.65)
          + (least(size(source_families), 6) / 6.0 * 0.25)
          + (has_public_sector_trigger * 0.10)
      ),
      4
    ) AS proposition_readiness_score
  FROM source_rollup
)
SELECT
  concat('smart_city_readiness_', target_entity_id, '_', offering_family) AS proposition_readiness_id,
  signal_pack_id,
  scenario_id,
  target_entity_id,
  target_entity_name,
  country_code,
  market,
  target_entity_type,
  offering_family,
  offer_bundle,
  proposition_readiness_score,
  CASE
    WHEN has_governance_constraint = 1 THEN 'review_required'
    WHEN proposition_readiness_score >= 0.82 THEN 'activation_safe'
    WHEN proposition_readiness_score >= 0.70 THEN 'review_required'
    ELSE 'blocked'
  END AS activation_state,
  CASE
    WHEN has_governance_constraint = 1 THEN array('governance_or_privacy_review_required')
    WHEN proposition_readiness_score < 0.70 THEN array('insufficient_cross_source_evidence')
    ELSE array()
  END AS activation_block_reasons,
  signal_count,
  average_signal_confidence,
  target_b2b_customer_ids,
  source_families,
  consent_classes,
  to_json(source_refs) AS source_refs,
  to_json(recommended_next_actions) AS recommended_next_actions,
  current_timestamp() AS run_timestamp,
  'csp-smart-city-proposition-v1' AS model_version
FROM scored;
