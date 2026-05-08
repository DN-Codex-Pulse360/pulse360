# DAN-291 Six Module Delivery Sequence Closure

## Scope

`DAN-291` closes the six-module sequencing work for the RevOps Intelligence build under parent `DAN-280`.

The closure is source-only. It does not deploy Salesforce metadata, mutate Data Cloud mappings, run Databricks jobs, or change folder sharing.

## Decision

The selected first delivery slice is `M1 Account Hierarchy Intelligence`.

M1 leads because it uses the already validated account identity, Data Cloud relationship, firmographic profile, corporate linkage, evidence, and weighted attribute contracts. It also creates the account group context required by later scoring, whitespace, routing, and renewal-risk modules.

## Source Artifacts

- `config/databricks/revops-module-delivery-sequence.json`
- `docs/planning/pulse360-revops-module-delivery-sequence-2026-05-08.md`
- `scripts/validate-revops-module-sequence.sh`

## Module Status

| Module | Status | Gate |
| --- | --- | --- |
| `M1` Account Hierarchy Intelligence | Ready for demo hardening | Corporate linkage and firmographic evidence reports render through Account joins. |
| `M2` ICP Fit and Account Scoring | Blocked | Requires `DAN-286` feature engineering and model serving plan. |
| `M3` Whitespace and Expansion | Blocked | Requires M1 and `DAN-286`; also needs product/entitlement source availability. |
| `M4` Buying Committee | Blocked | Requires contact/person and consent source availability. |
| `M5` Intent Routing | Blocked | Requires `DAN-286` and intent source availability. |
| `M6` Renewal Risk | Blocked | Requires `DAN-286` and engagement/support/usage/contract source availability. |

## Validation

Run:

```bash
./scripts/validate-revops-module-sequence.sh
```

Expected checks:

- exactly six modules are declared in order `M1` through `M6`;
- `M1` is selected as the first slice;
- M1 depends on the already-closed identity, hierarchy, weighted attribute, Data Cloud, and Salesforce UX slices;
- `M2`, `M3`, `M5`, and `M6` remain explicitly gated by `DAN-286`;
- the planning document references `DAN-291`, M1, `DAN-286`, and the native Agentforce runtime gate.

## Recommended Linear Outcome

Move `DAN-291` to Done after validator success.

The remaining open sequence should be:

1. `DAN-286` feature engineering, model serving, and BYOM plan;
2. `DAN-290` governance, lineage, audit, and regulator evidence hardening;
3. `DAN-292` final acceptance gate and readout evidence.
