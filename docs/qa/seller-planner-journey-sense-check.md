# Seller And Planner Journey Sense Check

## Purpose
Turn the Seller and Planner proposition into a concrete sense-check artifact for live review.

This document is stricter than a UX walkthrough and more operational than the proposition docs.
It is designed to answer:

- does the experience help the user make a better commercial decision
- does it move a buyer-relevant metric
- can we prove that with a realistic baseline-vs-Pulse360 test

Use this together with:
- [persona-business-acceptance-criteria.md](/Users/danielnortje/Documents/Pulse360/docs/qa/persona-business-acceptance-criteria.md)
- [philippines-buyer-acceptance-scorecard.md](/Users/danielnortje/Documents/Pulse360/docs/qa/philippines-buyer-acceptance-scorecard.md)
- [pulse360-account-intelligence-proposition.md](/Users/danielnortje/Documents/Pulse360/docs/readout/pulse360-account-intelligence-proposition.md)
- [pulse360-product-slice-definition.md](/Users/danielnortje/Documents/Pulse360/docs/readout/pulse360-product-slice-definition.md)

## Review Principle
The journey passes only if the user can move from account context to business action without rebuilding the answer in spreadsheets, Slack, or tribal memory.

The journey fails if Pulse360 only makes the page more informative but does not make the next decision easier, faster, or more defensible.

## Test Method
For each journey, run the same scenario twice:

1. Baseline workflow using current CRM context without Pulse360 assistance.
2. Pulse360-assisted workflow using the live account, group, and planning surfaces.

Capture:
- start and end time
- business decision reached
- confidence rating from the user
- whether a CRM or planning action was actually created
- what new information changed the decision

## Seller Journey

### Persona
`Key Account Manager` or `Sales Specialist`

Example from the original proposition:
- James, Regional Sales Manager
- 40 enterprise accounts
- QBR with the CEO next week
- suspects the customer is larger than Salesforce shows but cannot prove it quickly

### Business Value Driver
Pulse360 should help the seller create more pipeline from the same account base by making hidden group revenue, whitespace, and next-best action visible in workflow.

### Buyer Metrics This Journey Should Influence
- time from account open to meaningful next action
- percentage of reviewed accounts with a credible next step
- opportunities or specialist actions created from the review
- visible increase in revenue-understanding at group level
- reduction in manual account research time

### Scenario To Use
Use the `Pacific Capital Singapore` style scenario from the original Philippines brief:
- baseline local-account revenue view: `SGD 820K`
- group truth after hierarchy and Data Cloud aggregation: `SGD 4.2M`
- two uncovered subsidiaries at `SGD 0`
- cross-sell propensity: `78/100`
- health score: `61/100`

### Journey Steps And Acceptance Criteria

#### Step 1. Seller opens the account and establishes the baseline view
What should happen:
- the seller lands on a normal Salesforce account view
- the current-state limit is obvious: BU-local revenue is visible, but group reality is not

Acceptance criteria:
- the reviewer can state what the seller would believe without Pulse360
- the missing business context is commercially meaningful, not cosmetic
- the baseline account looks plausible enough that a real seller could otherwise move on

Evidence to capture:
- screenshot of the baseline account view
- seller estimate of account value before Pulse360
- time spent before the seller decides they need more context

Failure conditions:
- the "before" state already exposes hierarchy and whitespace clearly
- the problem looks artificially broken rather than realistically incomplete

#### Step 2. Seller sees group truth and whitespace in one workflow
What should happen:
- Pulse360 reveals the parent-child structure and group-level commercial context
- the seller can see that the account is part of a larger group with uncovered entities

Acceptance criteria:
- the seller can identify the parent group and affected subsidiaries without leaving the workflow
- the seller can quantify the difference between local-account value and group value
- the whitespace is concrete enough to name at least one target subsidiary or play

Evidence to capture:
- screenshot of the group view
- count of newly visible subsidiaries
- seller statement of what new commercial understanding became visible

Failure conditions:
- hierarchy is shown, but it does not change commercial understanding
- the user still needs manual research to tell which part of the group matters

#### Step 3. Seller understands why the signal matters now
What should happen:
- Pulse360 explains the opportunity in terms the seller can use immediately
- the signal is tied to uncovered revenue, product fit, engagement change, or risk

