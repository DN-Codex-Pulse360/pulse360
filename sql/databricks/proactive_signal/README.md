# Pulse360 Proactive Signal Databricks Pack

This pack turns the Northstar Foods Group proactive-signal fixture into a
Databricks-shaped demo data product. It is intentionally separate from the main
`pulse360_s4.intelligence.datacloud_export_accounts` table until the live
workspace path is explicitly approved.

## Views

1. `pulse360_s4.bronze_proactive_signal.northstar_source_change_fixture`
   captures synthetic source-change events across telemetry, service, ERP,
   partner, and CRM systems.
2. `pulse360_s4.silver_proactive_signal.northstar_proactive_account_signal`
   groups those events into one `maintenance_coverage_gap` signal with source
   references, confidence, and an Agentforce execution policy.
3. `pulse360_s4.gold_proactive_signal.datacloud_proactive_signal_projection`
   projects the signal into the same Data Cloud account-intelligence field
   family used by `datacloud_export_accounts`: `intent_signal_payload`,
   `coverage_gap_flag`, `ai_narrative`, `ai_recommended_actions`,
   `source_refs`, `last_synced_timestamp`, `run_id`, and `model_version`.

## Run Order

```sql
-- 1
-- sql/databricks/proactive_signal/00_create_schemas.sql
-- 2
-- sql/databricks/proactive_signal/05_northstar_source_change_fixture.sql
-- 3
-- sql/databricks/proactive_signal/10_northstar_proactive_account_signal.sql
-- 4
-- sql/databricks/proactive_signal/20_datacloud_proactive_signal_projection.sql
```

## Demo Boundary

The pack is synthetic and demo-safe. It preserves `native_runtime_verified =
false` and keeps high-impact CRM actions such as opportunity creation and
hierarchy writeback behind approval.
