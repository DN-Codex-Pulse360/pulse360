# Agentforce Capability Reality Check

Date: 2026-04-23

## Purpose

Record the honest current state of Agentforce work in Pulse360 so the repo does
not blur together:

- repo-backed metadata and orchestration
- custom Salesforce UI fallbacks
- a true native Agentforce runtime experience

## Short Answer

Pulse360 currently has partial Agentforce implementation support in repo, but
native Agentforce runtime success is not yet proven end to end in
`pulse360-agent-target`.

## What Is Proven

- The repo contains Agentforce-related source metadata at
  [Pulse360_Agent.agent](/Users/danielnortje/Documents/Pulse360/force-app/main/default/aiAuthoringBundles/Pulse360_Agent/Pulse360_Agent.agent).
- Agentforce-related metadata can validate and deploy successfully to approved
  non-production orgs.
- Apex-backed seller orchestration can load account context, produce grounded
  responses, and execute approval-aware actions.
- Custom LWC surfaces can expose guided seller interaction on the Account page.

## What Is Not Yet Proven

- A native Agentforce conversational runtime is visibly available on the target
  Account experience in `pulse360-agent-target`.
- The intended user can interact with the agent through a native Agentforce
  surface using free-text prompts.
- The live runtime is definitively using Agentforce instructions, subagents, and
  actions rather than only custom LWC and Apex wiring.
- The intended seller experience is available as a true Agentforce surface on
  the page, rather than as a fallback custom assistant panel.

## Required Language Going Forward

Use these terms precisely:

- `Agentforce metadata`: source-backed agent-related config in repo
- `custom assistant panel`: LWC or Apex-driven UI that simulates agent behavior
- `native Agentforce runtime`: actual Agentforce conversational experience in
  the Salesforce runtime

Do not call a custom assistant panel a real Agentforce agent.

## Practical Conclusion

Codex can help with:

- building Agentforce-related source metadata
- building Apex, Flow, or prompt actions
- validating and deploying to non-production orgs
- building fallback UI when native Agentforce runtime is unavailable

Codex cannot honestly claim a real working Agentforce agent for a target org
until the org's native runtime capabilities are demonstrated directly.

## Next Operator Step

Any future Agentforce claim for `pulse360-agent-target` should first produce a
binary capability audit:

1. Is native Agentforce runtime available for the intended user and page?
2. Can the user interact with it directly through a visible conversational
   surface?
3. Are configured Agentforce instructions/subagents/actions actually driving the
   response and execution path?

If any answer is `no` or unproven, describe the implementation as a custom
assistant path, not Agentforce success.
