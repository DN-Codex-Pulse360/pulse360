# Seller Experience Build Roadmap

Date: 2026-04-14
Owner: Product / Salesforce Experience / Data Intelligence
Scope: Seller-facing Pulse360 Account experience, whitespace model, engagement model, and agentic action packaging

## Summary

The current seller surface proves hidden group value, coverage insufficiency, and evidence-backed recommendations.
It does not yet deliver a buyable seller workflow.

The core gap is not raw data.
The gap is translation from group-aware intelligence into a trusted, specific, executable revenue action.

This roadmap turns the seller critique and external benchmark into build-ready workstreams.

Source inputs:
- [Pulse360 Account Intelligence Proposition](/Users/danielnortje/Documents/Pulse360/docs/readout/pulse360-account-intelligence-proposition.md)
- [Pulse360 Product Slice Definition](/Users/danielnortje/Documents/Pulse360/docs/readout/pulse360-product-slice-definition.md)
- [Seller Human Walkthrough Guide](/Users/danielnortje/Documents/Pulse360/docs/qa/seller-human-walkthrough-guide.md)
- [Seller External Benchmark And Design Gap Analysis - 2026-04-14](/Users/danielnortje/Documents/Pulse360/docs/qa/seller-external-benchmark-and-design-gap-analysis-2026-04-14.md)

## Target Outcome

Pulse360 should behave like a `group-aware revenue action console`, not an enriched account record.

For a seller, that means one screen should answer:
- which legal entity or subsidiary should I pursue
- which product or solution play is the whitespace
- which buying-group roles are already engaged or missing
- why should I act now
- what exact CRM action should I take next

## Build Themes

### 1. Replace passive hierarchy signals with an operable group workspace

Problem:
- group revenue and coverage are visible
- the seller still cannot work the hierarchy
- the standard Salesforce hierarchy view does not reflect the commercial group story

Build change:
- replace the current passive revenue-reveal card with a seller workspace that shows:
  - parent account
  - known subsidiaries and related entities
  - covered versus uncovered entities
  - entity-level whitespace and coverage status
  - entity-level evidence and freshness

Recommended implementation shape:
- create or extend a dedicated LWC seller workspace rather than relying on the standard hierarchy page
- support clickable entity selection and context pivoting inside the workspace
- expose the entity graph as a first-class experience payload from Databricks / Data Cloud, not just a numeric rollup

Done when:
- the seller can identify the best target entity without leaving the page
- the hierarchy is actionable, not just descriptive

### 2. Define a canonical solution-family model for whitespace analysis

Problem:
- hidden revenue does not equal actionable whitespace
- the system cannot yet explain which solution or product family is missing or under-deployed

Build change:
- define a canonical `solution family` model in Salesforce and align it with Databricks and Data Cloud outputs
- compute whitespace as a coverage problem, not just a revenue gap

Recommended implementation shape:
- define Salesforce configuration for:
  - `Solution_Family`
  - `Solution_Play`
  - product-to-solution-family mapping
  - industry-to-play guidance
  - persona or buying-role fit
- represent whitespace as:
  - `entity x solution_family x coverage_status x evidence x recommended_play`
- distinguish between:
  - already sold
  - active but under-deployed
  - whitespace
  - not relevant

Possible Salesforce implementation options:
- `Custom Metadata` for solution families, play rules, and mapping logic
- standard Product model where it already fits
- custom object only if coverage state and evidence need to be operationally inspected in CRM

Done when:
- the seller sees a recommended play tied to a target entity and solution family
- `Create Opportunity` is no longer generic

### 3. Add a buying-group and relationship model to the seller experience

Problem:
- a seller needs more than account-level signals
- they need to understand stakeholder coverage, influence, and missing roles

Build change:
- add a relationship and buying-group surface that complements the legal-entity hierarchy

Recommended implementation shape:
- show:
  - known contacts by role or persona
  - missing buying-group roles
  - account owner and specialist context
  - relationship or influence notes where available
- create a seller workspace with:
  - entity hierarchy on one side
  - buying-group or relationship panel on the other
  - recommended play and action pack below

Done when:
- the seller can see who is missing from the buying group and who should be engaged next

### 4. Make engagement tracking a first-class decision input

Problem:
- today the seller surface is mostly blind to momentum
- without recency and engagement state, whitespace prioritization is too static

Build change:
- incorporate current-account, group-level, and buying-group engagement signals into seller prioritization

