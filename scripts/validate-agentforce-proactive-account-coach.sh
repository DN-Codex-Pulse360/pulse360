#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

search_fixed() {
  local needle="$1"
  shift

  if command -v rg >/dev/null 2>&1; then
    rg -Fq "$needle" "$@"
  else
    grep -Fq -- "$needle" "$@"
  fi
}

agent_file="force-app/main/default/aiAuthoringBundles/Pulse360_Agent/Pulse360_Agent.agent"
bundle_meta="force-app/main/default/aiAuthoringBundles/Pulse360_Agent/Pulse360_Agent.bundle-meta.xml"
action_class="force-app/main/default/classes/Pulse360GetProactiveSignalBriefAction.cls"
action_test="force-app/main/default/classes/Pulse360ProactiveSignalBriefTest.cls"
task_action_class="force-app/main/default/classes/Pulse360PrepReviewTaskAction.cls"
task_action_test="force-app/main/default/classes/Pulse360PrepReviewTaskActionTest.cls"
contract_doc="docs/contracts/pulse360-agentforce-capability-gate-contract.md"
permset="force-app/main/default/permissionsets/Pulse360_Account_Intelligence_User.permissionset-meta.xml"
account_quick_action="force-app/main/default/quickActions/Account.Pulse360_Proactive_Brief.quickAction-meta.xml"
account_layout="force-app/main/default/layouts/Account-Account Layout.layout-meta.xml"

for path in "$agent_file" "$bundle_meta" "$action_class" "$action_test" "$task_action_class" "$task_action_test"; do
  [[ -f "$path" ]] || fail "Missing Agentforce proactive coach artifact: $path"
done
pass "Agentforce proactive coach source artifacts exist"

search_fixed "<bundleType>AGENT</bundleType>" "$bundle_meta" \
  || fail "Agentforce bundle metadata must declare bundleType AGENT"
pass "Agentforce bundle metadata declares AGENT bundle type"

for token in \
  "topic proactive_account_coach" \
  "Proactive Account Coach" \
  "Get Proactive Signal Brief" \
  "apex://Pulse360GetProactiveSignalBriefAction" \
  "require_user_confirmation: True" \
  "runtime_unproven" \
  "native Agentforce runtime is not yet proven" \
  "Tasks and Opportunities are downstream effects" \
  "Prepare Account Review Task" \
  "apex://Pulse360PrepReviewTaskAction" \
  "with confirmed = ..." \
  "confirmed=true only after that confirmation" \
  "Opportunity creation requires a separate approval path"; do
  search_fixed "$token" "$agent_file" || fail "Agent metadata missing token: $token"
done
pass "Agent metadata defines a proactive account coach with explicit runtime and confirmation boundaries"

for token in \
  "@InvocableMethod" \
  "Get Proactive Signal Brief" \
  "briefJson" \
  "sourceRefsJson" \
  "approvalPolicyJson" \
  "runtime_unproven" \
  "review_required_missing_source_refs" \
  "blocked_missing_account_id"; do
  search_fixed "$token" "$action_class" || fail "Proactive signal brief action missing token: $token"
done
pass "Apex action exposes a non-mutating proactive signal brief contract"

for token in \
  "returnsGroundedProactiveSignalBrief" \
  "blocksMissingAccountId" \
  "requiresReviewWhenSourceRefsAreMissing" \
  "System.assertEquals('runtime_unproven'" \
  "System.assert(actionResult.briefJson.contains('Northstar Foods Group'))"; do
  search_fixed "$token" "$action_test" || fail "Apex test missing token: $token"
done
pass "Apex tests cover grounded brief, missing account, and missing source refs"

for token in \
  "@InvocableMethod" \
  "Prepare Account Review Task" \
  "confirmed" \
  "blocked_confirmation_required" \
  "review_required_missing_source_refs" \
  "blocked_high_impact_action_requires_separate_approval" \
  "task_created" \
  "insert tasksToInsert" \
  "high_impact_actions_require_separate_approval"; do
  search_fixed "$token" "$task_action_class" || fail "Governed Task action missing token: $token"
done
pass "Apex Task action exposes a confirmation-gated seller execution contract"

for token in \
  "createsTaskAfterConfirmationWithSourceRefs" \
  "blocksWithoutConfirmationAndDoesNotMutate" \
  "requiresReviewWhenSourceRefsAreMissingAndDoesNotMutate" \
  "blocksOpportunityCreationAndDoesNotMutate" \
  "System.assertEquals('task_created'" \
  "System.assertEquals('blocked_confirmation_required'" \
  "System.assertEquals('blocked_high_impact_action_requires_separate_approval'"; do
  search_fixed "$token" "$task_action_test" || fail "Governed Task action test missing token: $token"
done
pass "Apex Task action tests cover confirmation, source-ref, and high-impact gates"

[[ -f "$permset" ]] || fail "Missing Pulse360 Account Intelligence permission set"
search_fixed "Pulse360GetProactiveSignalBriefAction" "$permset" \
  || fail "Permission set must expose the proactive signal brief Agentforce action"
search_fixed "Pulse360PrepReviewTaskAction" "$permset" \
  || fail "Permission set must expose the governed Task Agentforce action"
pass "Permission set exposes the proactive signal brief and governed Task actions"

[[ -f "$account_quick_action" ]] || fail "Missing Account-page Agentforce quick action: $account_quick_action"
for token in \
  "<label>Pulse360 Proactive Brief</label>" \
  "<type>Copilot</type>" \
  "<name>User Utterance</name>" \
  "Pulse360 proactive signal brief" \
  "{!Account.Id}" \
  "001dL00002HTb4cQAD" \
  "ask for confirmation before creating any Task" \
  "do not create Opportunities"; do
  search_fixed "$token" "$account_quick_action" || fail "Account-page quick action missing token: $token"
done
pass "Account-page quick action passes explicit Account context and approval policy to Agentforce"

[[ -f "$account_layout" ]] || fail "Missing Account layout with Account-page action placement"
search_fixed "<actionName>Account.Pulse360_Proactive_Brief</actionName>" "$account_layout" \
  || fail "Account layout must include the Pulse360 Agentforce quick action in the record action list"
search_fixed "<quickActionName>Account.Pulse360_Proactive_Brief</quickActionName>" "$account_layout" \
  || fail "Account layout must include the Pulse360 Agentforce quick action in the quick action list"
pass "Account layout exposes the Pulse360 Agentforce quick action on Account records"

if search_fixed "Task created" "$agent_file" "$action_class" "$action_test"; then
  fail "Agentforce proactive coach must not use Task creation as the primary proof"
fi

if [[ -f "$contract_doc" ]]; then
  search_fixed "runtime_verified" "$contract_doc" \
    || fail "Agentforce capability contract must retain runtime verification gate"
fi

pass "Agentforce proactive account coach validation completed"
