# Pulse360 Account Page Agentforce UAT - 2026-07-01

This note captures the live Account-page UAT after deploying the Pulse360
Agentforce proactive signal brief and governed Task action.

## Target Org

- Org alias: `pulse360-agent-target`
- User: `dnortje.37cf563036b7@agentforce.com`
- Account: `Northstar Foods Group`
- Account Id: `001dL00002HTb4cQAD`
- Account page:
  `https://orgfarm-d50863b207-dev-ed.develop.lightning.force.com/lightning/r/Account/001dL00002HTb4cQAD/view`

## Verified Live Account Page State

The Northstar Account page opened successfully in Salesforce Lightning.

The page showed:

- Account name: `Northstar Foods Group`
- Industry: `Food & Beverage Manufacturing`
- Contact: `Maya Tan`, Regional Operations Director
- Activity timeline entry:
  `Pulse360 coverage review - Northstar Foods Group`
- Task Id: `00TdL00000CjmsnUAB`
- Task link:
  `https://orgfarm-d50863b207-dev-ed.develop.lightning.force.com/lightning/r/Task/00TdL00000CjmsnUAB/view`

This proves the governed Task created by `Pulse360PrepReviewTaskAction` is
visible from the live Account activity timeline.

## Agentforce Panel UAT

The global Agentforce panel was opened from the Northstar Account page.

Observed panel:

- Panel title: `Slack Customer Insights`
- Panel type in Setup: `AgentforceEmployeeAgent`
- Prompt sent:
  `Which Salesforce account page am I viewing, and do you have this Account record context?`
- Response summary:
  The agent stated that it did not have direct visibility into the current
  Salesforce account page or context unless the Account name or Id was
  provided.

This proves the Account page has an Agentforce entry point, but the active
header panel is not the Pulse360 Agent and is not receiving record-aware
context from the Account page in this configuration.

## Account Agent Quick Action UAT

An Account object Agent Quick Action was created and deployed:

- Quick action: `Account.Pulse360_Proactive_Brief`
- Label: `Pulse360 Proactive Brief`
- Metadata type: `QuickAction`
- Quick action type in metadata: `Copilot`
- User utterance parameter:
  `Pulse360 proactive signal brief for Account {!Account.Id}. Use Account Id 001dL00002HTb4cQAD as the Northstar demo control only if no runtime record context is available. Explain why now, cite source evidence, include confidence and freshness, ask for confirmation before creating any Task, and do not create Opportunities or hierarchy updates.`

The Account layout was updated to expose this quick action on Account records:

- Layout: `Account-Account Layout`
- Platform action entry: `Account.Pulse360_Proactive_Brief`
- Quick action list entry: `Account.Pulse360_Proactive_Brief`

Live browser UAT on the Northstar Account page confirmed:

- The Account action overflow menu includes `Pulse360 Proactive Brief`.
- Clicking `Pulse360 Proactive Brief` opens the native Agentforce side panel.
- The user message `Pulse360 Proactive Brief` is sent into the panel.
- The panel title is still `Slack Customer Insights`, not `Pulse360 Agent`.
- The response attempted Slack Canvas behavior and returned:
  `It looks like there was an issue with creating a Slack canvas because the operation isn't supported on free Slack teams.`

This proves the Account-page Agent Quick Action is live and dispatches into
Agentforce. It also proves the current org routing is still bound to the active
employee agent, `Slack Customer Insights`, rather than the Pulse360 service
agent/runtime.

## Setup Evidence

Salesforce Setup > Agentforce Agents showed:

| Agent | Type | Active | Implication |
| --- | --- | --- | --- |
| Agentforce Employee Agent | AgentforceEmployeeAgent | False | Not the active header panel. |
| HuronBot Test CSR | Service Agent | True | Unrelated active service agent. |
| Pulse360 Agent | Service Agent | True | Active, but not an employee/header agent. |
| Slack Customer Insights | AgentforceEmployeeAgent | True | Active employee agent used by the header panel. |

Pulse360 row actions showed no available setup actions in the list view.

Metadata retrieval confirmed:

- `AiAuthoringBundle:Pulse360_Agent_6` exists and was modified on
  `2026-07-01T02:45:34.000Z`.
- `GenAiPlannerBundle:Slack_Customer_Insights` exists and matches the live
  panel title.
- `GenAiPlannerBundle:Pulse360_Agent_v5` exists, but the Setup list still
  presents Pulse360 as a `Service Agent`.
- `Account_Record_Page` does not contain a native Agentforce component or agent
  selection property. The Account page metadata is standard record detail,
  related list, and activity panel composition.
- The `devedapp__Developer_Edition_UtilityBar` is empty; the panel is not
  coming from a utility-bar item.

## Current Claim Boundary

Proven:

- Pulse360 Agent metadata/action bundle exists and is active in Agentforce
  Builder.
- Advisory action runtime was proven previously in Builder preview.
- Governed Task action deploy and Apex runtime were proven.
- The governed Task is visible on the Northstar Account activity timeline.
- The live Account page has an Agentforce panel entry point.
- The Northstar Account page exposes the `Pulse360 Proactive Brief` Agent Quick
  Action.
- The Account-page action opens the native Agentforce side panel and sends the
  quick-action prompt into that surface.

Not yet proven:

- Pulse360 Agent is the agent opened from the Account page header or Account
  quick action.
- The Account page Agentforce panel passes implicit `recordId` context to a
  Pulse360-specific runtime.
- The governed Task action is invoked from the Account page Agentforce panel.
- The Account quick action can complete a Pulse360 brief response while the
  active employee agent remains `Slack Customer Insights`.

## Recommended Next Build Path

The next strongest path is to bind the Account-page quick action to a
Pulse360-capable employee-agent surface.

Rationale:

- Salesforce's record-page pattern for Agentforce is an AI-powered quick action
  that opens the employee agent panel and passes a fixed utterance into the
  panel.
- The current global header panel is an employee agent surface, while the
  Pulse360 agent is currently a service agent.
- The quick action now explicitly includes Account Id in the utterance, avoiding
  reliance on implicit page context.
- The remaining routing issue is that the active employee agent interprets the
  shortcut through the Slack Customer Insights capability set.

Target behavior:

1. Seller opens `Northstar Foods Group`.
2. Seller clicks `Pulse360 Proactive Brief` from the Account action surface.
3. Agentforce panel opens with a Pulse360-capable employee agent.
4. The agent retrieves the source-backed proactive brief.
5. The agent asks for confirmation before any CRM mutation.
6. On confirmation, the governed Task action creates or links the review Task.

This would make the demo honestly Account-page native and Agentforce-native
without claiming that the current Slack Customer Insights panel already runs
Pulse360.
