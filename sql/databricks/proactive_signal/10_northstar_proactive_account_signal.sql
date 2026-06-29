CREATE OR REPLACE VIEW pulse360_s4.silver_proactive_signal.northstar_proactive_account_signal AS
WITH source_events AS (
  SELECT *
  FROM pulse360_s4.bronze_proactive_signal.northstar_source_change_fixture
  WHERE synthetic_flag = true
    AND group_entity_id = 'grp_northstar_foods'
),
evidence AS (
  SELECT
    any_value(fixture_id) AS fixture_id,
    any_value(customer_name) AS customer_name,
    any_value(customer_industry) AS customer_industry,
    any_value(customer_region) AS customer_region,
    group_entity_id,
    any_value(group_name) AS group_name,
    any_value(country_scope) AS country_scope,
    any_value(crm_anchor_status) AS crm_anchor_status,
    any_value(simulation_run_id) AS simulation_run_id,
    array_sort(collect_set(source_event_id)) AS trigger_source_events,
    array_sort(collect_set(source_family)) AS supporting_source_families,
    COUNT(*) AS source_event_count,
    MAX(event_timestamp) AS latest_source_event_timestamp,
    flatten(collect_list(source_refs)) AS source_refs
  FROM source_events
  GROUP BY group_entity_id
)
SELECT
  'sig_maintenance_coverage_gap_northstar_20260629' AS signal_id,
  true AS synthetic_flag,
  customer_name,
  customer_industry,
  customer_region,
  group_entity_id,
  group_name,
  country_scope,
  crm_anchor_status,
  '001NST000000001AAA' AS source_account_id,
  group_name AS account_name,
  'maintenance_coverage_gap' AS signal_type,
  'cross_source_coverage_gap' AS source_event_type,
  'high' AS priority,
  CAST(0.82 AS DOUBLE) AS confidence_score,
  concat(
    'A new Indonesia installed-base signal, warranty expiry in 45 days, missing service entitlement, ',
    'rising Thailand spare-parts demand, duplicate subsidiary risk, and Philippines service-case growth ',
    'now point to the same group-level maintenance coverage gap.'
  ) AS why_now,
  trigger_source_events,
  to_json(named_struct(
    'source_event_count', CAST(source_event_count AS BIGINT),
    'supporting_source_families', supporting_source_families,
    'conflicting_evidence_present', false,
    'freshness_window_days', 1,
    'latest_source_event_timestamp', CAST(latest_source_event_timestamp AS STRING)
  )) AS evidence_summary,
  to_json(named_struct(
    'routing_version', 'pulse360-proactive-signal-routing-v1',
    'signal_score', CAST(88 AS DOUBLE),
    'signal_label', 'Coverage-led review',
    'threshold_label', 'Coverage gap, warranty urgency, and cross-source service demand crossed the routed-review threshold.',
    'route_to', 'account_owner_plus_coverage',
    'routing_confidence', CAST(0.82 AS DOUBLE),
    'signal_type', 'maintenance_coverage_gap',
    'priority', 'high',
    'hero_group', group_entity_id,
    'why_now', 'Cross-source evidence shows an actionable preventive-maintenance coverage gap before warranty expiry.',
    'drafted_outreach', 'Pulse360 flagged Northstar Foods Group because installed equipment, warranty expiry, missing maintenance coverage, and regional service demand now point to a preventive-maintenance motion. Lead with service continuity and confirm the Indonesia plant owner path.',
    'recommended_next_step', 'Route a service-specialist review and prepare an approved seller task for the CRM account team.',
    'channel_readiness', 'salesforce_preview',
    'top_drivers', array(
      'Warranty expiry creates a near-term reason to engage.',
      'No active maintenance contract is visible for the Indonesia plant account or known subsidiaries.',
      'Thailand spare-parts demand and Philippines case growth corroborate a regional service opportunity.'
    ),
    'generated_at', '2026-06-29T03:00:00Z'
  )) AS intent_signal_payload,
  true AS coverage_gap_flag,
  concat(
    group_name,
    ' is showing a proactive maintenance coverage gap across ASEAN operations. The signal is based on synthetic installed-base, ',
    'warranty, contract, partner-spares, CRM hierarchy, and service-case evidence. This is ready for seller review, ',
    'but any opportunity creation or hierarchy writeback should require approval.'
  ) AS ai_narrative,
  to_json(array(
    named_struct(
      'rank', 1,
      'action_type', 'route_specialist',
      'target', 'Northstar Foods Group service coverage review',
      'target_record_id', '001NST000000001AAA',
      'reasoning', 'The signal is supported by six current source-change events and can be reviewed without writing to CRM.',
      'confidence', CAST(0.82 AS DOUBLE),
      'approval_required', false
    ),
    named_struct(
      'rank', 2,
      'action_type', 'create_opportunity',
      'target', 'Northstar Foods preventive maintenance proposal',
      'target_record_id', '001NST000000001AAA',
      'reasoning', 'A commercial action is plausible, but opportunity creation is a high-impact CRM action and needs approval.',
      'confidence', CAST(0.72 AS DOUBLE),
      'approval_required', true
    )
  )) AS ai_recommended_actions,
  source_refs,
  to_json(named_struct(
    'native_runtime_verified', false,
    'fallback_surface', 'custom Salesforce LWC/Apex assistant and action panels',
    'approval_policy_enforced', true,
    'recommended_actions', array(
      named_struct(
        'rank', 1,
        'action_type', 'route_specialist',
        'target_record_id', '001NST000000001AAA',
        'approval_required', false,
        'reason', 'Routing a specialist review is low impact and does not mutate account hierarchy or commercial records.'
      ),
      named_struct(
        'rank', 2,
        'action_type', 'create_task',
        'target_record_id', '001NST000000001AAA',
        'approval_required', false,
        'reason', 'A seller follow-up task is allowed when the action preserves citations and account context.'
      ),
      named_struct(
        'rank', 3,
        'action_type', 'create_opportunity',
        'target_record_id', '001NST000000001AAA',
        'approval_required', true,
        'reason', 'Opportunity creation is a high-impact CRM action and must be approved before execution.'
      ),
      named_struct(
        'rank', 4,
        'action_type', 'update_account_hierarchy',
        'target_record_id', '001NST000000001AAA',
        'approval_required', true,
        'reason', 'Hierarchy updates require stewardship review because one subsidiary is flagged as a duplicate candidate.'
      )
    )
  )) AS agentforce_execution_policy,
  0 AS unsupported_claim_count,
  simulation_run_id AS run_id,
  timestamp('2026-06-29T03:00:00Z') AS run_timestamp,
  timestamp('2026-06-29T03:00:00Z') AS run_ts,
  'proactive-account-signal-v1' AS model_version
FROM evidence;
