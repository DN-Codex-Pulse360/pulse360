# Seller External Benchmark And Design Gap Analysis - 2026-04-14

## Purpose
Refine the seller-surface critique against:
- the original Pulse360 vision
- current official Salesforce and Databricks thinking
- leading market examples in adjacent account-intelligence and revenue-intelligence tooling

This document is intentionally critical.
The goal is not to defend the current screen.
The goal is to identify what would make Pulse360 genuinely buyable and differentiated.

## Executive Summary
The current Pulse360 seller surface is directionally right but strategically incomplete.

It proves:
- hidden group revenue exists
- CRM coverage is incomplete
- the recommendation is grounded in cited public evidence

It does not yet prove:
- who the seller should pursue
- which buying group is incomplete
- which product or play is the whitespace
- why this is the best action now versus other actions
- how the seller can move directly from insight to a decision-ready action package

Against the original vision, the current screen is strongest on `Account Truth` and parts of `Account Trust`, but weakest on `Account Action`.

Against current Salesforce, Databricks, and leading market patterns, the largest gaps are:
- missing operable hierarchy and relationship mapping
- weak buying-group and contact-whitespace logic
- insufficient engagement tracking and recency logic
- generic action packaging
- prompt design that summarizes but does not orchestrate a differentiated revenue move

## 1. What The Original Pulse360 Vision Actually Promised

The original proposition said Pulse360 should help a seller answer five questions faster:
- who is this account really
- how is it connected to the wider group
- what is happening commercially
- how much should I trust this view
- what should I do next

