#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

readout_doc="docs/readout/internal-solution-readout-dashboard-pack.md"
control_center_doc="docs/epf/control-center.md"
checklist_doc="docs/qa/acceptance-checklist.md"
plan_doc="docs/planning/dan-70-implementation-estimate-and-resource-plan.md"
e2e_evidence="docs/evidence/e2e-qa-latest.md"
prerun_evidence="docs/evidence/datacloud-prerun-import-latest.md"

[[ -f "$readout_doc" ]] || fail "Missing internal readout pack: $readout_doc"
[[ -f "$control_center_doc" ]] || fail "Missing control center: $control_center_doc"
[[ -f "$checklist_doc" ]] || fail "Missing acceptance checklist: $checklist_doc"
[[ -f "$plan_doc" ]] || fail "Missing DAN-70 plan doc: $plan_doc"
[[ -f "$e2e_evidence" ]] || fail "Missing E2E evidence: $e2e_evidence"
[[ -f "$prerun_evidence" ]] || fail "Missing pre-run import evidence: $prerun_evidence"
pass "DAN-71 readout files and dependencies are present"

for token in \
  "## Dashboard Snapshot" \
  "## Delivery Readiness Panels" \
  "### Assumptions and Risk Register" \
  "## Gate Status Dashboard" \
  "## Linked Live Prototype Evidence and Issue Status" \
  "## Review Meeting Agenda (Prepared)" \
  "## Decision Rubric (Prepared)" \
  "## Commercially Sensitive Internal-Only Details" \
  "run_20260309_042146"; do
  rg -Fq -- "$token" "$readout_doc" || fail "Internal readout pack missing token: $token"
done
pass "Readout pack includes required dashboard, risk, agenda, rubric, and sensitivity sections"

for token in \
  "docs/evidence/e2e-qa-latest.md" \
  "docs/evidence/datacloud-prerun-import-latest.md" \
  "https://linear.app/danielnortje/issue/DAN-71" \
  "https://linear.app/danielnortje/issue/DAN-73"; do
  rg -Fq -- "$token" "$readout_doc" || fail "Readout pack missing evidence/issue link: $token"
done
pass "Readout pack links live evidence and issue status"

rg -Fq -- "run_id: run_20260309_042146" "$prerun_evidence" \
  || fail "Pre-run evidence missing expected run_id"
rg -Fq -- 'Total runtime (seconds): `91`' "$e2e_evidence" \
  || fail "E2E evidence missing expected runtime token"
pass "Runtime evidence baseline tokens are present"

rg -Fq -- "internal-solution-readout-dashboard-pack.md" "$control_center_doc" \
  || fail "Control center missing DAN-71 readout evidence link"
rg -Fq -- "validate-readout-dashboard-pack.sh" "$checklist_doc" \
  || fail "Checklist missing DAN-71 validator reference"
pass "Control center and checklist reference DAN-71 artifacts"

