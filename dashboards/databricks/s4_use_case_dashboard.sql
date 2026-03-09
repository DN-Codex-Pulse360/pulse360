-- S4 Databricks Use Case + Transition Dashboard
-- Target: Databricks SQL / Lakeview dashboard datasets
-- Source schema verified post-load: pulse360_s4.intelligence
-- Available base tables:
--   1) pulse360_s4.intelligence.crm_accounts_raw
--   2) pulse360_s4.intelligence.hierarchy_entity_graph
--
-- NOTE: DS-01 and DS-02 datasets are derived from the available tables until
-- dedicated duplicate/governance tables are populated.

-- 1) DS-01: fragmentation trend from CRM ingest (high-signal duplicate proxy)
WITH account_keys AS (
  SELECT
    source_account_id,
    account_name,
    source_system,
    ingest_ts,
    lower(regexp_replace(account_name, '[^a-z0-9 ]', '')) AS account_name_key,
    lower(regexp_extract(account_name, '^([A-Za-z0-9]+)', 1)) AS family_key
  FROM pulse360_s4.intelligence.crm_accounts_raw
),
family_collisions AS (
  SELECT
    date_trunc('hour', ingest_ts) AS ingest_hour,
    family_key,
    COUNT(*) AS family_account_count
  FROM account_keys
  WHERE family_key IS NOT NULL AND family_key <> ''
  GROUP BY 1, 2
)
SELECT
  'DS-01' AS use_case,
  ingest_hour,
  family_key,
  family_account_count,
  CASE
    WHEN family_account_count >= 3 THEN 'high_fragmentation'
    WHEN family_account_count = 2 THEN 'medium_fragmentation'
    ELSE 'low_fragmentation'
  END AS fragmentation_signal
FROM family_collisions
ORDER BY ingest_hour DESC, family_account_count DESC, family_key;

-- 2) DS-01: heuristic duplicate pair candidates with confidence bands
WITH account_keys AS (
  SELECT
    source_account_id,
    account_name,
    source_system,
    ingest_ts,
    lower(regexp_replace(account_name, '[^a-z0-9 ]', '')) AS account_name_key,
    lower(regexp_extract(account_name, '^([A-Za-z0-9]+)', 1)) AS family_key
  FROM pulse360_s4.intelligence.crm_accounts_raw
),
pair_candidates AS (
  SELECT
    date_trunc('hour', greatest(a.ingest_ts, b.ingest_ts)) AS run_hour,
    a.source_account_id AS account_id_left,
    b.source_account_id AS account_id_right,
    a.account_name AS account_name_left,
    b.account_name AS account_name_right,
    CASE
      WHEN a.account_name_key = b.account_name_key THEN 98
      WHEN a.source_system = b.source_system THEN 92
      ELSE 85
    END AS heuristic_confidence
  FROM account_keys a
  JOIN account_keys b
    ON a.source_account_id < b.source_account_id
   AND a.family_key = b.family_key
)
SELECT
  'DS-01' AS use_case,
  run_hour,
  CASE
    WHEN heuristic_confidence >= 95 THEN '95-100'
    WHEN heuristic_confidence >= 90 THEN '90-94'
    WHEN heuristic_confidence >= 80 THEN '80-89'
    ELSE '<80'
  END AS confidence_band,
  COUNT(*) AS pair_count
FROM pair_candidates
GROUP BY 1, 2, 3
ORDER BY run_hour DESC, confidence_band;

-- 3) DS-02: governance transition states (derived from hierarchy pipeline stages)
WITH transitions AS (
  SELECT
    run_id,
    run_timestamp AS transition_ts,
    'candidate_identified' AS transition_state,
    COUNT(*) AS transition_volume
  FROM pulse360_s4.intelligence.hierarchy_entity_graph
  GROUP BY 1, 2

  UNION ALL

  SELECT
    run_id,
    run_timestamp AS transition_ts,
    'hierarchy_linked' AS transition_state,
    COUNT(DISTINCT hierarchy_child_id) AS transition_volume
  FROM pulse360_s4.intelligence.hierarchy_entity_graph
  GROUP BY 1, 2

  UNION ALL

  SELECT
    run_id,
    run_timestamp AS transition_ts,
    'review_ready' AS transition_state,
    COUNT(DISTINCT entity_id) AS transition_volume
  FROM pulse360_s4.intelligence.hierarchy_entity_graph
  GROUP BY 1, 2
)
SELECT
  'DS-02' AS use_case,
  run_id,
  transition_ts,
  transition_state,
  transition_volume,
  SUM(transition_volume) OVER (
    PARTITION BY run_id
    ORDER BY transition_ts, transition_state
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_volume
FROM transitions
ORDER BY transition_ts DESC, run_id, transition_state;

-- 4) DS-03: hierarchy depth/readiness proxy and rollup shape
WITH edges AS (
  SELECT
    run_id,
    run_timestamp,
    entity_id,
    hierarchy_parent_id,
    hierarchy_child_id,
    model_version
  FROM pulse360_s4.intelligence.hierarchy_entity_graph
),
parent_stats AS (
  SELECT
    run_id,
    hierarchy_parent_id,
    COUNT(DISTINCT hierarchy_child_id) AS children_per_parent
  FROM edges
  GROUP BY 1, 2
),
root_candidates AS (
  SELECT DISTINCT run_id, hierarchy_parent_id AS root_entity_id FROM edges
  EXCEPT
  SELECT DISTINCT run_id, hierarchy_child_id AS root_entity_id FROM edges
)
SELECT
  'DS-03' AS use_case,
  e.run_id,
  MAX(e.run_timestamp) AS run_timestamp,
  COUNT(*) AS hierarchy_edge_count,
  COUNT(DISTINCT e.entity_id) AS hierarchy_entity_count,
  COUNT(DISTINCT e.hierarchy_child_id) AS child_entity_count,
  COUNT(DISTINCT r.root_entity_id) AS root_entity_count,
  MAX(ps.children_per_parent) AS max_children_per_parent,
  MAX(e.model_version) AS model_version
