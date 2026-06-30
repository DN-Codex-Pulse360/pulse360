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
action_class="force-app/main/default/classes/Pulse360GetProactiveSignalBriefAction.cls"
action_test="force-app/main/default/classes/Pulse360ProactiveSignalBriefTest.cls"
contract_doc="docs/contracts/pulse360-agentforce-capability-gate-contract.md"
permset="force-app/main/default/permissionsets/Pulse360_Account_Intelligence_User.permissionset-meta.xml"

for path in "$agent_file" "$action_class" "$action_test"; do
  [[ -f "$path" ]] || fail "Missing Agentforce proactive coach artifact: $path"
done
pass "Agentforce proactive coach source artifacts exist"

for token in \
  "topic proactive_account_coach" \
  "Proactive Account Coach" \
  "Get Proactive Signal Brief" \
  "apex://Pulse360GetProactiveSignalBriefAction" \
  "require_user_confirmation: True" \
  "runtime_unproven" \
  "native Agentforce runtime is not yet proven" \
  "Tasks and Opportunities are downstream effects"; do
  search_fixed "$token" "$agent_file" || fail "Agent metadata missing token: $token"
done
pass "Agent metadata defines a proactive account coach with explicit runtime boundary"

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

[[ -f "$permset" ]] || fail "Missing Pulse360 Account Intelligence permission set"
search_fixed "Pulse360GetProactiveSignalBriefAction" "$permset" \
  || fail "Permission set must expose the proactive signal brief Agentforce action"
pass "Permission set exposes the proactive signal brief action"

if search_fixed "Task created" "$agent_file" "$action_class" "$action_test"; then
  fail "Agentforce proactive coach must not use Task creation as the primary proof"
fi

if [[ -f "$contract_doc" ]]; then
  search_fixed "runtime_verified" "$contract_doc" \
    || fail "Agentforce capability contract must retain runtime verification gate"
fi

pass "Agentforce proactive account coach validation completed"
