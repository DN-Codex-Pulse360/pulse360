# Persona-Based Business Acceptance Criteria

## Purpose
Define acceptance criteria for Pulse360 in business terms rather than platform plumbing.

These criteria are intended to answer a stricter question than "does the page render" or "does the field sync":

- does the experience change a decision
- for a named persona
- in a way that creates measurable business value

This document is the acceptance lens for UX review, scenario proof, and milestone closeout.

## Critical Review Of The Original Docs

### What the original docs do well
- [acceptance-checklist.md](/Users/danielnortje/Documents/Pulse360/docs/qa/acceptance-checklist.md) captures environment and functional readiness checks.
- [pulse360-product-slice-definition.md](/Users/danielnortje/Documents/Pulse360/docs/readout/pulse360-product-slice-definition.md) clearly describes the steward, seller, and planner personas and the value Pulse360 is supposed to create for each of them.
- [pulse360-account-intelligence-proposition.md](/Users/danielnortje/Documents/Pulse360/docs/readout/pulse360-account-intelligence-proposition.md) frames the product around account truth, intelligence, trust, and action.
- [pulse360-solution-goals-and-implemented-design-2026-03-28.md](/Users/danielnortje/Documents/Pulse360/docs/readout/pulse360-solution-goals-and-implemented-design-2026-03-28.md) documents the implemented architecture and the current runtime proof.

### Where the original docs are weak
1. The acceptance checklist is mostly technical.
- It proves setup, wiring, and runtime health.
- It does not prove that a steward, seller, or planner can make a better decision.

2. The persona docs describe value, but they stop short of acceptance gates.
- They explain who the user is and what pain exists.
- They do not define what the reviewer must observe in order to say the slice is acceptable.

3. The design doc over-indexes on "validated surfaces".
- "UI assets validated" and "values visible" are necessary.
- They are not sufficient to prove business usefulness.

4. The current acceptance framing is feature-centric instead of decision-centric.
- It asks whether a UI exists.
- It should ask whether the UI reduces risk, accelerates action, or improves prioritization.

5. The current criteria are too easy to pass with a technically correct but commercially weak experience.
- A page full of synced fields can pass.
- A user can still leave without knowing what to do next.

## Acceptance Principle
Pulse360 is acceptable only when a persona can do all four of these in one workflow:

1. Understand what changed.
2. Understand why it matters.
3. Trust the signal enough to act.
4. Take the next business action without reconstructing the context manually.

If any of those four fail, the experience is not accepted, even if the backend is healthy.

## Buyer Lens

### What a buyer is actually buying
A buyer is not buying:
- another hierarchy widget
- another score
- another synced field set

A buyer is buying improvement in one or more operating metrics that matter to a budget owner.

For Pulse360, the economically meaningful outcomes are:
- lower cost of account-truth resolution
- lower commercial leakage from fragmented account structures
- faster seller execution on credible opportunities
- better coverage and whitespace discovery across group structures
- lower compliance and audit risk where customer identity quality matters

### Likely economic buyers
- Chief Data Officer or Head of Data Governance
- Chief Revenue Officer or Regional Sales Leader
- Head of Sales Operations / Revenue Operations
- COO or transformation sponsor for customer-data programs
- for regulated financial institutions, risk/compliance leadership tied to customer identity quality

### The key problem with the original proposition docs
The original proposition is strategically sound, but commercially under-specified.

It says:
- better account decisions
- faster stewardship resolution
- better planning and prioritization
- stronger cross-sell visibility

But a buyer will ask:
- by how much
- for whom
- against what baseline
- over what time period
- through which proof method

Acceptance should therefore be tied to measurable value hypotheses, not only UX usefulness.

## Buyer-Level Value Hypotheses

### 1. Data quality economics hypothesis
If Pulse360 makes entity resolution decision-ready, then stewardship teams should resolve duplicate/governance cases faster and with fewer reversals.

Commercial interpretation:
- less analyst time wasted
- lower downstream CRM corruption
- lower routing/segmentation error

### 2. Revenue productivity hypothesis
If Pulse360 makes whitespace, health, and group context visible at the point of sale, then sellers should reach meaningful next actions faster and convert more surfaced opportunities into pipeline.

Commercial interpretation:
- more pipeline from the same book of business
- lower research time per seller
- better rep focus on accounts with real upside

