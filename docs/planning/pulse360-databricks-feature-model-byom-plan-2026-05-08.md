# Pulse360 Databricks Feature, Model Serving, and BYOM Plan

## Purpose

This document closes the source-controlled planning slice for `DAN-286`.

It defines the Databricks feature engineering and model score outputs that unblock the model-backed RevOps modules, while keeping live serving and Salesforce BYOM claims gated until the target runtimes are verified.

## Decision

The first model path is `M2 ICP Fit and Account Scoring`.

The first implementation posture is batch-first:

- build governed feature snapshots in Databricks;
- score from those snapshots into a model score output table;
- activate through Data Cloud batch enrichment and Salesforce validation surfaces first;
- promote to Mosaic AI Model Serving or Salesforce BYOM only after endpoint, entitlement, auth, and mapping gates pass.

## Source Artifacts

- `contracts/account_feature_snapshot.schema.json`
- `contracts/model_score_output.schema.json`
- `config/databricks/model-serving-byom-plan.json`
- `data/samples/account_feature_snapshot_sample.json`
- `data/samples/model_score_output_sample.json`
- `sql/databricks/model_serving/`
- `docs/runbook/salesforce-byom-databricks-model-serving-runbook.md`
- `scripts/validate-databricks-model-serving-byom-plan.sh`

## Feature Contract

`account_feature_snapshot` is the governed model input boundary.

Required controls:

- `source_account_id` remains the Salesforce Account activation key;
- `snapshot_as_of` records point-in-time semantics;
- `feature_set_version` controls model reproducibility;
- `source_refs_json` links features back to source-bound evidence;
- `input_table_versions_json` captures lineage;
- quality metrics capture feature completeness, evidence coverage, conflicts, and activation eligibility.

## Score Contract

`model_score_output` is the governed model output boundary.

Required controls:

- score and confidence;
- score band;
- model family, model name, model version, and registered model name;
- top drivers as source-bound JSON;
- explanation text;
- serving mode and consumption path;
- run ID and scoring timestamp;
- explicit gates for Databricks endpoint readiness, Salesforce BYOM entitlement, Data Cloud mapping, and human review.

## First Model Path

`icp_fit` is the first planned model family because it can use the current firmographic profile, classification, weighted attribute, and evidence contracts without waiting for product usage, support, or intent data.

The first source-controlled scoring scaffold is:

`sql/databricks/model_serving/30_icp_fit_baseline_score.sql`

That view is deterministic and suitable for validation. It is not a live endpoint claim.

## Salesforce and Data Cloud Consumption

The default consumption path is:

1. Databricks produces `pulse360_s4.gold.account_feature_snapshot`.
2. Databricks produces `pulse360_s4.gold.model_score_output`.
3. Data Cloud ingests or direct-accesses the curated score output.
4. Salesforce reports, dashboards, or LWCs show score, confidence, top drivers, explanation, and freshness.

BYOM is a gated path, not the default claim. Before using BYOM in the target org, confirm:

- Salesforce entitlement and Model Builder/BYOM setup are available;
- the Databricks serving endpoint exists and is reachable;
- authentication is approved through the target org pattern;
- prediction outputs map to Data Cloud/Salesforce fields without DMO relationship changes;
- rollback to batch activation is documented.

## Module Impact

| Module | DAN-286 Impact |
| --- | --- |
| `M2` ICP Fit and Account Scoring | First planned model path; unblocked for feature/score contract work. |
| `M3` Whitespace and Expansion | Remains gated by product/entitlement coverage sources after feature contracts exist. |
| `M5` Intent Routing | Remains gated by intent source availability and real-time need. |
| `M6` Renewal Risk | Remains gated by engagement, support, usage, or contract sources. |

## Acceptance Gate

`DAN-286` is complete for the source-controlled plan when:

- account feature snapshot and model score output contracts exist;
- sample payloads validate as JSON;
- Databricks SQL defines feature and score outputs;
- first model path is documented;
- Salesforce BYOM runbook documents gates and fallback;
- repo validator passes.

## No State Change

This closure does not create a live Mosaic AI Model Serving endpoint, create a Salesforce BYOM connection, deploy Salesforce metadata, change Data Cloud DMO relationships, or run production scoring jobs.
