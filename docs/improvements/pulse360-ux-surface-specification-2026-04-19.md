# Pulse360 UX Surface Specification

## Purpose

This specification defines the intended user experience before contracts and implementation are finalized.

It converts the target proposition into explicit surface behavior.

## Information Architecture Across Altitudes

### Altitude 3

Audience:
- AE
- SDR
- CSM
- frontline manager

Design rule:
- weighted summary is the default

Must contain:
- top signals
- top recommendation
- visible evidence
- freshness and uncertainty
- one-click action

Must not contain:
- raw graph detail
- long source dumps
- implementation jargon

### Altitude 2

Audience:
- RevOps
- sales leadership
- CS leadership
- analysts using operational context

Design rule:
- comparative operational profile is the default

Must contain:
- ranking
- segmentation
- filtered portfolio views
- coverage and quality comparisons
- drill-through to account-level action context

### Altitude 1

Audience:
- data team
- compliance reviewer
- governance reviewer
- platform services

Design rule:
- full graph and lineage are available, but never forced into primary seller or planner workflows

## Cross-Surface Navigation Model

- every altitude 3 summary opens altitude 2 context when the user wants comparison or explanation depth
- every altitude 2 attribute drills into altitude 1 evidence or lineage when trust needs to be verified
- governance and trust cues should be reachable from every revenue-facing surface
- navigation should preserve the current decision context rather than reset the user into generic records

## Surface Blueprints

### Planner Workspace

Primary persona:
- Sales VP
- CRO
- RevOps Director

Primary promise:
- help leadership rank accounts and coverage by true commercial reality, not fragmented CRM records

Entry points:
- Salesforce app page
- leadership home page
- portfolio review context

Default view:
- ranked group list
- filters for tier, coverage gap, renewal risk, ICP quality, whitespace
- one highlighted planning insight
- one highlighted action queue

Top actions:
- reclassify tier
- flag coverage gap
- assign or reassign owner
- sponsor executive attention
- open affected accounts in context

Drill-through behavior:
- from group list to group profile
- from group profile to account-level workspace
- from account-level workspace back to portfolio context without losing the comparison

Evidence model:
- top reasons behind rank
- group size and coverage summary
- trust badge with freshness

Freshness and uncertainty cues:
- clearly show stale portfolio inputs
- show where hierarchy completeness is partial

### Seller Workspace

Primary persona:
- AE
- relationship manager
- strategic account seller

Primary promise:
- tell the seller what matters now and what to do next before the call or immediately after it

Entry points:
- Account page
- Opportunity page
- seller home rollup

Default view:
- top three things to know
- one-paragraph narrative
- group revenue summary
- top whitespace or committee issue
- top recommended move
- execute-now action row

Top actions:
- create opportunity
- create task
- route specialist
- open buying committee drill-through
- log call outcome

Drill-through behavior:
- recommendation to evidence
- recommendation to group tree
- recommendation to buying committee view
- recommendation to opportunity creation flow

Evidence model:
- three most relevant supporting facts
- why-now summary
- confidence label and freshness

Freshness and uncertainty cues:
- visible sync age
- visible missing coverage or missing stakeholder confidence

### Signal Routing Workspace

Primary persona:
- SDR
- demand gen lead
- front-line sales manager

Primary promise:
- route in-market accounts to the right rep with enough context to act immediately

Entry points:
- Slack alert
- SDR queue in Salesforce
- manager routing dashboard

Default view:
- alert headline
- reason for threshold crossing
- owner and territory
- top contacts to target
- drafted outreach
- send, edit, reject, or reroute actions

Top actions:
- send outreach
- edit outreach
- route to another owner
- snooze or reject alert
- create follow-up task or meeting record

Drill-through behavior:
- alert to account workspace
- alert to full signal breakdown
- alert to territory queue context

Evidence model:
- top sources that caused the alert
- intent, fit, and engagement summary

Freshness and uncertainty cues:
- show when signals are recent versus borderline stale
- show if routing confidence is low

### Renewal And Risk Workspace

Primary persona:
- CSM
- CS leader
- CRO staff

Primary promise:
- explain risk movement early enough for intervention and make the next save action obvious

Entry points:
- Account page
- renewal monitor page
- Slack proactive alert

Default view:
- renewal risk level
- top three drivers
- why risk changed
- recommended save play
- owner and deadline

Top actions:
- create executive outreach
- create save plan
- route specialist or leader
- log intervention outcome

Drill-through behavior:
- risk summary to driver detail
- risk summary to usage, support, and champion-change context
- risk summary to portfolio concentration view

Evidence model:
- driver list with citations
- freshness per driver family
- prior risk baseline for comparison

Freshness and uncertainty cues:
- visible staleness on support, usage, or external data
- clear distinction between signal deterioration and incomplete data

### Governance And Trust Support

Primary persona:
- steward
- reviewer
- revenue user seeking confidence

Primary promise:
- make it easy to validate why the platform believes what it believes

Entry points:
- governance case page
- evidence drill-through from planner, seller, signal, or renewal surfaces

Default view:
- evidence summary
- source contribution
- confidence explanation
- uncertainty and unresolved conflicts

Top actions:
- validate evidence
- open source trail
- escalate steward review

## Shared Experience Rules

- no score without an explanation
- no recommendation without a visible reason
- no action without context
- no high-value workflow should end in "investigate later"
- every surface should separate summary, evidence, and action clearly
- every default view should be presentable to the relevant user without presenter translation

## Visual And Interaction Direction

- one dominant decision per screen
- high-contrast sectioning between summary, evidence, and action
- clear visual treatment for freshness and uncertainty
- comparative data only where the user is making a comparative decision
- typography and spacing should feel deliberate and leadership-ready, not debug-panel-like

## Open Questions To Carry Into Validation

- how much portfolio density leadership users can absorb before the planner workspace feels too busy
- whether seller users prefer a single narrative block or split summary cards
- whether routed alerts need full drafted outreach inline or a shorter preview
- where the renewal workspace should live for daily use: account-first, queue-first, or hybrid