### 3. Coverage and planning hypothesis
If Pulse360 turns hierarchy into a planning surface, then sales operations and leaders should find more uncovered subsidiaries and allocate coverage more effectively.

Commercial interpretation:
- more complete group penetration
- less revenue hidden by fragmented account structures
- better account planning quality

### 4. Trust and compliance hypothesis
If Pulse360 preserves CRM-safe identity and evidence, then regulated or audit-sensitive teams should make decisions with less manual reconstruction and stronger defensibility.

Commercial interpretation:
- lower operational risk
- stronger audit trail
- lower rework during compliance or governance review

## Business Metrics By Buyer Outcome

### A. Stewardship ROI Metrics
Primary buyer:
- CDO
- Head of Data Governance

Metrics:
- median duplicate-resolution cycle time
- cases resolved per steward per day
- backlog age and backlog volume
- reopened-case rate
- merge reversal rate
- percentage of decisions with complete reason + evidence trail

Acceptance threshold examples:
- 30% or greater reduction in median case-resolution time
- 20% or greater increase in steward throughput
- reopened-case rate stays flat or improves
- 95% or greater of decisions retain complete audit evidence

How to test:
- establish a 2-4 week baseline from current governance-case handling
- run 10-20 comparable Pulse360-assisted cases
- compare median time, throughput, and rework
- require the reviewer to judge decision confidence, not only speed

### B. Seller Productivity Metrics
Primary buyer:
- CRO
- regional sales leader
- head of sales

Metrics:
- time from account open to meaningful next action
- percentage of reviewed accounts that produce a credible next step
- percentage of surfaced plays converted into follow-up activity or opportunity
- reduction in manual research time per account review
- seller adoption rate of recommended actions

Acceptance threshold examples:
- 50% or greater reduction in time to next meaningful action
- 70% or greater of reviewed target accounts produce a defensible next step
- measurable increase in opportunity/task creation from targeted account reviews

How to test:
- choose a fixed set of named accounts
- compare current-state seller review vs Pulse360-assisted review
- record:
  - time spent
  - next action chosen
  - confidence level
  - whether action is actually logged in CRM
- follow opportunity/task creation over 2-6 weeks

### C. Pipeline and Whitespace Metrics
Primary buyer:
- CRO
- Sales Ops

Metrics:
- uncovered subsidiaries identified per strategic group
- number and value of new whitespace opportunities surfaced
- share of named accounts with visible group context
- pipeline created from group-level expansion plays
- ratio of group revenue visible before vs after Pulse360 context

Acceptance threshold examples:
- at least 1 new credible whitespace target identified in a majority of reviewed strategic groups
- visible increase in group-revenue-understanding for selected pilot accounts
- documented pipeline creation from at least one Pulse360-identified group opportunity

How to test:
- select 5-10 strategic accounts or groups
- document current seller-visible revenue and known related entities
- run Pulse360 review
- record:
  - newly visible subsidiaries
  - newly identified whitespace
  - follow-up pipeline/actions created

### D. Planning and Coverage Metrics
Primary buyer:
- Sales Ops
- portfolio owner

Metrics:
- percentage of top groups with complete or materially improved hierarchy visibility
- uncovered-subsidiary count by group
- time required to prepare a group planning view
- number of coverage reallocations or ownership changes justified by Pulse360

Acceptance threshold examples:
- 50% or greater reduction in time to prepare a group planning view
- meaningful improvement in hierarchy completeness across pilot groups
- at least one planning or coverage decision changes because of group context surfaced by Pulse360

How to test:
- pick 3-5 planning scenarios
- have the planner create the view with current tools
- repeat using Pulse360
- compare time, coverage gaps identified, and resulting decisions

### E. Compliance / Audit Metrics
Primary buyer:
- risk/compliance lead
- CDO

Metrics:
- percentage of governance decisions with full evidence trail
- percentage of identity-sensitive workflows using a preserved CRM-safe key
- manual effort required to reconstruct evidence for audit/review
- exception rate caused by missing or conflicting identity data

Acceptance threshold examples:
- 100% of pilot governance decisions include traceable evidence and reason capture
- zero pilot writeback paths depend on synthetic-only account keys
- measurable reduction in evidence reconstruction time during review

How to test:
- choose one regulated or audit-sensitive scenario
- inspect a sample of decisions end to end
- verify identity key preservation, evidence presence, and replayability

