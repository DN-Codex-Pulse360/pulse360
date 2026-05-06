CREATE OR REPLACE TABLE pulse360_s4.intelligence.corporate_linkage_export AS
WITH account_gpt_firmographic_latest AS (
  SELECT *
  FROM pulse360_s4.gold.account_gpt_firmographic_latest
  WHERE gpt_status = 'schema_valid'
),
gpt_linkages AS (
  SELECT
    latest.source_account_id,
    latest.party_id,
    latest.run_id,
    latest.model_version,
    posexplode(
      from_json(
        corporate_linkages_json,
        'array<struct<relationship_type:string,related_entity_name:string,related_identifier_type:string,related_identifier_value:string,ownership_percentage:double,jurisdiction_country_code:string,confidence:double,source_url:string>>'
      )
    ) AS (position, linkage)
  FROM account_gpt_firmographic_latest latest
),
gpt_linkage_counts AS (
  SELECT source_account_id, COUNT(*) AS linkage_count
  FROM gpt_linkages
  GROUP BY source_account_id
)
SELECT
  concat('link_', lower(source_account_id), '_gpt_', CAST(position AS STRING), '_', lower(regexp_replace(linkage.relationship_type, '[^A-Za-z0-9]+', '_'))) AS linkage_id,
  party_id,
  source_account_id,
  linkage.relationship_type AS relationship_type,
  '' AS related_party_id,
  linkage.related_entity_name AS related_entity_name,
  COALESCE(linkage.related_identifier_type, '') AS related_identifier_type,
  COALESCE(linkage.related_identifier_value, '') AS related_identifier_value,
  CAST(linkage.ownership_percentage AS DOUBLE) AS ownership_percentage,
  linkage.jurisdiction_country_code AS jurisdiction_country_code,
  CAST(linkage.confidence AS DOUBLE) AS confidence,
  linkage.source_url AS source_url,
  run_id,
  model_version
FROM gpt_linkages
WHERE linkage.related_entity_name IS NOT NULL
  AND linkage.source_url IS NOT NULL

UNION ALL

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
  b.run_id,
  'pulse360-sovereign-firmographic-v1.0.0' AS model_version
FROM pulse360_s4.silver_salesforce.crm_account child
INNER JOIN pulse360_s4.silver_salesforce.crm_account parent
  ON child.crm_parent_account_id = parent.crm_account_id
LEFT JOIN gpt_linkage_counts g
  ON child.crm_account_id = g.source_account_id
LEFT JOIN pulse360_s4.gold.account_export_base b
  ON child.crm_account_id = b.source_account_id
WHERE child.crm_parent_account_id IS NOT NULL
  AND COALESCE(g.linkage_count, 0) = 0

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
  b.run_id,
  'pulse360-sovereign-firmographic-v1.0.0' AS model_version
FROM pulse360_s4.silver_salesforce.crm_account parent
INNER JOIN pulse360_s4.silver_salesforce.crm_account child
  ON child.crm_parent_account_id = parent.crm_account_id
LEFT JOIN gpt_linkage_counts g
  ON parent.crm_account_id = g.source_account_id
LEFT JOIN pulse360_s4.gold.account_export_base b
  ON parent.crm_account_id = b.source_account_id
WHERE child.crm_parent_account_id IS NOT NULL
  AND COALESCE(g.linkage_count, 0) = 0;
