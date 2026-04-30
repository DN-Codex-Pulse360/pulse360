# Alignment Audit - 2026-04-19

## Scope

Read-only alignment audit across:

- live Salesforce org `pulse360-agent-target`
- live Databricks workspace at `https://dbc-7f0ce7bb-56ca.cloud.databricks.com`
- GitHub repo `DN-Codex-Pulse360/pulse360`
- Linear project `Pulse360`

Audit timestamp: `2026-04-19 04:01:14 UTC`

## Summary

The live Salesforce and Databricks runtime surfaces are largely aligned with the repo contracts for the current Pulse360 activation and seller-workspace stack.

The main drift is in GitHub and Linear:

- the local branch `codex/dan-114-runtime-check` is `ahead 1` of origin
- PR `#10` is still titled and scoped to `DAN-114`
- the unpublished head commit is seller-workspace v2 work that aligns more closely with `DAN-267` and its child issues than with `DAN-114`
- the local checkout is also heavily dirty beyond the unpublished head commit (`34` tracked modifications and `94` untracked files)

## Salesforce

### What was checked

- repo validation scripts:
  - `scripts/validate-salesforce-account-activation-fields.sh`
  - `scripts/validate-governance-case-metadata.sh`
  - `scripts/validate-account-intelligence-experience.sh`
  - `scripts/validate-agentforce-orchestrator.sh`
- live org field inventory through `sf data query --use-tooling-api`
- targeted metadata retrieve into `output/live-audit/salesforce-2026-04-19`

### Result

- account activation field validation passed locally and against the live org
- governance metadata validation passed
- account intelligence experience validation passed
- Agentforce orchestrator validation passed

### Inventory alignment

The live org contains the expected targeted Apex, LWC, FlexiPage, and permission-set inventory for the current Pulse360 runtime slice, including:

- `Pulse360SellerWorkspaceService`
- `Pulse360AgentOrchestratorService`
- `Pulse360GetAccountContextAction`
- `Pulse360GetReviewContextAction`
- `Pulse360GetDataCloudReviewEvidenceAction`
- `Pulse360ExecuteSellerAction`
- `Pulse360RecordGovernanceDecisionAction`
- `GovernanceCaseDecisionStamping`
- `pulse360SellerWorkspace`
- `pulse360SellerWorkspaceSidebar`
- `pulse360SellerWorkspaceActionSupport`
- `pulse360SellerWorkspaceAgentforceSupport`
- `governanceCaseReview`
- `pulse360GovernanceSnapshot`
- `pulse360GovernanceMatchEvidence`
- `pulse360GovernanceDecisionWorkspace`
- `pulse360GovernanceAuditOutcome`
- `Account Record Page`
- `Governance Case Record Page`
- `Pulse360_Account_Intelligence_User`
- `Governance_Case_Steward`

### Drift note

The retrieved files differ from repo files mostly because Metadata API reserializes XML and strips trailing newlines from code files. Sample diffs showed formatting/default-field noise such as:

- XML pretty-print expansion
- explicit defaults like `trackTrending=false`
- explicit defaults like `viewAllFields=false`
- LWC/FlexiPage serialization differences such as `c:pulse360SellerWorkspace` vs `pulse360SellerWorkspace`

No behavioral Salesforce drift was confirmed in the targeted runtime slice during this audit.

## Databricks

### What was checked

- repo validation script `scripts/validate-databricks-salesforce-sql-pack.sh`
- live workspace root visibility
- live jobs and pipelines
- Unity Catalog table metadata for:
  - `pulse360_s4.gold.account_export_base`
  - `pulse360_s4.intelligence.datacloud_export_accounts`
- repo contract `contracts/databricks_to_datacloud.schema.json`
- repo bundle configs in generated Databricks package workspaces

### Result

- the Databricks SQL package validation passed locally
- job `pulse360-salesforce-extract job` exists and is scheduled every `6` hours
- pipeline `pulse360-salesforce-extract` is `IDLE` with recent successful updates on `2026-04-18`
- `pulse360_s4.gold.account_export_base` exists as a `VIEW`
- `pulse360_s4.intelligence.datacloud_export_accounts` exists as a `MANAGED` Delta table
- live export objects were updated on `2026-04-18T05:01:49Z` and `2026-04-18T05:02:21Z`

### Contract alignment

The live `pulse360_s4.intelligence.datacloud_export_accounts` table contains all `41` required fields from `contracts/databricks_to_datacloud.schema.json`.

It also exposes additional live columns not captured in the schema:

- `canonical_account_id`
- `deterministic_key`
- `account_name`
- `ingestion_metadata_label`
- `run_ts`

