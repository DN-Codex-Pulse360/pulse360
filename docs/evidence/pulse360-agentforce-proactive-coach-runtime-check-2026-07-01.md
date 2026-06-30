# Pulse360 Agentforce Proactive Coach Runtime Check

Date: 2026-07-01

## Status

The Agentforce proactive account coach metadata and Apex action are deployed to
`pulse360-agent-target`, and the action has been invoked live against the
Northstar Account.

Native Agentforce runtime is still not claimed as proven. The bundle deploy
succeeded, but post-deploy metadata listing/retrieval was ambiguous and no
Agentforce Builder or native chat invocation evidence has been captured yet.

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

## Remaining Runtime Boundary

Post-deploy metadata checks did not yet produce a clean runtime proof:

- `sf org list metadata --metadata-type AiAuthoringBundle` surfaced older
  numbered `Pulse360_Agent_*` bundles rather than the clean `Pulse360_Agent`
  deployment.
- `sf project retrieve start --metadata AiAuthoringBundle:Pulse360_Agent`
  completed but returned only `package.xml`, with no retrieved bundle files.

Therefore, the current honest capability state is:

```text
Agentforce metadata deployed.
Apex action live and source-backed.
Native Agentforce runtime invocation still unproven.
```

## Next Proof Step

Use the Salesforce UI to confirm which Agentforce bundle is active in
Agentforce Builder, bind or publish the `Get Proactive Signal Brief` action if
required, and capture a native Agentforce invocation against:

```text
Northstar Foods Group
```

The success criterion is an Agentforce surface response that includes the
Northstar proactive signal, source references, and approval policy while keeping
high-impact CRM mutations behind confirmation.
