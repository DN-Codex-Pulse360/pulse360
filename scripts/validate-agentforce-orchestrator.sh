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

seller_service_class="force-app/main/default/classes/Pulse360SellerOrchestratorService.cls"
seller_service_test="force-app/main/default/classes/Pulse360SellerOrchestratorServiceTest.cls"
governance_service_class="force-app/main/default/classes/Pulse360AgentOrchestratorService.cls"
governance_service_test="force-app/main/default/classes/Pulse360AgentOrchestratorServiceTest.cls"
seller_lwc="force-app/main/default/lwc/pulse360SellerWorkspace/pulse360SellerWorkspace.js"
seller_sidebar_lwc="force-app/main/default/lwc/pulse360SellerWorkspaceSidebar/pulse360SellerWorkspaceSidebar.js"
seller_support_lwc="force-app/main/default/lwc/pulse360SellerWorkspaceActionSupport/pulse360SellerWorkspaceActionSupport.js"
seller_agent_support_lwc="force-app/main/default/lwc/pulse360SellerWorkspaceAgentforceSupport/pulse360SellerWorkspaceAgentforceSupport.js"
governance_lwc="force-app/main/default/lwc/governanceCaseReview/governanceCaseReview.js"
governance_html="force-app/main/default/lwc/governanceCaseReview/governanceCaseReview.html"
seller_permset="force-app/main/default/permissionsets/Pulse360_Account_Intelligence_User.permissionset-meta.xml"
governance_permset="force-app/main/default/permissionsets/Governance_Case_Steward.permissionset-meta.xml"
contract_doc="docs/contracts/pulse360-agentforce-orchestrator-v1.md"
seller_account_action="force-app/main/default/classes/Pulse360GetAccountContextAction.cls"
seller_execute_action="force-app/main/default/classes/Pulse360ExecuteSellerAction.cls"
governance_review_action="force-app/main/default/classes/Pulse360GetReviewContextAction.cls"
governance_evidence_action="force-app/main/default/classes/Pulse360GetDataCloudReviewEvidenceAction.cls"
governance_decision_action="force-app/main/default/classes/Pulse360RecordGovernanceDecisionAction.cls"

required_classes=(
  "force-app/main/default/classes/Pulse360SellerOrchestratorService.cls"
  "force-app/main/default/classes/Pulse360AgentOrchestratorService.cls"
  "force-app/main/default/classes/Pulse360GetAccountContextAction.cls"
  "force-app/main/default/classes/Pulse360GetReviewContextAction.cls"
  "force-app/main/default/classes/Pulse360GetDataCloudReviewEvidenceAction.cls"
  "force-app/main/default/classes/Pulse360ExecuteSellerAction.cls"
  "force-app/main/default/classes/Pulse360RecordGovernanceDecisionAction.cls"
)

for class_file in "${required_classes[@]}"; do
  [[ -f "$class_file" ]] || fail "Missing orchestration Apex class: $class_file"
done
pass "Pulse360 orchestration Apex classes exist"

[[ -f "$seller_service_test" ]] || fail "Missing seller orchestrator Apex test"
[[ -f "$governance_service_test" ]] || fail "Missing governance orchestrator Apex test"
[[ -f "$contract_doc" ]] || fail "Missing orchestrator contract doc"
pass "Pulse360 orchestration test and contract doc exist"

for token in \
  "flowWrappersReturnEmptyListsWhenNoRequestsAreSupplied" \
  "executionWrapperRejectsNullFlowRowWithHandledSellerError"; do
  search_fixed "$token" "$governance_service_test" \
    || fail "Missing orchestration regression test token: $token"
done
pass "Orchestration regression coverage includes null-safe wrapper handling"

search_fixed "launchAgentCreatesEvidenceAwareSellerBriefTask" "$seller_service_test" \
  || fail "Missing seller brief regression test coverage"
pass "Seller orchestration regression coverage includes the seller brief path"

for token in \
  "Seller Account Manager" \
  "getPulse360AccountContext" \
  "executePulse360SellerAction" \
  "buildSellerBriefArtifact" \
  "executionChecklist" \
  "agentGoal"; do
  search_fixed "$token" "$seller_service_class" || fail "Missing seller orchestration service token: $token"
done

for token in \
  "Governance Review Manager" \
  "getPulse360ReviewContext" \
  "getPulse360DataCloudReviewEvidence" \
  "recordPulse360GovernanceDecision" \
  "Direct Data Cloud review evidence is unavailable"; do
  search_fixed "$token" "$governance_service_class" || fail "Missing governance orchestration service token: $token"
