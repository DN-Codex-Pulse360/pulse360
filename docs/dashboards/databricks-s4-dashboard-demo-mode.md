# Databricks Dashboard Demo Mode (Single Run)

## Goal
Run a stable, presentation-safe Lakeview dashboard for one fixed pipeline run.

## Files
- `dashboards/databricks/s4_use_case_dashboard_demo_mode.sql`
- `docs/dashboards/databricks-s4-use-case-dashboard.md`

## How To Use
1. Open `s4_use_case_dashboard_demo_mode.sql`.
2. Replace `run_20260308_03` with your chosen demo run ID.
3. In Lakeview, create datasets from each query block in order.
4. Build visuals using the same layout from the main dashboard guide.
5. Keep only one visible filter (optional): `run_id` locked to the chosen value.

## Recommended Defaults
- `run_id`: fixed to one validated run (for example `run_20260308_03`)
- Date range: fixed window that includes only that run day
- Auto-refresh: off during demos (manual refresh only)

## Demo Checklist
- Confirm all six datasets return rows before presentation.
- Confirm transition minutes (`ds01_to_activation_minutes`, `ds03_to_activation_minutes`) are populated.
- Confirm `last_synced_timestamp` matches expected activation evidence.
- Export one screenshot per DS panel as backup evidence.
