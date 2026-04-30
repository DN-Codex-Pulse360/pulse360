#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
temp_dir="$(mktemp -d)"
trap 'rm -rf "$temp_dir"' EXIT

"$repo_root/scripts/build-salesforce-package-workspace.sh" "$temp_dir/workspace" >/dev/null

workspace="$temp_dir/workspace"

[[ -f "$workspace/sfdx-project.json" ]] || fail "Generated Salesforce workspace is missing sfdx-project.json"
[[ -f "$workspace/README.md" ]] || fail "Generated Salesforce workspace is missing README.md"
[[ -d "$workspace/packages/account-intelligence/main/default/objects/Account/fields" ]] \
  || fail "Account intelligence package is missing Account fields"
[[ -d "$workspace/packages/account-intelligence/main/default/objects/Pulse360_Seller_Play__mdt" ]] \
  || fail "Account intelligence package is missing Pulse360 seller play metadata"
[[ -f "$workspace/packages/account-intelligence/main/default/customMetadata/Pulse360_Seller_Play__mdt.ACMobility_Logistics_Whitespace.md-meta.xml" ]] \
  || fail "Account intelligence package is missing the ACMobility logistics whitespace seller play"
[[ -f "$workspace/packages/account-intelligence/main/default/customMetadata/Pulse360_Seller_Play__mdt.Group_Coverage_Validation.md-meta.xml" ]] \
  || fail "Account intelligence package is missing the group coverage validation seller play"
[[ -f "$workspace/packages/account-intelligence/main/default/customMetadata/Pulse360_Seller_Play__mdt.NCS_Data_AI_Modernization.md-meta.xml" ]] \
  || fail "Account intelligence package is missing the NCS data and AI modernization seller play"
[[ -f "$workspace/packages/account-intelligence/main/default/customMetadata/Pulse360_Seller_Play__mdt.Rewards_Analytics_GoTyme.md-meta.xml" ]] \
  || fail "Account intelligence package is missing the Rewards Analytics GoTyme seller play"
[[ -f "$workspace/packages/account-intelligence/main/default/classes/Pulse360HealthScanService.cls" ]] \
  || fail "Account intelligence package is missing Pulse360HealthScanService"
[[ -f "$workspace/packages/account-intelligence/main/default/classes/Pulse360SellerWorkspaceService.cls" ]] \
  || fail "Account intelligence package is missing Pulse360SellerWorkspaceService"
[[ -f "$workspace/packages/account-intelligence/main/default/classes/Pulse360SellerOrchestratorService.cls" ]] \
  || fail "Account intelligence package is missing Pulse360SellerOrchestratorService"
[[ -f "$workspace/packages/account-intelligence/main/default/classes/Pulse360GetAccountContextAction.cls" ]] \
  || fail "Account intelligence package is missing Pulse360GetAccountContextAction"
[[ -f "$workspace/packages/account-intelligence/main/default/classes/Pulse360ExecuteSellerAction.cls" ]] \
  || fail "Account intelligence package is missing Pulse360ExecuteSellerAction"
[[ -f "$workspace/packages/account-intelligence/main/default/classes/Pulse360SellerWorkspaceDirectoryService.cls" ]] \
  || fail "Account intelligence package is missing Pulse360SellerWorkspaceDirectoryService"
[[ -f "$workspace/packages/account-intelligence/main/default/classes/Pulse360PlannerWorkspaceService.cls" ]] \
  || fail "Account intelligence package is missing Pulse360PlannerWorkspaceService"
[[ -f "$workspace/packages/account-intelligence/main/default/classes/Pulse360SignalRoutingWorkspaceService.cls" ]] \
  || fail "Account intelligence package is missing Pulse360SignalRoutingWorkspaceService"
[[ -f "$workspace/packages/account-intelligence/main/default/flexipages/Account_Record_Page.flexipage-meta.xml" ]] \
  || fail "Account intelligence package is missing the Account flexipage"
[[ -f "$workspace/packages/account-intelligence/main/default/permissionsets/Pulse360_Account_Intelligence_User.permissionset-meta.xml" ]] \
  || fail "Account intelligence package is missing the account intelligence permission set"
[[ -d "$workspace/packages/account-intelligence/main/default/lwc/pulse360HealthScan" ]] \
  || fail "Account intelligence package is missing pulse360HealthScan"
[[ -d "$workspace/packages/account-intelligence/main/default/lwc/pulse360NarrativeCard" ]] \
  || fail "Account intelligence package is missing pulse360NarrativeCard"
