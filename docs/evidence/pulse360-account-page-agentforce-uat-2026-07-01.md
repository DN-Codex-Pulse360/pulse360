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

Not yet proven:

- Pulse360 Agent is the agent opened from the Account page header.
- The Account page Agentforce panel passes implicit `recordId` context.
- The governed Task action is invoked from the Account page Agentforce panel.

## Recommended Next Build Path

The next strongest path is to build an Account-page Agent Quick Action for
Pulse360.

Rationale:

- Salesforce's record-page pattern for Agentforce is an AI-powered quick action
  that opens the employee agent panel and passes a fixed utterance into the
  panel.
- The current global header panel is an employee agent surface, while the
  Pulse360 agent is currently a service agent.
- A quick action can explicitly include Account name and Account Id in the
  utterance, avoiding reliance on implicit page context.

Target behavior:

1. Seller opens `Northstar Foods Group`.
2. Seller clicks `Pulse360 Proactive Brief` from the Account action surface.
3. Agentforce panel opens with a Pulse360-specific prompt that includes the
   Account Id.
4. The agent retrieves the source-backed proactive brief.
5. The agent asks for confirmation before any CRM mutation.
6. On confirmation, the governed Task action creates or links the review Task.

This would make the demo honestly Account-page native without claiming that the
current header panel already runs Pulse360.
