# Pulse360 Salesforce Release Checklist

## Pre-Deploy

1. Confirm target org alias and environment type.
2. Confirm source is the system of record for the metadata being deployed.
3. If the change touches Agentforce or Data Cloud, confirm the target org is capability-ready before deployment:
   - `Agentforce Studio` is present
   - the intended target user can authenticate into the org
   - the target user has the required Agentforce builder or admin access
   - target-org assumptions such as `default_agent_user` have been reviewed
4. Run:
   - `./scripts/validate-contracts.sh`
   - `./scripts/validate-account-intelligence-experience.sh` when the Account-facing seller surfaces are in scope
   - `./scripts/validate-governance-case-metadata.sh`
   - `./scripts/validate-agentforce-orchestrator.sh` when Agentforce surfaces are in scope
   - `./scripts/validate-signal-routing-workspace.sh` when routed-alert or intent-signal surfaces are in scope
   - `./scripts/validate-multi-surface-experience.sh` when planner, seller v2, renewal-risk, or health-scan surfaces are in scope
   - `./scripts/validate-salesforce-package-layout.sh` when unlocked-package packaging or package-boundary changes are in scope
5. Identify whether the change touches:
   - deployable Salesforce metadata
   - org-locked Data Cloud setup
   - both

## Deployable Metadata

1. Generate or refresh manifest from source.
2. If unlocked packaging is in scope, rebuild the package workspace from source with `./scripts/build-salesforce-package-workspace.sh`.
3. Run validate-only deploy before real deploy where practical.
4. If `aiAuthoringBundles` metadata is included, confirm the target org accepts the bundle and that any org-specific user bindings are correct.
5. Deploy to dev/sandbox org.
6. Validate the resulting page, object, fields, permission sets, seeded records, and Agentforce surfaces.

## Org-Locked Setup

1. Capture setup steps in a runbook.
2. Do not treat manual Data Cloud setup as source-deployable if the platform does not support it.
3. Record environment-specific values outside the code path.

## Post-Deploy

1. Verify the Lightning page renders.
2. Verify security access through the intended permission set.
3. Verify linked record behavior and decision workflow.
4. Record any rollback or remediation actions needed.
