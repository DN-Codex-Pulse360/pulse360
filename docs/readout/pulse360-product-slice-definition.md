# Pulse360 Product Slice Definition and First Execution Plan

## Purpose
Turn the Pulse360 proposition into three delivery-ready product slices that can drive real execution decisions.

This document keeps the focus on what will change user behavior in the real world, not on abstract positioning or broad implementation planning.

## S4 framing that constrains the slice design
- The current S4 proof points are already anchored in three scenario families: fragmentation discovery, governance resolution, and Account 360 group insight.
- Databricks must produce trusted duplicate, hierarchy, enrichment, and governance evidence with lineage and run metadata.
- Salesforce and Data Cloud must turn those outputs into action in workflow.
- Any slice that cannot show evidence, explanation, and action is incomplete.

## Persona framing
The product slice definition should be expressed in terms that match common B2B Salesforce operating roles.

### Target personas and analogous role descriptions
- `Data Operations`: data steward, MDM analyst, governance analyst, or operations user responsible for account quality, duplicate resolution, and trusted master data.
- `Sales Operations`: revenue operations, territory/planning analyst, or commercial operations user responsible for coverage, prioritization, account segmentation, and pipeline enablement.
- `Key Account Managers`: strategic account manager or account director responsible for growth, retention, and relationship strategy within named or strategic accounts.
- `Sales Specialists`: overlay specialist, product specialist, solution specialist, or industry specialist who helps identify whitespace and pursue specific plays within an account or group.
- `Sales Executives`: sales leader, regional VP, CRO staff, or portfolio owner responsible for group-level prioritization, coverage quality, and growth/risk oversight.

### Persona-to-slice mapping
- `Stewardship slice`: primary persona `Data Operations`; secondary persona `Sales Operations` when account quality affects routing, segmentation, and pipeline hygiene.
- `Seller slice`: primary personas `Key Account Managers` and `Sales Specialists`; secondary persona `Sales Executives` for inspection and coaching.
- `Planner slice`: primary personas `Sales Operations` and `Sales Executives`; secondary persona `Key Account Managers` for account-plan execution.

## Product slices

### Stewardship slice
**User**

Primary persona:
- `Data Operations`

Analogous role:
- data steward, MDM analyst, or governance analyst responsible for resolving duplicate accounts, conflicting attributes, and entity quality issues before they damage selling, planning, and reporting.

Secondary persona:
- `Sales Operations`, because poor account truth directly affects territory design, segmentation, routing, and pipeline quality.

**Pain**

The steward sees multiple records that may represent the same company, but the evidence is spread across systems and manual comparison is slow. Merge decisions are risky because the steward cannot easily prove why records should be joined, which attributes should survive, or how the decision affects hierarchy and downstream activation.

**Insight**

Pulse360 should not just flag likely duplicates. It should present a decision-ready entity resolution case: which records likely belong together, which fields conflict, how strong the match is, how trustworthy the enrichment is, and what hierarchy impact the decision will have.

**Evidence**

- duplicate confidence score with top feature explanations
- CRM-safe account IDs preserved for every candidate pair
- attribute-level validity scores and review-required flags
- side-by-side conflict view for legal name, website, domain, address, parent, and key commercial fields
- hierarchy implications of merge or non-merge
- lineage and run metadata showing where the evidence came from

**Action**

Approve merge, reject merge, or defer for review with a reason and an audit trail. When approved, push the resolution into Salesforce/Data Cloud so the operational record becomes cleaner and future intelligence becomes more trustworthy.

**Measure of value**

- lower median time to duplicate resolution
- higher steward throughput per day
- lower reopened-case rate
- lower share of merged records later reversed
- improved confidence that seller-facing and planning-facing insights are based on the right account

### Seller slice
**User**

Primary personas:
- `Key Account Managers`
- `Sales Specialists`

Analogous roles:
- strategic account manager, account director, overlay specialist, solution specialist, or industry specialist working inside Salesforce on live account, whitespace, and opportunity decisions.