These look additive rather than breaking, but they are contract drift if the schema is intended to be complete rather than minimum-required.

### Workspace sync drift

The repo-generated Databricks bundle configs declare workspace roots under:

- `/Workspace/Shared/pulse360/pulse360-account-intelligence-export/<target>`
- `/Workspace/Shared/pulse360/pulse360-salesforce-ingestion/<target>`

Those paths were not present in the live workspace during this audit.

Live workspace assets were visible under the user workspace, including dashboard files under `/Users/dnortje@danielnortje.com`.

This suggests one of the following:

1. bundle sync has not been run to the repo-declared shared paths
2. live code is being operated from a different workspace location than the repo currently documents

## GitHub

### Repo state

- remote repo: `DN-Codex-Pulse360/pulse360`
- default branch: `main`
- open GitHub issues returned by `gh issue list`: none

### Branch and PR state

- local branch: `codex/dan-114-runtime-check`
- remote tracking branch: `origin/codex/dan-114-runtime-check`
- branch status: `ahead 1`
- open PR for current branch: `#10`
- PR title: `DAN-114 runtime updates and package workspaces`
- PR last updated: `2026-04-01T08:28:54Z`

### Ahead commit

Local-only head commit:

- SHA: `22d063766094fba12891aecc5b75c28577446781`
- subject: `Implement insight-to-action seller workspace flow`
- author date: `2026-04-15 11:07:45 +0800`

This commit changes `35` files concentrated in:

- `force-app/main/default/lwc/pulse360SellerWorkspace/**`
- `force-app/main/default/lwc/pulse360SellerWorkspaceAction/**`
- `force-app/main/default/lwc/pulse360SellerWorkspaceContext/**`
- `force-app/main/default/lwc/pulse360SellerWorkspaceFollowThrough/**`
- `force-app/main/default/lwc/pulse360SellerWorkspaceGroup/**`
- `force-app/main/default/lwc/pulse360SellerWorkspaceHeader/**`
- `force-app/main/default/lwc/pulse360SellerWorkspaceMetrics/**`
- `force-app/main/default/lwc/pulse360SellerWorkspaceSidebar/**`
- `force-app/main/default/messageChannels/Pulse360SellerWorkspaceContext.messageChannel-meta.xml`

### Drift note

GitHub is not aligned with the actual local branch content:

- PR `#10` still describes `DAN-114` activation/runtime/package workspaces
- the unpublished local head is seller-workspace v2 work
- the PR has not been updated since `2026-04-01`

## Linear

### Project state

Project `Pulse360` is `In Progress`.

Project summary currently says:

`Databricks intelligence, Data Cloud source ingestion, and Salesforce experience layers are built. Critical path is Milestone C: finish Account DMO fields, complete mapping, and prove writeback to Salesforce Account.`

Project `updatedAt`: `2026-04-09T01:57:36.540Z`

### Relevant issues

- `DAN-114` is still `In Progress`
- `DAN-114` updated at `2026-04-09T05:43:18.372Z`
- `DAN-267` is `In Progress`
- `DAN-267` updated at `2026-04-15T05:27:23.369Z`
- seller-experience child issues under `DAN-267` include `DAN-269`, `DAN-273`, and `DAN-274`

### Drift note

Linear and GitHub are not telling the same story:

- the branch name and PR point to `DAN-114`
- the unpublished head commit content maps more naturally to the `DAN-267` seller-experience line of work
- `DAN-114` remains active even though the live Salesforce and Databricks activation/runtime slices validated successfully in this audit

## Alignment Assessment

### Aligned now

- live Salesforce runtime inventory and repo runtime contracts
- live Databricks export/table contracts and repo-required activation fields
- live Databricks ingestion cadence and runbook expectations

### Not aligned now

- GitHub branch/PR labeling versus actual local branch content
- Linear issue mapping versus actual local branch content
- repo-declared Databricks bundle workspace root versus observed live workspace paths

## Recommended Next Actions

These require a deliberate decision before mutation:

1. Decide whether seller-workspace v2 stays on `codex/dan-114-runtime-check` or is split to a new `DAN-267` branch and PR.
2. If seller-workspace v2 is `DAN-267` work, push the ahead commit to a branch/PR aligned with `DAN-267` and keep `DAN-114` scoped to activation/runtime closure.
3. Update Linear so `DAN-114` reflects the successful runtime/activation evidence and `DAN-267` owns the seller-workspace v2 implementation thread.
4. Either sync the Databricks bundle into the repo-declared shared workspace root or update the repo docs/config to reflect the actual live workspace pathing model.
