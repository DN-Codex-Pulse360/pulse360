# Pulse360 Agentforce Org Migration Checklist

## Purpose

Use this checklist before moving the Pulse360 solution into a different Salesforce org for Agentforce creation and runtime validation.

This runbook separates two questions that were previously blurred together:

- is the repo source-backed and portable?
- is the target org actually entitled, permissioned, and configured to create `Pulse360 Agent`?

## Current Baseline

- The repo already contains a source-backed Agentforce asset at [Pulse360_Agent.agent](/Users/danielnortje/Documents/Pulse360/force-app/main/default/aiAuthoringBundles/Pulse360_Agent/Pulse360_Agent.agent).
- The current agent metadata binds `default_agent_user` to `dnortje.37cf563036b7@agentforce.com`.
- Prior sessions established `pulse360-dev` as the validated reference org for the main CRM/Data Cloud runtime path.
- Prior checks also showed that `pulse360-dev` exposes `Agentforce Studio` and active Agentforce-related licenses.
- On 2026-04-17, CLI authentication for `pulse360-agent-target` completed successfully against org id `00DdL00000tqwwsUAA` on `orgfarm-d50863b207-dev-ed.develop.my.salesforce.com`.
- The bound target user exists in that org as an active `System Administrator`.
- The target org exposes `Agentforce Studio` and active Agentforce-related licenses, but explicit user-level Agent/Einstein permission set assignment evidence was still empty at last check.
- On 2026-04-17, both validate-only and live Salesforce metadata deploys to `pulse360-agent-target` completed successfully with `124/124` components and `0` component errors.
- The Pulse360 Salesforce Account activation fields now exist in `pulse360-agent-target`.
- On 2026-04-17, a new Data Cloud file-upload stream for `datacloud_export_accounts Pulse360_Datab` was created successfully in `pulse360-agent-target`, processed `3` rows, and materialized source object `datacloud_export_accounts_Pulse360_Datab__dll`.
- On 2026-04-17, the missing Pulse360 custom `Account` DMO field set was saved successfully through the Data Model UI in `pulse360-agent-target`, but those saved fields have not yet materialized in the queryable `sf sobject describe ssot__Account__dlm` surface.
- On 2026-04-17, the Data Stream mapping canvas in `pulse360-agent-target` loaded the Pulse360 source fields, but the target-entity selector still failed to materialize `Account` as a selectable mapping target.
- On 2026-04-18, the Data Stream mapping canvas progressed to `17` successful mappings, and the remaining failures aligned with source-type mismatches rather than missing DMO field definitions.
- On 2026-04-18, repo validation found a malformed JG Summit row in [databricks_enrichment_sample.csv](/Users/danielnortje/Documents/Pulse360/data/samples/databricks_enrichment_sample.csv) where `external_legal_name` was unquoted as `JG Summit Holdings, Inc.`, shifting the row and likely poisoning DLO type inference for several downstream fields.
- The sample CSV was corrected in-repo on 2026-04-18, but the target org should use a fresh file-upload stream or DLO re-creation path before treating remaining mapping failures as a platform runtime blocker.
- On 2026-04-18, a fresh recovery stream `DC Export Accounts P360 Fix` and source object `dc_export_accounts_p360_fix__dll` were created from the corrected CSV in `pulse360-agent-target`.
- On 2026-04-18, the recovered stream completed the Pulse360 `Account` DMO contract to `38/48` mapped fields and `validate-data-cloud-dmo-extension.sh` reached `missing_required_count = 0`.
- On 2026-04-18, `validate-data-cloud-field-path.sh` reached zero missing source, DMO, and `Account` target fields after the Data Cloud recovery path and permission fixes.
- On 2026-04-18, `Pulse360_Account_Intelligence_User` and `Governance_Case_Steward` were assigned to the target user in `pulse360-agent-target`, making the Salesforce `Account` activation fields queryable at runtime.
- On 2026-04-18, `validate-salesforce-data-cloud-mcp.sh`, `validate-data-cloud-dmo-extension.sh`, `validate-data-cloud-field-path.sh`, and `validate-salesforce-account-activation-fields.sh` all passed against `pulse360-agent-target` with the recovered stream as the default runtime source.
- On 2026-04-18, the legacy stream `datacloud_export_accounts Pulse360_Datab` and its associated data lake object were detached from the `Account` mapping surface and deleted from `pulse360-agent-target`.
- On 2026-04-18, the live Databricks gold/export SQL chain was rebuilt from repo source in the connected workspace, and a fresh `43`-row export was generated from `pulse360_s4.intelligence.datacloud_export_accounts` with `run_id = run_20260418_050206` and `model_version = dc-canonical-v2.crm-keyed`.
- On 2026-04-18, that fresh Databricks export was uploaded into the canonical stream `DC Export Accounts P360 Fix`, which finished with `DataStreamStatus = ACTIVE`, `ImportRunStatus = SUCCESS`, `LastRefreshDate = 2026-04-18T05:09:24.000+0000`, and `TotalRowsProcessed = 43`.
- On 2026-04-18, the Databricks runtime fingerprint was confirmed end to end: `dc_export_accounts_p360_fix__dll` exposed `run_id__c = run_20260418_050206` and `enrichment_run_id__c = run_default_20260418_050206`, and `ssot__Account__dlm` exposed `Enrichment_Run_ID__c = run_default_20260418_050206` for the refreshed records.

