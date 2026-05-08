CREATE OR REPLACE VIEW pulse360_s4.bronze_firmographic.raw_research_document AS
SELECT
  'research_doc_ayala_integrated_report_2024' AS research_document_id,
  'internet_research' AS source_family,
  'src_adapter_internet_research_document_extraction_demo_v1' AS source_adapter_id,
  'approved_public_pdf' AS source_type,
  'https://www.ayala.com/investors/reports' AS source_url,
  'Ayala Corporation Integrated Report 2024' AS document_title,
  to_date('2024-12-31') AS document_date,
  to_timestamp('2026-04-26T00:00:00Z') AS accessed_at,
  'public-company-investor-report-demo-use' AS license_or_use_basis,
  'Ayala Corporation' AS account_candidate_name,
  'PH' AS account_candidate_country,
  'ayala.com' AS website_domain,
  'ent_ph_sec_as096_003241' AS resolved_entity_id,
  'PH|SEC_AS096|003241' AS sovereign_identity_key,
  CAST(NULL AS STRING) AS crm_safe_activation_key,
  CAST(96 AS DOUBLE) AS identity_confidence,
  'approved_for_demo' AS approval_status,
  to_json(
    array(
      named_struct(
        'fact_type', 'financial',
        'fact_name', 'annual_revenue',
        'fact_value', CAST(176300000000 AS DOUBLE),
        'fact_value_normalized', CAST(176300000000 AS DOUBLE),
        'fact_unit', 'PHP',
        'fact_period_start', '2024-01-01',
        'fact_period_end', '2024-12-31',
        'source_excerpt', 'Approved research fixture: annual revenue fact extracted from governed public-report row.',
        'extraction_confidence', CAST(0.90 AS DOUBLE)
      ),
      named_struct(
        'fact_type', 'hierarchy_hint',
        'fact_name', 'external_subsidiaries_found',
        'fact_value', CAST(3 AS DOUBLE),
        'fact_value_normalized', CAST(3 AS DOUBLE),
        'fact_unit', 'count',
        'fact_period_start', CAST(NULL AS STRING),
        'fact_period_end', '2026-04-26',
        'source_excerpt', 'Approved research fixture: group coverage hint extracted from governed public-report row.',
        'extraction_confidence', CAST(0.82 AS DOUBLE)
      )
    )
  ) AS extracted_facts_json,
  'firmographic_research_fixture_run_20260426000000' AS run_id,
  to_timestamp('2026-04-26T00:00:00Z') AS run_timestamp,
  current_timestamp() AS ingested_at;