## From Persona Criteria To Buyer Acceptance

### Steward persona maps to buyer value
Persona success:
- safer, faster duplicate decisions

Buyer proof:
- lower case cycle time
- higher throughput
- lower rework

### Seller persona maps to buyer value
Persona success:
- better next action on the account

Buyer proof:
- faster time to action
- more opportunity creation
- better adoption of guided plays

### Planner persona maps to buyer value
Persona success:
- better group-level prioritization

Buyer proof:
- more uncovered subsidiaries found
- more whitespace surfaced
- faster planning prep

## Test Design Principles

### Principle 1: compare against a baseline workflow
Do not test Pulse360 in isolation.
Always compare:
- current workflow without Pulse360
- target workflow with Pulse360

### Principle 2: use decision quality, not only task completion
A user finishing a workflow is not enough.
The test must ask:
- was the decision better
- was confidence higher
- was action taken sooner

### Principle 3: use real records, not synthetic happy paths only
At least part of acceptance should use live or realistic accounts, governance cases, and hierarchy scenarios with ambiguity.

### Principle 4: separate leading indicators from lagging outcomes
Leading indicators:
- time to decision
- action created
- hierarchy discovered
- confidence to act

Lagging outcomes:
- pipeline conversion
- backlog reduction
- reversal rate
- improved coverage quality

### Principle 5: require business narration in the evidence
Every test case should capture:
- what the user believed before
- what Pulse360 changed
- what decision changed
- why that matters commercially

## Recommended Test Packs

### Pack 1: Stewardship proof pack
- 10 duplicate or governance cases
- baseline vs Pulse360 review timing
- confidence score from reviewer
- auditability check

Success condition:
- measurable reduction in case time without increased decision risk

### Pack 2: Seller productivity proof pack
- 10 named accounts
- seller reviews each account with and without Pulse360
- capture next action, time spent, confidence, and whether an opportunity/task is created

Success condition:
- faster time to action and more credible next actions

### Pack 3: Planning proof pack
- 5 strategic groups
- compare manual group reconstruction vs Pulse360 group context
- capture uncovered subsidiaries, whitespace, and planning decisions changed

Success condition:
- planning decisions improve because group context became visible

### Pack 4: Executive buyer proof pack
- one short business-value readout using the three packs above
- show:
  - time saved
  - revenue opportunities surfaced
  - risk reduced

Success condition:
- a sponsor can explain the ROI case without referring to platform internals

## Personas And Value Drivers

### 1. Data Operations Steward
Primary business outcome:
- reduce the cost and risk of account truth decisions

Value drivers:
- lower median time to duplicate resolution
- lower reopened-case rate
- lower merge-reversal risk
- higher throughput per steward
- better downstream trust in account identity for seller and planning workflows

### 2. Key Account Manager / Sales Specialist
Primary business outcome:
- improve account prioritization and next-action quality

Value drivers:
- faster time from account open to meaningful action
- reduced manual research time
- better whitespace and cross-sell identification
- higher adoption of recommended actions
- better conversion of surfaced opportunities into pipeline

### 3. Sales Operations / Sales Executive Planner
Primary business outcome:
- improve portfolio and group-level coverage decisions

Value drivers:
- better visibility into uncovered subsidiaries and group whitespace
- improved prioritization across groups rather than isolated records
- reduced planning effort to reconstruct hierarchy context
- better confidence in group-level revenue and coverage analysis

## Persona Acceptance Criteria

## Steward Acceptance

### Business question
Can a steward make a safer duplicate-resolution decision faster than with CRM alone?

### Must be true
- The steward can see the candidate pair, conflict evidence, trust signals, and hierarchy impact in one workflow.
- The steward can explain why the pair should be approved, rejected, or deferred without opening multiple systems.
- The steward can record a structured decision with reason capture and auditability.
- The steward can identify which attributes should survive and why.
- The steward can see evidence freshness and lineage strongly enough to judge whether the case is still actionable.

### Evidence required for acceptance
- one or more live governance cases where the reviewer can answer:
  - are these the same business entity
  - which attributes are trustworthy
  - what hierarchy consequence follows from acting
  - what the right decision is now
- visible audit trail for approve, reject, and defer behavior
- proof that validation rules still enforce decision discipline outside the LWC path

