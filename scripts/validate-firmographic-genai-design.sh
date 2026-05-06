#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

design_doc="docs/planning/pulse360-databricks-firmographic-provider-genai-design-2026-04-25.md"
decision_stack="docs/planning/pulse360-revops-intelligence-feasible-architecture-decision-stack-2026-04-24.md"
north_star="docs/improvements/pulse360-north-star-solution-specification.md"

for file in "$design_doc" "$decision_stack" "$north_star"; do
  [[ -f "$file" ]] || fail "Missing firmographic/GPT design artifact: $file"
done
pass "Firmographic/GPT design artifacts exist"

for forbidden in \
  "CompanyData" \
  "BoldData" \
  "Infobel" \
  "docs.companydata" \
  "bizsearch.infobelpro" \
  "x-api-key"; do
  if grep -Riq "$forbidden" "$design_doc" "$decision_stack" "$north_star"; then
    fail "Firmographic/GPT design must not hardwire paid-provider reference: $forbidden"
  fi
done
pass "Firmographic/GPT design avoids hardwired paid-provider references"

for token in \
  "Firmographic Evidence Shape" \
  "GPT Prompt Evidence Packet" \
  "llm_result_confidence" \
  "business_action_confidence" \
  "source_reliability_score" \
  "evidence_coverage_score" \
  "corroboration_score" \
  "freshness_score" \
  "extraction_certainty_score" \
  "conflict_penalty" \
  "citation_binding_score" \
  "schema_validation_score" \
  "unsupported_claim_count"; do
  grep -q "$token" "$design_doc" || fail "Firmographic/GPT design missing required confidence token: $token"
done
pass "Firmographic/GPT design includes source-bound confidence scoring"

for token in \
  "No paid-provider endpoint" \
  "source IDs" \
  "confidence components" \
  "No endpoint, paid service, or vendor runtime"; do
  grep -q "$token" "$design_doc" "$decision_stack" "$north_star" || fail "Firmographic/GPT governance language missing: $token"
done
pass "Firmographic/GPT design preserves provider-neutral governance language"

pass "Firmographic/GPT design validation completed"
