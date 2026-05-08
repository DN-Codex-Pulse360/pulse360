#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

search_fixed() {
  local needle="$1"
  shift

  if command -v rg >/dev/null 2>&1; then
    rg -Fq "$needle" "$@"
  else
    grep -Fq -- "$needle" "$@"
  fi
}

gate="config/revops-final-acceptance-gate.json"
readout="docs/readout/pulse360-revops-feasible-architecture-final-readout-2026-05-08.md"
evidence="docs/evidence/dan-292-final-acceptance-gate-closure-2026-05-08.md"

for path in "$gate" "$readout" "$evidence"; do
  [[ -f "$path" ]] || fail "Missing final acceptance artifact: $path"
done
pass "Final acceptance artifacts exist"

python3 -m json.tool "$gate" >/dev/null || fail "Invalid final acceptance gate JSON"
pass "Final acceptance JSON parses"

python3 - <<'PY'
import json
from pathlib import Path

gate = json.loads(Path("config/revops-final-acceptance-gate.json").read_text())
if gate.get("linear_parent") != "DAN-280":
    raise SystemExit("linear_parent must be DAN-280")
if gate.get("linear_issue") != "DAN-292":
    raise SystemExit("linear_issue must be DAN-292")
if gate.get("selected_first_module") != "M1 Account Hierarchy Intelligence":
    raise SystemExit("selected_first_module must be M1 Account Hierarchy Intelligence")
if gate.get("acceptance_decision") != "ready_for_m1_implementation_scope_with_runtime_gates":
    raise SystemExit("unexpected acceptance decision")

taxonomy = set(gate.get("claim_taxonomy", []))
for required in ["built", "feasible", "gated", "roadmap"]:
    if required not in taxonomy:
        raise SystemExit(f"Missing claim taxonomy entry: {required}")

closed = set(gate.get("closed_child_workstreams", []))
for issue in [f"DAN-{i}" for i in range(281, 292)]:
    if issue == "DAN-292":
        continue
    if issue not in closed:
        raise SystemExit(f"Missing closed child workstream: {issue}")

non_claims = " ".join(gate.get("do_not_claim_until_verified", []))
for phrase in [
    "Salesforce BYOM",
    "native Agentforce",
    "external audit readiness",
    "paid provider integration",
]:
    if phrase not in non_claims:
        raise SystemExit(f"Missing non-claim phrase: {phrase}")
PY
pass "Final acceptance gate semantics OK"

for token in \
  "built" \
  "feasible" \
  "gated" \
  "roadmap" \
  "M1 Account Hierarchy Intelligence" \
  "Databricks SQL Warehouse" \
  "Salesforce BYOM" \
  "native Agentforce" \
  "external audit readiness" \
  "paid provider integration"; do
  search_fixed "$token" "$gate" "$readout" "$evidence" \
    || fail "Final acceptance artifacts missing token: $token"
done
pass "Final acceptance artifacts preserve claim boundaries"

for token in \
  "DAN-281" \
  "DAN-282" \
  "DAN-283" \
  "DAN-284" \
  "DAN-285" \
  "DAN-286" \
  "DAN-287" \
  "DAN-288" \
  "DAN-289" \
  "DAN-290" \
  "DAN-291" \
  "DAN-292"; do
  search_fixed "$token" "$gate" "$readout" "$evidence" \
    || fail "Final acceptance artifacts missing issue: $token"
done
pass "Final acceptance artifacts reference child workstream sequence"

for token in \
  "Definition of Done" \
  "30/60/90 Day Plan" \
  "Risk Register" \
  "KPI Map" \
  "Platform-Native vs Custom" \
  "Final Recommendation"; do
  search_fixed "$token" "$readout" \
    || fail "Final readout missing section: $token"
done
pass "Final readout includes required sections"

echo "[PASS] RevOps final acceptance gate validation completed"
