# Pulse360 Governance, Lineage, Audit, and Regulator Evidence Plan

## Purpose

This document closes the source-controlled plan for `DAN-290`.

It defines the cross-platform evidence packet needed to defend served attributes, model scores, LLM narratives, and steward decisions across Databricks, Data Cloud, Salesforce, and AI runtime outputs.

## Decision

Create one governance evidence packet contract and make it the acceptance boundary for trusted output.

The packet does not replace source tables or platform-native lineage. It packages the references a steward, admin, or reviewer needs:

- source contributions;
- Unity Catalog lineage references;
- Data Cloud mapping references;
- model and feature lineage;
- LLM prompt/model/citation audit metadata;
- Salesforce Governance Case decision audit metadata;
- confidence, freshness, run ID, and known limitations.

## Source Artifacts

- `contracts/governance_evidence_packet.schema.json`
- `data/samples/governance_evidence_packet_sample.json`
- `config/databricks/governance-evidence-gates.json`
- `sql/databricks/governance_evidence/`
- `docs/runbook/pulse360-governance-evidence-runtime-runbook.md`
- `scripts/validate-governance-evidence-pack.sh`

## Evidence Families

| Evidence Family | Required For | Source-Control Status |
| --- | --- | --- |
| Unity Catalog lineage | Databricks bronze/silver/gold paths and feature/score outputs | Configured; live check remains runtime-gated |
| Source contribution | Resolved attributes and firmographic facts | Contracted in `DAN-285`; included in governance packet |
| Feature/model lineage | Model-generated scores | Contracted in `DAN-286`; included in governance packet |
| Data Cloud mapping | DLO/DMO activation and report fields | Source-controlled config/runbooks; org setup remains gated |
| Salesforce record audit | Visible account/report/dashboard state | Source-controlled checklist; live export requires org access |
| Governance Case audit | Steward decisions | Existing Governance Case metadata; packet references decision fields |
| LLM audit metadata | GPT-generated narratives and extracted facts | Prompt/model/hash/citation metadata required |
| Provider entitlement/license | Commercial or external source use | Required when applicable; currently not a paid-provider dependency |

## Acceptance Gate

A served attribute cannot pass clean activation if it lacks:

- `source_account_id`;
- source contribution;
- lineage reference;
- confidence;
- freshness;
- run ID;
- generated timestamp.

A model score cannot pass clean activation if it lacks:

- feature snapshot ID;
- model family;
- model version;
- registered model name;
- top drivers;
- run ID;
- scored timestamp.

An LLM narrative cannot pass clean activation if it lacks:

- provider;
- model;
- prompt version;
- input hash;
- output hash;
- citations or an explicit zero-citation review state.

## Regulator Evidence Posture

The current build is demo-ready when evidence packets are generated from source-controlled contracts and known limitations are visible.

The current build is not external-audit-ready until live runtime evidence is captured:

- Unity Catalog lineage response for key paths;
- Data Cloud stream/mapping screenshots or API output;
- Salesforce Governance Case audit export;
- target-org report/dashboard refresh evidence;
- provider/license evidence where external providers are introduced.

## No State Change

This closure does not deploy Salesforce metadata, change Data Cloud relationships, run Databricks jobs, or alter target-org permissions.
