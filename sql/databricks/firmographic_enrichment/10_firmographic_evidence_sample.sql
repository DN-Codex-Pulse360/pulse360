CREATE OR REPLACE VIEW pulse360_s4.bronze_firmographic.raw_company_evidence_sample AS
SELECT
  'neutral_fixture' AS source_system,
  'firmographic_evidence_fixture_v1' AS source_dataset,
  'neutral_ayala_20260425' AS source_record_id,
  'PH' AS source_country_code,
  to_json(
    named_struct(
      'company_identity', named_struct(
        'registered_legal_name', 'Ayala Corporation',
        'trade_name', 'Ayala',
        'normalized_name', 'ayala corporation'
      ),
      'official_identifiers', array(
        named_struct(
          'identifier_type', 'national_registry_number',
          'identifier_value', 'AS096-003241',
          'jurisdiction', 'PH'
        )
      ),
      'location', named_struct(
        'country', 'PH',
        'city', 'Makati',
        'headquarters_flag', true
      ),
      'classification', named_struct(
        'sector', 'Diversified Holdings',
        'business_description', 'Diversified group with operating company interests.'
      ),
      'financials', array(
        named_struct(
          'fact_name', 'annual_revenue',
          'fact_value', CAST(176300000000 AS DOUBLE),
          'fact_unit', 'PHP',
          'fact_period_start', '2024-01-01',
          'fact_period_end', '2024-12-31',
          'source_confidence', CAST(0.91 AS DOUBLE)
        )
      ),
      'hierarchy_hints', array(
        named_struct(
          'fact_name', 'external_subsidiaries_found',
          'fact_value', CAST(3 AS DOUBLE),
          'fact_unit', 'count',
          'source_confidence', CAST(0.84 AS DOUBLE)
        )
      ),
      'provider_confidence_metadata', named_struct(
        'source_reliability_code', 'independently_corroborated',
        'field_completeness_score', CAST(0.86 AS DOUBLE),
        'freshness_status', 'fresh'
      )
    )
  ) AS source_payload_json,
  'neutral-fixture-v1' AS field_set_version,
  'approved-neutral-fixture' AS license_or_contract_reference,
  to_timestamp('2026-04-25T00:00:00Z') AS source_retrieved_at,
  current_timestamp() AS ingested_at,
  concat('firmographic_evidence_fixture_run_', date_format(current_timestamp(), 'yyyyMMddHHmmss')) AS run_id,
  current_timestamp() AS run_timestamp;
