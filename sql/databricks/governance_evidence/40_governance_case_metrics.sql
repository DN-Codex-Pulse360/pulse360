CREATE OR REPLACE VIEW pulse360_s4.intelligence.governance_case_metrics AS
WITH cases AS (
  SELECT
    crm_governance_case_id,
    crm_governance_case_name,
    lower(coalesce(decision_status, '')) AS decision_status_key,
    lower(coalesce(recommended_action, '')) AS recommended_action_key,
    lower(coalesce(merge_execution_status, '')) AS merge_execution_status_key,
    lower(coalesce(downstream_update_status, '')) AS downstream_update_status_key,
    duplicate_confidence,
    confidence_band,
    review_flag,
    review_followup_required,
    decided_at,
    crm_system_modstamp,
    source_system
  FROM pulse360_s4.silver_salesforce.crm_governance_case
),
metrics AS (
  SELECT
    COUNT(*) AS total_governance_cases,
    COUNT_IF(decision_status_key IN ('approved', 'rejected', 'deferred')) AS resolved_decision_count,
    COUNT_IF(decision_status_key NOT IN ('approved', 'rejected', 'deferred')) AS pending_decision_count,
    COUNT_IF(decision_status_key = 'approved') AS approved_count,
    COUNT_IF(decision_status_key = 'rejected') AS rejected_count,
    COUNT_IF(decision_status_key = 'deferred') AS deferred_count,
    COUNT_IF(recommended_action_key = 'approve merge') AS recommended_merge_count,
    COUNT_IF(merge_execution_status_key = 'ready for merge') AS ready_for_merge_count,
    COUNT_IF(merge_execution_status_key IN ('merged', 'completed')) AS merge_completed_count,
    COUNT_IF(downstream_update_status_key = 'queued') AS downstream_update_queued_count,
    COUNT_IF(coalesce(review_followup_required, false)) AS review_followup_required_count,
    COUNT_IF(coalesce(review_flag, false)) AS review_flagged_count,
    COUNT_IF(duplicate_confidence >= 90) AS high_confidence_case_count,
    AVG(duplicate_confidence) AS average_duplicate_confidence,
    MAX(decided_at) AS latest_decision_at,
    MAX(crm_system_modstamp) AS latest_crm_system_modstamp,
    COUNT(DISTINCT source_system) AS source_system_count
  FROM cases
)
SELECT
  'governance_case_feedback_all_time' AS metric_id,
  'all_time' AS metric_grain,
  total_governance_cases,
  resolved_decision_count,
  pending_decision_count,
  approved_count,
  rejected_count,
  deferred_count,
  recommended_merge_count,
  ready_for_merge_count,
  merge_completed_count,
  downstream_update_queued_count,
  review_followup_required_count,
  review_flagged_count,
  high_confidence_case_count,
  CAST(average_duplicate_confidence AS DOUBLE) AS average_duplicate_confidence,
  latest_decision_at,
  latest_crm_system_modstamp,
  CASE
    WHEN source_system_count = 1 THEN 'source_bound'
    WHEN total_governance_cases = 0 THEN 'no_source_rows'
    ELSE 'mixed_source_systems'
  END AS lineage_status,
  concat('governance_case_metrics_run_', date_format(current_timestamp(), 'yyyyMMddHHmmss')) AS run_id,
  current_timestamp() AS run_timestamp,
  'governance-case-feedback-metrics-v1' AS model_version
FROM metrics;
