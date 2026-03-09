#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

plan_doc="docs/planning/dan-70-implementation-estimate-and-resource-plan.md"
prerun_evidence="docs/evidence/datacloud-prerun-import-latest.md"
e2e_evidence="docs/evidence/e2e-qa-latest.md"
runbook_doc="docs/runbook/s4-ds-runbook.md"
checklist_doc="docs/qa/acceptance-checklist.md"

[[ -f "$plan_doc" ]] || fail "Missing DAN-70 plan doc: $plan_doc"
[[ -f "$prerun_evidence" ]] || fail "Missing pre-run evidence: $prerun_evidence"
[[ -f "$e2e_evidence" ]] || fail "Missing E2E evidence: $e2e_evidence"
[[ -f "$runbook_doc" ]] || fail "Missing runbook doc: $runbook_doc"
[[ -f "$checklist_doc" ]] || fail "Missing checklist doc: $checklist_doc"
pass "DAN-70 files and evidence sources are present"

for token in \
  "## Effort Estimate (Prototype Evidence -> Implementation Plan)" \
  "## Resource Plan (Role Matrix by Milestone)" \
  "## Dependency Map" \
  "## Critical Path (Milestone E)" \
  "## Acceptance Mapping (DAN-70)" \
  "run_20260309_042146"; do
  rg -Fq -- "$token" "$plan_doc" || fail "DAN-70 plan missing token: $token"
done
pass "DAN-70 plan includes required sections and run evidence trace"

for token in \
  "run_id: run_20260309_042146" \
  'Total runtime (seconds): `91`'; do
  rg -Fq -- "$token" "$prerun_evidence" "$e2e_evidence" \
    || fail "Evidence files missing token: $token"
done
pass "Referenced runtime evidence tokens are present"

rg -Fq -- "validate-implementation-estimate-runtime.sh" "$runbook_doc" \
  || fail "Runbook missing DAN-70 validator reference"
rg -Fq -- "dan-70-implementation-estimate-and-resource-plan.md" "$checklist_doc" \
  || fail "Checklist missing DAN-70 planning artifact reference"
pass "Runbook and checklist reference DAN-70 artifacts"