### Business failure conditions
- The steward sees a score but not enough explanation to defend the decision.
- The steward must open other systems to understand attribute conflicts.
- The workflow captures a decision but not the rationale.
- The experience is technically complete but does not reduce decision risk.

## Seller Acceptance

### Business question
Can a seller decide what to do next on an account faster and with more confidence than with standard CRM context alone?

### Must be true
- The seller can see a small number of credible signals that explain why the account deserves attention now.
- The seller can understand group context, commercial importance, and signal freshness without reconstructing the story manually.
- The seller can identify a concrete next move such as:
  - pursue whitespace
  - route a specialist
  - create follow-up action
  - escalate account risk
- The seller can tell whether the signal is trustworthy enough to act on.

### Evidence required for acceptance
- live `Account` records that show current Pulse360 values through the working CRM realization path
- at least one reviewed example where the visible values support a plausible next action
- clear signal freshness or provenance cues so the seller knows whether the information is current

### Business failure conditions
- The seller sees lots of fields but no clear business narrative.
- The seller cannot tell what changed since last review.
- The seller cannot tell whether the signal is fresh enough to act on.
- The page is informative but still passive; it does not shorten time to action.

## Planner Acceptance

### Business question
Can a planner or sales leader make a better group-level prioritization decision without manually rebuilding hierarchy context?

### Must be true
- The planner can see group structure and the commercial meaning of that structure.
- The planner can detect coverage gaps, whitespace, or group-level asymmetry from the available context.
- The planner can distinguish between seller-visible revenue and broader group-visible revenue or exposure.
- The planner can identify where coverage or ownership changes should be made.

### Evidence required for acceptance
- one or more group-oriented examples where hierarchy context changes planning interpretation
- visible rollup or group metrics that are meaningful for coverage and whitespace review
- enough confidence markers to prevent false precision in uncertain hierarchy cases

### Business failure conditions
- The planner sees an org tree but no planning implication.
- Group signals are present but do not help choose where to focus coverage.
- The review still depends on offline hierarchy reconstruction.

## Cross-Persona Acceptance Gates

### Trust gate
- The experience must show enough confidence, lineage, freshness, or explanation to support action.
- Insight without trust is not acceptable.

### Action gate
- The experience must enable a concrete next step in workflow.
- Visibility without action is not acceptable.

### Compression gate
- The user must not need to manually reconstruct the situation from several disconnected screens.
- Multi-screen assembly may be tolerable for admin diagnosis, but not for persona acceptance.

### Outcome gate
- The reviewer must be able to state the business decision improved by the experience.
- If the only conclusion is "the integration works," acceptance has not been met.

## What Does Not Count As Acceptance
- Field existence by itself
- DMO mapping completeness by itself
- a healthy data stream by itself
- a rendered LWC by itself
- non-null values by themselves
- a screenshot of a page without a decision/usefulness narrative

## UX Review Method

### Recommended order
1. Validate backend/runtime proof first.
2. Run persona walkthroughs using live records and real scenarios.
3. Score the experience against business value drivers, not component presence.
4. Record UX issues as business-friction findings, not cosmetic-only observations.

### Review format
For each persona walkthrough, capture:
- scenario
- user question
- Pulse360 evidence shown
- decision made
- expected business value
- metric expected to move
- baseline comparator
- friction observed
- accept / conditional accept / reject

## Suggested Acceptance Scorecard

Use this scale for each persona:

- `Accept`
  - user can make the intended decision with confidence and take action in one workflow
- `Conditional Accept`
  - user can make the decision, but important friction still reduces trust, speed, or adoption
- `Reject`
  - user still cannot make or defend the intended decision without substantial manual reconstruction

## Current Recommended Milestone Framing

### Milestone C
Acceptance should focus on:
- trusted source-to-DMO value flow
- scalar CRM field realization through `Copy Field Enrichment`
- proof that seller-facing account intelligence is not only synced but usable

### Milestone D
Acceptance should focus on:
- governance-review usability for `Data Operations`
- whether the stewardship surface reduces decision risk and cycle time
- whether the Account page and related components create an action-ready seller/planner experience rather than a field dump

## Decision Rule
Pulse360 should be considered accepted only when:
- the steward workflow improves decision safety and speed
- the seller workflow improves prioritization and next-step clarity
- the planner workflow improves group-level coverage or whitespace judgment

If the system is technically healthy but does not improve one of those behaviors, it is not yet acceptable from a business perspective.
