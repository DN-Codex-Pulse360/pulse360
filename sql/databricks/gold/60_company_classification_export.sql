CREATE OR REPLACE TABLE pulse360_s4.intelligence.company_classification_export AS
SELECT
  concat('class_', lower(crm_account_id), '_industry') AS classification_id,
  concat('party_', lower(crm_account_id)) AS party_id,
  crm_account_id AS source_account_id,
  'LOCAL' AS scheme,
  upper(regexp_replace(COALESCE(crm_industry, 'unknown'), '[^A-Za-z0-9]+', '_')) AS code,
  COALESCE(crm_industry, 'Unknown') AS description,
  true AS is_primary,
  CAST(CASE WHEN crm_industry IS NOT NULL THEN 0.7 ELSE 0.45 END AS DOUBLE) AS confidence,
  concat('salesforce://Account/', crm_account_id) AS source_url,
  concat('run_', date_format(current_timestamp(), 'yyyyMMdd_HHmmss')) AS run_id,
  'pulse360-sovereign-firmographic-v1.0.0' AS model_version
FROM pulse360_s4.silver_salesforce.crm_account
WHERE crm_industry IS NOT NULL;
