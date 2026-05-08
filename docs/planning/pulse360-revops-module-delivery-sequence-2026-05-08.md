# Pulse360 RevOps Module Delivery Sequence

## Purpose

This document closes `DAN-291` by converting the six RevOps Intelligence modules into a buildable delivery sequence.

It sits underneath the feasible architecture decision stack and does three things:

- selects the first module slice;
- defines dependency, output, and acceptance boundaries for `M1` through `M6`;
- names the remaining Linear sequence needed to move from validated data foundation to model-backed and governance-hardened delivery.

## Decision

`M1 Account Hierarchy Intelligence` is the first delivery slice.

The reason is practical: hierarchy uses the Data Cloud and Databricks contracts already validated in the current build. It also creates the account group context needed by whitespace, ICP scoring, routing, and renewal risk. We should complete the hierarchy slice before claiming model-backed intelligence.

## Source-Control Contract

The machine-checkable sequence lives in:

`config/databricks/revops-module-delivery-sequence.json`

The validator lives in:

`scripts/validate-revops-module-sequence.sh`

## Delivery Sequence

| Priority | Module | First Slice | Primary Business Outcome | Current Posture |
| --- | --- | --- | --- | --- |
| 1 | `M1` Account Hierarchy Intelligence | Hierarchy foundation | Seller sees trusted parent-child structure, group revenue context, and coverage gaps. | Ready for demo hardening |
| 2 | `M2` ICP Fit and Account Scoring | Scoring foundation | Seller sees account fit score, top drivers, and source-bound confidence. | Blocked by `DAN-286` |
| 3 | `M3` Whitespace and Expansion | Group whitespace grid | Seller sees product or subsidiary gaps across known account groups. | Blocked by M1 and `DAN-286` |
| 4 | `M4` Buying Committee | Role coverage foundation | Seller sees stakeholder coverage and role gaps. | Blocked by contact/person source availability |
| 5 | `M5` Intent Routing | Governed routing queue | Seller or queue receives source-bound intent recommendations. | Blocked by `DAN-286` and intent source availability |
| 6 | `M6` Renewal Risk | Risk evidence foundation | Seller sees renewal risk and source-backed save plays. | Blocked by `DAN-286` and renewal source availability |

## M1 Build Boundary

M1 should build only the hierarchy foundation:

- CRM-safe account identity using `source_account_id`;
- sovereign identifier evidence where official source evidence exists;
- corporate linkage edges and group context;
- weighted hierarchy attributes with source contribution evidence;
- Data Cloud exports and Salesforce validation reports that preserve Account joins.

M1 should not create unsupported sovereign identifiers. A zero-row sovereign identifier report remains acceptable until official registry, tax, or filing evidence exists.

## M1 Acceptance Gate

M1 is accepted when:

- Account joins still use `source_account_id` and map to Salesforce Account;
- corporate linkage report renders linked Account rows;
- firmographic and linkage facts show confidence, model version, and source evidence;
- weighted attributes expose `source_contributions_json`;
- the dashboard shows hierarchy/linkage evidence without requiring DMO relationship changes.

## Remaining Dependency Path

The next open build sequence is:

1. `DAN-286`: build the feature engineering, model serving, and Salesforce BYOM plan. This gates `M2`, `M3`, `M5`, and `M6`.
2. `DAN-290`: harden governance, lineage, audit, and regulator evidence across Databricks and Salesforce.
3. `DAN-292`: create the final acceptance gate and readout evidence for the full feasible architecture build plan.

## Agentforce Boundary

Modules may define Agentforce-compatible actions, citations, and Trust Layer expectations, but the source-controlled build must not claim native Agentforce success until the target org proves runtime support.

Until then:

- Salesforce surfaces are custom validation reports, dashboards, LWCs, or action panels;
- Slack or Agentforce-style actions remain gated integration surfaces;
- all externally visible actions require human approval.

## No State Change

This `DAN-291` closure is source-only. It does not deploy Salesforce metadata, change Data Cloud relationships, run Databricks jobs, update folder sharing, or mutate target-org configuration.
