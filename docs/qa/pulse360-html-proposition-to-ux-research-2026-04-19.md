# Pulse360 HTML Proposition To UX Research

## Purpose

This assessment translates the revised HTML proposition into UX design guidance before implementation.

It answers four questions:

- which journeys are strongest commercially
- which journeys are strongest from a UX point of view
- what each persona needs at the moment of action
- where the proposition risks becoming compelling on paper but weak in workflow

## Inputs

- target proposition: [pulse360-revops-value-proposition.html](</Users/danielnortje/Desktop/Huron/AI CoE/Account360/pulse360-revops-value-proposition.html>)
- current product proposition: [pulse360-account-intelligence-proposition.md](/Users/danielnortje/Documents/Pulse360/docs/readout/pulse360-account-intelligence-proposition.md)
- current seller and planner QA baseline: [seller-planner-journey-sense-check.md](/Users/danielnortje/Documents/Pulse360/docs/qa/seller-planner-journey-sense-check.md)
- current alignment truth: [alignment-audit-2026-04-19.md](/Users/danielnortje/Documents/Pulse360/docs/evidence/alignment-audit-2026-04-19.md)

## Proposition Critique By Persona

| Persona | What the HTML gets right | What must be true in UX | Main risk if built badly |
|---|---|---|---|
| Sales VP / CRO | Makes hierarchy, coverage, ICP, and risk actionable in planning | Portfolio view must support ranking, filtering, and publishing decisions | Looks like a dashboard, not a planning tool |
| AE / Relationship Manager | Nails the pre-call promise: top three things, narrative, buying gaps, NBA | Account page must surface one obvious move with evidence and minimal clutter | Seller sees a smart page but still has to think too hard |
| SDR | Strong urgency and route-to-action story | Alert must be executable in under two minutes | Alert becomes noisy, generic, or hard to trust |
| CSM | Strong early-warning value story | Risk view must show why the account moved and what to do next | Risk score feels opaque or too late |
| RevOps Director | Strong pipeline-quality and coaching angle | Deal review must compare accounts and opportunities, not just summarize them | Becomes another report with little managerial leverage |
| Steward / Governance | Not the star of the HTML, but still critical trust substrate | Trust cues, provenance, and evidence drill-through must stay visible everywhere | Revenue-facing users stop trusting the system |

## Journey Priority Stack

This is the recommended priority order for UX design and validation, not a final implementation order.

| Priority | Journey | Commercial strength | UX clarity | Current foundation | Research conclusion |
|---|---|---|---|---|---|
| 1 | Territory and strategic account planning | Very high | High | Medium | Essential to buyer credibility because it proves Pulse360 changes portfolio decisions |
| 2 | Account engagement and pre-call prep | Very high | Very high | High | Best near-term proof that weighted summary plus evidence can outperform research-heavy prep |
| 3 | Cross-sell and expansion discovery | Very high | High | Medium | Strongest direct revenue story after planner and seller workflows |
| 4 | Pipeline and deal review | High | High | Low | Important for leadership adoption and forecast credibility |
| 5 | Prospecting with intent | High | Medium | Low | Strong commercial value, but UX quality depends heavily on routing precision and alert trust |
| 6 | Renewal protection and save | High | Medium | Low | Important target capability, but risk UX must avoid opaque model behavior and stale signals |

## Decision-Moment Inventory

### Sales VP / CRO

- Should this account group be tiered higher?
- Which groups are under-covered relative to true group value?
- Which ownership or territory decisions should change this quarter?
- Where is risk concentration building across the book?

### AE / Relationship Manager

- What are the top three things I need before this conversation?
- Which entity in the group deserves focus now?
- Which stakeholder gap matters most?
- What action should I take immediately after the call?

### SDR

- Is this alert worth acting on right now?
- Who should receive the outreach?
- Is the suggested message specific enough to use?
- Should I send, edit, reject, or reroute?

### CSM

- Why did this renewal risk change?
- Is this risk material or explainable noise?
- What is the best save or expansion motion?
- Who should own the intervention?

### RevOps Director / Sales Manager

- Which deals are low quality even if pipeline volume looks healthy?
- Which opportunities are single-threaded or under-covered?
- Which reps need coaching or reallocation?
- Which forecast assumptions should change?

## Trust And Adoption Risk Map

| Risk | Why it matters | UX response |
|---|---|---|
| Over-summary | Users miss why the system believes what it believes | Show top evidence and one-click drill-through by default |
| Over-detail | Users spend too long parsing the experience | Make weighted summary the default and hide the long tail |
| Score opacity | Model-backed output feels arbitrary | Pair every score with drivers, confidence, freshness, and recommended action |
| Channel noise | Slack alerts become background spam | Require reason, owner, target, and next action in every alert |
| Workflow breakage | Users must rebuild the answer in notes, slides, or email | Keep action creation inside the same workflow |
| Trust split | Governance is trustworthy but revenue surfaces are not | Reuse provenance, citations, and uncertainty cues across all surfaces |

## UX Success Criteria By Persona

### Planner / Sales Leader

- can reprioritize a group without reconstructing hierarchy context offline
- can explain why a group moved in priority in buyer language
- can leave the workflow with a real planning output

### Seller

- can identify the top move in under three minutes
- can explain why now, why this entity, and why the system believes it
- can execute a CRM action from the same page

### SDR

- can decide whether to act on an alert in under ninety seconds
- can see target, reason, owner, and drafted message immediately
- can convert alert to outbound action without context switching

### CSM

- can understand the top three drivers of risk quickly
- can distinguish deterioration from noise
- can launch a save motion from the same workflow

### Leadership / RevOps

- can compare quality, risk, and coverage across the portfolio
- can identify which actions should change forecast or staffing
- can use the surface in an actual review without slide rebuilding

## Pulse360 UX Principles

- weighted summary first
- commercial decision support over technical completeness
- actionability at the point of insight
- visible evidence, freshness, and uncertainty
- drill-down rather than overload
- same truth across altitudes, different levels of disclosure
- no recommendation without a user-level consequence

## Research Conclusions

### What the HTML should absolutely preserve

- the altitude model
- the "three things to know" default for altitude 3
- journey-driven value proof
- evidence-backed action generation
- multi-persona commercial coverage beyond the account page

### What the next phase must avoid

- treating the product as a field-enrichment exercise
- building planner behavior as a later add-on
- relying on narrative alone where users need explicit action structure
- surfacing scores without visible drivers and freshness
- designing Salesforce pages without designing Slack and portfolio workflows too

### What should be validated before build commitment

- the planner surface is genuinely decision-ready
- the seller default view is concise enough for live use
- routed alerts feel specific and trustworthy
- renewal explanations are interpretable by CSM and leadership users
