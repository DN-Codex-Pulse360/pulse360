#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

qa_script="scripts/run-e2e-qa-timing.sh"
runbook_doc="docs/runbook/s4-ds-runbook.md"
checklist_doc="docs/qa/acceptance-checklist.md"
evidence_doc="docs/evidence/e2e-qa-latest.md"

[[ -f "$qa_script" ]] || fail "Missing E2E QA runner: $qa_script"
[[ -f "$runbook_doc" ]] || fail "Missing runbook doc: $runbook_doc"
[[ -f "$checklist_doc" ]] || fail "Missing checklist doc: $checklist_doc"
pass "DAN-68 QA pack files are present"

rg -Fq -- "run-e2e-qa-timing.sh" "$runbook_doc" \
  || fail "Runbook missing E2E QA runner reference"
rg -Fq -- "e2e-qa-latest.md" "$checklist_doc" \
  || fail "Checklist missing E2E timing evidence reference"
pass "Runbook and checklist reference DAN-68 artifacts"

if [[ -f "$evidence_doc" ]]; then
  for token in \
    "E2E QA Timing Evidence (DAN-68)" \
    "Total runtime (seconds):" \
    "Defect Log"; do
    rg -Fq -- "$token" "$evidence_doc" || fail "E2E evidence missing token: $token"
  done
  pass "Existing E2E evidence artifact structure is valid"
else
  echo "[WARN] E2E evidence file not found yet: $evidence_doc"
  echo "[WARN] Generate it with: ./scripts/run-e2e-qa-timing.sh"
fi
