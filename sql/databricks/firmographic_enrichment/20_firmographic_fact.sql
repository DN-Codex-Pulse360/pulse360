CREATE OR REPLACE VIEW pulse360_s4.silver_firmographic.firmographic_fact AS
WITH legacy_raw AS (
  SELECT *
  FROM pulse360_s4.bronze_firmographic.raw_company_evidence_sample
),
legacy_facts AS (
  SELECT
    concat('src_', source_record_id, '_annual_revenue') AS source_id,
    source_system,
    source_record_id,
    'neutral_fixture_payload' AS source_type,
    CAST(NULL AS STRING) AS source_url,
    'Neutral fixture payload' AS document_title,
    to_date(get_json_object(source_payload_json, '$.financials[0].fact_period_end')) AS document_date,
    source_retrieved_at AS accessed_at,
    get_json_object(source_payload_json, '$.company_identity.registered_legal_name') AS account_candidate_name,
    source_country_code AS account_candidate_country,
    'ayala.com' AS website_domain,
    'ent_ph_sec_as096_003241' AS resolved_entity_id,
    'PH|SEC_AS096|003241' AS sovereign_identity_key,
    CAST(NULL AS STRING) AS crm_account_id,
    CAST(96 AS DOUBLE) AS identity_confidence,
    'financial' AS fact_type,
    'annual_revenue' AS fact_name,
    get_json_object(source_payload_json, '$.financials[0].fact_value') AS fact_value,
    get_json_object(source_payload_json, '$.financials[0].fact_value') AS fact_value_normalized,
    get_json_object(source_payload_json, '$.financials[0].fact_unit') AS fact_unit,
    to_date(get_json_object(source_payload_json, '$.financials[0].fact_period_start')) AS fact_period_start,
    to_date(get_json_object(source_payload_json, '$.financials[0].fact_period_end')) AS fact_period_end,
    CAST(get_json_object(source_payload_json, '$.financials[0].source_confidence') AS DOUBLE) AS source_confidence,
    get_json_object(source_payload_json, '$.provider_confidence_metadata.source_reliability_code') AS source_reliability_code,
    CAST(get_json_object(source_payload_json, '$.provider_confidence_metadata.field_completeness_score') AS DOUBLE) AS field_completeness_score,
    get_json_object(source_payload_json, '$.provider_confidence_metadata.freshness_status') AS freshness_status,
    source_retrieved_at AS last_refreshed_at,
    source_record_id AS raw_payload_ref,
    license_or_contract_reference,
    'Neutral fixture: revenue fact is bound to a governed source row.' AS source_excerpt,
    'approved_for_demo' AS approval_status,
    run_id,
    run_timestamp,
    'firmographic-fact-v1' AS model_version
  FROM legacy_raw

  UNION ALL

  SELECT
    concat('src_', source_record_id, '_external_subsidiaries_found') AS source_id,
    source_system,
    source_record_id,
    'neutral_fixture_payload' AS source_type,
    CAST(NULL AS STRING) AS source_url,
    'Neutral fixture payload' AS document_title,
    to_date('2026-04-25') AS document_date,
    source_retrieved_at AS accessed_at,
    get_json_object(source_payload_json, '$.company_identity.registered_legal_name') AS account_candidate_name,
    source_country_code AS account_candidate_country,
    'ayala.com' AS website_domain,
    'ent_ph_sec_as096_003241' AS resolved_entity_id,
    'PH|SEC_AS096|003241' AS sovereign_identity_key,
    CAST(NULL AS STRING) AS crm_account_id,
    CAST(96 AS DOUBLE) AS identity_confidence,
    'hierarchy_hint' AS fact_type,
    'external_subsidiaries_found' AS fact_name,
    get_json_object(source_payload_json, '$.hierarchy_hints[0].fact_value') AS fact_value,
    get_json_object(source_payload_json, '$.hierarchy_hints[0].fact_value') AS fact_value_normalized,
    get_json_object(source_payload_json, '$.hierarchy_hints[0].fact_unit') AS fact_unit,
    CAST(NULL AS DATE) AS fact_period_start,
    to_date('2026-04-25') AS fact_period_end,
    CAST(get_json_object(source_payload_json, '$.hierarchy_hints[0].source_confidence') AS DOUBLE) AS source_confidence,
    'single_source_review_required' AS source_reliability_code,
    CAST(0.78 AS DOUBLE) AS field_completeness_score,
    get_json_object(source_payload_json, '$.provider_confidence_metadata.freshness_status') AS freshness_status,
    source_retrieved_at AS last_refreshed_at,
    source_record_id AS raw_payload_ref,
    license_or_contract_reference,
    'Neutral fixture: group coverage fact is bound to a governed source row.' AS source_excerpt,
    'approved_for_demo' AS approval_status,
    run_id,
    run_timestamp,
    'firmographic-fact-v1' AS model_version
  FROM legacy_raw
),
research_facts AS (
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
    last_refreshed_at,
    raw_payload_ref,
    license_or_contract_reference,
    source_excerpt,
    approval_status,
    run_id,
    run_timestamp,
    model_version
  FROM pulse360_s4.silver_firmographic.extracted_firmographic_fact
),
facts AS (
  SELECT * FROM legacy_facts
  UNION ALL
  SELECT * FROM research_facts
)
SELECT *
FROM facts;
