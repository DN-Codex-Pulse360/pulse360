CREATE OR REPLACE TABLE pulse360_s4.intelligence.company_classification_export AS
WITH account_gpt_firmographic_latest AS (
  SELECT *
  FROM pulse360_s4.gold.account_gpt_firmographic_latest
  WHERE gpt_status = 'schema_valid'
),
gpt_classifications AS (
  SELECT
    latest.source_account_id,
    latest.party_id,
    latest.run_id,
    latest.model_version,
    posexplode(
      from_json(
        classifications_json,
        'array<struct<scheme:string,code:string,description:string,is_primary:boolean,confidence:double,source_url:string>>'
      )
    ) AS (position, classification)
  FROM account_gpt_firmographic_latest latest
),
gpt_classification_counts AS (
  SELECT source_account_id, COUNT(*) AS classification_count
  FROM gpt_classifications
  GROUP BY source_account_id
)
SELECT
  concat('class_', lower(source_account_id), '_gpt_', CAST(position AS STRING), '_', lower(regexp_replace(classification.code, '[^A-Za-z0-9]+', '_'))) AS classification_id,
  party_id,
  source_account_id,
  classification.scheme AS scheme,
  classification.code AS code,
  classification.description AS description,
  classification.is_primary AS is_primary,
  CAST(classification.confidence AS DOUBLE) AS confidence,
  classification.source_url AS source_url,
  run_id,
  model_version
FROM gpt_classifications
WHERE classification.code IS NOT NULL
  AND classification.source_url IS NOT NULL

UNION ALL

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
LEFT JOIN gpt_classification_counts g
  ON a.crm_account_id = g.source_account_id
LEFT JOIN pulse360_s4.gold.account_export_base b
  ON a.crm_account_id = b.source_account_id
WHERE a.crm_industry IS NOT NULL
  AND COALESCE(g.classification_count, 0) = 0;
