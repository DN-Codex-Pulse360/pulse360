# Databricks Dashboard: S4 Use Cases and Transitions

## Purpose
Visualize DS-01, DS-02, DS-03 evidence and transitions from the currently available post-load intelligence tables, including pipeline freshness and ingest-to-hierarchy timing.

## Source Query Pack
- `dashboards/databricks/s4_use_case_dashboard.sql`

## Verified Source Tables (2026-03-09)
- `pulse360_s4.intelligence.crm_accounts_raw`
- `pulse360_s4.intelligence.hierarchy_entity_graph`
- `pulse360_s4.intelligence.governance_ops_metrics`

## Dataset-to-Table Mapping
- DS-01 fragmentation trend: derived from `crm_accounts_raw` (family-key collisions by ingest hour).
- DS-01 duplicate confidence bands: derived heuristic pair candidates from `crm_accounts_raw`.
- DS-02 governance metrics: native `governance_ops_metrics` (`cases_opened`, `cases_resolved`, `backlog_open`, `avg_resolution_minutes`, `quality_score`).
- DS-03 hierarchy readiness: direct from `hierarchy_entity_graph` (entities, roots, child spread, model version).
- Transition timing: `crm_accounts_raw` ingest timestamps aligned to `hierarchy_entity_graph` run timestamps.
- Freshness + KPI cards: combined rollups from both tables.

## High-Signal Widget Layout
1. Trend widgets
- DS-01 fragmentation trend by ingest hour (`fragmentation_signal`, `family_account_count`).
- DS-01 confidence band trend (`confidence_band`, `pair_count`).

2. Transition widgets
- DS-02 governance trend by run/day (`cases_resolved`, `backlog_open`, `avg_resolution_minutes`, `quality_score`).
- Ingest-to-hierarchy transition minutes (`ingest_to_hierarchy_start_minutes`, `ingest_to_hierarchy_complete_minutes`).

3. Freshness widgets
- CRM data age (`crm_data_age_minutes`).
- Hierarchy data age (`hierarchy_data_age_minutes`).
- End-to-end freshness (`end_to_end_freshness_minutes`).

4. DS-03 structure widget
- Hierarchy edges/entities/roots and max children per parent by run.

5. KPI card widgets
- Estimated duplicate pairs.
- Governance resolved/open backlog + quality.
- Hierarchy entities/parents/children.
- Latest hierarchy timestamp.

## Deployment Steps (Databricks SQL)
1. Create a new Lakeview dashboard.
2. Add datasets by pasting each query block from `s4_use_case_dashboard.sql` in order.
3. Build visuals using the layout above.
4. Add filters:
- `run_id` (for DS-02/DS-03/transition datasets)
- date range (`ingest_hour` / `transition_ts` / `run_timestamp`)
5. Save as `Pulse360 S4 - Use Case & Transition Dashboard`.
6. Keep dataset references fully qualified to `pulse360_s4.intelligence.*`.

## Acceptance Mapping
- DS-01 evidence: fragmentation trend + heuristic duplicate confidence bands from CRM ingest records.
- DS-02 evidence: native governance metrics from `governance_ops_metrics`.
- DS-03 evidence: hierarchy readiness metrics for rollup shape (entities, roots, parent-child spread).
- Transition evidence: measured ingest-to-hierarchy latency per run.
- Freshness evidence: current age (minutes) for CRM, hierarchy, and end-to-end path.
