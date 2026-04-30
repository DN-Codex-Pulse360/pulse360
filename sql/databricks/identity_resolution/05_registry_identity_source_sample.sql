CREATE OR REPLACE VIEW pulse360_s4.identity_resolution.registry_identity_source_sample AS
SELECT
  'national_registry_ph_sec:AS096-003241' AS registry_source_id,
  'national_registry_ph_sec' AS source_system,
  'PH' AS country_of_incorporation,
  'SEC' AS national_id_type,
  'AS096-003241' AS national_id_value,
  'Ayala Corporation' AS registered_legal_name,
  'AYALA CORPORATION' AS normalized_legal_name,
  CAST(96 AS DOUBLE) AS source_confidence,
  to_timestamp('2026-03-28T00:00:00Z') AS last_refreshed_at,
  'https://ayala.com/' AS source_url,
  'public-registry-sample' AS contract_reference,
  array(
    named_struct(
      'source_id', 'ayala_home_2026',
      'source_name', 'Ayala Corporate Site',
      'source_type', 'corporate_profile',
      'source_url', 'https://ayala.com/',
      'document_date', '2026-03-28',
      'accessed_at', '2026-03-28T00:00:00Z',
      'excerpt', 'Ayala describes itself as a Philippine group with a broad portfolio across multiple industries and emerging businesses.'
    )
  ) AS source_refs;

