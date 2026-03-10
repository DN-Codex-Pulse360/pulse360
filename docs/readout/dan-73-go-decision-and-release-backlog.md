# DAN-73 EPF 2.6 Decision and Release Backlog Conversion

## Formal Decision Outcome
- Decision: **Conditional GO**
- Decision date (UTC): `2026-03-09`
- Decision timestamp (UTC): `2026-03-09T06:38:16Z`
- Gate: `EPF 2.6`

Approvers / decision authorities of record:
1. Daniel Nortje - Program Lead and EPF gate owner (approver).
2. Pulse360 prototype governance record - archived in Notion decision log by approver of record.

Decision rationale:
- DS-01/DS-02/DS-03 runtime evidence is complete and stable for readout handoff.
- Internal and customer readout packs are published and validated.
- Remaining deferred build depth (`DAN-58`, `DAN-59`) is not required for prototype gate closure but is required for implementation runway.

## Conditions, Risks, and Follow-up Actions
### Conditions attached to this decision
| Condition ID | Condition | Owner | Due window | Validation evidence |
| --- | --- | --- | --- | --- |
| C1 | Resolve deferred Data Cloud stream hardening scope (`DAN-59`) before pilot cutover. | Data Cloud Engineer | Next implementation sprint | Linear issue status + runtime validator re-run |
| C2 | Resolve deferred Databricks governance dashboard depth (`DAN-58`) before customer executive dashboard rollout. | Databricks Data Engineer | Next implementation sprint | Dashboard pack updates + validator pass |
| C3 | Re-run E2E timing + readout validators within 24h of implementation kickoff. | QA / Demo Reliability | Kickoff day | `scripts/run-e2e-qa-timing.sh` + readout validators |

### Active risks
| Risk ID | Risk | Severity | Mitigation |
| --- | --- | --- | --- |
| R1 | Deferred dashboard depth may constrain executive confidence during pilot governance reporting. | Medium | Prioritize `DAN-58` in first release sprint. |
| R2 | Stream hardening delay may affect activation freshness expectations. | Medium | Prioritize `DAN-59` with explicit readiness checkpoint. |
| R3 | Single-approver decision flow introduces concentration risk. | Medium | Archive decision evidence in both Notion and Linear; require follow-up checkpoint before production GO. |

### Follow-up actions
1. Open implementation sprint with prioritized backlog sequence (below).
2. Track condition closure in Linear and update decision status from Conditional GO -> GO when C1/C2 are complete.
3. Maintain decision archive in Notion and link all updates from Linear DAN-73.

## Prioritized Implementation Backlog (GO Path Translation)
Prioritization method: unblock activation reliability first, then governance depth, then production-path hardening.

| Priority | Backlog item | Source | Why now |
| ---: | --- | --- | --- |
| 1 | `DAN-59` - Configure Data Cloud account and enrichment data streams | Existing Linear (Todo, High) | Highest activation and freshness dependency for pilot readiness. |
| 2 | `DAN-58` - Build Databricks governance analytics dashboard | Existing Linear (Todo, Medium) | Required to complete governance reporting depth for executive rollout. |
| 3 | Production migration of connector path (pre-run import -> live Delta Share contract path) | Derived from `DAN-62` assumptions | Reduces operational friction after pilot stabilization. |
| 4 | EPF 2.6 post-decision checkpoint and release-governance review | Derived from DAN-73 conditions | Converts Conditional GO to GO with objective closure criteria. |

## Evidence and Cross-References
### Runtime and planning evidence
- `docs/evidence/e2e-qa-latest.md`
- `docs/evidence/datacloud-prerun-import-latest.md`
- `docs/planning/dan-70-implementation-estimate-and-resource-plan.md`
- `docs/readout/internal-solution-readout-dashboard-pack.md`
- `docs/readout/customer-sanitized-readout-page.md`

### Linear references
- `DAN-73`: https://linear.app/danielnortje/issue/DAN-73
- `DAN-59`: https://linear.app/danielnortje/issue/DAN-59
- `DAN-58`: https://linear.app/danielnortje/issue/DAN-58

### Notion archive references
- Control Center: https://www.notion.so/31dfe2e19eed813fbc18ee02d7295c27
- Decision Log page: https://www.notion.so/31dfe2e19eed81069b18f76d459a2954

## Acceptance Mapping (DAN-73)
- Formal decision outcome recorded with date and approvers: satisfied.
- Conditions, risks, and follow-up actions captured: satisfied.
- GO path translated into prioritized implementation backlog: satisfied.
- Decision references archived in Notion and Linear: satisfied.
