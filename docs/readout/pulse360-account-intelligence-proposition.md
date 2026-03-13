# Pulse360 Account Intelligence Proposition

## Vision
Pulse360 is an Account Intelligence solution that helps teams understand who an account really is, how it connects to the wider business, what is happening commercially, how much they should trust that view, and what they should do next.

It combines Databricks and Salesforce in a deliberate way:
- Databricks creates trusted, explainable enterprise account intelligence from fragmented operational, commercial, and stewardship-relevant data.
- Salesforce Data Cloud and CRM operationalize that intelligence into a CRM-centered account data foundation, workflow, and action.

The goal is not better dashboards alone. The goal is better account decisions.

## Market Context
Enterprise account management is constrained by four recurring problems:
- fragmented and conflicting account records across systems
- weak visibility into parent-child and group relationships
- slow manual stewardship and governance resolution
- poor conversion of account signals into timely commercial action

Most organizations do not suffer from a lack of data. They suffer from a lack of trusted, connected, and actionable account understanding.

## Product Thesis
Pulse360 creates value by turning fragmented account data into trusted account understanding, and then turning that understanding into action inside the systems where teams already work.

The product should enable users to answer five questions faster and with more confidence:
- who is this account really
- how is it connected to the wider group
- what is happening commercially
- how much should I trust this view
- what should I do next

## Proposition Pillars

### 1. Account Truth
Pulse360 establishes a trusted account foundation by resolving duplicates, preserving CRM-safe identity, and exposing group structure across parents, subsidiaries, brands, and related entities.

Outcome:
- teams work from a business entity view, not disconnected rows

### 2. Account Intelligence
Pulse360 generates relevant signals from account, contact, opportunity, product, and relationship data to identify health, momentum, whitespace, risk, coverage gaps, and stewardship issues.

Outcome:
- users see commercially meaningful patterns, not just raw attributes

### 3. Account Trust
Pulse360 attaches confidence, validity, traceability, and explanation to scores, matches, and recommendations so users can understand why the system is making a claim.

Outcome:
- insights are usable because they are interpretable and defensible

### 4. Account Action
Pulse360 embeds intelligence into stewardship, selling, and planning workflows through Data Cloud activation, Salesforce experiences, and guided next actions.

Outcome:
- insight changes behavior instead of remaining passive analytics

## Why Databricks and Salesforce Together

### Databricks Role
Databricks is the enterprise stewardship intelligence layer.
It should:
- ingest and normalize messy operational and commercial data from CRM and other trusted enterprise sources
- incorporate third-party reference data where it materially improves entity resolution, hierarchy, or firmographic trust
- optionally use external models or LLM-assisted methods only as bounded decision support, never as an untraceable authority
- resolve entity identity and hierarchy signals
- compute confidence, enrichment, validity, and explanation outputs
- maintain lineage, run metadata, source provenance, and governed transformation logic

Databricks should not make final stewardship decisions autonomously. It should produce a defensible evidence package that enables enterprise data stewardship.

### Data Cloud Role
Salesforce Data Cloud is the CRM-centered operational intelligence layer.
It should:
- unify Pulse360 account intelligence into a CRM-usable account and relationship model
- act as the modern CRM-centric data foundation that links canonical account context, extension intelligence, and activation
- preserve the account-safe payloads needed for Account 360, stewardship workflow, and downstream recompute
- make trusted intelligence operationally available to Salesforce UX, automation, and Agentforce
- provide the activation and refresh path between intelligence outputs and transactional workflow

### Salesforce Role
Salesforce is the transactional workflow and action layer.
It should:
- maintain the operational source-of-truth context for day-to-day CRM execution
- surface intelligence in CRM, workflow, and Agentforce experiences
- capture stewardship decisions, sales actions, and planner follow-through as governed transactions
- convert trusted intelligence into guided user action

### Combined Advantage
The innovation is not the presence of both platforms. It is the combination:
- Databricks provides enterprise-grade account understanding and stewardship evidence
- Data Cloud turns that into a CRM-centered operational account foundation
- Salesforce turns that foundation into transactional decisions and action

This is what makes Pulse360 more than an integration pattern.

## Primary User Moments

### Stewardship Moment
A steward sees that several records likely represent the same business entity.
Pulse360 shows duplicate confidence, conflicting attributes, hierarchy implications, and evidence so the steward can resolve the issue quickly and defensibly.

### Seller Moment
A seller opens an account and sees group context, whitespace, engagement change, and a credible next action.
Pulse360 explains why the signal matters and what to do now.

### Planner Moment
A portfolio or account leader sees group-wide revenue context, uncovered subsidiaries, and risk or expansion patterns across the hierarchy.
Pulse360 helps prioritize effort at group level rather than account-by-account.

## Highest-Value Capabilities
- trusted account graph across duplicates and hierarchies
- confidence-backed health, risk, and opportunity signals
- explainable duplicate, hierarchy, and enrichment evidence
- intelligence-to-action mapping for seller and steward workflows
- group-level commercial visibility for whitespace and coverage planning

## What Will Move the Needle
The solution should improve outcomes in four measurable ways:
- faster stewardship resolution
- better account planning and prioritization
- stronger cross-sell and expansion visibility
- reduced manual effort to establish account truth

If Pulse360 does not improve decision quality or decision speed, it is not delivering enough value.

## Blind Spots To Avoid
- score-heavy outputs with weak business meaning
- technically elegant signals that do not change user behavior
- dashboards that summarize but do not guide action
- activation of low-trust intelligence
- hierarchy or duplicate logic that is technically correct but commercially unhelpful
- product claims that emphasize platform plumbing over business value

## Design Principles
- preserve CRM-safe identity end to end
- favor explainability over opaque scoring
- build for group-level account understanding, not single-record enrichment only
- prioritize actions over passive visibility
- keep lineage and confidence visible for any insight that affects workflow
- reject features that are clever but not operationally useful

## Product Test
Pulse360 should be considered successful when a user can see:
- a more accurate account truth
- a more relevant commercial or governance insight
- a clear explanation of why it matters
- an obvious next action in workflow

If those four conditions are not met, the product still needs refinement.

## Next Artifact
The next-phase delivery definition for the stewardship, seller, and planner slices is captured in [pulse360-product-slice-definition.md](/Users/danielnortje/Documents/Pulse360/docs/readout/pulse360-product-slice-definition.md).

That artifact identifies the first real execution slice, the minimum capability set, and the first execution plan needed to move from proposition to product delivery.
