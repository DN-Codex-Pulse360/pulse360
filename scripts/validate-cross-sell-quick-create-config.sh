#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

schema="contracts/salesforce_cross_sell_quick_create_action.schema.json"
sample="data/samples/salesforce_cross_sell_quick_create_action_sample.json"
contract_doc="docs/contracts/datacloud-to-salesforce-agentforce-contract.md"
runbook="docs/runbook/s4-ds-runbook.md"
checklist="docs/qa/acceptance-checklist.md"
insights_cfg="config/data-cloud/calculated-insights.yaml"

[[ -f "$schema" ]] || fail "Missing schema: $schema"
[[ -f "$sample" ]] || fail "Missing sample: $sample"
[[ -f "$contract_doc" ]] || fail "Missing contract doc: $contract_doc"
[[ -f "$runbook" ]] || fail "Missing runbook: $runbook"
[[ -f "$checklist" ]] || fail "Missing checklist: $checklist"
[[ -f "$insights_cfg" ]] || fail "Missing insights config: $insights_cfg"
pass "Required DAN-66 files are present"

for token in \
  '"banner"' \
  '"cross_sell_propensity"' \
  '"coverage_gap_flag"' \
  '"quick_create"' \
  '"contact_association"' \
  '"linkage_type"' \
  '"refresh_trigger"' \
  '"event_name"'; do
  rg -Fq -- "$token" "$schema" || fail "Schema missing token: $token"
done
pass "Cross-sell quick-create schema includes banner, context, linkage, and trigger fields"

for key in \
  banner source_account_id unified_profile_id cross_sell_propensity coverage_gap_flag open_opportunity_count \
  quick_create context_account_id contact_association linkage_type contact_record_id opportunity_payload \
  refresh_trigger event_name is_enabled trigger_source expected_recompute_window_minutes; do
  rg -Fq -- "\"$key\"" "$sample" || fail "Sample missing key: $key"
done
pass "Cross-sell quick-create sample includes required payload fields"

for token in \
  "## Cross-Sell Banner and Quick Create Payload (DAN-66)" \
  "salesforce_cross_sell_quick_create_action.schema.json" \
  "salesforce_cross_sell_quick_create_action_sample.json"; do
  rg -Fq -- "$token" "$contract_doc" || fail "Contract doc missing DAN-66 token: $token"
done
pass "Contract docs include DAN-66 payload section"

rg -Fq -- "scripts/validate-cross-sell-quick-create-runtime.sh" "$runbook" \
  || fail "Runbook missing DAN-66 runtime validation step"
rg -Fq -- "Cross-sell banner quick-create payload is contract-backed" "$checklist" \
  || fail "Acceptance checklist missing DAN-66 criteria"
rg -Fq -- "- opportunity_created" "$insights_cfg" \
  || fail "Insights config missing opportunity_created trigger"
pass "Runbook/checklist/trigger config include DAN-66 checks"
