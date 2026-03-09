# DAN-58 Governance Analytics Dashboard Evidence

- Issue: `DAN-58`
- Milestone: `B - Databricks Intelligence Layer`
- Current status: `In Progress` (re-opened on `2026-03-09` after live UI review showed dashboard builder/skeleton state)
- Evidence date (UTC): `2026-03-09`
- Branch: `codex/dan-60-61-dashboard-pack`
- Commit: `c4d2d36548f42e2c2bf3d4462b3ed113dd8690e8`

## Scope Delivered
- DS-02 governance analytics is sourced from `pulse360_s4.intelligence.governance_ops_metrics`.
- Dashboard SQL pack and demo-mode SQL pack are present and validated:
  - `dashboards/databricks/s4_use_case_dashboard.sql`
  - `dashboards/databricks/s4_use_case_dashboard_demo_mode.sql`
- Dashboard runbooks are present and validated:
  - `docs/dashboards/databricks-s4-use-case-dashboard.md`
  - `docs/dashboards/databricks-s4-dashboard-demo-mode.md`

## Execution and Runtime Evidence
Command sequence:
1. `./scripts/build-governance-ops-metrics.sh`
2. `./scripts/validate-governance-ops-metrics-runtime.sh`
3. `./scripts/validate-databricks-dashboard-pack.sh`
4. `./scripts/validate-dan-58-governance-dashboard-pack.sh`

Runtime output snapshot:
```text
[PASS] Ensured governance metrics table exists: pulse360_s4.intelligence.governance_ops_metrics
[PASS] Refreshed governance ops metrics (statement_id=01f11b8e-e7d1-1a26-8985-ef2840ff2604)
[PASS] Collected governance summary (statement_id=01f11b8e-f4df-17da-927d-206e63832ac5, rows=1)
[["run_20260309_064746","2026-03-09T08:06:47.165Z","3","1","2","34.0","91.78","33.33","dbx-governance-v1.0.0"]]

[PASS] Table exists: pulse360_s4.intelligence.governance_ops_metrics
[PASS] Governance quality checks passed (rows=1)
[PASS] Metadata checks passed
[PASS] Latest governance metrics query succeeded
[["run_20260309_064746","2026-03-09T08:06:47.165Z","3","1","2","34.0","91.78","33.33"]]

[PASS] Databricks dashboard pack validated
[PASS] Databricks demo-mode dashboard pack validated
[PASS] DAN-58 governance dashboard pack validated
```

## Validator Coverage
- Runtime metrics validator:
  - `scripts/validate-governance-ops-metrics-runtime.sh`
  - checks table existence, quality ranges, case-balance consistency, metadata fields, and latest row query success.
- Dashboard artifact validator:
  - `scripts/validate-databricks-dashboard-pack.sh`
  - checks DS-01/02/03 tokens, source-table references, transition/freshness query tokens, and required guide sections.
- DAN-58 pack validator:
  - `scripts/validate-dan-58-governance-dashboard-pack.sh`
  - checks evidence/HITL artifacts and executes both validators above.

## Acceptance Mapping (DAN-58 / Milestone B)
- Databricks governance analytics dashboard depth completed: `Implemented + validated`.
- DS-02 governance metrics queryable and quality bounded: `Validated by runtime script`.
- Dashboard runbook and demo-mode guidance documented: `Validated by dashboard-pack script`.
- Evidence and script-based proof published in repo: `This document + validator outputs`.

## External Proof Links
- Linear issue: `https://linear.app/danielnortje/issue/DAN-58`
- PR #8: `https://github.com/DN-Codex-Pulse360/pulse360/pull/8`