Source:
- [Pulse360 Account Intelligence Proposition](/Users/danielnortje/Documents/Pulse360/docs/readout/pulse360-account-intelligence-proposition.md#L21)

The seller slice narrowed that further:
- not a dashboard full of metrics
- a small set of credible signals
- tied to a next action on the current account or group

Source:
- [Pulse360 Product Slice Definition](/Users/danielnortje/Documents/Pulse360/docs/readout/pulse360-product-slice-definition.md#L89)

The original Philippines DS-03 vision was even more specific:
- a normal-looking account before state
- Databricks hierarchy evidence
- Data Cloud group revenue truth
- Agentforce "Show Group View"
- hierarchy expansion
- a subsidiary-specific opportunity suggestion
- opportunity creation in `30 seconds`
- portfolio view updating afterward

Source:
- [/Users/danielnortje/Desktop/philippines-s4-intelligence-brief 1.html](/Users/danielnortje/Desktop/philippines-s4-intelligence-brief%201.html#L1397)

This matters because it means the benchmark is not "does the page show AI cards?"
The benchmark is "does the seller reach a credible next move on a group opportunity faster than with CRM alone?"

## 2. What Salesforce Is Signaling As Leading Practice

### 2.1 Salesforce is treating account management as a data-plus-action workflow, not a summary page
Salesforce's account management guidance emphasizes a single source of truth with:
- customer and contact profiles
- communication history
- support context
- relationship maps
- account health insights
- alerts
- automation

Source:
- [Salesforce - What is Account Management Software?](https://www.salesforce.com/sales/account-management/software/)

Implication for Pulse360:
- relationship maps and communication history are not optional polish
- they are table stakes for a believable account-management experience

### 2.2 Salesforce is explicitly tying agentic selling to activity capture, notes, plans, and Data Cloud
The recent Agentforce account-management implementation guidance calls out:
- `Data Cloud`
- `Salesforce Notes`
- `Einstein Conversation Insights`
- `Einstein Activity Capture`
- `Account Plans`

as relevant or recommended inputs for account-management agents.

Source:
- [Agentforce for Sales: Account Management Implementation Guide](https://www.salesforce.com/en-us/wp-content/uploads/sites/4/documents/Sales/Agentforce-for-Sales-Account-Management_-Implementation-Guide.pdf)
- [Search result excerpt captured on 2026-04-14](https://www.salesforce.com/en-us/wp-content/uploads/sites/4/documents/Sales/Agentforce-for-Sales-Account-Management_-Implementation-Guide.pdf)

Implication for Pulse360:
- if we do not capture emails, meetings, notes, plans, and conversation context, our "agentic" layer is under-grounded compared with Salesforce's own design posture

### 2.3 Salesforce's current AI sales guidance is explicit about prompt customization
The Agentforce quick-start materials emphasize:
- giving agents trusted data and files
- customizing personas and industry prompts
- adding specific data points for personalization
- versioning and testing prompts

Source:
- [Agentforce Sales Quick Start Guide](https://www.salesforce.com/en-us/wp-content/uploads/sites/4/documents/guides/SC-Agentforce-QuickStartGuide-Asset.pdf)

Implication for Pulse360:
- prompt differentiation is not only about tone
- it should encode persona, industry, product, evidence, and action policy
- the current one-line narrative plus generic CTA is below that bar

### 2.4 Salesforce also sees hierarchy and customer coverage as planning primitives
Sales Planning materials emphasize:
- segment and hierarchy design
- customer-coverage optimization
- connected CRM data
- planning activity tracking

Source:
- [Sales Planning Datasheet](https://www.salesforce.com/en-us/wp-content/uploads/sites/4/documents/datasheets/sales-planning-datasheet.pdf)

Implication for Pulse360:
- hierarchy should not stop at "group revenue reveal"
- it should feed coverage decisions, planning views, and portfolio prioritization

## 3. What Databricks Is Signaling As Leading Practice

### 3.1 Databricks is moving from customer 360 data stores to entity management frameworks
Recent Databricks customer-360 examples describe the evolution from a simple profile store to an entity management framework that supports multiple downstream use cases.

Source:
- [DoorDash Customer 360 Data Store and its Evolution to Become an Entity Management Framework](https://www.databricks.com/dataaisummit/session/doordash-customer-360-data-store-and-its-evolution-become-entity)

Implication for Pulse360:
- the hierarchy graph should not be treated as a background enrichment artifact
- it should be a first-class operational model that powers sales, planning, and governance surfaces

### 3.2 Databricks is explicitly framing the future as a customer-360 plus agentic decision engine
Recent financial services messaging from Databricks describes a future state with:
- cross-business-unit customer standardization
- advanced identity resolution and linking
- agent-based decisioning
- low-latency serving for operational use cases

Source:
- [Building a Financial Services Customer 360 and Agentic Decision Engine on Databricks](https://www.databricks.com/dataaisummit/session/building-financial-services-customer-360-and-agentic-decision-engine)

Implication for Pulse360:
- simply syncing fields into Salesforce is not the end-state
- the end-state is decisioning on top of a trusted party / account graph

### 3.3 Databricks is treating agent quality and observability as part of the product, not an afterthought
Databricks MLflow 3 for GenAI emphasizes:
- tracking
- evaluation
- observability
- human feedback
- versioning
- governance through Unity Catalog

Source:
- [MLflow 3 for GenAI](https://docs.databricks.com/aws/en/mlflow3/genai)

Implication for Pulse360:
- prompt quality and action quality should be evaluated explicitly
- a seller-facing agent without outcome-level evaluation is not leading practice

## 4. What Leading Market Examples Show

These are vendor examples, not neutral proof of business outcomes.
They are still useful because they show what buyers increasingly expect as table stakes.

### 4.1 6sense: actions plus engagement / reach plus persona coverage
6sense's company-details experience includes:
- recommended actions
- engagement and reach activity timelines
- buying-stage overlays
- persona maps
- engaged / not engaged / not reached contact states

Source:
- [6sense Company Details Pages](https://support.6sense.com/docs/company-details-pages-in-6sense-sales-intelligence)

Why this matters:
- 6sense does not stop at "this account looks interesting"
- it tries to show who is engaging, who has not been reached, and what to do next

### 4.2 Demandbase: buying-group prioritization, persona coverage, and recommended members
Demandbase's current buying-group view shows:
- which buying groups to prioritize
- persona coverage percentage
- confirmed member engagement
- recommended buying members

Source:
- [Demandbase Top Buying Groups](https://support.demandbase.com/hc/en-us/articles/29668362525083-Understanding-Top-Buying-Groups)
- [Demandbase Buying Groups](https://www.demandbase.com/products/buying-groups/)

Why this matters:
- the modern whitespace problem is not only "which account?"
- it is "which buying group inside the account is incomplete, active, or under-covered?"

### 4.3 Gong: account timeline, interaction history, AI Q&A, and meeting prep
Gong's account experience includes:
- a timeline of calls, emails, CRM updates, and engagement events
- an activity feed
- AI account questions
- AI meeting prep
- direct compose / outreach actions from the account view

Source:
- [Gong Account Activity Page](https://help.gong.io/docs/track-activity-with-the-accountpage)

Why this matters:
- engagement context is a major part of seller trust and prioritization
- Pulse360 currently has almost none of this in the seller surface

### 4.4 Altify: relationship maps are about influence and next steps, not just org charts
Altify positions relationship mapping as:
- more than an org chart
- visualized influence and relationships
- explicit next steps to improve those relationships

Source:
- [Altify Relationship Mapping](https://altify.com/relationship-map/)

Why this matters:
- a hierarchy tree alone is not enough
- sellers need stakeholder and influence context to act on whitespace

## 5. Refined Critique Of The Current Pulse360 Seller Surface

## What is already strong
- Hidden group value is visible.
- Coverage insufficiency is visible.
- Public evidence and citations are visible.
- Provenance concepts such as model, prompt, citations, and generated date are visible.

This is better than most generic CRM-enrichment screens.

## What is missing against the original vision and benchmark

### 5.1 The hierarchy is numerically present, but operationally absent
The screen says:
- `known group entities = 4`
- `CRM group coverage = 1 of 4`

But the seller cannot work the hierarchy.
There is no trustworthy expandable group model on the page.
The standard Salesforce hierarchy view is effectively empty.

This misses both the original DS-03 vision and the benchmark from Salesforce planning + Altify-style relationship thinking.

### 5.2 The CTA is still generic
`Create Opportunity` is not enough.

A seller needs:
- which entity to pursue
- which play or product family
- why this play now
- who the likely stakeholders are
- what evidence justifies the action
- what the opportunity should be called or scoped as

Without that, the system is still asking the seller to perform the commercial reasoning themselves.

### 5.3 The agentic layer is more summarization than orchestration
The current experience has:
- narrative
- citations
- one recommendation

It does not yet:
- assemble a buying-group or contact gap
- recommend the target subsidiary visually
- create a structured action package
- route to a specialist
- prepare an outreach or meeting brief automatically

So the product is AI-assisted, but not yet convincingly agentic.

### 5.4 Engagement is almost entirely absent
Compared with 6sense, Demandbase, and Gong, the current seller surface lacks:
- engagement recency by person or buying group
- seller reach versus buyer engagement distinction
- activity timelines
- meeting / call / email context
- contact whitespace
- persona coverage

This is a major gap because whitespace prioritization is much stronger when paired with engagement state.

### 5.5 The score layer is not carrying enough of the decision
The narrative and revenue gap currently do more work than:
- health score
- propensity
- confidence

That means the scoring is not yet well-expressed for the seller job.
If the seller trusts the narrative but ignores the scores, the score layer is not yet doing its job.

### 5.6 Trust is undermined by consistency problems
Any stale or mismatched card content on the account page is a serious trust issue.
If the seller sees account content that does not belong to the current account, the credibility of the whole surface drops sharply.

## 6. Design Gaps To Address

### 6.1 Yes, product configuration in Salesforce should be defined much better for whitespace analysis
Whitespace cannot be meaningfully actioned without a clear product / solution model.

At minimum Pulse360 needs:
- a canonical solution or product-family taxonomy
- mapping from opportunities and existing products to those solution families
- a way to distinguish:
  - already sold
  - active but under-deployed
  - whitespace
  - irrelevant
- play definitions tied to product families, industries, and buying-group personas

Without this, "Create Opportunity" will remain generic.

Recommended design move:
- define a `solution family` layer in Salesforce, whether via standard product model, custom metadata, or a custom object
- create a group-by-product coverage matrix so whitespace is computed as:
  - `entity x product family x coverage status x evidence x recommended play`

### 6.2 Engagement tracking needs to become a first-class input
Leading practice strongly suggests that seller-facing recommendations should be grounded in:
- email and meeting capture
- note capture
- conversation summaries or transcripts
- website / form / campaign / event engagement
- recency windows
- account-team reach versus buyer engagement

Recommended design move:
- enable or standardize:
  - `Einstein Activity Capture`
  - `Salesforce Notes`
  - `Einstein Conversation Insights` or equivalent conversation layer
  - marketing / web / event engagement into Data Cloud where possible
- build group-aware engagement views:
  - current-account engagement
  - group-level engagement
  - buying-group engagement
  - not reached versus engaged contacts

### 6.3 Pulse360 needs a real relationship / buying-group model in the seller UX
To be buyable, the seller surface should move beyond account facts and show:
- group hierarchy
- stakeholder map
- known contacts
- missing personas
- recommended people to add or engage
- influence and owner context

Recommended design move:
- create a dedicated seller relationship workspace:
  - legal-entity hierarchy on the left
  - buying-group / relationship map on the right
  - recommended play panel below

### 6.4 Agentic prompts are not yet innovative enough
Current prompt behavior is useful, but not differentiated.

Today it mainly does:
- summarize evidence
- name a possible action

Leading prompt behavior should do more:
- identify target entity
- identify missing buying-group roles
- state the likely play
- explain why this play now
- attach evidence
- suggest outreach objective
- prefill the CRM action
- state what information is still missing

Recommended prompt design move:
- separate prompt families by job:
  - seller whitespace discovery
  - seller meeting prep
  - seller action pack creation
  - planner coverage review
  - steward evidence review
- output structured fields, not only prose:
  - `target_entity`
  - `recommended_play`
  - `buying_group_gap`
  - `next_meeting_goal`
  - `specialist_route`
  - `evidence_summary`
  - `freshness_risk`
  - `confidence_reason`

### 6.5 Prompt evaluation should be treated as a product capability
If Databricks and Salesforce are both pushing toward prompt and agent governance, Pulse360 should not treat prompt text as an unmanaged asset.

Recommended design move:
- version prompts explicitly
- evaluate outputs for:
  - action specificity
  - evidence grounding
  - hallucination risk
  - seller usefulness
  - false-positive action risk
- incorporate human feedback from walkthroughs and pilots

## 7. What Would Be Truly Differentiated

Pulse360 becomes genuinely differentiated when it acts like a `group-aware revenue operating system`, not a CRM page with AI summaries.

That means the seller can do all of this in one experience:
- see the full commercial group
- see where coverage is missing
- see which buying group or subsidiary is most actionable
- understand the recommended play
- trust the evidence and freshness
- create the right action with the right context attached

Most tools in market are strong in one or two areas:
- account intent
- activity intelligence
- relationship mapping
- conversation intelligence

Pulse360 can differentiate if it combines:
- legal-entity-aware group truth
- Data Cloud operationalization
- seller-visible provenance
- buying-group and product whitespace logic
- action packaging inside Salesforce

## 8. Commercial Verdict

### Would a customer buy the current seller experience?
Not yet as a finished seller solution.

### Would a customer buy the direction?
Yes, potentially strongly, because the underlying problem is real and under-served:
- fragmented multi-BU account truth
- invisible group whitespace
- AI underperformance caused by poor data foundations

### What must be true before the seller surface becomes buyable?
- hierarchy is visible and operable
- whitespace is defined by product / play, not just revenue gap
- engagement and buying-group context are visible
- agentic recommendations become decision-ready action packages
- trust issues and stale content are eliminated

## External Sources
- Salesforce: [What is Account Management Software?](https://www.salesforce.com/sales/account-management/software/)
- Salesforce: [Sales Planning Datasheet](https://www.salesforce.com/en-us/wp-content/uploads/sites/4/documents/datasheets/sales-planning-datasheet.pdf)
- Salesforce: [Agentforce for Sales: Account Management Implementation Guide](https://www.salesforce.com/en-us/wp-content/uploads/sites/4/documents/Sales/Agentforce-for-Sales-Account-Management_-Implementation-Guide.pdf)
- Salesforce: [Agentforce Sales Quick Start Guide](https://www.salesforce.com/en-us/wp-content/uploads/sites/4/documents/guides/SC-Agentforce-QuickStartGuide-Asset.pdf)
- Databricks: [DoorDash Customer 360 Data Store and its Evolution to Become an Entity Management Framework](https://www.databricks.com/dataaisummit/session/doordash-customer-360-data-store-and-its-evolution-become-entity)
- Databricks: [Building a Financial Services Customer 360 and Agentic Decision Engine on Databricks](https://www.databricks.com/dataaisummit/session/building-financial-services-customer-360-and-agentic-decision-engine)
- Databricks: [MLflow 3 for GenAI](https://docs.databricks.com/aws/en/mlflow3/genai)
- 6sense: [Company Details Pages in 6sense Sales Intelligence](https://support.6sense.com/docs/company-details-pages-in-6sense-sales-intelligence)
- Demandbase: [Buying Groups](https://www.demandbase.com/products/buying-groups/)
- Demandbase: [Understanding Top Buying Groups](https://support.demandbase.com/hc/en-us/articles/29668362525083-Understanding-Top-Buying-Groups)
- Gong: [Track activity with the account page](https://help.gong.io/docs/track-activity-with-the-accountpage)
- Altify: [Relationship Mapping Software for Salesforce](https://altify.com/relationship-map/)
