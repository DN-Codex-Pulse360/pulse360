# Pulse360 Solution Brief Target UX Map

Date: 2026-04-22

## Purpose

This document translates the current north-star brief in [pulse360-revops-value-proposition.html](</Users/danielnortje/Desktop/Huron/AI CoE/Account360/pulse360-revops-value-proposition.html>) into a concrete Salesforce UX map.

The main clarification is simple:

- the brief describes a multi-surface product
- the current Salesforce build contains several partial surfaces
- not every deployed page should be read as "the Pulse360 experience"

The planner confusion came from treating one portfolio tab as if it were the full product.

## Brief Summary

The brief defines Pulse360 as:

- a RevOps intelligence platform anchored on sovereign identity and weighted multi-source enrichment
- delivered across three altitudes of detail
- composed from six modules
- surfaced inside Salesforce, Slack, Data Cloud, and Databricks

The most important UX signals in the brief are:

- `Altitude 3`: Salesforce weighted summary for daily execution users
- `Altitude 2`: portfolio and dashboard view for RevOps and leadership
- `Altitude 1`: full graph and evidence for analysts and governance

Relevant brief anchors:

- [Three altitudes](</Users/danielnortje/Desktop/Huron/AI CoE/Account360/pulse360-revops-value-proposition.html:1271>)
- [Salesforce UX at altitude 3](</Users/danielnortje/Desktop/Huron/AI CoE/Account360/pulse360-revops-value-proposition.html:1302>)
- [RevOps dashboard at altitude 2](</Users/danielnortje/Desktop/Huron/AI CoE/Account360/pulse360-revops-value-proposition.html:1354>)
- [AE account-page experience](</Users/danielnortje/Desktop/Huron/AI CoE/Account360/pulse360-revops-value-proposition.html:1371>)
- [Intent alert in Slack](</Users/danielnortje/Desktop/Huron/AI CoE/Account360/pulse360-revops-value-proposition.html:1388>)
- [Whitespace and renewal journeys](</Users/danielnortje/Desktop/Huron/AI CoE/Account360/pulse360-revops-value-proposition.html:1405>)
- [Home page dashboard and channels](</Users/danielnortje/Desktop/Huron/AI CoE/Account360/pulse360-revops-value-proposition.html:2011>)

## Design Principle

The right mental model is not "one giant Account 360 page."

The right mental model is:

1. a portfolio surface for leadership and RevOps
2. an account execution surface for sellers and CSMs
3. specialist surfaces for routing, renewal, and governance
4. one shared intelligence substrate underneath all of them

## Target UX Map

| Surface | Primary persona | Altitude | Salesforce location | Purpose | Current status |
| --- | --- | --- | --- | --- | --- |
| Pulse360 Portfolio Dashboard | CRO, RevOps Director, Sales VP | 2 | Lightning App Page or Home page | Full-book prioritisation, coverage, whitespace, risk, KPI dashboards | Partially built as planner tab, not yet framed as dashboard |
| Pulse360 Account Workspace | AE, AM, CSM | 3 | Account Record Page | Weighted account summary, top actions, group reveal, committee, citations | Partially built across seller and renewal surfaces, not yet unified |
| Signal Routing Workspace | SDR, BDR, demand / routing ops | 3 | App Page plus Slack | Threshold alerts, drafted outreach, route / edit / reject | Partially built in Salesforce, Slack path still incomplete |
| Renewal and Risk Workspace | CSM, renewal manager, account team | 3 | Account Record Page and App Page | Risk drivers, save plays, renewal chronology, escalation | Built as separate workspace, not yet tightly embedded into Account journey |
| Governance and Trust Workspace | Data steward, governance lead, architect | 1/3 bridge | Governance Case Record Page | Evidence review, merge / reject / defer, lineage-backed trust | Built and deployed |
| Buyer / ROI Dashboard | CRO, COO, sponsor, buyer | 2 | Home / app dashboard | KPI and ROI tracking against baseline | Not built as a named product surface |

## Recommended Salesforce Information Architecture

