CREATE OR REPLACE TABLE pulse360_s4.intelligence.sovereign_identifier_export AS
WITH account_gpt_firmographic_latest AS (
  SELECT *
  FROM pulse360_s4.gold.account_gpt_firmographic_latest
  WHERE gpt_status = 'schema_valid'
),
gpt_identifiers AS (
  SELECT
    explode(
      from_json(
        identifiers_json,
        'array<struct<identifier_id:string,party_id:string,source_account_id:string,identifier_type:string,identifier_name:string,identifier_value:string,normalized_identifier_value:string,jurisdiction_country_code:string,issuing_authority:string,issued_at_location:string,issued_date:string,expiry_date:string,is_sovereign_identifier:boolean,verification_status:string,confidence:double,source_name:string,source_type:string,source_url:string,evidence_excerpt:string,last_verified_at:string,run_id:string,model_version:string>>'
      )
    ) AS identifier
  FROM account_gpt_firmographic_latest
)
SELECT
  identifier.identifier_id,
  identifier.party_id,
  identifier.source_account_id,
  identifier.identifier_type,
  identifier.identifier_name,
  identifier.identifier_value,
  identifier.normalized_identifier_value,
  identifier.jurisdiction_country_code,
  identifier.issuing_authority,
  identifier.issued_at_location,
  CAST(identifier.issued_date AS DATE) AS issued_date,
  CAST(identifier.expiry_date AS DATE) AS expiry_date,
  identifier.is_sovereign_identifier,
  identifier.verification_status,
  CAST(identifier.confidence AS DOUBLE) AS confidence,
  identifier.source_name,
  identifier.source_type,
  identifier.source_url,
  identifier.evidence_excerpt,
  CAST(identifier.last_verified_at AS TIMESTAMP) AS last_verified_at,
  identifier.run_id,
  identifier.model_version
FROM gpt_identifiers
WHERE identifier.identifier_id IS NOT NULL
  AND identifier.is_sovereign_identifier = true
  AND identifier.identifier_type NOT LIKE 'PROVIDER_%'
  AND identifier.identifier_type NOT LIKE 'CRM_%'
  AND identifier.identifier_type NOT LIKE 'SEARCH_%'
  AND identifier.source_url IS NOT NULL
  AND (
    identifier.verification_status <> 'verified'
    OR (
      identifier.confidence >= 0.90
      AND identifier.source_type IN ('official_registry', 'tax_authority', 'filing')
    )
  );
