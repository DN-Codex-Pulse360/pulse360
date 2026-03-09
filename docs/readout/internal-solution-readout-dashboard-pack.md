# Internal Solution Read Out Dashboard Pack (DAN-71)

## Distribution and Data Classification
- Audience: Internal review stakeholders only.
- Classification: Internal / commercially sensitive.
- External sharing: Prohibited. Use sanitized successor artifact from `DAN-72`.

## Dashboard Snapshot
| Panel | Current status | Evidence source |
| --- | --- | --- |
| Effort estimate | `26.25` person-weeks (range `24-29`) | `docs/planning/dan-70-implementation-estimate-and-resource-plan.md` |
| Resource plan | Role matrix mapped across milestones A-E | `docs/planning/dan-70-implementation-estimate-and-resource-plan.md` |
| Dependency map | Databricks -> Data Cloud -> Salesforce/Agentforce -> Readouts -> Decision | `docs/planning/dan-70-implementation-estimate-and-resource-plan.md` |
| Critical path | `DAN-70 -> DAN-71 -> DAN-72 -> DAN-73` | `docs/planning/dan-70-implementation-estimate-and-resource-plan.md` |
| Runtime readiness | E2E runtime `91` seconds (`<= 900` target) | `docs/evidence/e2e-qa-latest.md` |
| Data handoff readiness | `run_20260309_042146`; export + metadata checks pass | `docs/evidence/datacloud-prerun-import-latest.md` |

## Delivery Readiness Panels
### Effort and Capacity
- Implementation estimate baseline is evidence-derived from runtime outputs and validators (`DAN-70`).
- Peak combined staffing assumption remains `~5.1` FTE during Milestone D/E overlap.
- Planning confidence: Medium (prototype validated, production controls pending hardening).

### Dependencies and Critical Path
- Hard dependency order:
  1. Databricks intelligence outputs validated.
  2. Data Cloud ingestion/identity checks validated.
  3. Salesforce runtime payload checks validated.
  4. Internal readout approval (`DAN-71`).
  5. Customer sanitized readout (`DAN-72`).
  6. Formal decision and backlog conversion (`DAN-73`).
- Critical path risk concentration: late-stage readout approval and decision cadence.

### Assumptions and Risk Register
| ID | Assumption / Risk | Severity | Mitigation | Owner |
| --- | --- | --- | --- | --- |
| R1 | Runtime evidence drift between rehearsal and decision review | Medium | Re-run `scripts/run-e2e-qa-timing.sh` within 24h of review | QA / Demo Reliability |
| R2 | Deferred dashboard depth (`DAN-58`, `DAN-59`) limits richness of executive visuals | Medium | Keep as explicit out-of-scope for go/no-go decision basis | Product/Solution Lead |
| R3 | Cross-team availability for milestone E close is constrained | High | Pre-allocate approver window and backups in agenda | Product/Solution Lead |
| R4 | External compliance request changes before decision | Medium | Gate decision as Conditional GO until evidence updated | Security / Governance |

## Gate Status Dashboard
| Gate | Status | Evidence |
| --- | --- | --- |
| EPF 2.4 | In Review | `docs/qa/acceptance-checklist.md`; runtime validators + E2E proof |
| EPF 2.5 | Done | `docs/planning/dan-70-implementation-estimate-and-resource-plan.md`; `scripts/validate-implementation-estimate-runtime.sh` |
| EPF 2.6 | In Progress | This internal readout pack (`DAN-71`), followed by `DAN-72` and `DAN-73` |

## Linked Live Prototype Evidence and Issue Status
### Runtime evidence
- `docs/evidence/e2e-qa-latest.md`
- `docs/evidence/datacloud-prerun-import-latest.md`

### Validator entry points
- `scripts/validate-e2e-qa-pack.sh`
- `scripts/validate-implementation-estimate-runtime.sh`
- `scripts/validate-readout-dashboard-pack.sh`

### Linear issue status links
- `DAN-63`: https://linear.app/danielnortje/issue/DAN-63
- `DAN-64`: https://linear.app/danielnortje/issue/DAN-64
- `DAN-65`: https://linear.app/danielnortje/issue/DAN-65
- `DAN-66`: https://linear.app/danielnortje/issue/DAN-66
- `DAN-67`: https://linear.app/danielnortje/issue/DAN-67
- `DAN-68`: https://linear.app/danielnortje/issue/DAN-68
- `DAN-70`: https://linear.app/danielnortje/issue/DAN-70
- `DAN-71`: https://linear.app/danielnortje/issue/DAN-71
- `DAN-72`: https://linear.app/danielnortje/issue/DAN-72
- `DAN-73`: https://linear.app/danielnortje/issue/DAN-73

## Review Meeting Agenda (Prepared)
1. Decision framing and objective (`5` min).
2. Runtime proof review across DS-01/DS-02/DS-03 (`10` min).
3. Effort/resource/dependency review (`10` min).
4. Risks, assumptions, and conditions (`10` min).
5. Decision vote and follow-up owners (`10` min).

## Decision Rubric (Prepared)
| Criterion | Scoring guidance |
| --- | --- |
| Runtime reliability | `0`: fails target; `1`: meets target with instability; `2`: consistently meets target with evidence |
| Data contract and traceability | `0`: missing contracts; `1`: partial coverage; `2`: full coverage with validator proof |
| Delivery feasibility | `0`: no credible plan; `1`: plan exists with unresolved blockers; `2`: plan + owner/capacity clear |
| Risk containment | `0`: unmanaged high risks; `1`: risks known but weak mitigations; `2`: mitigations and owners assigned |
| Governance readiness | `0`: no decision path; `1`: path drafted; `2`: agenda, rubric, and handoff sequence complete |

Decision thresholds:
- `9-10`: GO
- `7-8`: Conditional GO
- `<=6`: No-GO

## Commercially Sensitive Internal-Only Details
- Internal capacity assumptions by role and milestone are intentionally included in this pack.
- Internal risk posture and mitigation ownership are intentionally included in this pack.
- These details must be removed or generalized in customer-facing materials (`DAN-72`).
