CREATE OR REPLACE TABLE pulse360_s4.intelligence.m1_account_hierarchy_activation AS
WITH membership AS (
  SELECT
    group_anchor_source_account_id,
    source_account_id
  FROM (
    SELECT
      parent_source_account_id AS group_anchor_source_account_id,
      parent_source_account_id AS source_account_id
    FROM pulse360_s4.intelligence.m1_account_hierarchy_edge
    UNION
    SELECT
      parent_source_account_id AS group_anchor_source_account_id,
      child_source_account_id AS source_account_id
    FROM pulse360_s4.intelligence.m1_account_hierarchy_edge
  )
  UNION
  SELECT
    a.crm_account_id AS group_anchor_source_account_id,
    a.crm_account_id AS source_account_id
  FROM pulse360_s4.silver_salesforce.crm_account a
  LEFT ANTI JOIN pulse360_s4.intelligence.m1_account_hierarchy_edge e
    ON a.crm_account_id = e.child_source_account_id
    OR a.crm_account_id = e.parent_source_account_id
)
SELECT
  concat('m1act_', lower(m.source_account_id)) AS activation_id,
  m.source_account_id,
  a.crm_account_name AS account_name,
  r.account_group_id,
  r.group_anchor_source_account_id,
  r.group_anchor_name,
  r.member_account_count,
  r.known_child_account_count,
  r.group_revenue_local,
  r.group_revenue_usd,
  r.revenue_coverage_ratio,
  r.hierarchy_completeness_score,
  r.coverage_gap_count,
  r.coverage_gap_flag,
  r.coverage_gap_summary,
  r.confidence,
  r.evidence_refs_json,
  r.run_id,
  r.model_version,
  r.generated_at
FROM membership m
INNER JOIN pulse360_s4.silver_salesforce.crm_account a
  ON m.source_account_id = a.crm_account_id
INNER JOIN pulse360_s4.intelligence.m1_account_group_rollup r
  ON m.group_anchor_source_account_id = r.group_anchor_source_account_id;
