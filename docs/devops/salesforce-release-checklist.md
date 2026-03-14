# Pulse360 Salesforce Release Checklist

## Pre-Deploy

1. Confirm target org alias and environment type.
2. Confirm source is the system of record for the metadata being deployed.
3. Run:
   - `./scripts/validate-contracts.sh`
   - `./scripts/validate-governance-case-metadata.sh`
4. Identify whether the change touches:
   - deployable Salesforce metadata
   - org-locked Data Cloud setup
   - both

## Deployable Metadata

1. Generate or refresh manifest from source.
2. Run validate-only deploy before real deploy where practical.
3. Deploy to dev/sandbox org.
4. Validate the resulting page, object, fields, permission sets, and seeded records.

## Org-Locked Setup

1. Capture setup steps in a runbook.
2. Do not treat manual Data Cloud setup as source-deployable if the platform does not support it.
3. Record environment-specific values outside the code path.

## Post-Deploy

1. Verify the Lightning page renders.
2. Verify security access through the intended permission set.
3. Verify linked record behavior and decision workflow.
4. Record any rollback or remediation actions needed.