Acceptance criteria:
- the seller can explain why this account deserves attention now
- the system surfaces at least one commercially specific reason, such as product gap, uncovered subsidiary, or risk trigger
- freshness is visible enough for the seller to trust the signal timing

Evidence to capture:
- screenshot showing the recommendation and freshness cue
- seller explanation of why the prompt is credible
- whether the seller needed verbal help from the presenter to interpret it

Failure conditions:
- the experience shows a score but not the business reason behind it
- freshness or trust markers are missing
- the seller says "interesting" but cannot translate the signal into a near-term action

#### Step 4. Seller chooses a meaningful next action
What should happen:
- the seller can turn the insight into a concrete action inside Salesforce
- the action is tied to the surfaced group opportunity rather than a generic follow-up

Acceptance criteria:
- the seller selects a next action within the review session
- the next action is specific, such as create cross-sell opportunity, route specialist, or engage uncovered subsidiary
- the action is defensible enough that a sales leader would support it in pipeline review

Evidence to capture:
- chosen next action
- time from account open to decision
- seller confidence score before and after Pulse360

Failure conditions:
- the only outcome is "investigate later"
- the seller still has to reconstruct the opportunity manually before acting

#### Step 5. Seller executes the action without leaving the operating system
What should happen:
- the opportunity, task, or specialist action is created in Salesforce
- the group context remains attached to the business action

Acceptance criteria:
- a real CRM artifact is created during the journey
- the created artifact references the commercial context surfaced by Pulse360
- the action takes materially less time than the baseline manual workflow

Evidence to capture:
- screenshot or record ID of the created action
- elapsed time to create it
- any auto-attached context such as contacts, account linkage, or reason

Failure conditions:
- the experience ends with a recommendation only
- the seller has to copy findings into a separate workflow by hand

#### Step 6. Sales leadership can use the same context for portfolio inspection
What should happen:
- the seller journey rolls up into a planning or QBR-ready view
- the same account-level signal can be used by a manager to inspect coverage and opportunity at portfolio level

Acceptance criteria:
- the manager view can show uncovered subsidiaries, opportunity concentration, or risk across the book
- the account-level action is visible as part of a broader commercial pattern
- the seller does not have to build the QBR slide manually from scratch

Evidence to capture:
- screenshot of the portfolio view
- number of accounts with similar uncovered-group patterns
- total surfaced opportunity across the review set

Failure conditions:
- the account-level experience works, but cannot roll into portfolio-level management use
- the manager still needs offline spreadsheet reconstruction

### Seller Journey Pass Rule
The Seller journey passes only if all of the following are true:
- the seller reaches a meaningful next action at least `50%` faster than baseline
- at least `70%` of reviewed seller accounts produce a credible next step
- at least one real CRM action is created from the pilot set
- the seller can clearly explain what changed, why it matters, and why they trust it

## Planner Journey

### Persona
`Sales Operations`, `Portfolio Owner`, or `Regional Sales Executive`

Example from the original proposition:
- manager preparing a QBR or coverage review
- needs to understand the top `40` accounts as commercial groups, not isolated records
- wants to know where coverage is missing, where revenue is hidden, and which groups deserve executive focus

### Business Value Driver
Pulse360 should help planning and leadership teams allocate attention and coverage based on group truth, whitespace, and risk rather than fragmented account lists.

### Buyer Metrics This Journey Should Influence
- time to prepare a usable group planning view
- number of uncovered subsidiaries identified per strategic group
- number of planning or coverage decisions changed because of group context
- improvement in seller-visible revenue understanding across pilot groups
- new whitespace opportunities surfaced across the portfolio

### Scenario To Use
Use the portfolio pattern from the original Philippines brief:
- `40` strategic accounts in view
- `12` accounts with uncovered subsidiaries
- `SGD 8.7M` total cross-sell opportunity
- average health score `58/100`
- `3` accounts flagged for competitor risk

### Journey Steps And Acceptance Criteria

#### Step 1. Planner starts with the current book of business
What should happen:
- the planner can identify the top accounts or groups under review
- the baseline planning problem is visible: account lists exist, but group-level structure is incomplete

