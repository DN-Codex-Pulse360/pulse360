---
name: databricks-s4-solution-builder
description: Design and delivery workflow for Databricks solutions that power the S4 Account Intelligence & Data Foundation prototype (duplicate detection, hierarchy stitching, firmographic enrichment, lineage, and governance dashboards) with downstream Salesforce Data Cloud activation. Use when building, refining, demoing, or troubleshooting the Databricks layer for S4 DS-01/DS-02/DS-03 scenarios.
---

# Databricks S4 Solution Builder

## Overview
Design, build, and operationalize the Databricks intelligence layer that feeds Salesforce Data Cloud and Agentforce for the S4 prototype. Keep the build demo-safe: pre-computed outputs, visible lineage, and explicit handoff contracts.

## Workflow

### 1. Confirm scope and scenario coverage
1. Confirm which scenario(s) are in scope: `DS-01`, `DS-02`, `DS-03`, or all.
2. Confirm target deliverable type: `prototype design`, `build implementation`, `demo hardening`, or `production migration blueprint`.
3. Default to all three scenarios if unspecified.
4. Read [references/s4-prototype-requirements.md](references/s4-prototype-requirements.md) before design decisions.

### 2. Build the Databricks data products
1. Build duplicate-detection output with pair confidence score (`0-100`).
2. Build hierarchy-stitching output with parent-child graph and unlimited depth support.
3. Build firmographic enrichment output with per-attribute validity score (`0-100`) and review flags.
4. Persist each product in governed tables with lineage-visible transformations.
5. Maintain deterministic IDs so Data Cloud identity resolution can map records reliably.

### 3. Enforce governance and lineage
1. Register data assets in Unity Catalog.
2. Ensure lineage is visible from CRM source tables to enriched entity graph outputs.
3. Include run metadata: run ID, timestamp, source snapshot, model version.
4. Reject non-traceable enrichments in demo or build outputs.

### 4. Prepare Data Cloud handoff
1. Publish a clean handoff dataset for Data Cloud ingestion (batch for prototype).
2. Include explicit ingestion metadata label: `Databricks Enrichment — Last ingested: [date]`.
3. Ensure fields required by Data Cloud and Salesforce UI are present.
4. Validate confidence thresholds meet demo expectations (identity confidence target `>=90%` on key examples).
5. Use [references/databricks-implementation-patterns.md](references/databricks-implementation-patterns.md) for the minimum data contract.

### 5. Build demo-facing analytics
1. Duplicate detection dashboard: pair counts, confidence distribution, duplicate rate.
2. Governance dashboard: cases resolved, average resolution time, backlog trend, quality score trend.
3. Portfolio support view: uncovered subsidiaries and cross-sell signals consumed by Data Cloud.
4. Keep dashboards pre-computed for demo reliability (no live cluster dependency during walkthrough).

### 6. Run gate checks before handoff
1. Verify DS-01 evidence can be shown from Databricks outputs.
2. Verify DS-02 governance evidence includes validity scores and confidence inputs.
3. Verify DS-03 hierarchy evidence supports group revenue rollup downstream.
4. Reject hardcoded revenue metrics in demonstration artifacts.
5. Run the checklist generator script for final readiness:
```bash
python3 scripts/generate_s4_databricks_plan.py --mode checklist --scenarios ds01,ds02,ds03
```

## Decision Rules
1. Prefer pre-computed daily batch outputs for prototype/demo stability.
2. Keep logic in Databricks for intelligence; keep Salesforce for execution surfaces.
3. Flag low-confidence enrichment values rather than forcing deterministic values.
4. Treat lineage visibility as mandatory, not optional.
5. If a requirement conflicts with demo runtime limits, preserve layer visibility and traceability first.

## Resources

### scripts/
- `scripts/generate_s4_databricks_plan.py`: Generate a structured implementation plan or go-live checklist for the S4 Databricks layer.

### references/
- `references/s4-prototype-requirements.md`: Condensed S4 requirements and non-negotiable acceptance criteria.
- `references/databricks-implementation-patterns.md`: Recommended Databricks architecture, table contracts, jobs, and handoff patterns.
