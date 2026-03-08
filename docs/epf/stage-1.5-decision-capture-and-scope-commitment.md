# EPF Stage 1.5 - Decision Capture and Scope Commitment (DAN-77)

## Scope
This artifact captures committed discovery decisions for prototype start and records scope boundaries for Milestone A onward.

## Scope Commitment
### Minimum Viable Architecture (MVA)
1. Databricks intelligence layer for duplicate detection, hierarchy stitching, and enrichment validity scoring.
2. Data Cloud identity resolution and Account-centered activation.
3. Salesforce/Agentforce execution surface using Data Cloud-backed insights.
4. Contract-driven integration artifacts with CI validations.

### Deferred
1. Full production Delta Share implementation (prototype uses pre-run import path).
2. Advanced multi-region deployment controls and cost optimization layers.
3. Expanded channel engagement models beyond current prototype entities.

### Excluded
1. Production-scale performance hardening beyond prototype runtime targets.
2. Non-Pulse360 domains outside DS-01/02/03 and B2B account intelligence scope.
3. Enterprise-wide policy automation not required for prototype gate evidence.

## Decision Log (Prototype-Start Baseline)
| Decision ID | Decision | Status | Evidence |
| --- | --- | --- | --- |
| D-01 | Canonical model aligns to Data Cloud standard DMOs | Accepted | `docs/contracts/b2b-customer360-canonical-model-v2.md` |
| D-02 | Databricks remains intelligence computation layer; Data Cloud remains canonical identity + activation layer | Accepted | `docs/contracts/databricks-to-datacloud-contract.md`, `docs/contracts/datacloud-to-salesforce-agentforce-contract.md` |
| D-03 | Contract-first validation gates are mandatory in CI | Accepted | `.github/workflows/ci.yml`, `scripts/validate-*.sh` |
| D-04 | Prototype branch governance follows protected-main + PR checks | Accepted | `.github/workflows/ci.yml`, branch protection policy evidence in repository operations |
| D-05 | Milestone A closes only when Stage 1.1-1.5 artifacts are linked in control center and Linear | Accepted | `docs/epf/control-center.md`, Linear Milestone A issues |

## New Architect Handover Readiness Check
Handover question: can a new architect understand the engagement using documented artifacts only?

Checklist:
1. Business framing and constraints documented (`Stage 1.1`, `Stage 1.2` artifacts).
2. Platform landscape and option tradeoffs documented (`Stage 1.3/1.4` artifact).
3. Scope boundaries and accepted decisions documented (this artifact).
4. Control-center stage tracker references current evidence links.

Status: **Pass candidate**  
Note: final pass requires Milestone A issue review completion in Linear.

## Gate 1.5 Self-Check
Gate question: if a new architect joined tomorrow, could they onboard from project documentation alone?

Status: **Pass candidate**  
Rationale: scope, decisions, and evidence paths are documented and cross-linked for onboarding.

