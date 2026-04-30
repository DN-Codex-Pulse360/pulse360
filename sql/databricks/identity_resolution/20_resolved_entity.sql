CREATE OR REPLACE VIEW pulse360_s4.identity_resolution.resolved_entity AS
SELECT
  concat('ent_crm_', lower(a.crm_account_id)) AS resolved_entity_id,
  concat('CRM_SAFE_FALLBACK|', a.crm_account_id) AS sovereign_identity_key,
  COALESCE(a.crm_billing_country, 'UN') AS country_of_incorporation,
  'CRM_ACCOUNT_ID' AS national_id_type,
  a.crm_account_id AS national_id_value,
  a.crm_account_name AS registered_legal_name,
  upper(regexp_replace(COALESCE(a.crm_account_name, ''), '[^A-Za-z0-9]+', ' ')) AS normalized_legal_name,
  'crm_safe_fallback' AS identity_resolution_method,
  CAST(90 AS DOUBLE) AS identity_confidence,
  array(a.crm_account_id) AS crm_account_ids,
  a.crm_account_id AS primary_crm_account_id,
  array(
    named_struct(
      'source_system', 'salesforce_crm',
      'source_identifier_type', 'Account.Id',
      'source_identifier_value', a.crm_account_id,
      'is_identity_anchor', false,
      'source_confidence', CAST(90 AS DOUBLE),
      'last_refreshed_at', a.crm_system_modstamp,
      'source_url', CAST(NULL AS STRING),
      'contract_reference', CAST(NULL AS STRING)
    )
  ) AS source_identifiers,
  array(
    named_struct(
      'feature_name', 'crm_account_id',
      'feature_value', 'crm_safe_fallback',
      'feature_weight', CAST(1.0 AS DOUBLE),
      'feature_explanation', 'No sovereign registry input is present in the first slice, so Salesforce Account.Id is preserved as the activation-safe fallback identity.'
    )
  ) AS match_features,
  false AS review_required_flag,
  '' AS review_reason,
  concat('identity_run_', date_format(current_timestamp(), 'yyyyMMddHHmmss')) AS run_id,
  current_timestamp() AS run_timestamp,
  'sovereign-identity-v1.crm-safe-fallback' AS model_version
FROM pulse360_s4.silver_salesforce.crm_account a
WHERE a.crm_account_id IS NOT NULL

UNION ALL

SELECT
  concat(
    'ent_',
    lower(r.country_of_incorporation),
    '_',
    lower(regexp_replace(r.national_id_type, '[^A-Za-z0-9]+', '_')),
    '_',
    lower(regexp_replace(r.national_id_value, '[^A-Za-z0-9]+', '_'))
  ) AS resolved_entity_id,
  concat(
    r.country_of_incorporation,
    '|',
    r.national_id_type,
    '|',
    r.national_id_value,
    '|',
    r.normalized_legal_name
  ) AS sovereign_identity_key,
  r.country_of_incorporation,
  r.national_id_type,
  r.national_id_value,
  r.registered_legal_name,
  r.normalized_legal_name,
  'deterministic_sovereign_id' AS identity_resolution_method,
  r.source_confidence AS identity_confidence,
  array() AS crm_account_ids,
  CAST(NULL AS STRING) AS primary_crm_account_id,
  array(
    named_struct(
      'source_system', r.source_system,
      'source_identifier_type', r.national_id_type,
      'source_identifier_value', r.national_id_value,
      'is_identity_anchor', true,
      'source_confidence', r.source_confidence,
      'last_refreshed_at', r.last_refreshed_at,
      'source_url', r.source_url,
      'contract_reference', r.contract_reference
    )
  ) AS source_identifiers,
  array(
    named_struct(
      'feature_name', 'sovereign_registry_identifier',
      'feature_value', concat(r.national_id_type, ':', r.national_id_value),
      'feature_weight', CAST(1.0 AS DOUBLE),
      'feature_explanation', 'A regulator-style identifier is present in the registry source sample and is treated as the deterministic identity anchor.'
    )
  ) AS match_features,
  false AS review_required_flag,
  '' AS review_reason,
  concat('identity_run_', date_format(current_timestamp(), 'yyyyMMddHHmmss')) AS run_id,
  current_timestamp() AS run_timestamp,
  'sovereign-identity-v1.registry-sample' AS model_version
FROM pulse360_s4.identity_resolution.registry_identity_source_sample r;
