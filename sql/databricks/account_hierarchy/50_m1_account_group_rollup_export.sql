CREATE OR REPLACE TABLE pulse360_s4.intelligence.m1_account_group_rollup_export AS
SELECT
  account_group_id,
  group_anchor_source_account_id,
  group_anchor_name,
  ultimate_parent_name,
  member_account_count,
  known_child_account_count,
  group_revenue_local,
  group_revenue_usd,
  revenue_coverage_ratio,
  hierarchy_completeness_score,
  coverage_gap_count,
  coverage_gap_flag,
  coverage_gap_summary,
  confidence,
  source_account_ids_json,
  evidence_refs_json,
  run_id,
  model_version,
  generated_at
FROM pulse360_s4.intelligence.m1_account_group_rollup;
