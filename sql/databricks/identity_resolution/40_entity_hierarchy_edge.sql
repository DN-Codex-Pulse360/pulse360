CREATE OR REPLACE VIEW pulse360_s4.identity_resolution.entity_hierarchy_edge AS
WITH crm_edges AS (
  SELECT
    concat('edge_crm_', lower(h.parent_account_id), '_', lower(h.child_account_id)) AS hierarchy_edge_id,
    concat('ent_crm_', lower(h.parent_account_id)) AS parent_entity_id,
    concat('ent_crm_', lower(h.child_account_id)) AS child_entity_id,
    h.parent_account_id,
    h.child_account_id,
    'CRM_PARENT_ACCOUNT' AS relationship_type,
    CAST(90 AS DOUBLE) AS hierarchy_confidence,
    true AS parent_in_crm,
    true AS child_in_crm,
    'covered' AS child_coverage_status,
    child.crm_annual_revenue AS child_revenue,
    'crm_account_hierarchy_edge' AS source_name,
    'crm' AS source_type,
    h.hierarchy_path,
    h.hierarchy_depth,
    current_timestamp() AS last_refreshed_at
  FROM pulse360_s4.silver_salesforce.crm_account_hierarchy_edge h
  INNER JOIN pulse360_s4.silver_salesforce.crm_account child
    ON h.child_account_id = child.crm_account_id
  WHERE h.parent_account_id IS NOT NULL
    AND h.child_account_id IS NOT NULL
),
registry_sample_edges AS (
  SELECT
    'edge_registry_ayala_uncovered_operating_entities' AS hierarchy_edge_id,
    concat(
      'ent_',
      lower(country_of_incorporation),
      '_',
      lower(regexp_replace(national_id_type, '[^A-Za-z0-9]+', '_')),
      '_',
      lower(regexp_replace(national_id_value, '[^A-Za-z0-9]+', '_'))
    ) AS parent_entity_id,
    'ent_ph_ayala_uncovered_operating_entities' AS child_entity_id,
    CAST(NULL AS STRING) AS parent_account_id,
    CAST(NULL AS STRING) AS child_account_id,
    'PUBLIC_PORTFOLIO_ENTITY' AS relationship_type,
    CAST(78 AS DOUBLE) AS hierarchy_confidence,
    false AS parent_in_crm,
    false AS child_in_crm,
    'uncovered' AS child_coverage_status,
    CAST(NULL AS DOUBLE) AS child_revenue,
    source_system AS source_name,
    'national_registry' AS source_type,
    concat(normalized_legal_name, ' > UNCOVERED_OPERATING_ENTITIES') AS hierarchy_path,
    1 AS hierarchy_depth,
    last_refreshed_at
  FROM pulse360_s4.identity_resolution.registry_identity_source_sample
)
SELECT
  hierarchy_edge_id,
  parent_entity_id,
  child_entity_id,
  parent_account_id,
  child_account_id,
  relationship_type,
  hierarchy_confidence,
  parent_in_crm,
  child_in_crm,
  child_coverage_status,
  child_revenue,
  array(
    named_struct(
      'source_id', hierarchy_edge_id,
      'source_name', source_name,
      'source_type', source_type,
      'candidate_value', relationship_type,
      'source_weight', CAST(1.0 AS DOUBLE),
      'source_confidence', hierarchy_confidence,
      'last_refreshed_at', last_refreshed_at,
      'citation', named_struct(
        'source_ref_id', hierarchy_edge_id,
        'source_url', CAST(NULL AS STRING),
        'document_date', CAST(NULL AS STRING),
        'accessed_at', current_timestamp(),
        'excerpt', concat('Hierarchy relationship derived from ', source_name, '.')
      ),
      'license_or_contract_reference', CAST(NULL AS STRING)
    )
  ) AS source_contributions,
  hierarchy_path,
  hierarchy_depth,
  CASE
    WHEN last_refreshed_at >= current_timestamp() - INTERVAL 90 DAYS THEN 'fresh'
    WHEN last_refreshed_at >= current_timestamp() - INTERVAL 365 DAYS THEN 'stale'
    ELSE 'unknown'
  END AS freshness_status,
  concat('hierarchy_edge_run_', date_format(current_timestamp(), 'yyyyMMddHHmmss')) AS run_id,
  current_timestamp() AS run_timestamp,
  'entity-hierarchy-v1' AS model_version
FROM crm_edges

UNION ALL

SELECT
  hierarchy_edge_id,
  parent_entity_id,
  child_entity_id,
  parent_account_id,
  child_account_id,
  relationship_type,
  hierarchy_confidence,
  parent_in_crm,
  child_in_crm,
  child_coverage_status,
  child_revenue,
  array(
    named_struct(
      'source_id', hierarchy_edge_id,
      'source_name', source_name,
      'source_type', source_type,
      'candidate_value', relationship_type,
      'source_weight', CAST(1.0 AS DOUBLE),
      'source_confidence', hierarchy_confidence,
      'last_refreshed_at', last_refreshed_at,
      'citation', named_struct(
        'source_ref_id', hierarchy_edge_id,
        'source_url', CAST(NULL AS STRING),
        'document_date', CAST(NULL AS STRING),
        'accessed_at', current_timestamp(),
        'excerpt', concat('Hierarchy relationship derived from ', source_name, '.')
      ),
      'license_or_contract_reference', 'public-registry-sample'
    )
  ) AS source_contributions,
  hierarchy_path,
  hierarchy_depth,
  CASE
    WHEN last_refreshed_at >= current_timestamp() - INTERVAL 90 DAYS THEN 'fresh'
    WHEN last_refreshed_at >= current_timestamp() - INTERVAL 365 DAYS THEN 'stale'
    ELSE 'unknown'
  END AS freshness_status,
  concat('hierarchy_edge_run_', date_format(current_timestamp(), 'yyyyMMddHHmmss')) AS run_id,
  current_timestamp() AS run_timestamp,
  'entity-hierarchy-v1.registry-sample' AS model_version
FROM registry_sample_edges;

