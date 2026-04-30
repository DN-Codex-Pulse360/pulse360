# Pulse360 Technical Design Derived From UX

## Purpose

This document translates the validated UX direction into technical design constraints and implementation sequence.

It is not the final implementation spec for every service. It is the design bridge that ensures the build serves the designed experience.

## Design Premise

- the target HTML defines the product proposition
- the UX specification defines how the proposition appears in workflow
- technical design must preserve the UX shape instead of shrinking it to fit current implementation convenience

## Surface-To-Service Model

### Planner Workspace

Primary technical needs:
- comparative portfolio query model
- group-level rollups and filters
- planning action persistence
- drill-through from portfolio context to account context

Service implications:
- a portfolio service is required; account-only retrieval is insufficient
- group ranking logic must be reusable across planner and leadership review surfaces
- planning actions must persist as first-class business artifacts, not presentation notes

### Seller Workspace

Primary technical needs:
- weighted summary projection for altitude 3
- typed action packs
- hierarchy and whitespace drill-through
- evidence and freshness projection

Service implications:
- account context service must separate summary, evidence, and action payloads
- narrative generation cannot be the only integration artifact
- seller action execution must accept typed action context and return created CRM artifacts

### Signal Routing Workspace

Primary technical needs:
- threshold evaluation and owner routing
- message generation
- Slack and Salesforce channel rendering
- action outcome capture

Service implications:
- routing service must expose both queue and alert context
- the same action-pack contract must render in Slack and Salesforce
- outcome capture should feed back into ranking and alert tuning

### Renewal And Risk Workspace

Primary technical needs:
- risk trend calculation
- top-driver explanation
- save-play recommendation
- portfolio concentration view

Service implications:
- risk service must support account and portfolio views
- driver evidence needs stable identifiers that can be cited in multiple channels
- intervention outcomes must be captured as feedback, not just activities

## Payload Design Rules

- altitude 3 surfaces should consume weighted summaries and typed actions, not raw model output
- altitude 2 surfaces should consume comparable operational profiles, not flattened account cards
- altitude 1 remains the source of lineage and full evidence, but should be addressable via drill-through identifiers
- freshness, provenance, and confidence must be carried alongside any surfaced insight

## Cross-Channel Reasoning Design

### Atlas / Agentforce

Must do:
- generate short summaries matched to surface context
- return typed recommended actions alongside narrative
- cite source or evidence references
- respect channel constraints without changing the underlying decision

Must not do:
- return freeform prose as the only actionable output
- hide confidence or freshness behind agent responses
- vary the business conclusion across channels without explicit reason

### BYOM

Must support:
- ICP scoring for planning, seller prioritization, and pipeline review
- propensity and expansion scoring for whitespace
- churn or renewal risk scoring for save workflows

UX constraint:
- any BYOM-served score used in a primary surface must have an explainability path and confidence expression

### Zero Copy And Data Cloud

Must support:
- altitude 2 operational profile depth without copying the full graph into CRM
- selective realization of altitude 3 summary attributes
- stable drill-through from CRM summary to richer Data Cloud or Databricks context

UX constraint:
- the data path must not force the product to expose stale or contextless summary tiles

## Delivery Sequence

### Stage 1: Research And UX Lock

Deliver:
- research assessment
- surface specification
- visual blueprint
- validation kit

Do not finalize:
- schemas
- field mapping expansion
- implementation backlog decomposition

### Stage 2: Technical Lock

Deliver:
- payload family definitions
- service ownership split
- Zero Copy / Data Cloud / CRM realization design
- Atlas and BYOM interaction design

Do not finalize:
- full backlog until UX disagreements are resolved

### Stage 3: Foundation Build

Deliver:
- shared payload contracts
- account and portfolio retrieval services
- evidence and freshness projection
- action-pack execution spine

### Stage 4: Surface Build

Deliver:
- planner workspace
- seller workspace
- signal routing workspace
- renewal and risk workspace

### Stage 5: Validation And Realignment

Deliver:
- journey-based acceptance evidence
- updated contracts and schemas
- GitHub and Linear restructured around surfaces and journeys

## Key Technical Disagreements To Surface Early

### If the implementation tries to preserve account-page centrality

Why it is a problem:
- planner and routed-alert workflows become secondary and weaker than the proposition requires

Expected decision:
- build separate planner and routed-alert experiences as first-class surfaces

### If the implementation tries to rely on narrative fields as the product boundary

Why it is a problem:
- actions, evidence, and channel behavior become inconsistent

Expected decision:
- make typed action packs and evidence references the stable interface

### If the implementation tries to flatten altitude 2 into CRM copy-downs

Why it is a problem:
- the portfolio and comparative UX become shallow and stale

Expected decision:
- keep operational depth in Data Cloud with explicit drill-through and selective CRM realization

### If the implementation tries to postpone Slack and routing behavior

Why it is a problem:
- Journey 3 becomes a future story instead of a designed product workflow

Expected decision:
- design the signal-routing surface and channel behavior now, even if phased implementation follows

## Implementation Success Conditions

- every primary surface is traceable back to a validated user workflow
- every critical score has explanation and freshness support
- every recommendation can result in a concrete business action
- technical decomposition is legible in user-outcome terms, not just platform terms
