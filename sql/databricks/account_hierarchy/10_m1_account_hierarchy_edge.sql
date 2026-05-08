CREATE OR REPLACE TABLE pulse360_s4.intelligence.m1_account_hierarchy_edge AS
WITH linkage_edges AS (
  SELECT
    source_account_id,
    CASE
      WHEN lower(relationship_type) = 'parent' THEN regexp_replace(related_party_id, '^party_', '')
      ELSE source_account_id
    END AS parent_source_account_id_hint,
    CASE
      WHEN lower(relationship_type) = 'parent' THEN source_account_id
      ELSE regexp_replace(related_party_id, '^party_', '')
    END AS child_source_account_id_hint,
    relationship_type,
    relationship_type AS raw_relationship_type,
    party_id,
    related_party_id,
    related_entity_name,
    confidence,
    source_url,
    run_id,
    model_version
  FROM pulse360_s4.intelligence.corporate_linkage_export
  WHERE lower(relationship_type) IN ('parent', 'subsidiary')
),
account_resolved AS (
  SELECT
    l.*,
    parent.crm_account_id AS parent_source_account_id,
    child.crm_account_id AS child_source_account_id,
    parent.crm_account_name AS parent_name,
    child.crm_account_name AS child_name
  FROM linkage_edges l
  LEFT JOIN pulse360_s4.silver_salesforce.crm_account parent
    ON lower(parent.crm_account_id) = lower(l.parent_source_account_id_hint)
  LEFT JOIN pulse360_s4.silver_salesforce.crm_account child
    ON lower(child.crm_account_id) = lower(l.child_source_account_id_hint)
)
SELECT
  concat(
    'm1edge_',
    md5(concat_ws('||', parent_source_account_id, child_source_account_id, lower(raw_relationship_type)))
  ) AS hierarchy_edge_id,
  child_source_account_id AS source_account_id,
  parent_source_account_id,
  child_source_account_id,
  concat('party_', lower(parent_source_account_id)) AS parent_party_id,
  concat('party_', lower(child_source_account_id)) AS child_party_id,
  parent_name,
  child_name,
  'subsidiary' AS relationship_type,
  CASE
    WHEN source_url LIKE 'salesforce://%' THEN 'crm_parent_account'
    WHEN lower(source_url) RLIKE 'registry|register|sec|acra|companieshouse|filing' THEN 'official_registry'
    WHEN source_url IS NOT NULL AND trim(source_url) <> '' THEN 'gpt_source_bound'
    ELSE 'manual_review'
  END AS relationship_basis,
  CAST(1 AS INT) AS hierarchy_level,
  CAST(COALESCE(confidence, 0.50) AS DOUBLE) AS confidence,
  COALESCE(source_url, concat('salesforce://Account/', child_source_account_id)) AS source_url,
  CAST(NULL AS STRING) AS evidence_id,
  CASE
    WHEN source_url LIKE 'salesforce://%' THEN 'CRM parent-child account relationship accepted as prototype hierarchy evidence.'
    ELSE concat('Source-bound corporate linkage evidence: ', COALESCE(related_entity_name, parent_name))
  END AS evidence_summary,
  to_json(array(
    'pulse360_s4.silver_salesforce.crm_account',
    'pulse360_s4.intelligence.corporate_linkage_export'
  )) AS lineage_refs_json,
  COALESCE(run_id, concat('run_m1_', date_format(current_timestamp(), 'yyyyMMdd_HHmmss'))) AS run_id,
  COALESCE(model_version, 'pulse360-m1-account-hierarchy-v0.1.0') AS model_version,
  current_timestamp() AS generated_at
FROM account_resolved
WHERE parent_source_account_id IS NOT NULL
  AND child_source_account_id IS NOT NULL
  AND parent_source_account_id <> child_source_account_id;
