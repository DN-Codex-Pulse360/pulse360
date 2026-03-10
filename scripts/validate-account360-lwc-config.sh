#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

schema="contracts/salesforce_account360_hierarchy_lwc.schema.json"
sample="data/samples/salesforce_account360_hierarchy_lwc_sample.json"
contract_doc="docs/contracts/datacloud-to-salesforce-agentforce-contract.md"
runbook="docs/runbook/s4-ds-runbook.md"
checklist="docs/qa/acceptance-checklist.md"

[[ -f "$schema" ]] || fail "Missing schema: $schema"
[[ -f "$sample" ]] || fail "Missing sample: $sample"
[[ -f "$contract_doc" ]] || fail "Missing contract doc: $contract_doc"
[[ -f "$runbook" ]] || fail "Missing runbook: $runbook"
[[ -f "$checklist" ]] || fail "Missing checklist: $checklist"
pass "Required DAN-64 files are present"

for token in \
  '"hierarchy_payload"' \
  '"group_revenue_rollup"' \
  '"cross_sell_propensity"' \
  '"coverage_gap_flag"' \
  '"last_synced_timestamp"' \
  '"data_health_status"' \
  '"degraded_mode_message"'; do
  rg -Fq -- "$token" "$schema" || fail "Schema missing token: $token"
done
pass "Account 360 schema includes hierarchy, insights, sync, and degraded mode fields"

for key in \
  unified_profile_id source_account_id account_name hierarchy_payload group_revenue_rollup \
  cross_sell_propensity coverage_gap_flag last_synced_timestamp data_health_status \
  degraded_mode_message run_id run_timestamp model_version; do
  rg -Fq -- "\"$key\"" "$sample" || fail "Sample missing key: $key"
done
pass "Account 360 sample includes required payload fields"

for token in \
  "## Account 360 Hierarchy LWC Payload (DAN-64)" \
  "salesforce_account360_hierarchy_lwc.schema.json" \
  "salesforce_account360_hierarchy_lwc_sample.json"; do
  rg -Fq -- "$token" "$contract_doc" || fail "Contract doc missing DAN-64 token: $token"
done
pass "Contract docs include DAN-64 payload section"

rg -Fq -- "scripts/validate-account360-lwc-runtime.sh" "$runbook" \
  || fail "Runbook missing DAN-64 runtime validation step"
rg -Fq -- "Account 360 hierarchy payload is contract-backed" "$checklist" \
  || fail "Acceptance checklist missing DAN-64 criteria"
pass "Runbook and checklist include DAN-64 checks"
