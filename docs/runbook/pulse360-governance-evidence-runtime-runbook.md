# Pulse360 Governance Evidence Runtime Runbook

## Purpose

This runbook lists the runtime checks needed to promote governance evidence from demo-ready to externally audit-ready.

The current source work defines contracts and validators only. Runtime checks should be executed after explicit review because they access live Databricks, Data Cloud, and Salesforce state.

## Source Validation

Run:

```bash
./scripts/validate-governance-evidence-pack.sh
./scripts/validate-unity-catalog-config.sh
./scripts/validate-governance-case-metadata.sh
```

## Databricks Lineage Check

Use the existing runtime script for each key path:

```bash
LINEAGE_UPSTREAM_TABLE=pulse360_s4.silver_salesforce.crm_account \
LINEAGE_DOWNSTREAM_TABLE=pulse360_s4.intelligence.firmographic_profile_export \
./scripts/check-databricks-lineage-runtime.sh
```

Feature-to-score path:

```bash
LINEAGE_UPSTREAM_TABLE=pulse360_s4.gold.account_feature_snapshot \
LINEAGE_DOWNSTREAM_TABLE=pulse360_s4.gold.model_score_output \
./scripts/check-databricks-lineage-runtime.sh
```

Capture the output in a dated evidence file under `docs/evidence/`.

## Data Cloud Evidence Check

Capture:

- data stream status for the five firmographic exports;
- DLO/DMO field mapping status;
- relationship status to Account;
- report/dashboard render status for the five validation reports.

Do not change mappings as part of evidence capture unless a separate deployment/configuration review is approved.

## Salesforce Governance Case Audit Check

Capture:

- Governance Case object metadata and permission set validation;
- sample decision with before value, after value, reviewer, decision reason, timestamp, and downstream update status;
- report or export proving the audit fields retain values after save.

## LLM Audit Check

For GPT-derived fields, capture:

- provider;
- model;
- prompt version;
- input hash;
- output hash;
- citation count;
- source URLs or explicit review state when citation count is zero.

## External Provider Evidence Check

If a paid or commercial provider is introduced later, capture:

- provider agreement or entitlement reference;
- allowed use basis;
- field-set version;
- import/export run ID;
- source confidence and freshness metadata.

Provider IDs must remain xrefs or evidence IDs. They must not become sovereign identifiers.

## Promotion Rule

Only mark `ready_for_external_audit=true` after the runtime checks above are captured and linked from the governance evidence packet.