## Migration Decision Rule

Treat `pulse360-dev` as the reference baseline until a target org passes every gate below.

Do not update the repo's `default_agent_user` binding, default org assumptions, or deployment guidance based only on a username and password check.

## Gate 1: Authentication And Org Identity

Confirm all of the following in the target org:

- interactive browser login completes successfully
- CLI or API login completes successfully for non-interactive validation paths
- the intended target user exists as an active Salesforce `User`
- the authenticated org id and instance host are recorded in the migration notes

Recommended evidence:

- `sf org display --target-org <alias> --verbose --json`
- `sf data query --target-org <alias> --query "SELECT Id, Name, Username, IsActive, Profile.Name FROM User WHERE Username = '<target-username>'" --result-format json`

Stop if:

- browser login requires identity verification that cannot be completed
- API login still requires a missing security token
- the target username does not exist in the org

## Gate 2: Agentforce Capability

Confirm the target org exposes the Agentforce surface needed for build and validation:

- `Agentforce Studio` app is present
- Agentforce-related permission set licenses are active in the org
- the target user has the builder/admin access needed to create or manage custom agents

Recommended evidence:

- `sf data query --target-org <alias> --query "SELECT Label, DeveloperName, NamespacePrefix FROM AppDefinition WHERE Label IN ('Agentforce Studio','Data Cloud','Sales','Service') ORDER BY Label" --result-format json`
- `sf data query --target-org <alias> --query "SELECT Id, MasterLabel, Status FROM PermissionSetLicense WHERE MasterLabel LIKE '%Agent%' OR MasterLabel LIKE '%Einstein%' ORDER BY MasterLabel" --result-format json`
- `sf data query --target-org <alias> --query "SELECT Assignee.Username, PermissionSet.Name, PermissionSet.Label FROM PermissionSetAssignment WHERE Assignee.Username = '<target-username>' AND (PermissionSet.Name LIKE '%Agent%' OR PermissionSet.Label LIKE '%Agent%' OR PermissionSet.Name LIKE '%Einstein%' OR PermissionSet.Label LIKE '%Einstein%') ORDER BY PermissionSet.Label" --result-format json`

Stop if:

- the org lacks `Agentforce Studio`
- builder or admin capabilities are missing for the intended user
- the org shows only end-user Agentforce access but not custom-agent configuration access

## Gate 3: Data Cloud And CRM Readiness

Pulse360 agent behavior depends on the CRM/Data Cloud foundation already proved in the reference org.

Before migration, confirm the target org can support:

- the Pulse360 Account sync fields
- the Data Cloud source-object and DMO surfaces used by the seller and governance flows
- direct governance evidence reads where required by the orchestrator contract

Recommended validators:

- `./scripts/validate-contracts.sh`
- `./scripts/validate-salesforce-account-activation-fields.sh`
- `./scripts/validate-data-cloud-dmo-extension.sh`
- `./scripts/validate-data-cloud-field-path.sh`
- `./scripts/validate-agentforce-orchestrator.sh`

Stop if:

- the target org does not expose the required Data Cloud objects or fields
- the org still relies on stale activation-target assumptions rather than the implemented Copy Field Enrichment path
- governance evidence reads cannot be grounded in the target runtime

## Gate 4: Agent Metadata Binding Review

The agent bundle is portable, but the `default_agent_user` value is not inherently portable.

Current repo binding:

- file: [Pulse360_Agent.agent](/Users/danielnortje/Documents/Pulse360/force-app/main/default/aiAuthoringBundles/Pulse360_Agent/Pulse360_Agent.agent)
- current value: `dnortje.37cf563036b7@agentforce.com`

Before deploying to a different org:

- confirm whether that user exists in the target org
- if not, update the metadata to the actual target agent user
- revalidate any permission-set or setup assumptions tied to that user

Stop if:

- the repo still points at a user that belongs only to the old org
- the target org uses a different login identity and the binding has not been reviewed

## Gate 5: Dry-Run Deployment

Perform a validate-only or lowest-risk deploy path before treating the target org as migration-ready.

Confirm all of the following:

