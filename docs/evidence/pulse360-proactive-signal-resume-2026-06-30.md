# Pulse360 Proactive Signal Resume - 2026-06-30

## Status

The proactive signal Databricks publish is now live. The blocker recorded on
2026-06-29 was cleared once the SQL warehouse was running again.

## Databricks Live Publish

Command:

```bash
./scripts/publish-databricks-proactive-signal-demo.sh
```

Result:

```text
[OK] Applied sql/databricks/proactive_signal/00_create_schemas.sql via warehouse 7052914888c7e86c
[OK] Applied sql/databricks/proactive_signal/05_northstar_source_change_fixture.sql via warehouse 7052914888c7e86c
[OK] Applied sql/databricks/proactive_signal/10_northstar_proactive_account_signal.sql via warehouse 7052914888c7e86c
[OK] Applied sql/databricks/proactive_signal/20_datacloud_proactive_signal_projection.sql via warehouse 7052914888c7e86c
[OK] Verified proactive projection columns and row count
[OK] Wrote evidence to docs/evidence/pulse360-proactive-signal-databricks-live-check-2026-06-30.json
```

## Live Evidence

- Workspace host: `https://dbc-7f0ce7bb-56ca.cloud.databricks.com`
- Warehouse ID: `7052914888c7e86c`
- Projection: `pulse360_s4.gold_proactive_signal.datacloud_proactive_signal_projection`
- Row count: `1`
- Account: `Northstar Foods Group`
- Source Account ID: `001NST000000001AAA`
- Coverage gap: `true`
- Citation count: `6`

Evidence file:

```text
docs/evidence/pulse360-proactive-signal-databricks-live-check-2026-06-30.json
```

## Remaining Boundary

The Salesforce preview remains fixture-backed and validated. Native Agentforce
runtime remains unproven and must not be claimed until the Agentforce bundle is
validated against the proactive signal context/action contract.

## Next Gate

Decide whether to:

1. connect the live Databricks proactive projection into Data Cloud; or
2. keep it as isolated Databricks proof and move next to Agentforce-specific
   context/action validation.
