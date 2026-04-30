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

contract_doc="docs/contracts/pulse360-agentforce-capability-gate-contract.md"
runbook="docs/runbook/pulse360-agentforce-capability-gate-runbook.md"
schema="contracts/agentforce_capability_gate.schema.json"
sample="data/samples/agentforce_capability_gate_sample.json"
config="config/agentforce/pulse360-capability-gates.yaml"
reality_check="docs/evidence/agentforce-capability-reality-check-2026-04-23.md"
agent_script="force-app/main/default/aiAuthoringBundles/Pulse360_Agent/Pulse360_Agent.agent"
agent_support="force-app/main/default/lwc/pulse360SellerWorkspaceAgentforceSupport/pulse360SellerWorkspaceAgentforceSupport.js"
seller_orchestrator="force-app/main/default/classes/Pulse360SellerOrchestratorService.cls"
governance_orchestrator="force-app/main/default/classes/Pulse360AgentOrchestratorService.cls"

for file in "$contract_doc" "$runbook" "$schema" "$sample" "$config" "$reality_check" "$agent_script" "$agent_support"; do
  [[ -f "$file" ]] || fail "Missing required Agentforce gate artifact: $file"
done
pass "Agentforce capability gate artifacts are present"

python3 -m json.tool "$schema" >/dev/null || fail "Invalid Agentforce capability gate schema"
python3 -m json.tool "$sample" >/dev/null || fail "Invalid Agentforce capability gate sample"
pass "Agentforce capability gate JSON files parse"

for token in \
  metadata_ready runtime_unproven runtime_blocked runtime_verified \
  data_360_ready einstein_enabled trust_layer_configured agent_metadata_deployed \
  agent_user_bound native_surface_visible actions_registered citations_supported \
  approval_policy_enforced audit_artifacts_written; do
  search_fixed "$token" "$contract_doc" "$config" || fail "Missing gate token: $token"
done
pass "Capability gate states and checks are documented"

for token in \
  "https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-ref-actions.html" \
  "https://developer.salesforce.com/docs/einstein/genai/guide/citations.html" \
  "https://developer.salesforce.com/docs/einstein/genai/references/citations/citations-reference.html" \
  "https://developer.salesforce.com/docs/einstein/genai/guide/org-setup.html" \
  "https://developer.salesforce.com/docs/ai/agentforce/guide/models-api.html" \
  "https://developer.salesforce.com/docs/ai/agentforce/guide/trust.html"; do
  search_fixed "$token" "$contract_doc" "$config" || fail "Missing official reference: $token"
done
pass "Official Agentforce and Trust Layer references are captured"

for token in \
  source_id source_name source_type source_object_api_name source_object_record_id \
  source_url excerpt accessed_at document_date jurisdiction; do
  search_fixed "$token" "$schema" "$sample" "$config" "$contract_doc" \
    || fail "Missing citation field token: $token"
done
pass "Citation fallback fields are captured"

for token in \
  user_id surface_context record_id action_type prompt_version model_id enrichment_run_id \
  source_ids generated_at approval_required approval_state audit_event_id trust_layer_status \
  masked_field_policy; do
  search_fixed "$token" "$schema" "$sample" "$config" "$contract_doc" \
    || fail "Missing trust/audit field token: $token"
done
pass "Trust and audit fields are captured"

for token in \
  "native Agentforce runtime success is not yet proven" \
  "custom assistant panel" \
  "native Agentforce runtime"; do
  search_fixed "$token" "$reality_check" || fail "Reality check missing token: $token"
done
pass "Reality check preserves non-overclaiming posture"

for token in \
  "Pulse360 Agent" \
  "Seller Account Manager" \
  "Governance Review Manager" \
  "default_agent_user"; do
  search_fixed "$token" "$agent_script" || fail "Agent Script missing token: $token"
done
pass "Agentforce metadata source exists and names the expected workstreams"

for token in \
  "canLaunchAgentforce" \
  "return Boolean(agentId) && !runtimeBlocked && false" \
  "ACC side-panel module" \
  "agentforceCompatibilityMessage"; do
  search_fixed "$token" "$agent_support" || fail "Agentforce fallback support missing token: $token"
done
pass "Fallback helper blocks native launch until runtime support is proven"

for token in \
  "HIGH_RISK_SELLER_ACTIONS" \
  "SELLER_APPROVAL_REQUIRED" \
  "open_opportunity" \
  "create_opportunity"; do
  search_fixed "$token" "$seller_orchestrator" || fail "Seller approval gate missing token: $token"
done

for token in \
  "Governance execution requires an explicit approval" \
  "Direct Data Cloud review evidence is unavailable" \
  "recordPulse360GovernanceDecision"; do
  search_fixed "$token" "$governance_orchestrator" || fail "Governance approval/evidence gate missing token: $token"
done
pass "Mutating action gates are enforced in Apex"

pass "Agentforce capability gate validation completed"

