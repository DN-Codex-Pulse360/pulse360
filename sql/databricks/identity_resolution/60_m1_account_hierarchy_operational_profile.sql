CREATE OR REPLACE VIEW pulse360_s4.identity_resolution.m1_account_hierarchy_operational_profile AS
WITH rollup AS (
  SELECT *
  FROM pulse360_s4.identity_resolution.entity_hierarchy_rollup
),
anchors AS (
  SELECT
    group_entity_id,
    filter(
      transform(
        from_json(
          hierarchy_payload,
          'STRUCT<group_entity_id:STRING,children:ARRAY<STRUCT<entity_id:STRING,crm_record_id:STRING,relationship_type:STRING,coverage_status:STRING,in_crm:BOOLEAN,confidence:DOUBLE,hierarchy_path:STRING>>>'
        ).children,
        child -> child.crm_record_id
      ),
      crm_record_id -> crm_record_id IS NOT NULL
    ) AS crm_anchor_account_ids
  FROM rollup
)
SELECT
  concat('m1_hierarchy_profile_', r.group_entity_id) AS operational_profile_id,
  r.group_entity_id,
  try_element_at(a.crm_anchor_account_ids, 1) AS primary_anchor_account_id,
  coalesce(a.crm_anchor_account_ids, array()) AS crm_anchor_account_ids,
  concat('pulse360_m1_group:', r.group_entity_id) AS unified_profile_id,
  r.hierarchy_confidence AS identity_confidence,
  r.hierarchy_confidence,
  r.hierarchy_confidence AS validity_score_external,
  r.group_revenue_visible AS group_revenue_rollup,
  r.group_revenue_visible,
  r.known_subsidiary_count AS group_known_subsidiary_count,
  r.crm_covered_subsidiary_count,
  r.uncovered_subsidiary_count AS external_subsidiaries_found,
  r.coverage_gap_flag,
  r.hierarchy_payload,
  to_json(r.source_contributions) AS source_refs,
  r.freshness_status,
  r.run_timestamp AS last_synced_timestamp,
  r.run_id AS enrichment_run_id,
  r.model_version AS model_id,
  concat('m1_profile_run_', date_format(current_timestamp(), 'yyyyMMddHHmmss')) AS run_id,
  current_timestamp() AS run_timestamp,
  'm1-data-cloud-operational-profile-v1' AS model_version
FROM rollup r
LEFT JOIN anchors a
  ON r.group_entity_id = a.group_entity_id;