[[ -d "$workspace/packages/account-intelligence/main/default/lwc/pulse360NextBestAction" ]] \
  || fail "Account intelligence package is missing pulse360NextBestAction"
[[ -d "$workspace/packages/account-intelligence/main/default/lwc/pulse360GroupRevenueReveal" ]] \
  || fail "Account intelligence package is missing pulse360GroupRevenueReveal"
[[ -d "$workspace/packages/account-intelligence/main/default/lwc/pulse360SellerWorkspace" ]] \
  || fail "Account intelligence package is missing pulse360SellerWorkspace"
[[ -d "$workspace/packages/account-intelligence/main/default/lwc/pulse360SellerWorkspaceSidebar" ]] \
  || fail "Account intelligence package is missing pulse360SellerWorkspaceSidebar"
[[ -d "$workspace/packages/account-intelligence/main/default/lwc/pulse360SellerWorkspaceActionSupport" ]] \
  || fail "Account intelligence package is missing pulse360SellerWorkspaceActionSupport"
[[ -d "$workspace/packages/account-intelligence/main/default/lwc/pulse360SellerWorkspaceAgentforceSupport" ]] \
  || fail "Account intelligence package is missing pulse360SellerWorkspaceAgentforceSupport"
[[ -d "$workspace/packages/account-intelligence/main/default/lwc/pulse360SellerWorkspaceV2" ]] \
  || fail "Account intelligence package is missing pulse360SellerWorkspaceV2"
[[ -d "$workspace/packages/account-intelligence/main/default/lwc/pulse360PlannerWorkspace" ]] \
  || fail "Account intelligence package is missing pulse360PlannerWorkspace"
[[ -d "$workspace/packages/account-intelligence/main/default/lwc/pulse360RenewalRiskWorkspace" ]] \
  || fail "Account intelligence package is missing pulse360RenewalRiskWorkspace"
[[ -d "$workspace/packages/account-intelligence/main/default/lwc/pulse360SignalRoutingWorkspace" ]] \
  || fail "Account intelligence package is missing pulse360SignalRoutingWorkspace"
[[ -f "$workspace/packages/account-intelligence/main/default/messageChannels/Pulse360SellerWorkspaceContext.messageChannel-meta.xml" ]] \
  || fail "Account intelligence package is missing Pulse360SellerWorkspaceContext message channel"
[[ -f "$workspace/packages/account-intelligence/main/default/tabs/Pulse360_Planner.tab-meta.xml" ]] \
  || fail "Account intelligence package is missing Pulse360_Planner tab metadata"
[[ -f "$workspace/packages/account-intelligence/main/default/tabs/Pulse360_Renewal_Risk.tab-meta.xml" ]] \
  || fail "Account intelligence package is missing Pulse360_Renewal_Risk tab metadata"
[[ -f "$workspace/packages/account-intelligence/main/default/tabs/Pulse360_Seller_V2.tab-meta.xml" ]] \
  || fail "Account intelligence package is missing Pulse360_Seller_V2 tab metadata"
[[ -f "$workspace/packages/account-intelligence/main/default/tabs/Pulse360_Signal_Routing.tab-meta.xml" ]] \
  || fail "Account intelligence package is missing Pulse360_Signal_Routing tab metadata"
[[ ! -f "$workspace/packages/account-intelligence/main/default/classes/Pulse360AgentOrchestratorService.cls" ]] \
  || fail "Account intelligence package should not include Pulse360AgentOrchestratorService"
[[ ! -f "$workspace/packages/account-intelligence/main/default/classes/Pulse360GetReviewContextAction.cls" ]] \
  || fail "Account intelligence package should not include governance invocable actions"
[[ ! -d "$workspace/packages/account-intelligence/main/default/objects/Governance_Case__c" ]] \
  || fail "Account intelligence package should not include Governance_Case__c metadata"
[[ ! -d "$workspace/packages/account-intelligence/main/default/lwc/pulse360GovernanceDecisionWorkspace" ]] \
  || fail "Account intelligence package should not include governance decision LWCs"
[[ ! -d "$workspace/packages/account-intelligence/main/default/lwc/governanceCaseReview" ]] \
  || fail "Account intelligence package should not include governanceCaseReview"
[[ ! -d "$workspace/packages/account-intelligence/main/default/lwc/pulse360GovernanceSnapshot" ]] \
  || fail "Account intelligence package should not include governance snapshot LWCs"
[[ ! -d "$workspace/packages/account-intelligence/main/default/lwc/pulse360GovernanceMatchEvidence" ]] \
  || fail "Account intelligence package should not include governance evidence LWCs"
