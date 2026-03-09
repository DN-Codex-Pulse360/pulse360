# Databricks Dashboard Demo Mode (Single Run)

## Goal
Run a stable, presentation-safe Lakeview dashboard for one fixed hierarchy run while keeping DS-01/DS-02/DS-03 evidence consistent with post-load tables.

## Files
- `dashboards/databricks/s4_use_case_dashboard_demo_mode.sql`
- `docs/dashboards/databricks-s4-use-case-dashboard.md`

## How To Use
1. Open `s4_use_case_dashboard_demo_mode.sql`.
2. Replace `run_20260308_03` with your chosen demo run ID from `hierarchy_entity_graph`.
3. In Lakeview, create datasets from each query block in order.
4. Build visuals using the high-signal layout from the main dashboard guide.
5. Keep only one visible filter (optional): `run_id` locked to the chosen value.

## Recommended Defaults
- `run_id`: fixed to one validated run (for example `run_20260308_03`)
- Date range: fixed window that includes that run's ingest and hierarchy timestamps
- Auto-refresh: off during demos (manual refresh only)

## Demo Checklist
- Confirm all seven datasets return rows before presentation.
- Confirm DS-02 transition states (`candidate_identified`, `hierarchy_linked`, `review_ready`) are present.
- Confirm transition minutes (`ingest_to_hierarchy_start_minutes`, `ingest_to_hierarchy_complete_minutes`) are populated.
- Confirm freshness values (`crm_data_age_minutes`, `hierarchy_data_age_minutes`, `end_to_end_freshness_minutes`) are populated.
- Export one screenshot per DS panel as backup evidence.
