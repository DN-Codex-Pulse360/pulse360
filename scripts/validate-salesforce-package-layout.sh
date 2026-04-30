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
[[ -d "$workspace/packages/account-intelligence/main/default/objects/Account/fields" ]] \
  || fail "Account intelligence package is missing Account fields"
[[ -f "$workspace/packages/account-intelligence/main/default/classes/Pulse360HealthScanService.cls" ]] \
  || fail "Account intelligence package is missing Pulse360HealthScanService"
[[ -f "$workspace/packages/account-intelligence/main/default/flexipages/Account_Record_Page.flexipage-meta.xml" ]] \
  || fail "Account intelligence package is missing the Account flexipage"
for lwc in \
  pulse360AccountWorkspaceHeader \
  pulse360AccountSummaryPanel \
  pulse360AgentPanel \
  pulse360RecommendedMovePanel \
  pulse360EntityFocusPanel \
  pulse360AccountWorkspaceGuidance \
  pulse360AccountTimelinePanel \
  pulse360TrustPanel \
  pulse360RenewalRiskPanel \
  pulse360PlannerHeader \
  pulse360PlannerFilterBar \
  pulse360PlannerSummaryPanel \
  pulse360PlannerBoard \
  pulse360PlannerTimeline \
  pulse360PlannerActionRail; do
  [[ -d "$workspace/packages/account-intelligence/main/default/lwc/$lwc" ]] \
    || fail "Account intelligence package is missing $lwc"
  [[ ! -d "$workspace/packages/governance/main/default/lwc/$lwc" ]] \
    || fail "Governance package should not include $lwc"
done
[[ -d "$workspace/packages/governance/main/default/objects/Governance_Case__c" ]] \
  || fail "Governance package is missing Governance_Case__c metadata"
[[ -f "$workspace/packages/governance/main/default/triggers/GovernanceCaseDecisionStamping.trigger" ]] \
  || fail "Governance package is missing GovernanceCaseDecisionStamping trigger"
[[ -f "$workspace/packages/governance/main/default/permissionsets/Governance_Case_Steward.permissionset-meta.xml" ]] \
  || fail "Governance package is missing the Governance steward permission set"

grep -Fq '"package": "pulse360-account-intelligence"' "$workspace/sfdx-project.json" \
  || fail "Generated sfdx-project.json is missing pulse360-account-intelligence"
grep -Fq '"package": "pulse360-governance"' "$workspace/sfdx-project.json" \
  || fail "Generated sfdx-project.json is missing pulse360-governance"
grep -Fq '"dependencies"' "$workspace/sfdx-project.json" \
  || fail "Generated sfdx-project.json is missing package dependency metadata"

pass "Salesforce package layout validation completed"