[[ ! -d "$workspace/packages/account-intelligence/main/default/lwc/pulse360GovernanceAuditOutcome" ]] \
  || fail "Account intelligence package should not include governance audit outcome LWCs"
[[ ! -d "$workspace/packages/account-intelligence/main/default/lwc/pulse360SellerWorkspaceAction" ]] \
  || fail "Account intelligence package should not include the retired seller action bundle"
[[ ! -d "$workspace/packages/account-intelligence/main/default/lwc/pulse360SellerWorkspaceContext" ]] \
  || fail "Account intelligence package should not include the retired seller context bundle"
[[ ! -d "$workspace/packages/account-intelligence/main/default/lwc/pulse360SellerWorkspaceFollowThrough" ]] \
  || fail "Account intelligence package should not include the retired seller follow-through bundle"
[[ ! -d "$workspace/packages/account-intelligence/main/default/lwc/pulse360SellerWorkspaceGroup" ]] \
  || fail "Account intelligence package should not include the retired seller group bundle"
[[ ! -d "$workspace/packages/account-intelligence/main/default/lwc/pulse360SellerWorkspaceHeader" ]] \
  || fail "Account intelligence package should not include the retired seller header bundle"
[[ ! -d "$workspace/packages/account-intelligence/main/default/lwc/pulse360SellerWorkspaceMetrics" ]] \
  || fail "Account intelligence package should not include the retired seller metrics bundle"
[[ ! -f "$workspace/packages/account-intelligence/main/default/permissionsets/Governance_Case_Steward.permissionset-meta.xml" ]] \
  || fail "Account intelligence package should not include the governance permission set"
[[ ! -f "$workspace/packages/account-intelligence/main/default/tabs/Governance_Case__c.tab-meta.xml" ]] \
  || fail "Account intelligence package should not include the Governance Case tab"
[[ -d "$workspace/packages/governance/main/default/objects/Governance_Case__c" ]] \
  || fail "Governance package is missing Governance_Case__c metadata"
[[ -f "$workspace/packages/governance/main/default/classes/GovernanceCaseDecisionStamping.cls" ]] \
  || fail "Governance package is missing GovernanceCaseDecisionStamping"
[[ -f "$workspace/packages/governance/main/default/classes/Pulse360AgentOrchestratorService.cls" ]] \
  || fail "Governance package is missing Pulse360AgentOrchestratorService"
[[ -f "$workspace/packages/governance/main/default/classes/Pulse360GetReviewContextAction.cls" ]] \
  || fail "Governance package is missing Pulse360GetReviewContextAction"
[[ -f "$workspace/packages/governance/main/default/classes/Pulse360GetDataCloudReviewEvidenceAction.cls" ]] \
  || fail "Governance package is missing Pulse360GetDataCloudReviewEvidenceAction"
[[ -f "$workspace/packages/governance/main/default/classes/Pulse360RecordGovernanceDecisionAction.cls" ]] \
  || fail "Governance package is missing Pulse360RecordGovernanceDecisionAction"
[[ -f "$workspace/packages/governance/main/default/triggers/GovernanceCaseDecisionStamping.trigger" ]] \
  || fail "Governance package is missing GovernanceCaseDecisionStamping trigger"
[[ -f "$workspace/packages/governance/main/default/flexipages/Governance_Case_Record_Page.flexipage-meta.xml" ]] \
  || fail "Governance package is missing the Governance Case record page"
[[ -f "$workspace/packages/governance/main/default/tabs/Governance_Case__c.tab-meta.xml" ]] \
  || fail "Governance package is missing the Governance Case tab"
[[ -d "$workspace/packages/governance/main/default/lwc/governanceCaseReview" ]] \
  || fail "Governance package is missing governanceCaseReview"
[[ -d "$workspace/packages/governance/main/default/lwc/pulse360GovernanceSnapshot" ]] \
  || fail "Governance package is missing pulse360GovernanceSnapshot"
[[ -d "$workspace/packages/governance/main/default/lwc/pulse360GovernanceMatchEvidence" ]] \
  || fail "Governance package is missing pulse360GovernanceMatchEvidence"
[[ -d "$workspace/packages/governance/main/default/lwc/pulse360GovernanceDecisionWorkspace" ]] \
  || fail "Governance package is missing pulse360GovernanceDecisionWorkspace"
[[ -d "$workspace/packages/governance/main/default/lwc/pulse360GovernanceAuditOutcome" ]] \
  || fail "Governance package is missing pulse360GovernanceAuditOutcome"
[[ -f "$workspace/packages/governance/main/default/permissionsets/Governance_Case_Steward.permissionset-meta.xml" ]] \
  || fail "Governance package is missing the Governance steward permission set"