Secondary persona:
- `Sales Executives`, who need the same signal pattern in summary form for inspection and coaching.

**Pain**

The seller has account data, but not account understanding. Group context, whitespace, risk, engagement change, and trustworthiness are fragmented or absent, so prioritization depends on memory and manual digging. Generic scores without explanation are easy to ignore.

**Insight**

Pulse360 should tell the seller what changed and why it matters now. The right seller view is not a dashboard full of metrics. It is a small set of credible signals tied to a next action on the current account or group.

**Evidence**

- group context showing parent, subsidiaries, and rollup exposure
- whitespace or cross-sell signal tied to uncovered subsidiaries, product gaps, or portfolio asymmetry
- change signal such as health movement, inactivity risk, or competitor threat
- confidence and explanation payload showing why the signal is credible
- last-synced timestamp so the seller knows the signal is current enough to act on

**Action**

Prioritize the account, open the related subsidiary or group context, create a follow-up opportunity or task, route a specialist play, or invoke an Agentforce action with the insight payload already attached.

**Measure of value**

- faster time from account open to meaningful next step
- higher conversion of surfaced opportunities into pipeline
- better seller adoption of recommended actions
- reduced time spent assembling account context manually

### Planner slice
**User**

Primary personas:
- `Sales Operations`
- `Sales Executives`

Analogous roles:
- revenue operations lead, territory/planning analyst, regional sales leader, or portfolio owner responsible for coverage, whitespace, and risk across a book of business or group structure.

Secondary persona:
- `Key Account Managers`, who need group-level planning context translated into specific account actions.

**Pain**

Planning usually happens account by account because teams cannot reliably see the commercial group. Subsidiaries are missed, whitespace is hidden, and risk or concentration patterns appear too late. Leaders can see revenue, but not enough trustworthy structure to decide where to place coverage and growth effort.

**Insight**

Pulse360 should turn hierarchy into a commercial planning surface. The value is not only seeing the org tree. The value is seeing which parts of the group are uncovered, underpenetrated, overexposed, or at risk, and what that means for territory and account strategy.

**Evidence**

- stitched entity hierarchy with unlimited-depth rollup support
- group-level revenue and product penetration view
- uncovered subsidiaries and coverage gaps
- concentration, risk, or expansion patterns across the hierarchy
- confidence markers where hierarchy or enrichment remains uncertain

**Action**

Reprioritize account coverage, assign owners to uncovered subsidiaries, focus planning on the parent group instead of isolated records, and target expansion plays where group context shows whitespace.

**Measure of value**

- more complete group coverage
- more whitespace opportunities identified per strategic group
- reduced planning effort to assemble hierarchy context
- better portfolio prioritization quality across top groups

## S4 interpretation through the target personas
- `DS-01 Fragmentation Discovery` matters most to `Data Operations` and `Sales Operations` because it exposes where account truth is weak enough to distort segmentation, routing, and pipeline reporting.
- `DS-02 Governance Case Resolution` is the clearest first slice because it gives `Data Operations` a tight evidence-to-decision loop and gives `Sales Operations` a cleaner commercial operating model downstream.
- `DS-03 Account 360 Moment` matters most to `Key Account Managers`, `Sales Specialists`, and `Sales Executives` because it turns hierarchy and whitespace context into growth, coverage, and risk decisions.

## Which slice should execute first
The first real product slice should be the **stewardship slice**.

### Why stewardship goes first
- It has the clearest action loop: evidence, decision, audit, and measurable outcome.
- It directly exploits the plumbing that is already closest to useful: duplicate detection, firmographic validity, governance metrics, CRM-safe identity, and DS-02 governance flow.
- It creates the trust foundation required by the seller and planner slices. If entity identity and attribute trust are weak, seller recommendations and planner rollups will not be credible.
- It produces value even before the rest of the product is complete because faster, safer account resolution improves CRM quality immediately.
- It gives Pulse360 a defensible differentiator: not just “we found duplicates,” but “we make account truth operationally resolvable with explainable evidence.”