- Salesforce metadata deploys cleanly
- the `aiAuthoringBundles` asset is accepted by the target org
- no Agentforce-specific metadata errors are returned

Recommended checks:

- generate or refresh a manifest from source
- validate-only deploy where practical
- inspect deployment errors specifically for Agentforce bundle handling and org capability mismatches

## Gate 6: Functional Pulse360 Agent Proof

Do not treat the migration as complete until the target org can prove the agent experience, not just the metadata deploy.

Minimum proof:

- `Pulse360 Agent` can be created, opened, or materialized in Agentforce Studio
- seller routing works for account/action prompts
- governance routing works for duplicate-review prompts
- the runtime can explain missing evidence instead of hallucinating it

Preferred proof:

- open a seeded Account and confirm seller context is grounded in live CRM fields
- open a seeded `Governance_Case__c` record and confirm the governance path fails closed when direct evidence is unavailable

## Recommended Migration Sequence

1. Authenticate the target org and record exact org identity.
2. Validate Agentforce Studio, licenses, and target-user access.
3. Run the repo validators against the target org.
4. Review and, if needed, update `default_agent_user`.
5. Run a validate-only deployment.
6. Open Agentforce Studio and confirm `Pulse360 Agent` can be created or managed.
7. Run seller and governance smoke tests on seeded records.

## Current Recommendation

The repo is ready for a target-org capability gate, but the new org should not yet replace `pulse360-dev` as the working Pulse360 reference until:

- Agentforce builder access is proven
- CRM metadata required by the Pulse360 Account sync path is present or validated for deployment
- Data Cloud source-object and DMO extension surfaces are present in the target org
- `Pulse360 Agent` can be created or opened in that org

## 2026-04-23 Clarification

The checks above are necessary but still not sufficient to claim a real native Agentforce experience on an Account page.

As of 2026-04-23, the repo can prove all of the following independently:

- Agentforce-related source metadata exists in repo.
- Agentforce-related metadata can deploy successfully to `pulse360-agent-target`.
- Apex-backed ask and execute paths can respond successfully in-org.
- Custom LWC surfaces can expose guided seller interactions on the Account record page.

Those proofs do not by themselves mean that `pulse360-agent-target` has a fully working native Agentforce runtime surface for the intended seller experience.

Do not claim native Agentforce success for this org unless all of the following are demonstrated directly:

- a native Agentforce conversational surface is visible to the intended user
- the user can submit free-text prompts through that surface
- the runtime uses the configured Agentforce instructions/subagents/actions rather than only custom LWC wiring
- approval-aware actions execute through the native agent path

If only the custom LWC path is proven, describe it as a custom assistant or fallback panel, not a real Agentforce runtime.

Current state after the 2026-04-17 migration pass:

- Salesforce metadata migration is complete for the current `force-app` source.
- Pulse360 CRM-side Account sync fields are deployed and validated in `pulse360-agent-target`.
- The recovered Data Cloud stream/source path now exists and validates in `pulse360-agent-target`.
- The Pulse360 `Account` DMO surface and Salesforce `Account` activation surface are both queryable in `pulse360-agent-target`.
- `Pulse360 Agent` opens in Agentforce Builder in `pulse360-agent-target` as `Version 1 (Draft)` with `0 Errors`.
- `DC Export Accounts P360 Fix` and `dc_export_accounts_p360_fix__dll` are now the canonical dev-instance Data Cloud runtime path in `pulse360-agent-target`.
- The legacy `datacloud_export_accounts Pulse360_Datab` path has been retired from `pulse360-agent-target`, so the target org no longer has a split-brain Data Cloud source for Pulse360 validation.
- The canonical stream has now been proven with a fresh live Databricks export, not only with the corrected sample file, so the dev-instance solution path is reintegrated across Databricks, Data Cloud, Salesforce, and Agentforce.
- On 2026-04-18, the target org was seeded with the public-regional walkthrough fixtures:
  - `JG Summit Holdings, Inc.`: `001dL000024xj2cQAA`
  - `Ayala Corporation`: `001dL000024wgYRQAY`
  - `Ayala Corp.`: `001dL000024weudQAA`
  - `Ayala duplicate review`: `a00dL000036IsSgQAK`
- On 2026-04-18, the `Account Record Page` and `Governance Case Record Page` were activated as org defaults in `pulse360-agent-target`.
- On 2026-04-18, the live seller walkthrough rendered on `JG Summit Holdings, Inc.` with the `Commercial Group`, `Trust and Agent Support`, and `GoTyme Bank` whitespace cards visible on the record page.
- On 2026-04-18, the live governance walkthrough rendered on `GC-00000` with `Match Evidence`, `Decision Workspace`, and the direct-evidence execution guard visible on the record page.
