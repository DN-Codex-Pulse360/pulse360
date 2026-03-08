# EPF Stage 1.2 - Enterprise Constraint Mapping (DAN-75)

## Scope
This artifact records prototype-critical enterprise constraints for Pulse360 and maps each to risk, mitigation owner, and escalation status.

## Constraint Register
| Category | Constraint | Impact | Severity | Mitigation Owner | Status |
| --- | --- | --- | --- | --- | --- |
| Regulatory | Customer/production data cannot be exposed in public demo/readout assets | Evidence artifacts must be sanitized; limits direct production screenshots | High | Architecture + Security | Active control |
| Data | Identity/hierarchy confidence evidence must be traceable with run metadata | Non-traceable outputs fail acceptance for DS-01/02/03 | High | Data Engineering | Active control |
| Data | Cross-system key consistency required between Databricks, Data Cloud, and CRM | Broken key mapping invalidates Account 360 view and activation | High | Data Engineering | Active control |
| Procurement/Platform | Data Cloud and Agentforce features depend on trial/org entitlements | Missing features can block planned flow or require fallback path | Medium | Salesforce Platform Owner | Monitoring |
| Procurement/Platform | GitHub protected-branch policy enforces PR + required checks | Delivery cannot bypass CI/PR path | Medium | Repo Admin | Active control |
| Organizational | Limited stakeholder review bandwidth can delay EPF gate approvals | Milestone closure lag despite technical completion | Medium | Project Lead | Monitoring |
| Organizational | Multi-system ownership (Databricks, Data Cloud, CRM) requires explicit handoff contracts | Ambiguous ownership increases rework risk | High | Solution Architect | Active control |

## Risk Profile and Mitigation Owners
| Risk ID | Risk Description | Probability | Impact | Owner | Mitigation |
| --- | --- | --- | --- | --- | --- |
| R-01 | Unsanitized content leaks into customer-facing assets | Medium | High | Security Lead | Enforce sanitization checklist in EPF and review gate before publication |
| R-02 | Canonical model drift between systems | Medium | High | Data Engineering Lead | Enforce contract + cross-file integrity validators in CI |
| R-03 | Entitlement limitations block target demo behavior | Low | High | Salesforce Platform Owner | Validate org capabilities early; maintain fallback narrative |
| R-04 | Gate evidence updates lag behind implementation | Medium | Medium | Project Lead | Linear-first status protocol; evidence linked at every transition |
| R-05 | Cross-team handoff ambiguity on connector ownership | Medium | Medium | Solution Architect | Maintain explicit contract ownership and milestone-level acceptance mapping |

## Blocking Constraints and Escalation
| Blocker ID | Blocking Constraint | Current State | Escalation Path | Decision Needed By |
| --- | --- | --- | --- | --- |
| B-01 | Absence of minimal real Databricks extract evidence for canonical exports | Open | Escalate to Data Engineering owner in Milestone C execution | Before closing DAN-60/61/62 |
| B-02 | Final approval cadence for remaining Milestone A gate artifacts | Open | Escalate to Project Lead for review window commitment | Before Milestone A closeout |

## Gate 1.2 Self-Check
Gate question: identify at least one blocking constraint per category (regulatory, data, procurement, organizational).

Status: **Pass candidate**  
Rationale: all four categories are represented, risk ownership is assigned, and active blockers include escalation paths.

