-- S4 Databricks Use Case + Transition Dashboard (Demo Mode)
-- Lakeview pre-filtered version for a single deterministic run_id
-- Recommended source schema: pulse360_s4.intelligence

-- Set this before building datasets:
-- Replace run_20260308_03 with the run you want to demo.
WITH run_scope AS (
  SELECT 'run_20260308_03' AS demo_run_id
)
SELECT
  'DS-01' AS use_case,
  d.run_id,
  date_trunc('hour', d.run_ts) AS run_hour,
  CASE
    WHEN d.duplicate_confidence_score >= 95 THEN '95-100'
    WHEN d.duplicate_confidence_score >= 90 THEN '90-94'
    WHEN d.duplicate_confidence_score >= 80 THEN '80-89'
    ELSE '<80'
  END AS confidence_band,
  COUNT(*) AS pair_count
FROM pulse360_s4.intelligence.duplicate_candidate_pairs d
JOIN run_scope r ON d.run_id = r.demo_run_id
GROUP BY 1,2,3,4;

WITH run_scope AS (
  SELECT 'run_20260308_03' AS demo_run_id
)
SELECT
  'DS-02' AS use_case,
  date_trunc('day', g.metric_ts) AS metric_day,
  SUM(g.cases_resolved) AS cases_resolved,
  AVG(g.avg_resolution_minutes) AS avg_resolution_minutes,
  SUM(g.backlog_open) AS backlog_open,
  AVG(g.quality_score) AS quality_score
FROM pulse360_s4.intelligence.governance_ops_metrics g
JOIN run_scope r ON g.run_id = r.demo_run_id
GROUP BY 1,2
ORDER BY metric_day;

WITH run_scope AS (
  SELECT 'run_20260308_03' AS demo_run_id
)
SELECT
  'DS-03' AS use_case,
  h.run_id,
  MAX(h.hierarchy_depth) AS max_hierarchy_depth,
  COUNT(DISTINCT h.entity_id) AS entity_count,
  COUNT(DISTINCT h.parent_entity_id) AS parent_count,
  AVG(h.validity_score) AS avg_validity_score
FROM pulse360_s4.intelligence.entity_hierarchy_graph h
JOIN run_scope r ON h.run_id = r.demo_run_id
GROUP BY 1,2;

WITH run_scope AS (
  SELECT 'run_20260308_03' AS demo_run_id
),
ds01 AS (
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
JOIN run_scope r ON COALESCE(ds01.run_id, ds02.run_id, ds03.run_id, activation.run_id) = r.demo_run_id;

WITH run_scope AS (
  SELECT 'run_20260308_03' AS demo_run_id
)
SELECT
  a.run_id,
  MAX(a.run_ts) AS last_synced_timestamp,
  COUNT(*) AS activated_account_count
FROM pulse360_s4.intelligence.datacloud_export_accounts a
JOIN run_scope r ON a.run_id = r.demo_run_id
GROUP BY a.run_id;

WITH run_scope AS (
  SELECT 'run_20260308_03' AS demo_run_id
),
d1 AS (
  SELECT
    COUNT(*) AS duplicate_pairs,
    AVG(duplicate_confidence_score) AS avg_duplicate_confidence
  FROM pulse360_s4.intelligence.duplicate_candidate_pairs d
  JOIN run_scope r ON d.run_id = r.demo_run_id
),
d2 AS (
  SELECT
    SUM(cases_resolved) AS total_cases_resolved,
    AVG(quality_score) AS avg_governance_quality
  FROM pulse360_s4.intelligence.governance_ops_metrics g
  JOIN run_scope r ON g.run_id = r.demo_run_id
),
d3 AS (
  SELECT
    COUNT(DISTINCT entity_id) AS hierarchy_entities,
    MAX(hierarchy_depth) AS hierarchy_depth_max
  FROM pulse360_s4.intelligence.entity_hierarchy_graph h
  JOIN run_scope r ON h.run_id = r.demo_run_id
),
act AS (
  SELECT
    COUNT(*) AS activated_accounts,
    MAX(run_ts) AS latest_activation_ts
  FROM pulse360_s4.intelligence.datacloud_export_accounts a
  JOIN run_scope r ON a.run_id = r.demo_run_id
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
