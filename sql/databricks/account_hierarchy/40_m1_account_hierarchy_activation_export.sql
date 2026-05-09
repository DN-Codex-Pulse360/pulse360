CREATE OR REPLACE TABLE pulse360_s4.intelligence.m1_account_hierarchy_activation_export AS
SELECT
  activation_id,
  source_account_id,
  account_name,
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
  evidence_refs_json,
  to_json(
    named_struct(
      'account_group_id', account_group_id,
      'group_anchor_source_account_id', group_anchor_source_account_id,
      'group_anchor_name', group_anchor_name,
      'member_account_count', member_account_count,
      'known_child_account_count', known_child_account_count,
      'coverage_gap_count', coverage_gap_count,
      'coverage_gap_flag', coverage_gap_flag,
      'coverage_gap_summary', coverage_gap_summary,
      'evidence_refs_json', evidence_refs_json
    )
  ) AS hierarchy_payload,
  run_id,
  model_version,
  generated_at
FROM pulse360_s4.intelligence.m1_account_hierarchy_activation;
