# Pulse360 Surface-Driven Contract Requirements

## Purpose

This document captures the contract and payload requirements implied by the UX specification.

It is intentionally pre-schema. These are requirements for contract design, not final schemas.

## Principles

- surface needs define payload scope
- typed actions are primary, narrative is supportive
- summary, evidence, and action should be separable
- CRM-safe execution keys remain mandatory
- provenance, freshness, and confidence must travel with the surfaced insight

## Interface Families

### `planner_portfolio_payload`

Purpose:
- support ranking, filtering, coverage inspection, and planning actions at altitude 2

Required capabilities:
- group identifier and CRM-safe binding
- tier and segment context
- group value summary
- coverage gap summary
- ICP and risk comparators
- planning action candidates
- freshness and confidence summary

### `whitespace_payload`

Purpose:
- support entity-by-solution whitespace views and ranked expansion actions

Required capabilities:
- target entity
- target record id where known
- solution family
- coverage status
- estimated impact
- why-now summary
- supporting evidence refs

### `buying_committee_payload`

Purpose:
- support missing-stakeholder visibility and follow-up actions

Required capabilities:
- role model or committee template
- known stakeholders
- missing stakeholders
- engagement state
- recommended outreach targets
- confidence and freshness summary

### `intent_signal_payload`

Purpose:
- support routed alerts and SDR queue decisions

Required capabilities:
- routing owner and territory
- threshold-crossing reason
- top intent or engagement drivers
- target contacts
- drafted outreach or message preview
- alert freshness and routing confidence

### `renewal_risk_payload`

Purpose:
- support risk interpretation and save-motion planning

Required capabilities:
- risk level and trend
- top drivers
- driver evidence refs
- recommended intervention
- owner and time horizon
- freshness by signal family

### `action_pack_payload`

Purpose:
- provide the typed action contract that all surfaces can execute against

Minimum fields:
- `target_entity`
- `target_record_id`
- `recommended_play`
- `action_type`
- `owner_route`
- `why_now`
- `estimated_impact`
- `confidence`
- `evidence_refs`
- `prompt_version`
- `model_version`
- `enrichment_run_id`

## Shared Payload Expectations

Every surfaced recommendation should carry:

- user-readable summary
- typed action intent
- evidence references
- confidence signal
- freshness signal
- uncertainty or missing-context signal
- CRM-safe binding when execution inside Salesforce is possible

## Service And Integration Implications

### Databricks

Must provide:
- full-graph and model outputs
- weighted summaries suitable for altitude 2 and altitude 3 projection
- explanation and lineage artifacts addressable by downstream surfaces

### Data Cloud

Must provide:
- operationally curated profile layer
- Calculated Insights and unified object mapping
- selective realization to CRM
- drill-through linkage back to richer context

### Salesforce And Slack

Must provide:
- execution-ready surface actions
- context-preserving drill-through
- visible provenance and freshness
- channel-appropriate rendering of the same action contract

### Agentforce / Atlas / BYOM

Must provide:
- reusable reasoning across channels
- typed outputs alongside narrative
- citations and guardrails visible enough for trust

## Explicit Non-Requirements At This Stage

- final JSON schema shapes
- field-level storage mapping
- Apex or Flow ownership split
- exact DMO and DLO layout

Those decisions should follow the validated UX, not precede it.
