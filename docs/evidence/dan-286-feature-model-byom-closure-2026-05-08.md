# DAN-286 Feature Engineering, Model Serving, and BYOM Closure

## Scope

`DAN-286` closes the source-controlled feature/model/BYOM plan needed to unblock the model-backed RevOps modules.

This closure creates contracts, SQL definitions, package membership, and a runbook. It does not create live Databricks serving endpoints or Salesforce BYOM connections.

## Decision

Use a batch-first model path for the first slice.

The first model family is `icp_fit` because it can use the current firmographic, classification, weighted attribute, and evidence contracts without waiting for intent, product usage, support, or contract sources.

## Source Artifacts

- `contracts/account_feature_snapshot.schema.json`
- `contracts/model_score_output.schema.json`
- `data/samples/account_feature_snapshot_sample.json`
- `data/samples/model_score_output_sample.json`
- `config/databricks/model-serving-byom-plan.json`
- `sql/databricks/model_serving/`
- `docs/planning/pulse360-databricks-feature-model-byom-plan-2026-05-08.md`
- `docs/runbook/salesforce-byom-databricks-model-serving-runbook.md`
- `scripts/validate-databricks-model-serving-byom-plan.sh`
- `config/packages/databricks/model-serving-byom.members.txt`

## Acceptance Position

| Requirement | Closure Evidence |
| --- | --- |
| Feature table contract with keys and point-in-time semantics | `account_feature_snapshot` contract and SQL table require `source_account_id`, `snapshot_as_of`, `feature_set_version`, source refs, lineage, and quality metrics. |
| Priority model train/score/deploy plan | `icp_fit` is the first model family with a batch scoring path and registered model naming convention. |
| Model output fields | `model_score_output` requires score, confidence, score band, top drivers, explanation, model version, run ID, and timestamp. |
| Salesforce/Data Cloud path | Default is Data Cloud batch enrichment; BYOM, Flow/Apex, and report-only options are documented with gates. |
| Region/entitlement limitations | BYOM and real-time serving are explicitly gated by endpoint, entitlement, auth, and mapping checks. |

## Validation

Run:

```bash
./scripts/validate-databricks-model-serving-byom-plan.sh
./scripts/validate-databricks-package-layout.sh
```

Expected checks:

- contracts, samples, config, SQL, planning doc, and runbook exist;
- JSON artifacts parse;
- default serving mode is batch;
- Salesforce BYOM status is gated;
- score outputs default endpoint/BYOM/Data Cloud mapping flags to false until proven;
- package workspace includes the model-serving bundle.

## Remaining Runtime Gates

- Databricks SQL Warehouse availability is still required before live SQL execution can be claimed.
- Mosaic AI Model Serving endpoint creation remains a runtime activity.
- Salesforce BYOM/Model Builder setup remains gated by target-org entitlement and admin configuration.
- Data Cloud score mapping should be performed only after the target output fields are approved.

## Recommended Linear Outcome

Move `DAN-286` to Done for the source-controlled plan/contract slice.

The next critical path item is `DAN-290` for governance, lineage, audit, and regulator evidence hardening.
