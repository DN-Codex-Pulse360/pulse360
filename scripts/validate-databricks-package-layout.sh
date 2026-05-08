#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
temp_dir="$(mktemp -d)"
trap 'rm -rf "$temp_dir"' EXIT

"$repo_root/scripts/build-databricks-package-workspace.sh" "$temp_dir/workspace" >/dev/null

workspace="$temp_dir/workspace"

[[ -f "$workspace/salesforce-ingestion/databricks.yml" ]] \
  || fail "Databricks salesforce-ingestion workspace is missing databricks.yml"
[[ -f "$workspace/salesforce-ingestion/sql/databricks/silver_salesforce/10_crm_account.sql" ]] \
  || fail "Databricks salesforce-ingestion workspace is missing crm_account SQL"
[[ -f "$workspace/account-intelligence-export/databricks.yml" ]] \
  || fail "Databricks account-intelligence-export workspace is missing databricks.yml"
[[ -f "$workspace/account-intelligence-export/sql/databricks/gold/30_datacloud_export_accounts.sql" ]] \
  || fail "Databricks account-intelligence-export workspace is missing export SQL"
[[ -f "$workspace/account-intelligence-export/sql/databricks/gold/80_firmographic_source_evidence_export.sql" ]] \
  || fail "Databricks account-intelligence-export workspace is missing firmographic evidence export SQL"
[[ -f "$workspace/account-intelligence-export/contracts/databricks_to_datacloud.schema.json" ]] \
  || fail "Databricks account-intelligence-export workspace is missing the handoff contract"
[[ -f "$workspace/model-serving-byom/databricks.yml" ]] \
  || fail "Databricks model-serving-byom workspace is missing databricks.yml"
[[ -f "$workspace/model-serving-byom/sql/databricks/model_serving/10_account_feature_snapshot.sql" ]] \
  || fail "Databricks model-serving-byom workspace is missing account feature snapshot SQL"
[[ -f "$workspace/model-serving-byom/sql/databricks/model_serving/20_model_score_output.sql" ]] \
  || fail "Databricks model-serving-byom workspace is missing model score output SQL"
[[ -f "$workspace/model-serving-byom/contracts/model_score_output.schema.json" ]] \
  || fail "Databricks model-serving-byom workspace is missing model score contract"

grep -Fq 'pulse360-salesforce-ingestion' "$workspace/salesforce-ingestion/databricks.yml" \
  || fail "Databricks salesforce-ingestion bundle is missing its bundle name"
grep -Fq 'pulse360-account-intelligence-export' "$workspace/account-intelligence-export/databricks.yml" \
  || fail "Databricks account-intelligence-export bundle is missing its bundle name"
grep -Fq 'pulse360-model-serving-byom' "$workspace/model-serving-byom/databricks.yml" \
  || fail "Databricks model-serving-byom bundle is missing its bundle name"

pass "Databricks package layout validation completed"
