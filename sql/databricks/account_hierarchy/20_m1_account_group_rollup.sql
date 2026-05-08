CREATE OR REPLACE TABLE pulse360_s4.intelligence.m1_account_group_rollup AS
WITH edge AS (
  SELECT *
  FROM pulse360_s4.intelligence.m1_account_hierarchy_edge
),
linked_members AS (
  SELECT
    parent_source_account_id AS group_anchor_source_account_id,
    parent_source_account_id AS source_account_id
  FROM edge
  UNION
  SELECT
    parent_source_account_id AS group_anchor_source_account_id,
    child_source_account_id AS source_account_id
  FROM edge
),
standalone_members AS (
  SELECT
    a.crm_account_id AS group_anchor_source_account_id,
    a.crm_account_id AS source_account_id
  FROM pulse360_s4.silver_salesforce.crm_account a
  LEFT ANTI JOIN linked_members lm
    ON a.crm_account_id = lm.source_account_id
),
group_members AS (
  SELECT * FROM linked_members
  UNION
  SELECT * FROM standalone_members
),
member_profile AS (
  SELECT
    gm.group_anchor_source_account_id,
    gm.source_account_id,
    a.crm_account_name,
    fp.annual_revenue_local,
    fp.annual_revenue_usd,
    fp.confidence AS profile_confidence,
    fp.primary_source_url
  FROM group_members gm
  INNER JOIN pulse360_s4.silver_salesforce.crm_account a
    ON gm.source_account_id = a.crm_account_id
  LEFT JOIN pulse360_s4.intelligence.firmographic_profile_export fp
    ON gm.source_account_id = fp.source_account_id
),
edge_rollup AS (
  SELECT
    parent_source_account_id AS group_anchor_source_account_id,
    COUNT(DISTINCT child_source_account_id) AS known_child_account_count,
    AVG(confidence) AS edge_confidence,
    collect_set(source_url) AS edge_evidence_refs
  FROM edge
  GROUP BY parent_source_account_id
)
SELECT
  concat('agrp_', lower(group_anchor_source_account_id)) AS account_group_id,
  group_anchor_source_account_id,
  MAX(CASE WHEN source_account_id = group_anchor_source_account_id THEN crm_account_name END) AS group_anchor_name,
  MAX(CASE WHEN source_account_id = group_anchor_source_account_id THEN crm_account_name END) AS ultimate_parent_name,
  COUNT(DISTINCT source_account_id) AS member_account_count,
  COALESCE(MAX(er.known_child_account_count), 0) AS known_child_account_count,
  SUM(COALESCE(annual_revenue_local, 0)) AS group_revenue_local,
  SUM(COALESCE(annual_revenue_usd, 0)) AS group_revenue_usd,
  CAST(
    SUM(CASE WHEN annual_revenue_usd IS NOT NULL OR annual_revenue_local IS NOT NULL THEN 1 ELSE 0 END)
    / COUNT(DISTINCT source_account_id)
    AS DOUBLE
  ) AS revenue_coverage_ratio,
  CAST(
    LEAST(
      1.0,
      0.30
      + CASE WHEN COALESCE(MAX(er.known_child_account_count), 0) > 0 THEN 0.25 ELSE 0 END
      + (SUM(CASE WHEN annual_revenue_usd IS NOT NULL OR annual_revenue_local IS NOT NULL THEN 1 ELSE 0 END)
        / COUNT(DISTINCT source_account_id)) * 0.25
      + COALESCE(MAX(er.edge_confidence), AVG(profile_confidence), 0.50) * 0.20
    )
    AS DOUBLE
  ) AS hierarchy_completeness_score,
  SUM(CASE WHEN annual_revenue_usd IS NULL AND annual_revenue_local IS NULL THEN 1 ELSE 0 END) AS coverage_gap_count,
  CASE
    WHEN SUM(CASE WHEN annual_revenue_usd IS NULL AND annual_revenue_local IS NULL THEN 1 ELSE 0 END) > 0 THEN true
    ELSE false
  END AS coverage_gap_flag,
  CASE
    WHEN SUM(CASE WHEN annual_revenue_usd IS NULL AND annual_revenue_local IS NULL THEN 1 ELSE 0 END) > 0
      THEN 'One or more group members lack source-backed revenue evidence.'
    ELSE 'All current group members have revenue evidence in the M1 profile output.'
  END AS coverage_gap_summary,
  CAST(COALESCE(MAX(er.edge_confidence), AVG(profile_confidence), 0.55) AS DOUBLE) AS confidence,
  to_json(collect_set(source_account_id)) AS source_account_ids_json,
  to_json(array_distinct(flatten(collect_list(COALESCE(er.edge_evidence_refs, array(primary_source_url)))))) AS evidence_refs_json,
  concat('run_m1_', date_format(current_timestamp(), 'yyyyMMdd_HHmmss')) AS run_id,
  'pulse360-m1-account-hierarchy-v0.1.0' AS model_version,
  current_timestamp() AS generated_at
FROM member_profile mp
LEFT JOIN edge_rollup er
  ON mp.group_anchor_source_account_id = er.group_anchor_source_account_id
GROUP BY group_anchor_source_account_id;
