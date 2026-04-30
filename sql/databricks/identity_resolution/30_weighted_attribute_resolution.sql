CREATE OR REPLACE VIEW pulse360_s4.identity_resolution.weighted_attribute_resolution AS
WITH account_attributes AS (
  SELECT
    concat('ent_crm_', lower(crm_account_id)) AS resolved_entity_id,
    crm_account_id,
    'registered_legal_name' AS attribute_name,
    crm_account_name AS resolved_value,
    'string' AS resolved_value_type,
    CAST(90 AS DOUBLE) AS attribute_confidence,
    concat('salesforce_crm:', crm_account_id) AS winning_source_id,
    'Salesforce CRM Account' AS source_name,
    'crm' AS source_type,
    'customer_internal_preferred' AS survivorship_rule,
    crm_account_name AS candidate_value,
    crm_system_modstamp AS last_refreshed_at
  FROM pulse360_s4.silver_salesforce.crm_account
  WHERE crm_account_name IS NOT NULL

  UNION ALL

  SELECT
    concat('ent_crm_', lower(crm_account_id)) AS resolved_entity_id,
    crm_account_id,
    'industry' AS attribute_name,
    crm_industry AS resolved_value,
    'string' AS resolved_value_type,
    CAST(75 AS DOUBLE) AS attribute_confidence,
    concat('salesforce_crm:', crm_account_id) AS winning_source_id,
    'Salesforce CRM Account' AS source_name,
    'crm' AS source_type,
    'customer_internal_preferred' AS survivorship_rule,
    crm_industry AS candidate_value,
    crm_system_modstamp AS last_refreshed_at
  FROM pulse360_s4.silver_salesforce.crm_account
  WHERE crm_industry IS NOT NULL

  UNION ALL

  SELECT
    concat('ent_crm_', lower(crm_account_id)) AS resolved_entity_id,
    crm_account_id,
    'annual_revenue' AS attribute_name,
    CAST(crm_annual_revenue AS STRING) AS resolved_value,
    'number' AS resolved_value_type,
    CAST(70 AS DOUBLE) AS attribute_confidence,
    concat('salesforce_crm:', crm_account_id) AS winning_source_id,
    'Salesforce CRM Account' AS source_name,
    'crm' AS source_type,
    'customer_internal_preferred' AS survivorship_rule,
    CAST(crm_annual_revenue AS STRING) AS candidate_value,
    crm_system_modstamp AS last_refreshed_at
  FROM pulse360_s4.silver_salesforce.crm_account
  WHERE crm_annual_revenue IS NOT NULL

  UNION ALL

  SELECT
    concat(
      'ent_',
      lower(country_of_incorporation),
      '_',
      lower(regexp_replace(national_id_type, '[^A-Za-z0-9]+', '_')),
      '_',
      lower(regexp_replace(national_id_value, '[^A-Za-z0-9]+', '_'))
    ) AS resolved_entity_id,
    CAST(NULL AS STRING) AS crm_account_id,
    'registered_legal_name' AS attribute_name,
    registered_legal_name AS resolved_value,
    'string' AS resolved_value_type,
    source_confidence AS attribute_confidence,
    registry_source_id AS winning_source_id,
    source_system AS source_name,
    'national_registry' AS source_type,
    'sovereign_source_preferred' AS survivorship_rule,
    registered_legal_name AS candidate_value,
    last_refreshed_at
  FROM pulse360_s4.identity_resolution.registry_identity_source_sample
)
SELECT
  resolved_entity_id,
  crm_account_id,
  attribute_name,
  resolved_value,
  resolved_value_type,
  attribute_confidence,
  winning_source_id,
  survivorship_rule,
  array(
    named_struct(
      'source_id', winning_source_id,
      'source_name', source_name,
      'source_type', source_type,
      'candidate_value', candidate_value,
      'source_weight', CAST(1.0 AS DOUBLE),
      'source_confidence', attribute_confidence,
      'last_refreshed_at', last_refreshed_at,
      'citation', named_struct(
        'source_ref_id', winning_source_id,
        'source_url', CAST(NULL AS STRING),
        'document_date', CAST(NULL AS STRING),
        'accessed_at', current_timestamp(),
        'excerpt', concat('CRM Account value used for ', attribute_name, ' in the first weighted-attribute slice.')
      ),
      'license_or_contract_reference', CAST(NULL AS STRING)
    )
  ) AS source_contributions,
  CASE
    WHEN last_refreshed_at >= current_timestamp() - INTERVAL 90 DAYS THEN 'fresh'
    WHEN last_refreshed_at >= current_timestamp() - INTERVAL 365 DAYS THEN 'stale'
    ELSE 'unknown'
  END AS freshness_status,
  false AS review_required_flag,
  '' AS review_reason,
  concat('weighted_attr_run_', date_format(current_timestamp(), 'yyyyMMddHHmmss')) AS run_id,
  current_timestamp() AS run_timestamp,
  'weighted-attribute-v1.crm-safe-fallback' AS model_version
FROM account_attributes;
