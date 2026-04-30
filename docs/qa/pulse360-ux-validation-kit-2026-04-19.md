# Pulse360 UX Validation Kit

## Purpose

Use this kit to review the designed experience before implementation scope is locked.

The goal is to validate whether the UX is commercially strong, trustworthy, and fast enough in workflow.

## Validation Method

For each surface and journey:

1. Show the default view with no explanation.
2. Ask the reviewer what matters, why it matters, and what they would do next.
3. Allow drill-through only after the reviewer has interpreted the default state.
4. Capture time to decision, confidence, and trust concerns.
5. Record whether the workflow would be usable in a real meeting, planning session, or queue.

## Review Scenarios

### Scenario 1: Territory And Strategic Account Planning

Persona:
- Sales VP or RevOps Director

Prompt:
- "You are reviewing the quarter's portfolio. Which groups deserve tier escalation, ownership change, or executive attention?"

Pass conditions:
- reviewer can reprioritize at least one group
- reviewer can explain the change using group truth, coverage, or risk
- reviewer does not need spreadsheet reconstruction

### Scenario 2: Account Engagement And Pre-Call Prep

Persona:
- AE or relationship manager

Prompt:
- "You have eight minutes before a customer call. What should you know and what should you do?"

Pass conditions:
- reviewer identifies the top three things quickly
- reviewer can explain the top move without coaching
- reviewer can see which evidence supports the move

### Scenario 3: Prospecting With Intent

Persona:
- SDR

Prompt:
- "An alert just landed. Decide whether to act and what message to send."

Pass conditions:
- reviewer can accept, edit, reject, or reroute decisively
- reviewer understands why the alert fired
- reviewer trusts the routing enough to act

### Scenario 4: Cross-Sell And Expansion Discovery

Persona:
- AE or strategic account seller

Prompt:
- "You are preparing for a QBR and want to find the best expansion move."

Pass conditions:
- reviewer identifies the best target entity or product gap
- reviewer understands estimated impact
- reviewer can create a next action from the same flow

### Scenario 5: Renewal Protection And Save

Persona:
- CSM or CS leader

Prompt:
- "This account's renewal risk increased. What changed and what should happen now?"

Pass conditions:
- reviewer can state the top three drivers
- reviewer can distinguish a real warning from weak evidence
- reviewer can launch an intervention plan

### Scenario 6: Pipeline And Deal Review

Persona:
- RevOps Director or Sales Manager

Prompt:
- "Which deals need reclassification, coaching, or forecast adjustment this week?"

Pass conditions:
- reviewer can identify low-fit or under-covered opportunities
- reviewer can explain the decision in managerial terms
- reviewer can connect portfolio patterns to rep actions

## Review Note Template

Use the following structure during every session:

- reviewer persona
- scenario used
- first thing they noticed
- what they thought the top decision was
- where they hesitated
- what evidence they wanted immediately
- whether the default view felt too dense or too thin
- whether the action felt credible
- time to decision
- confidence score before drill-through
- confidence score after drill-through
- recommended change

## Design Decision Log

### Accepted Patterns

- weighted summary first
- evidence shown before long detail
- one dominant action row per surface
- freshness and uncertainty treated as first-class UX elements
- planner and seller experiences separated rather than merged into one overloaded page

### Rejected Patterns

- field-heavy layouts that require the user to infer the answer
- score-only views without top drivers
- narratives without typed next actions
- account-only design that assumes portfolio and routed-alert flows can follow later
- drill-downs that break the user's decision context

## UX Acceptance Checklist

- the user can identify what matters from the default view
- the user can explain why the recommendation exists
- the user can see whether the recommendation is fresh enough to trust
- the user can act without leaving the workflow
- the surface supports actual review or execution use rather than demo narration

## Decision Thresholds

The UX should not be considered ready for technical lock if:

- reviewers routinely ask where the evidence came from
- users cannot tell the difference between summary and detail
- actions are clear only after presenter explanation
- leadership users say they would rebuild the story in slides or spreadsheets
- seller users say the page is interesting but not action-ready