### 1. Pulse360 Portfolio Dashboard

This should be the Salesforce embodiment of the brief's altitude-2 portfolio view.

Recommended placement:

- Lightning App Page
- optional navigation tab pointing to that App Page

Recommended modules:

- KPI strip
- portfolio segmentation charts
- ranked account / group board
- planning chronology
- action queue

Current implementation footing:

- [pulse360PlannerWorkspace](/Users/danielnortje/Documents/Pulse360/force-app/main/default/lwc/pulse360PlannerWorkspace/pulse360PlannerWorkspace.html:1)
- [pulse360PlannerSummaryPanel](/Users/danielnortje/Documents/Pulse360/force-app/main/default/lwc/pulse360PlannerSummaryPanel/pulse360PlannerSummaryPanel.html:1)
- [pulse360PlannerTimeline](/Users/danielnortje/Documents/Pulse360/force-app/main/default/lwc/pulse360PlannerTimeline/pulse360PlannerTimeline.html:1)

Important note:

The current [Pulse360_Planner.tab-meta.xml](/Users/danielnortje/Documents/Pulse360/force-app/main/default/tabs/Pulse360_Planner.tab-meta.xml:1) points directly to the LWC. That makes the surface usable, but it does not fully express the brief's "dashboard" framing or App Builder configurability.

### 2. Pulse360 Account Workspace

This should be the main altitude-3 daily-user experience. It is the clearest match for the brief's AE and CSM stories.

Recommended placement:

- Account Record Page

Recommended modules:

- weighted account summary
- top three things to know before a call
- group hierarchy / revenue reveal
- next best action
- buying committee surface
- whitespace module
- renewal risk module
- trust / source cue strip

Current implementation footing:

- [pulse360SellerWorkspaceV2](/Users/danielnortje/Documents/Pulse360/force-app/main/default/lwc/pulse360SellerWorkspaceV2/pulse360SellerWorkspaceV2.html:1)
- [pulse360RenewalRiskWorkspace](/Users/danielnortje/Documents/Pulse360/force-app/main/default/lwc/pulse360RenewalRiskWorkspace/pulse360RenewalRiskWorkspace.html:1)
- [Account_Record_Page.flexipage-meta.xml](/Users/danielnortje/Documents/Pulse360/force-app/main/default/flexipages/Account_Record_Page.flexipage-meta.xml:1)

Current problem:

The account-level experience exists in parts, but not yet as one coherent "Pulse360 Account Workspace" matching the brief's account-page language.

### 3. Signal Routing Workspace

This is the SDR / intent execution surface described in the brief.

Recommended placement:

- Salesforce App Page
- Slack alerts as the fast-action channel

Recommended modules:

- threshold-crossing queue
- drafted outreach
- route / accept / edit / reject flow
- owner and territory context
- signal evidence

Current implementation footing:

- [pulse360SignalRoutingWorkspace](/Users/danielnortje/Documents/Pulse360/force-app/main/default/lwc/pulse360SignalRoutingWorkspace/pulse360SignalRoutingWorkspace.html:1)
- [Pulse360SignalRoutingWorkspaceService.cls](/Users/danielnortje/Documents/Pulse360/force-app/main/default/classes/Pulse360SignalRoutingWorkspaceService.cls:1)

Current problem:

The Salesforce side exists, but the brief's Slack-centered execution path is still not complete.

### 4. Renewal and Risk Workspace

This is the CSM / retention surface in the brief.

Recommended placement:

- embedded on Account Record Page
- also available as a dedicated App Page for portfolio review

Recommended modules:

- renewal risk score
- top drivers
- save play recommendations
- timeline of deterioration and interventions
- owner workflow / escalation

Current implementation footing:

- [pulse360RenewalRiskWorkspace](/Users/danielnortje/Documents/Pulse360/force-app/main/default/lwc/pulse360RenewalRiskWorkspace/pulse360RenewalRiskWorkspace.html:1)

Current problem:

The separate workspace exists, but it has not yet been woven into the account-level daily workflow strongly enough to match the brief's renewal journey.

