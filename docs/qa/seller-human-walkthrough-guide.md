# Seller Human Walkthrough Guide

## Purpose
This is a human walkthrough for sense-checking the Seller experience in Pulse360.

It is meant to be run by:
- a facilitator
- a real seller or seller proxy
- an observer taking notes

It is not a technical test script.
It is not a Codex or operator runbook.

The goal is to answer one business question:

Can a seller make a better commercial decision, faster, because of Pulse360?

## What We Are Testing
We are not testing whether fields sync correctly.
We are not testing whether the page renders.

We are testing whether the seller can:
1. understand what changed about the account
2. understand why it matters now
3. trust it enough to act
4. take a credible next step without rebuilding the answer manually

## What Good Looks Like
The walkthrough is successful only if the seller leaves with a concrete business action they would defend in a pipeline review or account review.

If the outcome is only "this is interesting" or "I need to investigate later", the walkthrough does not pass.

## Recommended Participants

### Facilitator
A human product lead, solution lead, or sales leader who keeps the session moving.

### Seller
An account executive, strategic account manager, specialist seller, or a credible proxy who can honestly say what they would do.

### Observer
Someone who captures:
- timing
- screenshots
- exact seller comments
- what changed the decision
- pass / fail notes

## Session Length
Target `10-15` minutes.

## Suggested Live Accounts

### Primary account
Use `JG Summit Holdings, Inc.`

Current live values in `pulse360-dev` as of `2026-04-13`:
- `Account.Id = 001dM00003d4bnNQAQ`
- `Group_Revenue_Rollup__c = 378600000000`
- `Group_Revenue_Visible__c = 126000000000`
- `Group_Known_Subsidiary_Count__c = 4`
- `CRM_Covered_Subsidiary_Count__c = 1`
- `Coverage_Gap_Flag__c = true`
- `AI_Recommended_Actions__c` includes `GoTyme and rewards analytics account review`

Why this is the best live seller case:
- there is a visible revenue gap between known group value and currently visible CRM value
- there is a visible coverage gap
- there is already a seller-style recommended action in the data

### Singapore fallback
Use `Singtel Group`

Current live values:
- `Account.Id = 001dM00003d4YKtQAM`
- `Group_Revenue_Rollup__c = 14146100000`
- `Group_Revenue_Visible__c = 10400000000`
- `Group_Known_Subsidiary_Count__c = 3`
- `CRM_Covered_Subsidiary_Count__c = 2`
- recommended action includes `NCS data and AI modernization program`

### Coverage / duplicate variant
Use `Ayala Corporation` plus `Ayala Corp.` if you want to test seller value with a secondary governance signal.

## Important Context For The Room
The original proposition used the fictional `Pacific Capital Singapore` story with a larger dramatic reveal.

The live org today does not reproduce those exact numbers.

So this walkthrough should be honest:
- it tests the real current experience
- it uses the strongest live records we have
- if the current experience feels commercially useful but not yet compelling, that is valid product feedback

## Preparation
Before the session:
- open the target Account record in Salesforce
- make sure the Pulse360 seller surface is visible
- have a timer ready
- prepare a simple note sheet for baseline vs Pulse360-assisted decision

Record these during the walkthrough:
- account used
- seller name / role
- baseline next action
- Pulse360-assisted next action
- time to baseline decision
- time to Pulse360-assisted decision
- seller confidence before
- seller confidence after
- screenshots of key moments

## Walkthrough Flow

