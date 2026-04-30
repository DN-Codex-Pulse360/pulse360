CREATE OR REPLACE VIEW pulse360_s4.identity_resolution.entity_hierarchy_rollup AS
SELECT
  parent_entity_id AS group_entity_id,
  COUNT(DISTINCT child_entity_id) AS known_subsidiary_count,
  COUNT(DISTINCT CASE WHEN child_in_crm THEN child_entity_id END) AS crm_covered_subsidiary_count,
  COUNT(DISTINCT CASE WHEN NOT child_in_crm THEN child_entity_id END) AS uncovered_subsidiary_count,
  COALESCE(SUM(child_revenue), CAST(0 AS DOUBLE)) AS group_revenue_visible,
  COUNT(DISTINCT CASE WHEN NOT child_in_crm THEN child_entity_id END) > 0 AS coverage_gap_flag,
  AVG(hierarchy_confidence) AS hierarchy_confidence,
  array_sort(collect_set(child_coverage_status)) AS coverage_statuses,
  to_json(
    named_struct(
      'group_entity_id', parent_entity_id,
      'children', collect_list(
        named_struct(
          'entity_id', child_entity_id,
          'crm_record_id', child_account_id,
          'relationship_type', relationship_type,
          'coverage_status', child_coverage_status,
          'in_crm', child_in_crm,
          'confidence', hierarchy_confidence,
          'hierarchy_path', hierarchy_path
        )
      )
    )
  ) AS hierarchy_payload,
  flatten(collect_list(source_contributions)) AS source_contributions,
  CASE
    WHEN SUM(CASE WHEN freshness_status = 'expired' THEN 1 ELSE 0 END) > 0 THEN 'expired'
    WHEN SUM(CASE WHEN freshness_status = 'stale' THEN 1 ELSE 0 END) > 0 THEN 'stale'
    WHEN SUM(CASE WHEN freshness_status = 'fresh' THEN 1 ELSE 0 END) > 0 THEN 'fresh'
    ELSE 'unknown'
  END AS freshness_status,
  concat('hierarchy_rollup_run_', date_format(current_timestamp(), 'yyyyMMddHHmmss')) AS run_id,
  current_timestamp() AS run_timestamp,
  'entity-hierarchy-rollup-v1' AS model_version
FROM pulse360_s4.identity_resolution.entity_hierarchy_edge
GROUP BY parent_entity_id;
