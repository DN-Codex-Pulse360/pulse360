CREATE OR REPLACE VIEW pulse360_s4.identity_resolution.identity_source_xref_base AS
SELECT
  concat('crm_account_id:', crm_account_id) AS source_xref_id,
  concat('ent_crm_', lower(crm_account_id)) AS resolved_entity_id,
  crm_account_id,
  crm_account_name,
  crm_billing_country AS country_of_incorporation,
  'salesforce_crm' AS source_system,
  'Account.Id' AS source_identifier_type,
  crm_account_id AS source_identifier_value,
  false AS is_identity_anchor,
  CAST(90 AS DOUBLE) AS source_confidence,
  crm_system_modstamp AS last_refreshed_at,
  CAST(NULL AS STRING) AS source_url,
  CAST(NULL AS STRING) AS contract_reference,
  current_timestamp() AS run_timestamp
FROM pulse360_s4.silver_salesforce.crm_account
WHERE crm_account_id IS NOT NULL

UNION ALL

SELECT
  concat('registry:', registry_source_id) AS source_xref_id,
  concat(
    'ent_',
    lower(country_of_incorporation),
    '_',
    lower(regexp_replace(national_id_type, '[^A-Za-z0-9]+', '_')),
    '_',
    lower(regexp_replace(national_id_value, '[^A-Za-z0-9]+', '_'))
  ) AS resolved_entity_id,
  CAST(NULL AS STRING) AS crm_account_id,
  registered_legal_name AS crm_account_name,
  country_of_incorporation,
  source_system,
  national_id_type AS source_identifier_type,
  national_id_value AS source_identifier_value,
  true AS is_identity_anchor,
  source_confidence,
  last_refreshed_at,
  source_url,
  contract_reference,
  current_timestamp() AS run_timestamp
FROM pulse360_s4.identity_resolution.registry_identity_source_sample;