Recommended implementation shape:
- standardize or enable:
  - `Einstein Activity Capture`
  - `Salesforce Notes`
  - `Einstein Conversation Insights` or equivalent conversation layer
  - marketing, web, form, event, and campaign engagement where available
- roll up seller-facing signals such as:
  - last engagement timestamp
  - engaged versus not reached contacts
  - engagement intensity by entity
  - active versus dormant buying groups
  - account-team reach versus buyer engagement

Done when:
- the seller can distinguish between a large theoretical opportunity and an active commercial window

### 5. Replace generic CTAs with structured action packs

Problem:
- `Create Opportunity` is too broad
- the seller still has to do the commercial reasoning and data entry manually

Build change:
- turn recommendations into structured action packs that can prefill CRM work

Recommended implementation shape:
- every recommendation should include:
  - `target_entity`
  - `recommended_play`
  - `why_now`
  - `suggested_opportunity_name`
  - `suggested_owner_or_specialist_route`
  - `evidence_summary`
  - `expected_value_or_scope`
  - `freshness_and_confidence_context`
- support prefilled:
  - opportunity creation
  - task creation
  - specialist handoff
  - manager review note

Done when:
- a seller can move from account open to a defendable CRM action with minimal manual reconstruction

### 6. Redesign agentic prompts around jobs-to-be-done and structured outputs

Problem:
- current prompts summarize evidence
- they do not yet orchestrate the seller move in a differentiated way

Build change:
- split prompt design by seller job and require structured outputs

Recommended implementation shape:
- define separate prompt families for:
  - seller whitespace discovery
  - seller meeting prep
  - seller action-pack generation
  - planner coverage review
  - steward evidence review
- return structured fields as part of the output:
  - `target_entity`
  - `recommended_play`
  - `buying_group_gap`
  - `outreach_objective`
  - `specialist_route`
  - `evidence_summary`
  - `freshness_risk`
  - `confidence_reason`

Done when:
- the prompt layer materially reduces seller reasoning effort instead of only narrating the answer

### 7. Treat prompt and action quality as a product capability

Problem:
- prompt text and AI actions are still too implicit
- the current experience does not evaluate whether recommendations are useful, grounded, or safe

Build change:
- add prompt versioning, evaluation, and walkthrough feedback into the product loop

Recommended implementation shape:
- evaluate outputs for:
  - action specificity
  - evidence grounding
  - hallucination risk
  - seller usefulness
  - false-positive action risk
- store prompt version and evaluation metadata alongside the generated action pack
- feed seller walkthrough and pilot feedback into prompt revision

Done when:
- recommendation quality can be measured and improved deliberately

### 8. Harden trust and freshness cues

Problem:
- stale or mismatched cards undermine the entire experience
- freshness is visible in places, but not yet a disciplined product feature

Build change:
- enforce account-context correctness, source consistency, and freshness visibility across every seller panel

Recommended implementation shape:
- remove stale or demo-only cards that do not belong to the current account
- show sync recency, generated date, and source provenance consistently
- make evidence links and confidence reasons available wherever action is proposed

Done when:
- the seller can explain why the recommendation is trustworthy without extra coaching

## Suggested Delivery Sequence

### Phase 1. Trust and action foundation
- harden context correctness and freshness
- define solution-family model
- redesign recommendations into structured action packs

### Phase 2. Operable hierarchy and whitespace
- build the entity workspace
- expose entity-level whitespace and coverage state
- support entity-specific opportunity and task creation

### Phase 3. Buying-group and engagement intelligence
- add relationship and persona coverage
- add engagement capture and momentum views
- differentiate prioritization by active versus dormant whitespace

### Phase 4. Agentic differentiation
- split prompts by job
- add structured prompt outputs
- add prompt evaluation and pilot feedback loops

## Validation Standard

The seller experience should not be considered complete unless the human walkthrough proves all of these:
- the seller identifies a specific target entity
- the seller identifies a specific play or solution family
- the seller can explain why now in business language
- the seller can see enough engagement or coverage context to justify prioritization
- the seller can create a defendable CRM action without reconstructing the recommendation manually

Reference walkthrough:
- [Seller Human Walkthrough Guide](/Users/danielnortje/Documents/Pulse360/docs/qa/seller-human-walkthrough-guide.md)

## Commercial Standard

This work is successful when Pulse360 is stronger than a generic enriched CRM page on five fronts:
- group truth
- product whitespace logic
- buying-group context
- engagement-aware prioritization
- action packaging

If it only improves visibility but not action quality, it is still below the bar set by the original proposition.
