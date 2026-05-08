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

required_files=(
  "contracts/governance_evidence_packet.schema.json"
  "data/samples/governance_evidence_packet_sample.json"
  "config/databricks/governance-evidence-gates.json"
  "sql/databricks/governance_evidence/00_create_schema.sql"
  "sql/databricks/governance_evidence/10_governance_evidence_packet.sql"
  "sql/databricks/governance_evidence/20_governance_evidence_from_firmographic.sql"
  "sql/databricks/governance_evidence/README.md"
  "docs/planning/pulse360-governance-lineage-audit-plan-2026-05-08.md"
  "docs/runbook/pulse360-governance-evidence-runtime-runbook.md"
)

for path in "${required_files[@]}"; do
  [[ -f "$path" ]] || fail "Missing governance evidence artifact: $path"
done
pass "Governance evidence artifacts exist"

for path in \
  contracts/governance_evidence_packet.schema.json \
  data/samples/governance_evidence_packet_sample.json \
  config/databricks/governance-evidence-gates.json; do
  python3 -m json.tool "$path" >/dev/null || fail "Invalid JSON: $path"
done
pass "Governance evidence JSON artifacts parse"

python3 - <<'PY'
import json
from pathlib import Path

gates = json.loads(Path("config/databricks/governance-evidence-gates.json").read_text())
if gates.get("linear_issue") != "DAN-290":
    raise SystemExit("governance evidence gate must map to DAN-290")

families = set(gates.get("required_evidence_families", []))
for required in [
    "unity_catalog_lineage",
    "source_contribution",
    "feature_model_lineage",
    "data_cloud_mapping",
    "salesforce_record_audit",
    "governance_case_decision_audit",
    "llm_prompt_model_citation_audit",
    "provider_entitlement_or_license",
]:
    if required not in families:
        raise SystemExit(f"Missing evidence family: {required}")

activation = gates.get("activation_rules", {})
for key in [
    "allow_activation_without_source_contribution",
    "allow_activation_without_run_id",
    "allow_activation_without_freshness",
    "allow_llm_narrative_without_citation",
    "allow_model_score_without_feature_snapshot",
]:
    if activation.get(key) is not False:
        raise SystemExit(f"Activation rule must be false: {key}")

packet = json.loads(Path("data/samples/governance_evidence_packet_sample.json").read_text())
if not packet.get("source_contributions"):
    raise SystemExit("Sample packet must include source contributions")
if not packet.get("lineage_refs"):
    raise SystemExit("Sample packet must include lineage refs")
readiness = packet.get("regulator_readiness", {})
if readiness.get("ready_for_demo") is not True:
    raise SystemExit("Sample packet should be demo-ready")
if readiness.get("ready_for_external_audit") is not False:
    raise SystemExit("Sample packet should not claim external audit readiness")
PY
pass "Governance evidence gate semantics OK"

for token in \
  "source_contributions" \
  "lineage_refs" \
  "model_refs" \
  "llm_audit_refs" \
  "salesforce_audit_refs" \
  "confidence" \
  "freshness_status" \
  "run_id" \
  "generated_at" \
  "validation_status" \
  "regulator_readiness"; do
  search_fixed "$token" contracts/governance_evidence_packet.schema.json data/samples/governance_evidence_packet_sample.json \
    || fail "Governance evidence contract/sample missing token: $token"
done
pass "Governance evidence contract preserves required evidence references"

for token in \
  "unity_catalog_lineage" \
  "source_contribution" \
  "feature_model_lineage" \
  "data_cloud_mapping" \
  "salesforce_record_audit" \
  "governance_case_decision_audit" \
  "llm_prompt_model_citation_audit" \
  "provider_entitlement_or_license" \
  "allow_activation_without_source_contribution" \
  "allow_model_score_without_feature_snapshot"; do
  search_fixed "$token" config/databricks/governance-evidence-gates.json \
    || fail "Governance gates config missing token: $token"
done
pass "Governance evidence gates cover cross-platform controls"

for token in \
  "pulse360_s4.gold.governance_evidence_packet" \
  "source_contributions_json" \
  "lineage_refs_json" \
  "model_refs_json" \
  "llm_audit_refs_json" \
  "salesforce_audit_refs_json" \
  "ready_for_external_audit" \
  "regulator_readiness_reason"; do
  search_fixed "$token" sql/databricks/governance_evidence \
    || fail "Governance evidence SQL missing token: $token"
done
pass "Governance evidence SQL emits audit-ready envelope"

for token in \
  "Unity Catalog lineage" \
  "Source contribution" \
  "Feature/model lineage" \
  "Data Cloud mapping" \
  "Governance Case audit" \
  "LLM audit metadata" \
  "ready_for_external_audit" \
  "No State Change"; do
  search_fixed "$token" docs/planning/pulse360-governance-lineage-audit-plan-2026-05-08.md docs/runbook/pulse360-governance-evidence-runtime-runbook.md \
    || fail "Governance evidence docs missing token: $token"
done
pass "Governance evidence docs preserve regulator/readiness boundaries"

echo "[PASS] Governance evidence pack validation completed"
