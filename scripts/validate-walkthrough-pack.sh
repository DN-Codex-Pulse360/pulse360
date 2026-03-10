#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

script_doc="docs/runbook/ds-01-02-03-walkthrough-script.md"
rubric_doc="docs/qa/walkthrough-rehearsal-rubric.md"
runbook_doc="docs/runbook/s4-ds-runbook.md"
checklist_doc="docs/qa/acceptance-checklist.md"

[[ -f "$script_doc" ]] || fail "Missing walkthrough script: $script_doc"
[[ -f "$rubric_doc" ]] || fail "Missing rehearsal rubric: $rubric_doc"
[[ -f "$runbook_doc" ]] || fail "Missing runbook: $runbook_doc"
[[ -f "$checklist_doc" ]] || fail "Missing checklist: $checklist_doc"
pass "Walkthrough files are present"

for token in \
  "## DS-01 Fragmentation Discovery (4 minutes)" \
  "## DS-02 Governance Case Resolution (5 minutes)" \
  "## DS-03 Account 360 Cross-Sell Moment (4 minutes)" \
  "Layer transition flow:" \
  "Fallback wording:" \
  "01f11b56ed40102ea9232dfb2404fb1b" \
  "01f11b5709051df5a21ba10e55942421"; do
  rg -Fq -- "$token" "$script_doc" || fail "Walkthrough script missing token: $token"
done
pass "Walkthrough script includes scenarios, transitions, fallback, and exact dashboard references"

extract_minutes() {
  local key="$1"
  local line
  line="$(rg -m1 -F "$key:" "$script_doc" || true)"
  [[ -n "$line" ]] || fail "Missing runtime budget line for $key"
  sed -E 's/.*`([0-9]+)` minutes.*/\1/' <<<"$line"
}

ds01="$(extract_minutes 'DS-01')"
ds02="$(extract_minutes 'DS-02')"
ds03="$(extract_minutes 'DS-03')"
buf="$(extract_minutes 'Buffer/Q&A')"
total_budget=$((ds01 + ds02 + ds03 + buf))
[[ "$total_budget" -le 15 ]] || fail "Walkthrough runtime budget exceeds 15 minutes (found $total_budget)"
pass "Walkthrough runtime budget is <= 15 minutes (total=$total_budget)"

for token in \
  "## Rehearsal Checklist" \
  "## Scoring Rubric (0-2 each, max 10)" \
  "## Pass Threshold" \
  'Minimum pass score: `8/10`'; do
  rg -Fq -- "$token" "$rubric_doc" || fail "Rehearsal rubric missing token: $token"
done
pass "Rehearsal checklist and scoring rubric are published"

rg -Fq -- "ds-01-02-03-walkthrough-script.md" "$runbook_doc" \
  || fail "Runbook missing walkthrough script reference"
rg -Fq -- "walkthrough-rehearsal-rubric.md" "$checklist_doc" \
  || fail "Acceptance checklist missing rehearsal rubric reference"
pass "Runbook and acceptance checklist reference DAN-67 artifacts"
