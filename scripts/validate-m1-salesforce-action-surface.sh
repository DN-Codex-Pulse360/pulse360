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

contract_doc="docs/contracts/pulse360-m1-salesforce-action-surface-contract.md"
schema="contracts/m1_account_hierarchy_action_pack.schema.json"
sample="data/samples/m1_account_hierarchy_action_pack_sample.json"
matrix="config/salesforce/m1-account-hierarchy-action-surface-matrix.csv"

for file in "$contract_doc" "$schema" "$sample" "$matrix"; do
  [[ -f "$file" ]] || fail "Missing required M1 Salesforce action surface file: $file"
done
pass "M1 Salesforce action surface files are present"

python3 -m json.tool "$schema" >/dev/null || fail "Invalid JSON schema: $schema"
python3 -m json.tool "$sample" >/dev/null || fail "Invalid JSON sample: $sample"
pass "M1 Salesforce action JSON files parse"

expected_header="journey,surface,source_payload,component_or_service,default_summary,drillthrough,action_type,artifact_created,approval_gate,crm_safe_key,guardrail"
actual_header="$(head -n 1 "$matrix")"
[[ "$actual_header" == "$expected_header" ]] || fail "M1 Salesforce action matrix header mismatch"

for token in \
  pulse360GroupRevenueReveal pulse360SellerWorkspaceGroup pulse360RecommendedMovePanel \
  pulse360PlannerWorkspace pulse360SignalRoutingWorkspace pulse360RenewalRiskWorkspace \
  governanceCaseReview pulse360NextBestAction; do
  search_fixed "$token" "$matrix" || fail "Missing surface in M1 action matrix: $token"
done

for token in \
  create_task route_specialist open_entity open_opportunity escalate_governance record_governance_decision; do
  search_fixed "$token" "$schema" || fail "Missing action type in schema: $token"
  search_fixed "$token" "$contract_doc" || fail "Missing action type in contract: $token"
done
pass "M1 surface matrix and action schema include required surfaces/actions"

for token in \
  "executePulse360SellerAction" \
  "HIGH_RISK_SELLER_ACTIONS" \
  "SELLER_APPROVAL_REQUIRED" \
  "route_specialist" \
  "Task followUp"; do
  search_fixed "$token" "force-app/main/default/classes/Pulse360SellerOrchestratorService.cls" \
    || fail "Seller orchestrator missing token: $token"
done

for token in \
  "getSellerWorkspace" \
  "Hierarchy_Payload__c" \
  "AI_Recommended_Actions__c" \
  "AI_Source_Refs__c" \
  "crmRecordId"; do
  search_fixed "$token" "force-app/main/default/classes/Pulse360SellerWorkspaceService.cls" \
    || fail "Seller workspace service missing token: $token"
done

for token in \
  "getPlannerWorkspace" \
  "Coverage_Gap_Flag__c" \
  "Group_Revenue_Visible__c" \
  "priorityScore"; do
  search_fixed "$token" "force-app/main/default/classes/Pulse360PlannerWorkspaceService.cls" \
    || fail "Planner service missing token: $token"
done

for token in \
  "getPulse360DataCloudReviewEvidence" \
  "recordPulse360GovernanceDecision" \
  "Direct Data Cloud review evidence is unavailable" \
  "Governance_Case__c"; do
  search_fixed "$token" "force-app/main/default/classes/Pulse360AgentOrchestratorService.cls" \
    || fail "Governance orchestrator missing token: $token"
done
pass "M1 Apex services expose the required action and evidence contracts"

for path in \
  force-app/main/default/lwc/pulse360GroupRevenueReveal/pulse360GroupRevenueReveal.js \
  force-app/main/default/lwc/pulse360SellerWorkspaceGroup/pulse360SellerWorkspaceGroup.js \
  force-app/main/default/lwc/pulse360RecommendedMovePanel/pulse360RecommendedMovePanel.js \
  force-app/main/default/lwc/pulse360PlannerWorkspace/pulse360PlannerWorkspace.js \
  force-app/main/default/lwc/pulse360SignalRoutingWorkspace/pulse360SignalRoutingWorkspace.js \
  force-app/main/default/lwc/pulse360RenewalRiskWorkspace/pulse360RenewalRiskWorkspace.js \
  force-app/main/default/lwc/governanceCaseReview/governanceCaseReview.js; do
  [[ -f "$path" ]] || fail "Missing required M1 surface component: $path"
done

search_fixed "Hierarchy_Payload__c" "force-app/main/default/lwc/pulse360GroupRevenueReveal/pulse360GroupRevenueReveal.js" \
  && fail "Group revenue reveal should not require raw hierarchy payload for the default summary"
search_fixed "targetRecordId" "force-app/main/default/classes/Pulse360SellerOrchestratorService.cls" \
  || fail "Seller orchestrator must preserve targetRecordId"
search_fixed "Governance execution requires an explicit approval" "force-app/main/default/classes/Pulse360AgentOrchestratorService.cls" \
  || fail "Governance execution must require explicit approval"
search_fixed "native Agentforce runtime support has been verified" "$contract_doc" \
  || fail "Contract must avoid overclaiming native Agentforce runtime"
pass "M1 LWC surfaces and guardrails are present"

"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/validate-surface-architecture.sh"
pass "Surface architecture validator passed"

"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/validate-multi-surface-experience.sh"
pass "Multi-surface experience validator passed"

pass "M1 Salesforce action surface validation completed"

