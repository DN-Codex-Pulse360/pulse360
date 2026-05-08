# DAN-290 Governance Evidence Closure

## Scope

`DAN-290` closes the source-controlled governance, lineage, audit, and regulator evidence plan across Databricks, Data Cloud, Salesforce, and AI-generated outputs.

This closure adds contracts, config, SQL, runbook, package membership, and validators. It does not run live lineage checks or mutate platform state.

## Source Artifacts

- `contracts/governance_evidence_packet.schema.json`
- `data/samples/governance_evidence_packet_sample.json`
- `config/databricks/governance-evidence-gates.json`
- `sql/databricks/governance_evidence/`
- `docs/planning/pulse360-governance-lineage-audit-plan-2026-05-08.md`
- `docs/runbook/pulse360-governance-evidence-runtime-runbook.md`
- `scripts/validate-governance-evidence-pack.sh`
- `config/packages/databricks/governance-evidence.members.txt`

## Acceptance Position

| Requirement | Closure Evidence |
| --- | --- |
| Served attributes require run ID, timestamp, confidence, freshness, source contribution, and lineage | Governance evidence packet contract and validator require those fields. |
| Feature/model lineage for model scores | Governance packet includes model refs; `DAN-286` feature/score contracts are referenced. |
| LLM prompt/model/citation/audit metadata | Governance packet includes provider, model, prompt version, input hash, output hash, and citation count. |
| Data Cloud/Salesforce audit evidence | Runtime runbook defines Data Cloud mapping capture and Salesforce Governance Case audit capture. |
| Provider/license evidence | Gate config requires provider entitlement/license evidence when applicable; current design remains no paid-provider dependency. |

## Validation

Run:

```bash
./scripts/validate-governance-evidence-pack.sh
./scripts/validate-unity-catalog-config.sh
./scripts/validate-databricks-package-layout.sh
```

Expected checks:

- governance evidence contract, sample, config, SQL, planning doc, and runbook exist;
- JSON artifacts parse;
- activation cannot pass without source contribution, run ID, freshness, citation, and feature snapshot controls;
- Unity Catalog config includes feature, score, and governance evidence tables;
- Databricks package workspace includes the governance evidence bundle.

## Runtime Caveats

- Unity Catalog lineage remains `pending_runtime_check` until the Databricks SQL Warehouse issue is resolved and lineage CLI output is captured.
- Salesforce record-level audit and Governance Case runtime export require target-org access and should be captured only after explicit approval.
- Data Cloud mapping evidence should be captured from the live org without changing relationships.

## Recommended Linear Outcome

Move `DAN-290` to Done for the source-controlled governance evidence slice.

The next critical path item is `DAN-292` for the final acceptance gate and readout evidence.