[[ ! -f "$workspace/packages/governance/main/default/classes/Pulse360SellerOrchestratorService.cls" ]] \
  || fail "Governance package should not include Pulse360SellerOrchestratorService"
[[ ! -f "$workspace/packages/governance/main/default/classes/Pulse360GetAccountContextAction.cls" ]] \
  || fail "Governance package should not include seller invocable actions"
[[ ! -f "$workspace/packages/governance/main/default/classes/Pulse360ExecuteSellerAction.cls" ]] \
  || fail "Governance package should not include seller execution actions"
[[ ! -d "$workspace/packages/governance/main/default/lwc/pulse360SellerWorkspace" ]] \
  || fail "Governance package should not include seller workspace LWCs"
[[ ! -d "$workspace/packages/governance/main/default/lwc/pulse360SellerWorkspaceSidebar" ]] \
  || fail "Governance package should not include seller sidebar LWCs"
[[ ! -d "$workspace/packages/governance/main/default/lwc/pulse360SellerWorkspaceActionSupport" ]] \
  || fail "Governance package should not include seller action-support LWCs"
[[ ! -d "$workspace/packages/governance/main/default/lwc/pulse360SellerWorkspaceAgentforceSupport" ]] \
  || fail "Governance package should not include seller Agentforce-support LWCs"
[[ ! -d "$workspace/packages/governance/main/default/lwc/pulse360SellerWorkspaceV2" ]] \
  || fail "Governance package should not include seller workspace v2"
[[ ! -d "$workspace/packages/governance/main/default/lwc/pulse360PlannerWorkspace" ]] \
  || fail "Governance package should not include planner workspace LWCs"
[[ ! -d "$workspace/packages/governance/main/default/lwc/pulse360RenewalRiskWorkspace" ]] \
  || fail "Governance package should not include renewal-risk workspace LWCs"
[[ ! -d "$workspace/packages/governance/main/default/lwc/pulse360SignalRoutingWorkspace" ]] \
  || fail "Governance package should not include signal-routing workspace LWCs"
[[ ! -d "$workspace/packages/governance/main/default/lwc/pulse360HealthScan" ]] \
  || fail "Governance package should not include health scan LWCs"
[[ ! -d "$workspace/packages/governance/main/default/lwc/pulse360NarrativeCard" ]] \
  || fail "Governance package should not include narrative card LWCs"
[[ ! -d "$workspace/packages/governance/main/default/lwc/pulse360NextBestAction" ]] \
  || fail "Governance package should not include next-best-action LWCs"
[[ ! -d "$workspace/packages/governance/main/default/lwc/pulse360GroupRevenueReveal" ]] \
  || fail "Governance package should not include group-revenue LWCs"
[[ ! -f "$workspace/packages/governance/main/default/messageChannels/Pulse360SellerWorkspaceContext.messageChannel-meta.xml" ]] \
  || fail "Governance package should not include the seller workspace message channel"
[[ ! -f "$workspace/packages/governance/main/default/permissionsets/Pulse360_Account_Intelligence_User.permissionset-meta.xml" ]] \
  || fail "Governance package should not include the account intelligence permission set"
[[ ! -f "$workspace/packages/governance/main/default/flexipages/Account_Record_Page.flexipage-meta.xml" ]] \
  || fail "Governance package should not include the Account record page"
[[ ! -f "$workspace/packages/governance/main/default/tabs/Pulse360_Seller_V2.tab-meta.xml" ]] \
  || fail "Governance package should not include seller tabs"

grep -Fq '"package": "pulse360-account-intelligence"' "$workspace/sfdx-project.json" \
  || fail "Generated sfdx-project.json is missing pulse360-account-intelligence"
grep -Fq '"package": "pulse360-governance"' "$workspace/sfdx-project.json" \
  || fail "Generated sfdx-project.json is missing pulse360-governance"
grep -Fq '"dependencies"' "$workspace/sfdx-project.json" \
  || fail "Generated sfdx-project.json is missing package dependency metadata"
grep -Fq '## Current Split' "$workspace/README.md" \
  || fail "Generated Salesforce workspace README is missing the current split section"
grep -Fq 'seller workspace runtime and seller execution orchestration' "$workspace/README.md" \
  || fail "Generated Salesforce workspace README is missing the seller package summary"
grep -Fq 'governance review orchestration and direct-evidence actions' "$workspace/README.md" \
  || fail "Generated Salesforce workspace README is missing the governance package summary"

pass "Salesforce package layout validation completed"