done
pass "Orchestration service exposes the expected API surface"

for token in \
  "getPulse360AccountContext" \
  "executePulse360SellerAction" \
  "Seller Account Manager"; do
  ! search_fixed "$token" "$governance_service_class" \
    || fail "Governance orchestration service should not expose seller compatibility token: $token"
done
pass "Governance orchestration service no longer exposes seller compatibility APIs"

for token in \
  "Pulse360SellerOrchestratorService.getPulse360AccountContext" \
  "Pulse360SellerOrchestratorService.executePulse360SellerAction"; do
  search_fixed "$token" "$seller_account_action" "$seller_execute_action" \
    || fail "Missing seller wrapper routing token: $token"
done

for token in \
  "requests == null || requests.isEmpty()" \
  "request == null ? null : request.accountId" \
  "request != null"; do
  search_fixed "$token" "$seller_account_action" "$seller_execute_action" \
    || fail "Missing seller wrapper guard token: $token"
done

for token in \
  "Pulse360AgentOrchestratorService.getPulse360ReviewContext" \
  "Pulse360AgentOrchestratorService.getPulse360DataCloudReviewEvidence" \
  "Pulse360AgentOrchestratorService.recordPulse360GovernanceDecision"; do
  search_fixed "$token" "$governance_review_action" "$governance_evidence_action" "$governance_decision_action" \
    || fail "Missing governance wrapper routing token: $token"
done

for token in \
  "requests == null || requests.isEmpty()" \
  "request == null ? null : request.governanceCaseId" \
  "request == null ? null : request.candidatePairId"; do
  search_fixed "$token" "$governance_review_action" "$governance_evidence_action" "$governance_decision_action" \
    || fail "Missing governance wrapper guard token: $token"
done
pass "Invocable wrappers route to the intended split orchestration services"

for token in \
  "requiresApproval" \
  "buildExecutionRequest" \
  "summarizeSupportingSources"; do
  search_fixed "$token" "$seller_support_lwc" || fail "Missing seller support token: $token"
done
pass "Seller LWC support includes approval-aware execution helpers"

for token in \
  "executePulse360SellerAction" \
  "LightningConfirm" \
  "navigateToExecutionResult"; do
  search_fixed "$token" "$seller_lwc" "$seller_sidebar_lwc" \
    || fail "Missing seller orchestration UI token: $token"
done
pass "Seller workspace surfaces use the orchestration service"

for token in \
  "launchAgentforceConversation" \
  "buildSellerAgentUtterance" \
  "agentforceCompatibilityMessage"; do
  search_fixed "$token" "$seller_lwc" "$seller_agent_support_lwc" \
    || fail "Missing native Agentforce ACC token: $token"
done
pass "Seller workspace includes the Agentforce handoff and compatibility path"

for token in \
  "getPulse360ReviewContext" \
  "getPulse360DataCloudReviewEvidence" \
  "recordPulse360GovernanceDecision" \
  "Direct Data Cloud evidence required" \
  "decisionDisabled"; do
  search_fixed "$token" "$governance_lwc" "$governance_html" \
    || fail "Missing governance orchestration token: $token"
done
pass "Governance review surface enforces direct-evidence execution"

for token in \
  "Pulse360SellerOrchestratorService" \
  "Pulse360GetAccountContextAction" \
  "Pulse360ExecuteSellerAction"; do
  search_fixed "$token" "$seller_permset" || fail "Missing seller permission set class access: $token"
done

for token in \
  "Pulse360AgentOrchestratorService" \
  "Pulse360GetReviewContextAction" \
  "Pulse360GetDataCloudReviewEvidenceAction" \
  "Pulse360RecordGovernanceDecisionAction"; do
  search_fixed "$token" "$governance_permset" || fail "Missing governance permission set class access: $token"
done
pass "Permission sets include the orchestration class access"

for token in \
  "# Contract: Pulse360 Agentforce Orchestrator V1" \
  "Pulse360 Agent" \
  "direct Data Cloud evidence read is mandatory in V1" \
  "high-risk mutations pause for approval" \
  'seller runtime methods live only on `Pulse360SellerOrchestratorService`' \
  'governance runtime methods live only on `Pulse360AgentOrchestratorService`' \
  "the governance runtime does not expose seller compatibility methods"; do
  search_fixed "$token" "$contract_doc" || fail "Missing contract doc token: $token"
done
pass "Contract doc captures the V1 orchestrator expectations"

pass "Agentforce orchestrator validation completed"
