# S4 Prototype Requirements (Databricks-Critical)

## Objective
Enable a <=15 minute end-to-end S4 demo where Databricks provides the intelligence foundation consumed by Data Cloud and surfaced in Salesforce/Agentforce.

## Databricks must provide
1. Duplicate detection output with confidence scoring.
2. Hierarchy stitching output (entity graph with parent-child relationships).
3. Firmographic enrichment with validity scoring and low-confidence flags.
4. Unity Catalog lineage proving source-to-output traceability.
5. Governance analytics trend outputs for operational impact storytelling.

## Scenario mapping

### DS-01 Fragmentation Discovery
- Evidence needed: duplicate pairs distribution, duplicate rate, firmographic validity examples, and lineage panel.

### DS-02 Governance Case Resolution
- Evidence needed: candidate pair confidence, attribute-level evidence inputs, validity scores for both records, and weekly governance trend metrics.

### DS-03 Account 360 Moment
- Evidence needed: stitched hierarchy output supporting group-level rollups and uncovered subsidiaries.

## Non-negotiable acceptance criteria
1. All scenario evidence must be sourced from data outputs, not hardcoded values.
2. Databricks outputs must be ingestible into Data Cloud with clear ingestion timestamp labeling.
3. Databricks evidence must remain accessible without requiring ad hoc cluster rebuilds during demo.
4. Lineage must show provenance from CRM source data to enriched graph artifacts.

## Demo reliability constraints
1. Pre-compute expensive pipelines before demo day.
2. Keep a reproducible snapshot of demo datasets.
3. Keep model and pipeline versions pinned for walkthrough stability.
