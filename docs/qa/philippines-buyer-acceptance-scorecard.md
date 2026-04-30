# Philippines Buyer Acceptance Scorecard

## Purpose
Define how a buyer should judge Pulse360 in the Philippines market.

This scorecard is not a technical readiness checklist.
It is a commercial proof framework tied to the original proposition:

- fragmented account records reduce account truth
- weak hierarchy visibility hides group revenue and whitespace
- slow stewardship increases operational risk
- low-trust signals fail to convert into commercial action

For the Philippines market, the scorecard also reflects the specific commercial and regulatory context documented in the original intelligence brief:
- diversified conglomerate structures create structurally fragmented customer views
- regulated banks face identity-quality pressure tied to BSP Circular 1213 and broader ITRM expectations
- Salesforce customers pursuing AI or CX transformation are likely to underperform if identity and hierarchy remain fragmented

## Buyer Question
A buyer is not asking whether Pulse360 has:
- a healthy stream
- a complete DMO
- a page that renders

A buyer is asking:
- will this reduce operating cost
- will this increase revenue productivity
- will this improve planning quality
- will this reduce governance or compliance risk

## Commercial Value Themes

## 1. Stewardship Cost Reduction
Economic buyer:
- Chief Data Officer
- Head of Data Governance

Business promise:
- Pulse360 reduces the cost and risk of duplicate-resolution and account-truth decisions.

Why it matters in the Philippines:
- multi-BU conglomerates make duplicate and hierarchy errors structurally likely
- unresolved account truth damages routing, reporting, and downstream commercial execution

Pilot metrics:
- median duplicate-resolution cycle time
- cases resolved per steward per day
- reopened-case rate
- merge reversal rate
- percentage of cases with complete evidence and reason capture

Target thresholds for pilot acceptance:
- 30% or greater reduction in median case-resolution time
- 20% or greater increase in steward throughput
- no increase in reopened-case rate
- 95% or greater of reviewed cases contain complete evidence + reason + audit trail

Test method:
- choose 10-20 duplicate/governance cases
- compare current-state steward workflow vs Pulse360-assisted workflow
- measure time, confidence, and rework

Buyer-level success statement:
- "We can resolve account-truth issues faster without increasing decision risk."

## 2. Seller Productivity And Pipeline Creation
Economic buyer:
- CRO
- Regional Sales Leader
- Head of Sales

Business promise:
- Pulse360 helps sellers reach credible next actions faster and creates more pipeline from existing strategic accounts.

Why it matters in the Philippines:
- large multi-BU enterprises such as telcos, banks, conglomerates, and utilities hide whitespace structurally
- a seller often sees only BU-local revenue, not group-level commercial reality

Pilot metrics:
- time from account open to meaningful next action
- percentage of reviewed accounts with a credible next step
- opportunities or tasks created from Pulse360-assisted reviews
- manual research time saved per account
- visible increase in account or group revenue understanding

Target thresholds for pilot acceptance:
- 50% or greater reduction in time to next meaningful action
- 70% or greater of reviewed target accounts produce a defensible next step
- at least 1 new opportunity, task, or specialist action created from the pilot set
- measurable reduction in manual account-research time

Test method:
- choose 10 named accounts in the pilot segment
- run seller review without Pulse360, then with Pulse360
- capture time spent, next action, confidence level, and whether a CRM action is logged

Buyer-level success statement:
- "Our sellers spend less time assembling context and more time creating pipeline from real group opportunity."

## 3. Group Coverage And Whitespace Discovery
Economic buyer:
- Sales Operations
- Portfolio Owner
- Regional Sales Executive

Business promise:
- Pulse360 makes group-level whitespace and coverage gaps visible enough to change planning decisions.

Why it matters in the Philippines:
- conglomerate structures and BU separation make cross-group selling hard to see in CRM
- hidden subsidiaries mean hidden revenue, hidden white space, and weak account prioritization

Pilot metrics:
- uncovered subsidiaries identified per strategic group
- number of new whitespace opportunities surfaced
- ratio of seller-visible revenue before vs after group context
- planning time to prepare a group view
- number of coverage or ownership changes justified by the new context

Target thresholds for pilot acceptance:
- at least 1 newly visible subsidiary or whitespace lead in a majority of reviewed groups
- 50% or greater reduction in time to prepare a usable group planning view
- at least 1 planning or coverage decision changes because of Pulse360 context

Test method:
- choose 5-10 strategic groups
- document current known structure and revenue visibility
- compare with Pulse360 hierarchy and group context
- record newly visible entities, new actions, and decisions changed

