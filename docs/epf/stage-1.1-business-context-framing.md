# EPF Stage 1.1 - Business Context Framing (DAN-74)

## Scope
This artifact captures the Stage 1.1 outputs for the Pulse360 S4 prototype and serves as gate evidence for Milestone A.

## Business Problem Statement (Testable)
Enterprise account intelligence is fragmented across CRM records and external enrichment sources, causing:
1. Duplicate and conflicting account identities.
2. Incomplete hierarchy context for group-level decisions.
3. Slow, manual governance case resolution.

Testable success criteria:
1. Identity confidence reaches `>=90` on key demo pairs.
2. Parent-child hierarchy rollups are available for DS-03 account 360 views.
3. Governance evidence (confidence, validity, review flags) is visible for DS-02.
4. DS-01/02/03 demo flow completes in `<=15` minutes with lineage-backed data.

## Stakeholder Map
| Stakeholder Group | Role | Primary Outcome |
| --- | --- | --- |
| Sales leadership | Revenue owner | Reliable group account context and cross-sell signals |
| Service/governance ops | Data steward | Faster conflict resolution with auditability |
| Data engineering | Delivery owner | Deterministic, lineage-visible data products |
| Architecture and security | Control owner | Governed integration contracts and traceability |
| Demo and readout audience | Decision makers | Clear business impact and implementation readiness |

## Initial Outcomes
1. Unified Account 360 context across enterprise hierarchies.
2. Confidence-driven identity resolution for Data Cloud and CRM activation.
3. Governance workflow supported by explainable enrichment and duplicate evidence.
4. B2B customer intelligence model aligned to Salesforce Data Cloud canonical objects.

## Sanitization Convention
1. Customer-facing assets use codename `Pulse360` and sanitized entity names.
2. No customer-sensitive identifiers, production URLs, or commercial terms in public artifacts.
3. Internal-only details remain in secured internal artifacts and issue threads.
4. Demo examples use synthetic IDs unless explicitly marked as approved real extracts.

## IP Inventory (Reusable Assets)
| IP Asset | Location | Reuse Value |
| --- | --- | --- |
| EPF control-center structure | `docs/epf/control-center.md` | Repeatable stage/gate governance |
| Data contracts baseline | `docs/contracts/*`, `contracts/*.json` | Reusable integration contract pattern |
| Validation automation | `scripts/validate-*.sh` | Portable quality gate scaffolding |
| DS scenario runbook | `docs/runbook/s4-ds-runbook.md` | Reusable demo operation template |
| Canonical model blueprint | `docs/contracts/b2b-customer360-canonical-model-v2.md` | Reusable B2B data model reference |

## Two-Minute Non-Technical Explanation
Pulse360 helps teams treat a business group as one customer instead of disconnected records. Today, account data is fragmented, so teams miss revenue opportunities and spend time reconciling conflicting information. The prototype combines account identity, hierarchy, product, and engagement signals so users can see a trusted account picture and act quickly. In practice, this means faster governance decisions, better account planning, and clearer cross-sell actions. The success target is an end-to-end demonstration where confidence-backed insights and hierarchy context are visible, traceable, and operational in under fifteen minutes.

## Gate 1.1 Self-Check
Gate question: explain the business problem in 2 minutes without mentioning technology.

Status: **Pass**  
Rationale: the explanation above is business-first and outcome-based, with measurable success criteria, and the Milestone A gate review was reconciled in Linear on 2026-03-25.