FROM edges e
LEFT JOIN parent_stats ps
  ON e.run_id = ps.run_id
 AND e.hierarchy_parent_id = ps.hierarchy_parent_id
LEFT JOIN root_candidates r
  ON e.run_id = r.run_id
GROUP BY 1, 2
ORDER BY run_timestamp DESC;

-- 5) Transition checkpoints: CRM ingest -> hierarchy build
WITH hierarchy_runs AS (
  SELECT
    run_id,
    MIN(run_timestamp) AS hierarchy_started_ts,
    MAX(run_timestamp) AS hierarchy_completed_ts
  FROM pulse360_s4.intelligence.hierarchy_entity_graph
  GROUP BY 1
),
crm_window AS (
  SELECT
    MIN(ingest_ts) AS first_ingest_ts,
    MAX(ingest_ts) AS last_ingest_ts,
    COUNT(*) AS crm_rows
  FROM pulse360_s4.intelligence.crm_accounts_raw
)
SELECT
  r.run_id,
  c.crm_rows,
  c.first_ingest_ts,
  c.last_ingest_ts,
  r.hierarchy_started_ts,
  r.hierarchy_completed_ts,
  TIMESTAMPDIFF(MINUTE, c.last_ingest_ts, r.hierarchy_started_ts) AS ingest_to_hierarchy_start_minutes,
  TIMESTAMPDIFF(MINUTE, c.last_ingest_ts, r.hierarchy_completed_ts) AS ingest_to_hierarchy_complete_minutes
FROM hierarchy_runs r
CROSS JOIN crm_window c
ORDER BY r.hierarchy_completed_ts DESC;

-- 6) Freshness panel dataset (single table output for cards/table)
WITH crm AS (
  SELECT
    COUNT(*) AS crm_row_count,
    MAX(ingest_ts) AS crm_last_ingest_ts
  FROM pulse360_s4.intelligence.crm_accounts_raw
),
hierarchy AS (
  SELECT
    COUNT(*) AS hierarchy_row_count,
    MAX(run_timestamp) AS hierarchy_last_run_ts,
    COUNT(DISTINCT run_id) AS hierarchy_run_count
  FROM pulse360_s4.intelligence.hierarchy_entity_graph
)
SELECT
  crm_row_count,
  hierarchy_row_count,
  hierarchy_run_count,
  crm_last_ingest_ts,
  hierarchy_last_run_ts,
  TIMESTAMPDIFF(MINUTE, crm_last_ingest_ts, current_timestamp()) AS crm_data_age_minutes,
  TIMESTAMPDIFF(MINUTE, hierarchy_last_run_ts, current_timestamp()) AS hierarchy_data_age_minutes,
  TIMESTAMPDIFF(MINUTE, greatest(crm_last_ingest_ts, hierarchy_last_run_ts), current_timestamp()) AS end_to_end_freshness_minutes
FROM crm
CROSS JOIN hierarchy;

-- 7) KPI summary dataset (cards)
WITH account_keys AS (
  SELECT
    source_account_id,
    source_system,
    lower(regexp_replace(account_name, '[^a-z0-9 ]', '')) AS account_name_key,
    lower(regexp_extract(account_name, '^([A-Za-z0-9]+)', 1)) AS family_key,
    ingest_ts
  FROM pulse360_s4.intelligence.crm_accounts_raw
),
dup_pairs AS (
  SELECT COUNT(*) AS estimated_duplicate_pairs
  FROM account_keys a
  JOIN account_keys b
    ON a.source_account_id < b.source_account_id
   AND a.family_key = b.family_key
),
ds01 AS (
  SELECT
    COUNT(DISTINCT family_key) AS fragment_families,
    COUNT(*) AS crm_accounts
  FROM account_keys
),
ds02 AS (
  SELECT
    COUNT(DISTINCT run_id) AS governance_runs,
    COUNT(*) AS governance_transition_events
  FROM (
    SELECT run_id, run_timestamp, 'candidate_identified' AS transition_state FROM pulse360_s4.intelligence.hierarchy_entity_graph
    UNION ALL
    SELECT run_id, run_timestamp, 'hierarchy_linked' AS transition_state FROM pulse360_s4.intelligence.hierarchy_entity_graph
    UNION ALL
    SELECT run_id, run_timestamp, 'review_ready' AS transition_state FROM pulse360_s4.intelligence.hierarchy_entity_graph
  ) t
),
ds03 AS (
  SELECT
    COUNT(DISTINCT entity_id) AS hierarchy_entities,
    COUNT(DISTINCT hierarchy_parent_id) AS hierarchy_parents,
    COUNT(DISTINCT hierarchy_child_id) AS hierarchy_children,
    MAX(run_timestamp) AS latest_hierarchy_ts
  FROM pulse360_s4.intelligence.hierarchy_entity_graph
)
SELECT
  ds01.crm_accounts,
  ds01.fragment_families,
  dup_pairs.estimated_duplicate_pairs,
  ds02.governance_runs,
  ds02.governance_transition_events,
  ds03.hierarchy_entities,
  ds03.hierarchy_parents,
  ds03.hierarchy_children,
  ds03.latest_hierarchy_ts
FROM ds01
CROSS JOIN dup_pairs
CROSS JOIN ds02
CROSS JOIN ds03;
