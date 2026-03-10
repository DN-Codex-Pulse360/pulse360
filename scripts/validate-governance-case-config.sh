#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

schema="contracts/salesforce_governance_case_lwc.schema.json"
sample="data/samples/salesforce_governance_case_lwc_sample.json"
contract_doc="docs/contracts/datacloud-to-salesforce-agentforce-contract.md"
runbook="docs/runbook/s4-ds-runbook.md"
checklist="docs/qa/acceptance-checklist.md"

[[ -f "$schema" ]] || fail "Missing schema: $schema"
[[ -f "$sample" ]] || fail "Missing sample: $sample"
[[ -f "$contract_doc" ]] || fail "Missing contract doc: $contract_doc"
[[ -f "$runbook" ]] || fail "Missing runbook: $runbook"
[[ -f "$checklist" ]] || fail "Missing checklist: $checklist"
pass "Required DAN-63 files are present"

for token in \
  '"governance_case_id"' \
  '"pair_confidence"' \
  '"candidate_left"' \
  '"candidate_right"' \
  '"conflict_fields"' \
  '"decision_status"' \
  '"audit_event_id"'; do
  rg -Fq -- "$token" "$schema" || fail "Schema missing token: $token"
done
pass "Governance case schema includes side-by-side and audit fields"

for key in \
  governance_case_id run_id run_timestamp pair_confidence \
  candidate_left candidate_right conflict_fields recommendation audit; do
  rg -Fq -- "\"$key\"" "$sample" || fail "Sample missing key: $key"
done
pass "Governance case sample contains required payload sections"

for token in \
  "## Governance Case Side-by-Side Payload (DAN-63)" \
  "salesforce_governance_case_lwc.schema.json" \
  "salesforce_governance_case_lwc_sample.json"; do
  rg -Fq -- "$token" "$contract_doc" || fail "Contract doc missing DAN-63 token: $token"
done
pass "Contract docs include DAN-63 payload section"

rg -Fq -- "scripts/validate-governance-case-runtime.sh" "$runbook" \
  || fail "Runbook missing DAN-63 runtime validation step"
rg -Fq -- "Governance case side-by-side payload is contract-backed" "$checklist" \
  || fail "Acceptance checklist missing DAN-63 criteria"
pass "Runbook and checklist include DAN-63 checks"
