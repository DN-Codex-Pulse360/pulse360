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
  "contracts/account_feature_snapshot.schema.json"
  "contracts/model_score_output.schema.json"
  "data/samples/account_feature_snapshot_sample.json"
  "data/samples/model_score_output_sample.json"
  "config/databricks/model-serving-byom-plan.json"
  "sql/databricks/model_serving/00_create_schema.sql"
  "sql/databricks/model_serving/10_account_feature_snapshot.sql"
  "sql/databricks/model_serving/20_model_score_output.sql"
  "sql/databricks/model_serving/30_icp_fit_baseline_score.sql"
  "sql/databricks/model_serving/README.md"
  "docs/planning/pulse360-databricks-feature-model-byom-plan-2026-05-08.md"
  "docs/runbook/salesforce-byom-databricks-model-serving-runbook.md"
)

for path in "${required_files[@]}"; do
  [[ -f "$path" ]] || fail "Missing model serving/BYOM artifact: $path"
done
pass "Model serving/BYOM artifacts exist"

for path in \
  contracts/account_feature_snapshot.schema.json \
  contracts/model_score_output.schema.json \
  data/samples/account_feature_snapshot_sample.json \
  data/samples/model_score_output_sample.json \
  config/databricks/model-serving-byom-plan.json; do
  python3 -m json.tool "$path" >/dev/null || fail "Invalid JSON: $path"
done
pass "Model serving/BYOM JSON artifacts parse"

python3 - <<'PY'
import json
from pathlib import Path

plan = json.loads(Path("config/databricks/model-serving-byom-plan.json").read_text())
if plan.get("linear_issue") != "DAN-286":
    raise SystemExit("model-serving-byom-plan linear_issue must be DAN-286")
if plan.get("primary_model_family") != "icp_fit":
    raise SystemExit("primary_model_family must be icp_fit")
if plan.get("serving_strategy", {}).get("default_mode") != "batch":
    raise SystemExit("default serving mode must be batch")
if plan.get("salesforce_byom_gate", {}).get("status") != "gated":
    raise SystemExit("Salesforce BYOM gate must be gated")
fallback = plan.get("salesforce_byom_gate", {}).get("default_fallback")
if fallback != "data_cloud_batch_enrichment":
    raise SystemExit("BYOM fallback must be data_cloud_batch_enrichment")

model_families = {m.get("model_family"): m for m in plan.get("model_families", [])}
for required in [
    "icp_fit",
    "cross_sell_propensity",
    "intent_routing",
    "renewal_risk",
    "entity_resolution",
]:
    if required not in model_families:
        raise SystemExit(f"Missing model family: {required}")

score = json.loads(Path("data/samples/model_score_output_sample.json").read_text())
if score.get("consumption_path") != "data_cloud_batch_enrichment":
    raise SystemExit("sample score must use data_cloud_batch_enrichment")
gates = score.get("gates", {})
for gate in [
    "databricks_endpoint_ready",
    "salesforce_byom_entitlement_verified",
    "data_cloud_mapping_verified",
]:
    if gates.get(gate) is not False:
        raise SystemExit(f"sample score gate must default false: {gate}")
if gates.get("human_review_required") is not True:
    raise SystemExit("sample score must require human review")
PY
pass "Model serving/BYOM plan semantics OK"

for token in \
  "source_account_id" \
  "snapshot_as_of" \
  "feature_set_version" \
  "point_in_time_policy" \
  "source_refs" \
  "input_table_versions" \
  "feature_completeness" \
  "evidence_coverage" \
  "activation_eligible_flag"; do
  search_fixed "$token" contracts/account_feature_snapshot.schema.json data/samples/account_feature_snapshot_sample.json \
    || fail "Feature snapshot contract/sample missing token: $token"
done
pass "Feature snapshot contract preserves point-in-time lineage controls"

for token in \
  "source_account_id" \
  "feature_snapshot_id" \
  "model_family" \
  "registered_model_name" \
  "score" \
  "confidence" \
  "score_band" \
  "top_drivers" \
  "explanation_text" \
  "serving_mode" \
  "consumption_path" \
  "run_id" \
  "scored_at" \
  "databricks_endpoint_ready" \
  "salesforce_byom_entitlement_verified" \
  "human_review_required"; do
  search_fixed "$token" contracts/model_score_output.schema.json data/samples/model_score_output_sample.json config/databricks/model-serving-byom-plan.json \
    || fail "Model score contract/sample/config missing token: $token"
done
pass "Model score contract preserves serving, BYOM, and explanation controls"

for token in \
  "pulse360_s4.gold.account_feature_snapshot" \
  "pulse360_s4.gold.model_score_output" \
  "source_account_id" \
  "top_drivers_json" \
  "registered_model_name" \
  "databricks_endpoint_ready" \
  "salesforce_byom_entitlement_verified" \
  "data_cloud_mapping_verified" \
  "human_review_required" \
  "icp_fit_baseline_score_vw"; do
  search_fixed "$token" sql/databricks/model_serving \
    || fail "Model serving SQL missing token: $token"
done
pass "Model serving SQL emits feature and score outputs"

for token in \
  "batch-first" \
  "BYOM" \
  "gated" \
  "source_account_id" \
  "M2 ICP Fit and Account Scoring" \
  "Mosaic AI Model Serving" \
  "Data Cloud batch enrichment" \
  "No State Change"; do
  search_fixed "$token" docs/planning/pulse360-databricks-feature-model-byom-plan-2026-05-08.md docs/runbook/salesforce-byom-databricks-model-serving-runbook.md \
    || fail "Model serving/BYOM docs missing token: $token"
done
pass "Model serving/BYOM docs preserve gated batch-first posture"

echo "[PASS] Databricks model serving/BYOM plan validation completed"
