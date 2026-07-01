# Pulse360 Proactive Signal Databricks Live Check - 2026-06-29

## Result

Blocked by Databricks Community Edition daily credit exhaustion.

## Attempted Command

```bash
./scripts/publish-databricks-proactive-signal-demo.sh
```

## Target Warehouse

- Workspace: `dbc-7f0ce7bb-56ca.cloud.databricks.com`
- Warehouse ID: `7052914888c7e86c`
- Warehouse state before execution: `STOPPED`

## Blocker

Databricks refused to start the SQL warehouse:

```text
Unable to start Databricks warehouse 7052914888c7e86c: Sorry, cannot run the resource because you have hit your free daily limit. Please come back again tomorrow. (COMMUNITY_EDITION_CREDIT_EXHAUSTED)
```

## What Passed Before The Block

- `PULSE360_DATABRICKS_PUBLISH_DRY_RUN=1 ./scripts/publish-databricks-proactive-signal-demo.sh`
- `bash -n ./scripts/publish-databricks-proactive-signal-demo.sh`
- `bash -n ./scripts/validate-proactive-signal-demo.sh`
- `./scripts/validate-proactive-signal-demo.sh`

## Next Action

Re-run the publisher after the Databricks Community Edition daily quota resets,
or move the SQL pack to a paid/dev workspace with available serverless SQL
capacity.
