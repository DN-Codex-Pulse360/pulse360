# Pulse360 Research-Led UX Realignment Program

## Purpose

This document turns the revised Pulse360 proposition into a concrete program of work that starts with research and UX design before build commitments.

It exists to prevent the next phase from collapsing back into a technically strong but experience-light implementation.

## Source Of Truth

The product target is the revised proposition in [pulse360-revops-value-proposition.html](</Users/danielnortje/Desktop/Huron/AI CoE/Account360/pulse360-revops-value-proposition.html>).

The current build is treated as input and implementation baseline, not as the product definition.

## Artifact Set

- Research assessment: [pulse360-html-proposition-to-ux-research-2026-04-19.md](/Users/danielnortje/Documents/Pulse360/docs/qa/pulse360-html-proposition-to-ux-research-2026-04-19.md)
- UX surface specification: [pulse360-ux-surface-specification-2026-04-19.md](/Users/danielnortje/Documents/Pulse360/docs/improvements/pulse360-ux-surface-specification-2026-04-19.md)
- UX validation kit: [pulse360-ux-validation-kit-2026-04-19.md](/Users/danielnortje/Documents/Pulse360/docs/qa/pulse360-ux-validation-kit-2026-04-19.md)
- Surface-driven contract requirements: [pulse360-surface-driven-contract-requirements-2026-04-19.md](/Users/danielnortje/Documents/Pulse360/docs/contracts/pulse360-surface-driven-contract-requirements-2026-04-19.md)
- UX-derived technical design: [pulse360-technical-design-derived-from-ux-2026-04-19.md](/Users/danielnortje/Documents/Pulse360/docs/improvements/pulse360-technical-design-derived-from-ux-2026-04-19.md)
- Visual blueprint: [pulse360-ux-blueprint-2026-04-19.html](/Users/danielnortje/Documents/Pulse360/docs/improvements/pulse360-ux-blueprint-2026-04-19.html)

## Program Stages

### 1. Proposition-To-UX Research

Objective:
- turn the HTML proposition into an explicit set of user, workflow, trust, and buying hypotheses

Outputs:
- proposition critique by persona
- journey priority stack
- decision-moment inventory
- trust and adoption risk map
- UX success criteria by persona

Exit criteria:
- the team agrees which journeys are essential to commercial credibility
- the team agrees which parts of the HTML are target-state aspiration versus required early experience scope

### 2. Journey And Information-Architecture Design

Objective:
- define how the altitude model becomes actual user flows and surface boundaries

Outputs:
- altitude 1, 2, and 3 information architecture
- cross-surface navigation model
- default versus drill-through rules
- surface ownership by persona

Exit criteria:
- every target journey has a primary entry point, default view, and action destination
- no journey depends on the user reconstructing the answer offline

### 3. Surface-Level UX Design And Validation

Objective:
- design the actual product experience before finalizing contracts or implementation scope

Outputs:
- planner workspace blueprint
- seller workspace blueprint
- signal routing workspace blueprint
- renewal and risk workspace blueprint
- governance and trust support patterns
- visual blueprint and walkthrough scripts

Exit criteria:
- reviewers can identify what matters, why it matters, and what to do next without coaching
- leadership-facing surfaces are strong enough for planning and review use
- seller-facing surfaces are strong enough for daily use without presenter narration

### 4. Technical Design Derived From UX

Objective:
- define contracts, services, and integration boundaries that support the validated experience

Outputs:
- surface-driven payload families
- typed action-pack requirements
- cross-channel reasoning design
- Zero Copy, BYOM, and Atlas dependency mapping
- implementation sequencing

Exit criteria:
- technical design preserves the designed experience instead of redefining it
- unresolved UX-to-technical disagreements are documented explicitly

### 5. Implementation And Tracking Realignment

Objective:
- implement the validated product and align repo work tracking around it

Outputs:
- GitHub and Linear reframed around surfaces and journeys
- contract/schema updates only after UX lock
- implementation backlog grouped by experience and shared service

Exit criteria:
- build progress can be reported in user-facing terms
- acceptance measures decision quality and workflow improvement, not just field sync

## Decision Gates

### Gate A: Proposition Lock

Required to pass:
- the HTML target is accepted as the product north star
- the journey priority stack is agreed

### Gate B: UX Lock

Required to pass:
- the four core surfaces are defined
- default summary, evidence, and action model are validated
- major interaction disagreements are resolved or logged

### Gate C: Technical Lock

Required to pass:
- payload families are defined from surface needs
- channel behavior and service responsibilities are stable

### Gate D: Delivery Lock

Required to pass:
- GitHub and Linear structure reflect the designed product
- implementation sequencing protects UX quality

## Delivery Principles

- weighted summary first
- detail on drill-through
- evidence visible before commitment
- action from the same workflow
- trust and freshness are product features, not metadata leftovers
- technical elegance does not outrank commercial usefulness

## Immediate Use

Use this program artifact set to:

- critique the current build against the proposition
- review target UX before coding
- align future contracts and schemas to surface needs
- structure backlog and delivery reporting around user outcomes
