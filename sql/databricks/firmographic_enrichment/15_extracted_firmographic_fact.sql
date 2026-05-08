CREATE OR REPLACE VIEW pulse360_s4.silver_firmographic.extracted_firmographic_fact AS
WITH raw AS (
  SELECT *
  FROM pulse360_s4.bronze_firmographic.raw_research_document
  WHERE approval_status IN ('approved_for_demo', 'approved_for_processing')
),
exploded AS (
  SELECT
    raw.*,
    fact
  FROM raw
  LATERAL VIEW explode(
    from_json(
      extracted_facts_json,
      'ARRAY<STRUCT<fact_type:STRING,fact_name:STRING,fact_value:DOUBLE,fact_value_normalized:DOUBLE,fact_unit:STRING,fact_period_start:STRING,fact_period_end:STRING,source_excerpt:STRING,extraction_confidence:DOUBLE>>'
    )
  ) facts AS fact
),
scored AS (
  SELECT
    concat('src_research_', research_document_id, '_', fact.fact_name) AS source_id,
    'governed_research_pipeline' AS source_system,
    research_document_id AS source_record_id,
    source_type,
    source_url,
    document_title,
    document_date,
    accessed_at,
    account_candidate_name,
    account_candidate_country,
    website_domain,
    resolved_entity_id,
    sovereign_identity_key,
    crm_safe_activation_key AS crm_account_id,
    identity_confidence,
    fact.fact_type,
    fact.fact_name,
    CAST(fact.fact_value AS STRING) AS fact_value,
    CAST(fact.fact_value_normalized AS STRING) AS fact_value_normalized,
    fact.fact_unit,
    to_date(fact.fact_period_start) AS fact_period_start,
    to_date(fact.fact_period_end) AS fact_period_end,
    fact.source_excerpt,
    fact.extraction_confidence,
    CASE
      WHEN source_type IN ('approved_registry_export', 'approved_regulatory_filing') THEN CAST(0.94 AS DOUBLE)
      WHEN source_type = 'approved_marketplace_delta_share' THEN CAST(0.90 AS DOUBLE)
      WHEN source_type IN ('approved_public_pdf', 'approved_public_url') THEN CAST(0.86 AS DOUBLE)
      WHEN source_type = 'approved_provider_export' THEN CAST(0.90 AS DOUBLE)
      WHEN source_type = 'approved_customer_internal_export' THEN CAST(0.88 AS DOUBLE)
      WHEN source_type = 'approved_clean_room_output' THEN CAST(0.82 AS DOUBLE)
      ELSE CAST(0.70 AS DOUBLE)
    END AS source_reliability_score,
    CASE
      WHEN document_date IS NULL THEN CAST(0.55 AS DOUBLE)
      WHEN months_between(current_date(), document_date) <= 18 THEN CAST(0.90 AS DOUBLE)
      WHEN months_between(current_date(), document_date) <= 36 THEN CAST(0.65 AS DOUBLE)
      ELSE CAST(0.35 AS DOUBLE)
    END AS freshness_score,
    CASE
      WHEN source_url IS NOT NULL
        AND document_date IS NOT NULL
        AND accessed_at IS NOT NULL
        AND license_or_use_basis IS NOT NULL
        AND fact.source_excerpt IS NOT NULL THEN CAST(0.95 AS DOUBLE)
      ELSE CAST(0.65 AS DOUBLE)
    END AS field_completeness_score,
    license_or_use_basis AS license_or_contract_reference,
    approval_status,
    run_id,
    run_timestamp
  FROM exploded
),
confidence AS (
  SELECT
    *,
    greatest(
      CAST(0 AS DOUBLE),
      least(
        CAST(1 AS DOUBLE),
        0.35 * source_reliability_score
        + 0.25 * extraction_confidence
        + 0.20 * field_completeness_score
        + 0.20 * freshness_score
      )
    ) AS source_confidence,
    CASE
      WHEN source_reliability_score >= 0.85 AND extraction_confidence >= 0.85 THEN 'source_bound_extracted'
      ELSE 'single_source_review_required'
    END AS source_reliability_code,
    CASE
      WHEN freshness_score >= 0.85 THEN 'fresh'
      WHEN freshness_score >= 0.60 THEN 'stale'
      ELSE 'expired'
    END AS freshness_status
  FROM scored
)
SELECT
  source_id,
  source_system,
  source_record_id,
  source_type,
  source_url,
  document_title,
  document_date,
  accessed_at,
  account_candidate_name,
  account_candidate_country,
  website_domain,
  resolved_entity_id,
  sovereign_identity_key,
  crm_account_id,
  identity_confidence,
  fact_type,
  fact_name,
  fact_value,
  fact_value_normalized,
  fact_unit,
  fact_period_start,
  fact_period_end,
  source_confidence,
  source_reliability_code,
  field_completeness_score,
  freshness_status,
  accessed_at AS last_refreshed_at,
  source_record_id AS raw_payload_ref,
  license_or_contract_reference,
  source_excerpt,
  approval_status,
  run_id,
  run_timestamp,
  'firmographic-research-extraction-v1' AS model_version
FROM confidence;
