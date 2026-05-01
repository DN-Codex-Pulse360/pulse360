CREATE OR REPLACE TABLE pulse360_s4.intelligence.company_classification_export AS
SELECT
  concat('class_', lower(a.crm_account_id), '_industry') AS classification_id,
  concat('party_', lower(a.crm_account_id)) AS party_id,
  a.crm_account_id AS source_account_id,
  'LOCAL' AS scheme,
  upper(regexp_replace(COALESCE(a.crm_industry, 'unknown'), '[^A-Za-z0-9]+', '_')) AS code,
  COALESCE(a.crm_industry, 'Unknown') AS description,
  true AS is_primary,
  CAST(CASE WHEN a.crm_industry IS NOT NULL THEN 0.7 ELSE 0.45 END AS DOUBLE) AS confidence,
  concat('salesforce://Account/', a.crm_account_id) AS source_url,
  b.run_id,
  'pulse360-sovereign-firmographic-v1.0.0' AS model_version
FROM pulse360_s4.silver_salesforce.crm_account a
LEFT JOIN pulse360_s4.gold.account_export_base b
  ON a.crm_account_id = b.source_account_id
WHERE a.crm_industry IS NOT NULL;