Acceptance criteria:
- the reviewer can explain how planning would normally happen without Pulse360
- the current-state process requires material manual reconstruction of group context
- the selected account set is commercially relevant enough to test prioritization quality

Evidence to capture:
- current planning artifact or baseline account list
- time needed to prepare a baseline view
- planner description of where confidence breaks down

Failure conditions:
- the baseline already includes reliable hierarchy and coverage visibility
- the test uses trivial or non-strategic accounts

#### Step 2. Planner sees the commercial group, not just isolated records
What should happen:
- Pulse360 reveals hierarchy, group rollup, and missing coverage in a way the planner can use directly
- group revenue and uncovered entities are visible without manual stitching

Acceptance criteria:
- the planner can identify which accounts belong to the same commercial group
- the planner can see which subsidiaries are uncovered or underpenetrated
- group-level revenue context changes how the planner ranks at least one group

Evidence to capture:
- screenshot of the group or portfolio planning view
- count of newly visible related entities
- before-and-after understanding of group revenue

Failure conditions:
- hierarchy is visually present but commercially inert
- group context is incomplete enough that prioritization still depends on outside analysis

#### Step 3. Planner can distinguish where to place coverage and why
What should happen:
- the experience highlights where group-level revenue, whitespace, health, or risk justify action
- the planner can see which groups are under-covered, overexposed, or strategically attractive

Acceptance criteria:
- the planner can name which groups need added coverage, specialist focus, or executive attention
- the surfaced signals are comparative enough to support prioritization across the portfolio
- the planner can explain at least one changed coverage decision because of Pulse360

Evidence to capture:
- ranked list of top groups or actions
- planner explanation of decision changes
- signals used in the prioritization decision

Failure conditions:
- the view is descriptive but not decision-driving
- all groups look interesting, but none are clearly more urgent or valuable

#### Step 4. Planner converts insight into a planning decision
What should happen:
- the planner records a concrete decision such as assign owner, reallocate coverage, sponsor a group play, or flag executive risk

Acceptance criteria:
- at least one real planning or coverage decision is made during the review
- the decision is linked to evidence surfaced by Pulse360
- the planner does not need to manually validate the full group in another tool before acting

Evidence to capture:
- documented planning action
- owner or follow-up assigned
- reason the decision was made now rather than later

Failure conditions:
- the meeting ends with a discussion only
- Pulse360 informs the room but does not change the plan

#### Step 5. Planner can take the result into QBR or leadership inspection
What should happen:
- the portfolio output is presentation-ready enough for leadership use
- the planner can explain opportunity, coverage gap, and risk in buyer language

Acceptance criteria:
- the portfolio view supports a QBR or coverage-review narrative without major offline rebuilding
- the planner can quote portfolio-level figures such as uncovered subsidiaries, cross-sell total, or risk concentration
- the surfaced output is good enough to support investment or staffing discussion

Evidence to capture:
- screenshot of the portfolio dashboard or exported view
- portfolio summary figures used in the review
- note on what was no longer needed from the old spreadsheet process

Failure conditions:
- the planner still has to rebuild the output in slides or spreadsheets
- the portfolio view is too technical for leadership discussion

### Planner Journey Pass Rule
The Planner journey passes only if all of the following are true:
- time to prepare a usable planning view improves by at least `50%`
- a majority of reviewed groups reveal at least one new subsidiary, whitespace lead, or coverage issue
- at least one planning or coverage decision changes because of the new group context
- the planner can take the output into a QBR or portfolio review without reconstructing the story offline

## Reviewer Questions

### Seller
- Did Pulse360 expose a larger opportunity than the seller could see alone
- Did it explain why the opportunity is credible
- Did the seller create a real action, not just acknowledge the insight
- Would a sales leader accept the created action as pipeline-relevant

### Planner
- Did Pulse360 change how the planner ranked or staffed the portfolio
- Did it make hidden group structure and whitespace visible enough to matter
- Did it reduce planning prep effort materially
- Could the output be used directly in an executive review

## Decision Rule
If the Seller and Planner journeys produce better understanding but not faster or better commercial decisions, the solution is still interesting but not yet acceptable.
