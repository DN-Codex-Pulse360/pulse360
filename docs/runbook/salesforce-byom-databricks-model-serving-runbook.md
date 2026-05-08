# Salesforce BYOM and Databricks Model Serving Runbook

## Purpose

This runbook defines the setup checks required before Pulse360 claims Salesforce BYOM or live Databricks model serving for `DAN-286`.

It is intentionally gated. The current source-controlled implementation defines the feature and score contracts; it does not mutate Salesforce, Data Cloud, or Databricks runtime state.

## Default Path

Use batch scoring first:

1. Build `pulse360_s4.gold.account_feature_snapshot`.
2. Generate `pulse360_s4.gold.model_score_output`.
3. Expose curated score output to Data Cloud through the approved data stream/direct-access path.
4. Render score, confidence, top drivers, explanation, model version, and freshness in Salesforce reports or LWCs.

## BYOM Readiness Checklist

Complete these checks before configuring BYOM in the target org:

- Salesforce org has the required Model Builder or BYOM entitlement.
- The Databricks serving endpoint exists, is running, and has an approved endpoint name.
- The endpoint request and response schema match `contracts/model_score_output.schema.json`.
- Authentication is approved through the target Salesforce and Databricks pattern.
- Data Cloud or Salesforce field mappings preserve `source_account_id`.
- Prediction output fields have a rollback path to batch activation.
- The run ID, model version, feature snapshot ID, score timestamp, and top drivers are visible to admins or stewards.
- Human review is required before externally visible actions.

## Databricks Endpoint Convention

Recommended endpoint naming:

`pulse360-<model_family>-<environment>`

Examples:

- `pulse360-icp-fit-dev`
- `pulse360-renewal-risk-dev`

Recommended registered model naming:

`pulse360.account_intelligence.<model_family>`

## Salesforce Consumption Options

Use the least complex option that satisfies the workflow:

| Option | When to Use | Gate |
| --- | --- | --- |
| Data Cloud batch enrichment | Default for account scores and dashboard/report surfaces. | Data stream/direct-access mapping verified. |
| Salesforce BYOM prediction job | Use when the org has entitlement and the model endpoint is stable. | BYOM entitlement and endpoint connectivity verified. |
| Flow or Apex callout | Use only for interactive or routing use cases that need near-real-time scoring. | Named credential/auth, endpoint latency, and review controls verified. |
| Report/dashboard only | Use for validation, demo, and steward review. | No runtime integration claim. |

## Rollback

If BYOM or endpoint setup fails:

1. Keep `model_score_output` as the governed batch score table.
2. Refresh Data Cloud/reporting from batch outputs.
3. Leave endpoint readiness and BYOM entitlement flags as false.
4. Document the failed gate in evidence before retrying.

## Validation

Run:

```bash
./scripts/validate-databricks-model-serving-byom-plan.sh
```

The validator checks that contracts, samples, config, SQL, and this runbook preserve the source-first, batch-first, gated BYOM posture.
