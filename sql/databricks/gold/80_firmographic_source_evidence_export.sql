CREATE OR REPLACE TABLE pulse360_s4.intelligence.firmographic_source_evidence_export AS
SELECT
  concat('evid_', lower(crm_account_id), '_legal_name') AS evidence_id,
  concat('party_', lower(crm_account_id)) AS party_id,
  crm_account_id AS source_account_id,
  'firmographic_profile.legal_name' AS field_path,
  'Salesforce Account' AS source_name,
  'crm' AS source_type,
  concat('salesforce://Account/', crm_account_id) AS source_url,
  concat('Salesforce Account Name: ', COALESCE(crm_account_name, '')) AS evidence_excerpt,
  current_timestamp() AS retrieved_at,
  CAST(0.7 AS DOUBLE) AS confidence,
  b.run_id,
  'pulse360-sovereign-firmographic-v1.0.0' AS model_version
FROM pulse360_s4.silver_salesforce.crm_account
LEFT JOIN pulse360_s4.gold.account_export_base b
  ON crm_account_id = b.source_account_id
WHERE crm_account_name IS NOT NULL

UNION ALL

SELECT
  concat('evid_', lower(crm_account_id), '_industry') AS evidence_id,
  concat('party_', lower(crm_account_id)) AS party_id,
  crm_account_id AS source_account_id,
  'firmographic_profile.primary_industry_label' AS field_path,
  'Salesforce Account' AS source_name,
  'crm' AS source_type,
  concat('salesforce://Account/', crm_account_id) AS source_url,
  concat('Salesforce Account Industry: ', COALESCE(crm_industry, '')) AS evidence_excerpt,
  current_timestamp() AS retrieved_at,
  CAST(0.65 AS DOUBLE) AS confidence,
  b.run_id,
  'pulse360-sovereign-firmographic-v1.0.0' AS model_version
FROM pulse360_s4.silver_salesforce.crm_account
LEFT JOIN pulse360_s4.gold.account_export_base b
  ON crm_account_id = b.source_account_id
WHERE crm_industry IS NOT NULL

UNION ALL

SELECT
  concat('evid_', lower(crm_account_id), '_annual_revenue') AS evidence_id,
  concat('party_', lower(crm_account_id)) AS party_id,
  crm_account_id AS source_account_id,
  'firmographic_profile.annual_revenue_local' AS field_path,
  'Salesforce Account' AS source_name,
  'crm' AS source_type,
  concat('salesforce://Account/', crm_account_id) AS source_url,
  concat('Salesforce AnnualRevenue: ', CAST(crm_annual_revenue AS STRING)) AS evidence_excerpt,
  current_timestamp() AS retrieved_at,
  CAST(0.6 AS DOUBLE) AS confidence,
  b.run_id,
  'pulse360-sovereign-firmographic-v1.0.0' AS model_version
FROM pulse360_s4.silver_salesforce.crm_account
LEFT JOIN pulse360_s4.gold.account_export_base b
  ON crm_account_id = b.source_account_id
WHERE crm_annual_revenue IS NOT NULL;
