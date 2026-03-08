# Databricks Dashboard: S4 Use Cases and Transitions

## Purpose
Visualize DS-01, DS-02, DS-03 evidence and transitions as executed in Databricks, including activation freshness and cross-use-case timing.

## Source Query Pack
- `dashboards/databricks/s4_use_case_dashboard.sql`

## Recommended Lakeview Layout
1. KPI cards
- duplicate pairs
- avg duplicate confidence
- total governance cases resolved
- avg governance quality
- hierarchy entities + max depth
- latest activation timestamp

2. DS-01 panel
- confidence band distribution over run hour
- chart: stacked bar by `confidence_band`

3. DS-02 panel
- resolved/backlog/quality trend by day
- chart: line + bar combo

4. DS-03 panel
- hierarchy depth and entity counts by run
- chart: bar + line combo

5. Transition panel
- DS-01 -> activation and DS-03 -> activation minutes by run
- chart: line by run_id

6. Activation freshness panel
- last synced timestamp and activated account count by run
- chart: table + time series

## Deployment Steps (Databricks SQL)
1. Create a new Lakeview dashboard.
2. Add datasets by pasting each query block from `s4_use_case_dashboard.sql`.
3. Build visuals per layout above.
4. Add filters:
- `run_id`
- date range (`run_ts`/`metric_ts`)
5. Save as `Pulse360 S4 - Use Case & Transition Dashboard`.
6. Keep dataset references fully qualified to `pulse360_s4.intelligence.*`.

## Table Dependencies
- `pulse360_s4.intelligence.duplicate_candidate_pairs`
- `pulse360_s4.intelligence.governance_ops_metrics`
- `pulse360_s4.intelligence.entity_hierarchy_graph`
- `pulse360_s4.intelligence.datacloud_export_accounts`

## Acceptance Mapping
- DS-01 evidence: duplicate confidence distribution.
- DS-02 evidence: governance resolved/backlog/quality trends.
- DS-03 evidence: hierarchy depth and rollup readiness.
- Transition evidence: run-level timing from use case outputs to activation.
- Last synced evidence: activation freshness dataset for Account 360.
