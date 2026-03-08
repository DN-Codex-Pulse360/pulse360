-- S4 Databricks Use Case + Transition Dashboard
-- Target: Databricks SQL / Lakeview dashboard datasets
-- Assumes Unity Catalog layout from references/databricks-implementation-patterns.md
-- Recommended source schema: pulse360_s4.intelligence

-- Optional session parameters for Lakeview controls
-- SET use_case = 'ALL';
-- SET run_id_filter = 'LATEST';

-- 1) DS-01 duplicate confidence distribution
SELECT
  'DS-01' AS use_case,
  run_id,
  date_trunc('hour', run_ts) AS run_hour,
  CASE
    WHEN duplicate_confidence_score >= 95 THEN '95-100'
    WHEN duplicate_confidence_score >= 90 THEN '90-94'
    WHEN duplicate_confidence_score >= 80 THEN '80-89'
    ELSE '<80'
  END AS confidence_band,
  COUNT(*) AS pair_count
FROM pulse360_s4.intelligence.duplicate_candidate_pairs
GROUP BY 1,2,3,4;

-- 2) DS-02 governance transition states (resolved, backlog, quality trend)
SELECT
  'DS-02' AS use_case,
  date_trunc('day', metric_ts) AS metric_day,
  SUM(cases_resolved) AS cases_resolved,
  AVG(avg_resolution_minutes) AS avg_resolution_minutes,
  SUM(backlog_open) AS backlog_open,
  AVG(quality_score) AS quality_score
FROM pulse360_s4.intelligence.governance_ops_metrics
GROUP BY 1,2
ORDER BY metric_day;

-- 3) DS-03 hierarchy depth + rollup readiness
SELECT
  'DS-03' AS use_case,
  run_id,
  MAX(hierarchy_depth) AS max_hierarchy_depth,
  COUNT(DISTINCT entity_id) AS entity_count,
  COUNT(DISTINCT parent_entity_id) AS parent_count,
  AVG(validity_score) AS avg_validity_score
FROM pulse360_s4.intelligence.entity_hierarchy_graph
GROUP BY 1,2;

-- 4) Cross-use-case transition checkpoints by run
-- Assumes run metadata is persisted across gold tables.
WITH ds01 AS (
  SELECT run_id, MIN(run_ts) AS ds01_ts
  FROM pulse360_s4.intelligence.duplicate_candidate_pairs
  GROUP BY run_id
),
ds02 AS (
  SELECT run_id, MIN(metric_ts) AS ds02_ts
  FROM pulse360_s4.intelligence.governance_ops_metrics
  GROUP BY run_id
),
ds03 AS (
  SELECT run_id, MIN(run_ts) AS ds03_ts
  FROM pulse360_s4.intelligence.entity_hierarchy_graph
  GROUP BY run_id
),
activation AS (
  SELECT run_id, MIN(run_ts) AS activation_ts
  FROM pulse360_s4.intelligence.datacloud_export_accounts
  GROUP BY run_id
)
SELECT
  COALESCE(ds01.run_id, ds02.run_id, ds03.run_id, activation.run_id) AS run_id,
  ds01.ds01_ts,
  ds02.ds02_ts,
  ds03.ds03_ts,
  activation.activation_ts,
  TIMESTAMPDIFF(MINUTE, ds01.ds01_ts, activation.activation_ts) AS ds01_to_activation_minutes,
  TIMESTAMPDIFF(MINUTE, ds03.ds03_ts, activation.activation_ts) AS ds03_to_activation_minutes
FROM ds01
FULL OUTER JOIN ds02 ON ds01.run_id = ds02.run_id
FULL OUTER JOIN ds03 ON COALESCE(ds01.run_id, ds02.run_id) = ds03.run_id
FULL OUTER JOIN activation ON COALESCE(ds01.run_id, ds02.run_id, ds03.run_id) = activation.run_id
ORDER BY run_id DESC;

-- 5) Activation freshness for Account 360 (last synced evidence)
SELECT
  run_id,
  MAX(run_ts) AS last_synced_timestamp,
  COUNT(*) AS activated_account_count
FROM pulse360_s4.intelligence.datacloud_export_accounts
GROUP BY run_id
ORDER BY last_synced_timestamp DESC;

-- 6) Use-case KPI summary card dataset
WITH d1 AS (
  SELECT
    COUNT(*) AS duplicate_pairs,
    AVG(duplicate_confidence_score) AS avg_duplicate_confidence
  FROM pulse360_s4.intelligence.duplicate_candidate_pairs
),
d2 AS (
  SELECT
    SUM(cases_resolved) AS total_cases_resolved,
    AVG(quality_score) AS avg_governance_quality
  FROM pulse360_s4.intelligence.governance_ops_metrics
),
d3 AS (
  SELECT
    COUNT(DISTINCT entity_id) AS hierarchy_entities,
    MAX(hierarchy_depth) AS hierarchy_depth_max
  FROM pulse360_s4.intelligence.entity_hierarchy_graph
),
act AS (
  SELECT
    COUNT(*) AS activated_accounts,
    MAX(run_ts) AS latest_activation_ts
  FROM pulse360_s4.intelligence.datacloud_export_accounts
)
SELECT
  duplicate_pairs,
  avg_duplicate_confidence,
  total_cases_resolved,
  avg_governance_quality,
  hierarchy_entities,
  hierarchy_depth_max,
  activated_accounts,
  latest_activation_ts
FROM d1 CROSS JOIN d2 CROSS JOIN d3 CROSS JOIN act;
