CREATE OR REPLACE TABLE pulse360_s4.intelligence.datacloud_activation_review_queue AS
WITH queue AS (
  SELECT *
  FROM pulse360_s4.gold.activation_eligibility_review_queue
),
csp_target_customer_ids AS (
  SELECT
    q.governance_evidence_id,
    target_customer_ids.target_b2b_customer_id
  FROM queue q
  LATERAL VIEW OUTER explode(
    coalesce(
      from_json(get_json_object(q.confidence_components, '$.target_b2b_customer_ids'), 'ARRAY<STRING>'),
      CAST(array() AS ARRAY<STRING>)
    )
  ) target_customer_ids AS target_b2b_customer_id
  WHERE q.source_product = 'csp_smart_city_proposition_readiness'
),
csp_target_customer_names AS (
  SELECT
    ids.governance_evidence_id,
    to_json(array_sort(collect_set(c.b2b_customer_name))) AS target_b2b_customer_names
  FROM csp_target_customer_ids ids
  LEFT JOIN pulse360_s4.bronze_smart_city.smart_city_b2b_customer_sample c
    ON ids.target_b2b_customer_id = c.b2b_customer_id
  GROUP BY ids.governance_evidence_id
)
SELECT
  q.governance_evidence_id AS review_queue_id,
  q.source_product,
  q.source_record_id,
  q.resolved_entity_id,
  q.crm_activation_key,
  q.source_refs,
  to_json(q.crm_activation_candidate_ids) AS crm_activation_candidate_ids,
  to_json(q.crm_activation_candidate_names) AS crm_activation_candidate_names,
  CAST(q.crm_activation_candidate_count AS INT) AS crm_activation_candidate_count,
  q.activation_resolution_hint,
  CAST(q.confidence_score AS DOUBLE) AS confidence_score,
  q.confidence_components,
  CASE
    WHEN q.source_product = 'csp_smart_city_proposition_readiness'
      THEN get_json_object(q.confidence_components, '$.target_entity_name')
  END AS target_entity_name,
  CASE
    WHEN q.source_product = 'csp_smart_city_proposition_readiness'
      THEN get_json_object(q.confidence_components, '$.country_code')
  END AS country_code,
  CASE
    WHEN q.source_product = 'csp_smart_city_proposition_readiness'
      THEN get_json_object(q.confidence_components, '$.market')
  END AS market,
  CASE
    WHEN q.source_product = 'csp_smart_city_proposition_readiness'
      THEN get_json_object(q.confidence_components, '$.offering_family')
  END AS offering_family,
  CASE
    WHEN q.source_product = 'csp_smart_city_proposition_readiness'
      THEN get_json_object(q.confidence_components, '$.offer_bundle')
  END AS offer_bundle,
  CASE
    WHEN q.source_product = 'csp_smart_city_proposition_readiness'
      THEN get_json_object(q.confidence_components, '$.target_b2b_customer_ids')
  END AS target_b2b_customer_ids,
  CASE
    WHEN q.source_product = 'csp_smart_city_proposition_readiness'
      THEN coalesce(n.target_b2b_customer_names, '[]')
  END AS target_b2b_customer_names,
  CASE
    WHEN q.source_product = 'csp_smart_city_proposition_readiness'
      THEN get_json_object(q.confidence_components, '$.recommended_next_actions')
  END AS recommended_next_actions,
  CASE
    WHEN q.source_product <> 'csp_smart_city_proposition_readiness' THEN NULL
    WHEN q.activation_eligible_flag THEN 'activation_candidate'
    WHEN array_contains(q.activation_block_reasons, 'governance_or_privacy_review_required') THEN 'governance_review'
    WHEN q.confidence_score >= 0.70 THEN 'account_mapping_review'
    ELSE 'evidence_build_required'
  END AS review_priority,
  q.freshness_status,
  q.activation_eligible_flag,
  to_json(q.activation_block_reasons) AS activation_block_reasons,
  q.lineage_status,
  q.model_id,
  q.prompt_version,
  q.enrichment_run_id,
  q.source_run_timestamp,
  concat('Databricks activation review queue refresh - ', CAST(current_date() AS STRING)) AS ingestion_metadata_label,
  q.run_id,
  q.run_timestamp AS run_ts,
  q.run_timestamp,
  q.model_version
FROM queue q
LEFT JOIN csp_target_customer_names n
  ON q.governance_evidence_id = n.governance_evidence_id;
