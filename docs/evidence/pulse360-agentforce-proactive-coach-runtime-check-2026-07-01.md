# Pulse360 Agentforce Proactive Coach Runtime Check

Date: 2026-07-01

## Status

The Agentforce proactive account coach metadata and Apex action are deployed to
`pulse360-agent-target`, and the action has been invoked live against the
Northstar Account.

Native Agentforce Builder preview runtime is now proven for the advisory
`get_proactive_signal_brief` action path. The active Builder artifact is
`Pulse360 Agent`, Version 6 (Draft), project `1bYdL00000072hpUAA`, version
`1bZdL000000Om8LUAS`.

Downstream CRM mutation is still not claimed as proven. The validated runtime
path explains and recommends next moves; task/opportunity creation remains a
separate approval-gated capability.

## Target Org

- Alias: `pulse360-agent-target`
- Org URL:
  `https://orgfarm-d50863b207-dev-ed.develop.my.salesforce.com`
- Northstar Account:
  `https://orgfarm-d50863b207-dev-ed.develop.my.salesforce.com/lightning/r/Account/001dL00002HTb4cQAD/view`

## Apex Action Deploy

Command:

```bash
sf project deploy start --target-org pulse360-agent-target \
  --source-dir force-app/main/default/classes/Pulse360GetProactiveSignalBriefAction.cls \
  --source-dir force-app/main/default/classes/Pulse360GetProactiveSignalBriefAction.cls-meta.xml \
  --source-dir force-app/main/default/classes/Pulse360ProactiveSignalBriefTest.cls \
  --source-dir force-app/main/default/classes/Pulse360ProactiveSignalBriefTest.cls-meta.xml \
  --source-dir force-app/main/default/permissionsets/Pulse360_Account_Intelligence_User.permissionset-meta.xml \
  --test-level RunSpecifiedTests \
  --tests Pulse360ProactiveSignalBriefTest \
  --wait 10 --json
```

Result:

- Status: `Succeeded`
- Deploy Id: `0AfdL00000cjm93SAA`
- Components deployed: `3`
- Tests: `3 / 3` passed
- Test class: `Pulse360ProactiveSignalBriefTest`
- Deploy status:
  `https://orgfarm-d50863b207-dev-ed.develop.my.salesforce.com/lightning/setup/DeployStatus/page?address=%2Fchangemgmt%2FmonitorDeploymentsDetails.apexp%3FasyncId%3D0AfdL00000cjm93SAA%26retURL%3D%252Fchangemgmt%252FmonitorDeployment.apexp`

Passing tests:

- `blocksMissingAccountId`
- `requiresReviewWhenSourceRefsAreMissing`
- `returnsGroundedProactiveSignalBrief`

## Live Apex Invocation

The Apex action was invoked directly in the target org against
`Northstar Foods Group`.

Observed debug markers:

```text
P360_AGENTFORCE_BRIEF_STATUS=ready
P360_AGENTFORCE_RUNTIME_STATE=runtime_unproven
P360_AGENTFORCE_BRIEF_HAS_NORTHSTAR=true
P360_AGENTFORCE_SOURCE_REFS_LENGTH=2527
```

The action returned grounded proactive signal context and source references,
while retaining the explicit runtime boundary:

```json
{
  "runtimeState": "runtime_unproven",
  "low_risk_agent_outputs": [
    "explain_signal",
    "recommend_next_move",
    "draft_seller_outreach"
  ],
  "downstream_effects_require_confirmation": [
    "create_task",
    "route_specialist",
    "open_opportunity",
    "create_opportunity"
  ]
}
```

The invocation did not create Salesforce Tasks or other CRM mutations as proof
of the agent capability.

## Permission Evidence

The `Pulse360_Account_Intelligence_User` permission set exists in the target
org and has Apex class access to:

- `Pulse360GetProactiveSignalBriefAction`
- `Pulse360ProactiveSignalBriefTest`

## Agentforce Bundle Deploy

Initial dry-run deployment of the Agentforce bundle failed because the bundle
directory was missing its metadata descriptor:

```text
Required field is missing: bundleType
```

The source bundle was fixed by adding:

```text
force-app/main/default/aiAuthoringBundles/Pulse360_Agent/Pulse360_Agent.bundle-meta.xml
```

with:

```xml
<bundleType>AGENT</bundleType>
```

Dry-run result after the fix:

- Status: `Succeeded`
- Deploy Id: `0AfdL00000cjk0pSAA`
- Component: `AiAuthoringBundle`
- Full name: `Pulse360_Agent`
- Deploy status:
  `https://orgfarm-d50863b207-dev-ed.develop.my.salesforce.com/lightning/setup/DeployStatus/page?address=%2Fchangemgmt%2FmonitorDeploymentsDetails.apexp%3FasyncId%3D0AfdL00000cjk0pSAA%26retURL%3D%252Fchangemgmt%252FmonitorDeployment.apexp`

Real deploy result:

- Status: `Succeeded`
- Deploy Id: `0AfdL00000cjmH7SAI`
- Component: `AiAuthoringBundle`
- Full name: `Pulse360_Agent`
- Component state: `Created`
- Deploy status:
  `https://orgfarm-d50863b207-dev-ed.develop.my.salesforce.com/lightning/setup/DeployStatus/page?address=%2Fchangemgmt%2FmonitorDeploymentsDetails.apexp%3FasyncId%3D0AfdL00000cjmH7SAI%26retURL%3D%252Fchangemgmt%252FmonitorDeployment.apexp`

## Metadata Retrieval Boundary

Post-deploy metadata checks did not produce a clean retrieve-based proof:

- `sf org list metadata --metadata-type AiAuthoringBundle` surfaced older
  numbered `Pulse360_Agent_*` bundles rather than the clean `Pulse360_Agent`
  deployment.
- `sf project retrieve start --metadata AiAuthoringBundle:Pulse360_Agent`
  completed but returned only `package.xml`, with no retrieved bundle files.

The current honest capability state is:

```text
Agentforce metadata deployed.
Apex action live and source-backed.
Native Agentforce Builder preview invocation proven for advisory signal brief.
Downstream CRM mutation still unproven and approval-gated.
```

## Native Builder Runtime Proof

The Salesforce UI confirmed that the active Agentforce Builder artifact is:

```text
Pulse360 Agent
Version 6 (Draft)
Project: 1bYdL00000072hpUAA
Project version: 1bZdL000000Om8LUAS
```

The Builder preview was invoked against:

```text
Account Id: 001dL00002HTb4cQAD
Account: Northstar Foods Group
Session: 97d2140e-ec2a-4afd-a975-2ff2f431c0a8
```

The preview first requested confirmation, then executed the native
`get proactive signal brief` action successfully. The trace also showed
successful `GROUNDED` output evaluation.

See the detailed browser-validated evidence note:

```text
docs/evidence/pulse360-agentforce-builder-preview-2026-07-01.md
```

## Next Proof Step

The separate confirmation-gated Salesforce Task action has now been deployed
and invoked directly in the target org.

See:

```text
docs/evidence/pulse360-agentforce-governed-task-action-2026-07-01.md
```

The remaining proof step is a native Agentforce Builder preview trace for the
Task action itself. Until that trace is captured, the honest state is:

```text
Advisory Agentforce signal brief proven in Builder.
Governed Task action deployed and live via Apex.
Native Builder trace for Task mutation pending.
```