### 5. Governance and Trust Workspace

This is the trust bridge between altitude 1 and the daily-user Salesforce surfaces.

Recommended placement:

- Governance Case Record Page

Recommended modules:

- evidence snapshot
- side-by-side comparison
- decision workspace
- audit outcome

Current implementation footing:

- [governanceCaseReview](/Users/danielnortje/Documents/Pulse360/force-app/main/default/lwc/governanceCaseReview/governanceCaseReview.html:1)
- [Governance_Case_Record_Page.flexipage-meta.xml](/Users/danielnortje/Documents/Pulse360/force-app/main/default/flexipages/Governance_Case_Record_Page.flexipage-meta.xml:1)

Status:

This is the cleanest brief-to-build alignment in the current repo.

## Built vs Missing

### Built or materially underway

- portfolio planner / dashboard direction
- seller workspace direction
- renewal and risk direction
- governance and trust flow
- signal routing base surface
- Account and Governance record-page deployment infrastructure

### Missing or incomplete against the brief

- single named `Pulse360 Account Workspace` on the Account page
- buyer-facing ROI dashboard
- explicit Home page dashboard
- full buying committee surface as a flagship module
- Slack-first intent execution parity
- clear navigation model connecting dashboard -> account -> governance
- stronger altitude labeling across product surfaces

## Naming Map

To align the product language with the brief, the Salesforce surfaces should be named as follows:

| Current name | Recommended product name | Why |
| --- | --- | --- |
| Pulse360 Planner | Pulse360 Portfolio Dashboard | Better matches altitude-2 dashboard language in the brief |
| Pulse360 Seller Workspace V2 | Pulse360 Account Workspace | Better matches the brief's Account-page execution story |
| Pulse360 Renewal Risk Workspace | Pulse360 Renewal & Risk Module | Better positioned as a module inside the account workspace |
| Pulse360 Signal Routing Workspace | Pulse360 Intent Routing Workspace | Closer to the brief's intent-routing framing |
| Governance Case Review | Pulse360 Governance Workspace | Makes its role in the Pulse360 product system more obvious |

## Priority Decisions

### Decision 1: What is the primary daily-user surface?

Recommended answer:

- the Account Record Page should become the primary daily-user Pulse360 surface

Reason:

- the brief repeatedly frames the AE and CSM journey around opening the Account page

### Decision 2: What is the portfolio surface?

Recommended answer:

- the planner should become the Pulse360 Portfolio Dashboard

Reason:

- that is the closest match to the altitude-2 RevOps / CRO dashboard story

### Decision 3: How should configurability be surfaced?

Recommended answer:

- use Lightning App Pages for configurable portfolio views
- use modular record-page components for account-level views

Reason:

- App Builder properties are meaningful on App Pages
- record-specific context belongs on Account pages, not generic tabs

## Recommended Next Build Sequence

1. Create a real `Pulse360 Portfolio Dashboard` Lightning App Page and place [pulse360PlannerWorkspace](/Users/danielnortje/Documents/Pulse360/force-app/main/default/lwc/pulse360PlannerWorkspace/pulse360PlannerWorkspace.html:1) on it so the new App Builder properties are usable.
2. Reframe `Pulse360 Seller Workspace V2` as the true `Pulse360 Account Workspace` and make it the primary Account Record Page experience.
3. Fold renewal and risk into the Account Record Page as a first-class module rather than treating it only as a separate destination.
4. Decide whether buying committee belongs inside the Account Workspace or as a dedicated adjacent module, then build that explicitly.
5. Add buyer / ROI dashboards so the brief's sponsor story exists as product, not only prose.

## Bottom Line

The brief does not describe one page.

It describes a layered product system:

- portfolio dashboard
- account workspace
- routing workspace
- renewal module
- governance workspace

The current build contains meaningful pieces of that system, but the naming, placement, and navigation still make the experience feel more fragmented than the brief intends.

The most important corrective move is to treat the planner as the portfolio dashboard and the Account page as the true center of the daily-user experience.
