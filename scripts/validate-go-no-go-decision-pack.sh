#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

decision_doc="docs/readout/dan-73-go-decision-and-release-backlog.md"
control_center_doc="docs/epf/control-center.md"
checklist_doc="docs/qa/acceptance-checklist.md"

[[ -f "$decision_doc" ]] || fail "Missing DAN-73 decision artifact: $decision_doc"
[[ -f "$control_center_doc" ]] || fail "Missing control center doc: $control_center_doc"
[[ -f "$checklist_doc" ]] || fail "Missing acceptance checklist: $checklist_doc"
pass "DAN-73 files are present"

for token in \
  "## Formal Decision Outcome" \
  "Decision: **Conditional GO**" \
  'Decision date (UTC): `2026-03-09`' \
  "## Conditions, Risks, and Follow-up Actions" \
  "## Prioritized Implementation Backlog (GO Path Translation)" \
  "## Acceptance Mapping (DAN-73)"; do
  rg -Fq -- "$token" "$decision_doc" || fail "Decision artifact missing token: $token"
done
pass "Decision outcome, conditions, backlog translation, and acceptance sections are present"

for token in \
  "https://linear.app/danielnortje/issue/DAN-73" \
  "https://linear.app/danielnortje/issue/DAN-59" \
  "https://linear.app/danielnortje/issue/DAN-58" \
  "https://www.notion.so/31dfe2e19eed813fbc18ee02d7295c27" \
  "https://www.notion.so/31dfe2e19eed81069b18f76d459a2954"; do
  rg -Fq -- "$token" "$decision_doc" || fail "Decision artifact missing reference: $token"
done
pass "Decision artifact includes required Linear and Notion references"

rg -Fq -- "dan-73-go-decision-and-release-backlog.md" "$control_center_doc" \
  || fail "Control center missing DAN-73 decision artifact link"
rg -Fq -- "validate-go-no-go-decision-pack.sh" "$checklist_doc" \
  || fail "Checklist missing DAN-73 validator reference"
pass "Control center and checklist reference DAN-73 artifacts"
