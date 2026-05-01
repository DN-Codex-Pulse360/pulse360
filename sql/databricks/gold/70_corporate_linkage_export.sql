CREATE OR REPLACE TABLE pulse360_s4.intelligence.corporate_linkage_export AS
SELECT
  concat('link_', lower(child.crm_account_id), '_parent') AS linkage_id,
  concat('party_', lower(child.crm_account_id)) AS party_id,
  child.crm_account_id AS source_account_id,
  'parent' AS relationship_type,
  concat('party_', lower(parent.crm_account_id)) AS related_party_id,
  parent.crm_account_name AS related_entity_name,
  '' AS related_identifier_type,
  '' AS related_identifier_value,
  CAST(NULL AS DOUBLE) AS ownership_percentage,
  substr(COALESCE(parent.crm_billing_country, child.crm_billing_country, 'ZZ'), 1, 2) AS jurisdiction_country_code,
  CAST(0.72 AS DOUBLE) AS confidence,
  concat('salesforce://Account/', child.crm_account_id) AS source_url,
  concat('run_', date_format(current_timestamp(), 'yyyyMMdd_HHmmss')) AS run_id,
  'pulse360-sovereign-firmographic-v1.0.0' AS model_version
FROM pulse360_s4.silver_salesforce.crm_account child
INNER JOIN pulse360_s4.silver_salesforce.crm_account parent
  ON child.crm_parent_account_id = parent.crm_account_id
WHERE child.crm_parent_account_id IS NOT NULL

UNION ALL

SELECT
  concat('link_', lower(parent.crm_account_id), '_child_', lower(child.crm_account_id)) AS linkage_id,
  concat('party_', lower(parent.crm_account_id)) AS party_id,
  parent.crm_account_id AS source_account_id,
  'subsidiary' AS relationship_type,
  concat('party_', lower(child.crm_account_id)) AS related_party_id,
  child.crm_account_name AS related_entity_name,
  '' AS related_identifier_type,
  '' AS related_identifier_value,
  CAST(NULL AS DOUBLE) AS ownership_percentage,
  substr(COALESCE(child.crm_billing_country, parent.crm_billing_country, 'ZZ'), 1, 2) AS jurisdiction_country_code,
  CAST(0.72 AS DOUBLE) AS confidence,
  concat('salesforce://Account/', parent.crm_account_id) AS source_url,
  concat('run_', date_format(current_timestamp(), 'yyyyMMdd_HHmmss')) AS run_id,
  'pulse360-sovereign-firmographic-v1.0.0' AS model_version
FROM pulse360_s4.silver_salesforce.crm_account parent
INNER JOIN pulse360_s4.silver_salesforce.crm_account child
  ON child.crm_parent_account_id = parent.crm_account_id
WHERE child.crm_parent_account_id IS NOT NULL;