Buyer-level success statement:
- "We can see more of the commercial group and act on whitespace that was previously invisible."

## 4. AI And CX Productivity Enablement
Economic buyer:
- COO
- CX Transformation Sponsor
- Revenue or Service Transformation Leader

Business promise:
- Pulse360 improves the data foundation required for AI and customer-experience initiatives to perform credibly.

Why it matters in the Philippines:
- the original intelligence brief highlights active AI/CX programs with explicit performance targets
- if customer identity and group structure are fragmented, AI outputs become lower-trust and lower-yield

Pilot metrics:
- percentage of AI/CX pilot accounts with unified CRM-safe identity
- percentage of reviewed AI/CX accounts with visible group context
- reduction in manual exception handling caused by fragmented customer identity
- stakeholder confidence that downstream AI actions are using the correct customer context

Target thresholds for pilot acceptance:
- 90% or greater of pilot accounts have preserved CRM-safe identity through the flow
- a majority of pilot accounts show materially improved group/customer context
- documented reduction in manual identity reconciliation for AI/CX use cases

Test method:
- choose a small AI/CX-relevant pilot cohort
- trace identity and hierarchy context end to end
- interview the operational owner on whether the enriched context changes trust in the workflow

Buyer-level success statement:
- "Our AI and CX programs are less likely to underperform because the customer data foundation is more trustworthy."

## 5. Compliance And Audit Defensibility
Economic buyer:
- Chief Risk Officer
- Compliance Lead
- CDO

Business promise:
- Pulse360 strengthens identity-quality defensibility and governance evidence for regulated workflows.

Why it matters in the Philippines:
- the original brief ties identity quality directly to BSP Circular 1213 and ITRM expectations
- fragmented customer identity undermines ML-based fraud controls and audit defensibility

Pilot metrics:
- percentage of reviewed governance decisions with full evidence trail
- percentage of reviewed identity-sensitive flows using preserved CRM-safe account key
- time required to reconstruct evidence during review
- identity-related exception rate in the tested workflow

Target thresholds for pilot acceptance:
- 100% of reviewed governance decisions contain full evidence + reason + lineage
- zero tested writeback paths depend on synthetic-only customer keys
- measurable reduction in audit reconstruction effort

Test method:
- review a sample of governance and identity-sensitive cases
- inspect evidence completeness, key preservation, and replayability
- validate that the steward can defend the decision without offline reconstruction

Buyer-level success statement:
- "We can defend identity-sensitive decisions with stronger evidence and lower audit friction."

## Scorecard Summary

| Value Theme | Primary Buyer | Core Metric | Pilot Acceptance Threshold |
| --- | --- | --- | --- |
| Stewardship cost reduction | CDO / Data Governance | Median case-resolution time | `>= 30%` improvement |
| Seller productivity | CRO / Sales Leader | Time to next meaningful action | `>= 50%` improvement |
| Pipeline / whitespace discovery | CRO / Sales Ops | New whitespace surfaced per group | `>= 1` in most reviewed groups |
| Planning quality | Sales Ops / Exec | Time to prepare group planning view | `>= 50%` improvement |
| Compliance defensibility | Risk / Compliance / CDO | Evidence-trail completeness | `100%` in reviewed sample |

## Recommended Pilot Test Design

### Pilot shape
- 10-20 stewardship cases
- 10 named seller accounts
- 5-10 strategic groups for planning review
- 1 regulated or audit-sensitive workflow sample

### Baseline requirement
Every scorecard item must compare:
- current workflow without Pulse360
- workflow with Pulse360

### Evidence package required
- before vs after timing
- decision taken
- confidence rating from the user
- action created in CRM where applicable
- screenshot or record proof
- short note describing why the business outcome improved

## Decision Rule For Buyer Acceptance
Pulse360 should be considered commercially acceptable in the Philippines pilot only if it proves all three of these:

1. It reduces cost or effort in stewardship and account-truth operations.
2. It creates more actionable commercial opportunity from the same account base.
3. It improves trust and defensibility in identity-sensitive workflows.

If the pilot only proves technical correctness, it is not yet buyable.

## Relationship To Existing QA Docs
Use this scorecard together with:
- [persona-business-acceptance-criteria.md](/Users/danielnortje/Documents/Pulse360/docs/qa/persona-business-acceptance-criteria.md)
- [acceptance-checklist.md](/Users/danielnortje/Documents/Pulse360/docs/qa/acceptance-checklist.md)

Interpretation:
- `acceptance-checklist.md` proves technical and operational readiness
- `persona-business-acceptance-criteria.md` proves persona usefulness
- this scorecard proves buyer-relevant commercial value
