CREATE OR REPLACE VIEW pulse360_s4.gold.activation_eligibility_review_queue AS
WITH registry_entities AS (
  SELECT
    concat(
      'ent_',
      lower(country_of_incorporation),
      '_',
      lower(regexp_replace(national_id_type, '[^A-Za-z0-9]+', '_')),
      '_',
      lower(regexp_replace(national_id_value, '[^A-Za-z0-9]+', '_'))
    ) AS resolved_entity_id,
    country_of_incorporation,
    regexp_replace(
      regexp_replace(upper(coalesce(normalized_legal_name, registered_legal_name, '')), '\\bCORPORATION\\b', 'CORP'),
      '[^A-Z0-9]+',
      ' '
    ) AS crm_match_name_key
  FROM pulse360_s4.identity_resolution.registry_identity_source_sample
),
crm_account_candidates AS (
  SELECT
    crm_account_id,
    crm_account_name,
    crm_billing_country,
    regexp_replace(
      regexp_replace(upper(coalesce(crm_account_name, '')), '\\bCORPORATION\\b', 'CORP'),
      '[^A-Z0-9]+',
      ' '
    ) AS crm_match_name_key
  FROM pulse360_s4.silver_salesforce.crm_account
  WHERE crm_account_id IS NOT NULL
),
activation_candidates AS (
  SELECT
    r.resolved_entity_id,
    array_sort(collect_set(c.crm_account_id)) AS crm_activation_candidate_ids,
    array_sort(collect_set(c.crm_account_name)) AS crm_activation_candidate_names,
    COUNT(DISTINCT c.crm_account_id) AS crm_activation_candidate_count
  FROM registry_entities r
  INNER JOIN crm_account_candidates c
    ON r.crm_match_name_key = c.crm_match_name_key
   AND coalesce(c.crm_billing_country, '') = r.country_of_incorporation
  GROUP BY r.resolved_entity_id
),
queue AS (
  SELECT *
  FROM pulse360_s4.gold.account_intelligence_governance_evidence
  WHERE (
      source_product = 'csp_smart_city_proposition_readiness'
      AND (review_required_flag = true OR activation_eligible_flag = true)
    )
    OR (
      source_product <> 'csp_smart_city_proposition_readiness'
      AND (review_required_flag = true OR activation_eligible_flag = false)
    )
)
SELECT
  q.governance_evidence_id,
  q.source_product,
  q.source_record_id,
  q.resolved_entity_id,
  q.crm_activation_key,
  q.source_refs,
  coalesce(c.crm_activation_candidate_ids, array()) AS crm_activation_candidate_ids,
  coalesce(c.crm_activation_candidate_names, array()) AS crm_activation_candidate_names,
  coalesce(c.crm_activation_candidate_count, 0) AS crm_activation_candidate_count,
  CASE
    WHEN q.crm_activation_key IS NOT NULL THEN 'activation_key_available'
    WHEN coalesce(c.crm_activation_candidate_count, 0) = 1 THEN 'single_crm_candidate_requires_steward_review'
    WHEN coalesce(c.crm_activation_candidate_count, 0) > 1 THEN 'ambiguous_crm_candidates_require_stewardship'
    ELSE 'create_or_map_crm_account_required'
  END AS activation_resolution_hint,
  q.confidence_score,
  q.confidence_components,
  q.freshness_status,
  q.activation_eligible_flag,
  q.activation_block_reasons,
  q.lineage_status,
  q.model_id,
  q.prompt_version,
  q.enrichment_run_id,
  q.source_run_timestamp,
  q.run_id,
  q.run_timestamp,
  q.model_version
FROM queue q
LEFT JOIN activation_candidates c
  ON q.resolved_entity_id = c.resolved_entity_id;
