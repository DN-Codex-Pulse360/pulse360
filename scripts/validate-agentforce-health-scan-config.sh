#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

schema="contracts/agentforce_account_health_scan_action.schema.json"
sample="data/samples/agentforce_account_health_scan_action_sample.json"
contract_doc="docs/contracts/datacloud-to-salesforce-agentforce-contract.md"
runbook="docs/runbook/s4-ds-runbook.md"
checklist="docs/qa/acceptance-checklist.md"

[[ -f "$schema" ]] || fail "Missing schema: $schema"
[[ -f "$sample" ]] || fail "Missing sample: $sample"
[[ -f "$contract_doc" ]] || fail "Missing contract doc: $contract_doc"
[[ -f "$runbook" ]] || fail "Missing runbook: $runbook"
[[ -f "$checklist" ]] || fail "Missing checklist: $checklist"
pass "Required DAN-65 files are present"

for token in \
  '"action_name"' \
  '"response_card"' \
  '"duplicate_evidence"' \
  '"cross_sell_estimate"' \
  '"health_score"' \
  '"ai_impact_summary"' \
  '"failure_mode"' \
  '"is_non_blocking"' \
  '"retry_disposition"'; do
  rg -Fq -- "$token" "$schema" || fail "Schema missing token: $token"
done
pass "Agentforce health scan schema includes response card and failure mode fields"

for key in \
  action_name request response action_request_id source_account_id correlation_id requested_at \
  status http_status api_latency_ms data_source response_card duplicate_evidence pair_count \
  max_confidence confidence_band cross_sell_estimate health_score competitor_risk_signal \
  ai_impact_summary last_synced_timestamp failure_mode is_non_blocking error_code user_message retry_disposition; do
  rg -Fq -- "\"$key\"" "$sample" || fail "Sample missing key: $key"
done
pass "Agentforce health scan sample includes required payload fields"

for token in \
  "## Agentforce Account Health Scan Action Payload (DAN-65)" \
  "agentforce_account_health_scan_action.schema.json" \
  "agentforce_account_health_scan_action_sample.json"; do
  rg -Fq -- "$token" "$contract_doc" || fail "Contract doc missing DAN-65 token: $token"
done
pass "Contract docs include DAN-65 payload section"

rg -Fq -- "scripts/validate-agentforce-health-scan-runtime.sh" "$runbook" \
  || fail "Runbook missing DAN-65 runtime validation step"
rg -Fq -- "Agentforce Account Health Scan action payload is contract-backed" "$checklist" \
  || fail "Acceptance checklist missing DAN-65 criteria"
pass "Runbook and checklist include DAN-65 checks"