## Minimum capability set for the first slice
The minimum capability set should be the smallest end-to-end loop that makes stewardship measurably better.

### Must have
- CRM-safe account identity preserved from source ingestion through gold outputs and activation contracts
- duplicate candidate pairs with confidence scoring and feature explanations
- attribute-level validity scoring and review-required flags for conflicting firmographics
- hierarchy impact signal for the candidate pair, even if initially shallow
- a steward-facing side-by-side decision surface in Salesforce
- explicit explanation payloads for why the pair was flagged and why certain attributes are trustworthy
- approve, reject, and defer actions with audit trail
- governance metrics showing resolution speed, backlog, and quality trend

### Good enough for first execution
- daily batch refresh rather than real-time resolution
- focused evidence on the top attributes that affect merge confidence and downstream selling
- one strong steward workflow instead of a broad multi-role experience layer

### Not required for first execution
- full seller scoring model
- advanced propensity or health scoring
- complete planner portfolio workspace
- deeply automated merge orchestration beyond the approval and audit loop

## First execution plan

### Objective
Deliver a working stewardship loop that proves Pulse360 can make account truth faster, safer, and more explainable inside operational workflow.

### Workstream 1: lock the stewardship data contract
- Make `crm_account_id` mandatory end to end in the Databricks and Data Cloud contracts.
- Define the stewardship evidence payload for duplicate confidence, top match features, attribute conflicts, validity scores, hierarchy implications, run metadata, and explanation text.
- Treat this as the contract that downstream UI and workflow must consume.
- The execution-ready contract is captured in `docs/contracts/pulse360-stewardship-slice-contract.md`.

### Workstream 2: build the decision-grade intelligence output
- Harden `gold.duplicate_candidate_pairs` so it includes human-usable evidence, not only a score.
- Publish attribute-level validity outputs from firmographic enrichment for the fields a steward must compare.
- Add minimal hierarchy implication markers so a merge decision reflects group consequences.
- Keep lineage, run ID, snapshot ID, and model version visible.
- The implementation-facing Databricks output spec is captured in `docs/contracts/databricks-stewardship-output-spec.md`.

### Workstream 3: operationalize the steward action loop
- Surface the candidate pair and evidence payload in the governance case experience.
- Support approve, reject, and defer actions with reason capture and audit history.
- Ensure the chosen outcome can be reflected back into downstream account truth and activation-safe datasets.

### Workstream 4: prove measurable value
- Track baseline and post-slice median resolution time, case throughput, backlog trend, and reversal rate.
- Prepare 3 to 5 validation cases where the steward can make a faster and more defensible decision than with CRM alone.
- Use those cases as the proof-of-value moments for Milestone B and the readout.

## Backlog implication
This execution order tightens the meaning of the current backlog rather than replacing it.

- `DAN-116` becomes the non-negotiable identity foundation for the stewardship loop.
- `DAN-117` should prioritize the intelligence blueprint elements required for duplicate and validity decision support before broader seller scoring.
- `DAN-118` should define the explainability payload for steward trust first, then extend to seller and planner contexts.
- `DAN-119` should start with governance actions as the strictest test of intelligence-to-action usefulness.
- `DAN-120` should frame the first proof-of-value moment around explainable account truth resolution, not generic scoring.

## What this means for the next slice after stewardship
Once the stewardship loop is working, the next slice should be the **seller slice**, because it can reuse the improved account truth and explanation model to drive revenue-facing action. The planner slice should follow once hierarchy trust and group-level coverage signals are strong enough to support portfolio decisions.

## Practical product test
The first slice is ready when a steward can look at one governance case and immediately answer:

1. Are these records really the same business entity?
2. Which attributes should I trust?
3. What happens to hierarchy and downstream workflow if I act?
4. What is the right decision now?

If Pulse360 cannot answer those four questions inside one workflow, the first slice is still too abstract.
