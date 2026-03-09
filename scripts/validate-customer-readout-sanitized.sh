#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

customer_doc="docs/readout/customer-sanitized-readout-page.md"
internal_doc="docs/readout/internal-solution-readout-dashboard-pack.md"
control_center_doc="docs/epf/control-center.md"
checklist_doc="docs/qa/acceptance-checklist.md"

[[ -f "$customer_doc" ]] || fail "Missing customer sanitized readout page: $customer_doc"
[[ -f "$internal_doc" ]] || fail "Missing DAN-71 internal readout source: $internal_doc"
[[ -f "$control_center_doc" ]] || fail "Missing control center doc: $control_center_doc"
[[ -f "$checklist_doc" ]] || fail "Missing acceptance checklist: $checklist_doc"
pass "DAN-72 artifacts and references are present"

for token in \
  "## Executive Outcomes" \
  "## Architecture Overview" \
  "## Demo Proof Points" \
  "## Roadmap and Delivery Shape" \
  "## Customer Review Narrative" \
  "## Evidence References (Sanitized)"; do
  rg -Fq -- "$token" "$customer_doc" || fail "Customer readout missing section: $token"
done
pass "Customer readout includes outcomes, architecture, roadmap, and proof sections"

for token in \
  "DS-01" \
  "DS-02" \
  "DS-03" \
  "presentation" \
  "sanitized"; do
  rg -iq -- "$token" "$customer_doc" || fail "Customer readout missing presentation/proof token: $token"
done
pass "Customer readout language and proof-point framing are present"

# Reject internal-commercial/sensitive implementation markers.
for forbidden in \
  "FTE" \
  "person-weeks" \
  "Internal / commercially sensitive" \
  "R1 |" \
  "R2 |" \
  "R3 |" \
  "R4 |" \
  "capacity assumptions"; do
  if rg -Fqi -- "$forbidden" "$customer_doc"; then
    fail "Customer readout contains internal/sensitive marker: $forbidden"
  fi
done
pass "Customer readout excludes internal commercial/sensitive implementation detail"

rg -Fq -- "customer-sanitized-readout-page.md" "$control_center_doc" \
  || fail "Control center missing DAN-72 customer readout link"
rg -Fq -- "validate-customer-readout-sanitized.sh" "$checklist_doc" \
  || fail "Checklist missing DAN-72 validator reference"
pass "Control center and checklist reference DAN-72 artifacts"