### Step 1. Let the seller review the account normally
Linear subtask:
- [DAN-249](https://linear.app/danielnortje/issue/DAN-249/seller-step-1-capture-baseline-account-view-and-current-seller-belief)

Facilitator says:
"Start as you normally would. Look at this account as if you were deciding whether it deserves attention this week. Tell us what you think the account is worth, how healthy it looks, and what you would do next."

Seller should do:
- look only at the standard account context first
- state what they think is going on
- state their likely next action

Observer captures:
- what the seller believes the account is worth
- whether they see a reason to prioritize it
- how long it takes to reach that conclusion

What we want to see:
- the seller makes a plausible but incomplete judgment
- the seller does not yet see the full group opportunity

What would fail this step:
- the standard view already makes the seller's best action obvious
- or the standard view is so bare that the test is unrealistic

### Step 2. Show the Pulse360 group view
Linear subtask:
- [DAN-250](https://linear.app/danielnortje/issue/DAN-250/seller-step-2-reveal-group-truth-and-whitespace-in-workflow)

Facilitator says:
"Now look at the Pulse360 account intelligence view. What changed in your understanding of this customer?"

For `JG Summit Holdings, Inc.`, point the seller to:
- `Group_Revenue_Rollup__c = 378600000000`
- `Group_Revenue_Visible__c = 126000000000`
- `Group_Known_Subsidiary_Count__c = 4`
- `CRM_Covered_Subsidiary_Count__c = 1`
- `Coverage_Gap_Flag__c = true`

Seller should do:
- explain the gap between what CRM shows and what the broader group appears to be worth
- identify whether uncovered subsidiaries change the commercial picture

Observer captures:
- whether the seller can explain the revenue gap in business language
- whether the seller identifies whitespace or a group coverage issue
- screenshot of this moment

What we want to see:
- the seller clearly recognizes a larger commercial group than they originally saw
- the seller sees that coverage is incomplete

What would fail this step:
- the extra context is visible but not commercially meaningful to the seller

### Step 3. Ask why this matters now
Linear subtask:
- [DAN-251](https://linear.app/danielnortje/issue/DAN-251/seller-step-3-validate-why-the-signal-matters-now-and-why-it-is)

Facilitator says:
"Why should you act on this now, and why do you trust the signal enough to do something with it?"

For `JG Summit Holdings, Inc.`, use:
- `AI_Narrative__c`: broad portfolio and digital transformation momentum
- `AI_Recommended_Actions__c`: `GoTyme and rewards analytics account review`
- `DataCloud_Last_Synced__c = 2026-03-28T09:00:00.000+0000`

Seller should do:
- explain why the account now matters more than they first thought
- say whether the recommendation is specific enough to act on
- say whether the freshness feels good enough for planning

Observer captures:
- the seller's own explanation of why this matters
- whether they trust the signal
- whether they needed help interpreting it

What we want to see:
- the seller can explain the opportunity in business terms without being coached into it

What would fail this step:
- the seller finds the recommendation too vague, stale, or generic

### Step 4. Force a real next-action choice
Linear subtask:
- [DAN-252](https://linear.app/danielnortje/issue/DAN-252/seller-step-4-select-a-meaningful-next-action-from-the-surfaced)

Facilitator says:
"What would you do now? Be specific. If your manager asked tomorrow why you did this, what would you say?"

For `JG Summit Holdings, Inc.`, the strongest expected answer is:
- create or sponsor an opportunity around `GoTyme and rewards analytics account review`

Other acceptable answers:
- route a specialist to the uncovered subsidiary
- create a task to validate missing group coverage
- elevate the group for strategic account planning

Observer captures:
- the next action chosen
- how long it took to choose it
- confidence before vs after Pulse360

What we want to see:
- the seller chooses a commercially meaningful action during the session

What would fail this step:
- the answer is only "I'd look into it later"

### Step 5. Turn the decision into a real CRM action
Linear subtask:
- [DAN-253](https://linear.app/danielnortje/issue/DAN-253/seller-step-5-execute-the-crm-action-without-leaving-the-operating)

Facilitator says:
"Create the action now. We want to prove this changes workflow, not just thinking."

Seller should do:
- create the task or opportunity in Salesforce

Observer captures:
- screenshot or ID of the created artifact
- elapsed time from account open to action creation
- whether the action clearly reflects the surfaced opportunity

What we want to see:
- a real artifact is created in CRM
- the action is clearly shaped by Pulse360 context

What would fail this step:
- no action is created
- or the created action is generic enough that Pulse360 did not really change it

### Step 6. Close with the manager question
Linear subtask:
- [DAN-254](https://linear.app/danielnortje/issue/DAN-254/seller-step-6-prove-the-same-context-rolls-into-manager-or-qbr)

Facilitator says:
"If you had to take this into a QBR or manager review, what is the bigger takeaway?"

Seller or manager should do:
- describe the broader pattern, not just the single account
- explain whether this is a one-off or evidence of wider whitespace / coverage issues

Observer captures:
- the portfolio-level takeaway
- whether the seller or manager can explain it without rebuilding a spreadsheet

What we want to see:
- the story scales beyond one account

What would fail this step:
- the value only works as an isolated anecdote

## Human Scorecard
At the end of the session, the room should score these from `1-5`:

1. I understood what changed about the account.
2. I understood why it mattered now.
3. I trusted the signal enough to act.
4. I could take a next step without manual reconstruction.
5. I would use this in a real seller workflow.

Add one open text response:
- "What, specifically, changed your decision?"

## Pass Rule
The walkthrough passes only if:
- the seller reaches a meaningful next action materially faster than baseline, target `>= 50%`
- the seller can describe the difference between visible CRM value and broader group truth
- the seller selects a defensible next action during the session
- a real CRM action is created
- the seller says Pulse360 made the decision easier or faster, not just more interesting

## Product Feedback To Listen For
Watch for these honest reactions:
- "The revenue gap is useful, but the scores all feel the same."
- "The narrative is helpful, but I need stronger proof of why this specific action is best."
- "This is useful for planning, but I still need a sharper seller play."

If that feedback appears, log it as real product insight.
Do not smooth it away just because the data path is working.
