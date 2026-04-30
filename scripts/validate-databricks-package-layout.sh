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
[[ -f "$workspace/account-intelligence-export/contracts/databricks_to_datacloud.schema.json" ]] \
  || fail "Databricks account-intelligence-export workspace is missing the handoff contract"
[[ -f "$workspace/identity-resolution/databricks.yml" ]] \
  || fail "Databricks identity-resolution workspace is missing databricks.yml"
[[ -f "$workspace/identity-resolution/sql/databricks/identity_resolution/20_resolved_entity.sql" ]] \
  || fail "Databricks identity-resolution workspace is missing resolved entity SQL"
[[ -f "$workspace/identity-resolution/sql/databricks/identity_resolution/60_m1_account_hierarchy_operational_profile.sql" ]] \
  || fail "Databricks identity-resolution workspace is missing M1 operational profile SQL"
[[ -f "$workspace/identity-resolution/contracts/sovereign_identity_spine.schema.json" ]] \
  || fail "Databricks identity-resolution workspace is missing sovereign identity contract"
[[ -f "$workspace/identity-resolution/contracts/weighted_attribute_resolution.schema.json" ]] \
  || fail "Databricks identity-resolution workspace is missing weighted attribute contract"
[[ -f "$workspace/firmographic-enrichment/databricks.yml" ]] \
  || fail "Databricks firmographic-enrichment workspace is missing databricks.yml"
[[ -f "$workspace/firmographic-enrichment/sql/databricks/firmographic_enrichment/30_account_genai_enrichment_output.sql" ]] \
  || fail "Databricks firmographic-enrichment workspace is missing Gen AI output SQL"
[[ -f "$workspace/firmographic-enrichment/contracts/firmographic_evidence_packet.schema.json" ]] \
  || fail "Databricks firmographic-enrichment workspace is missing firmographic evidence contract"
[[ -f "$workspace/firmographic-enrichment/contracts/genai_firmographic_enrichment_output.schema.json" ]] \
  || fail "Databricks firmographic-enrichment workspace is missing Gen AI enrichment output contract"
[[ -f "$workspace/account-intelligence-sources/databricks.yml" ]] \
  || fail "Databricks account-intelligence-sources workspace is missing databricks.yml"
[[ -f "$workspace/account-intelligence-sources/sql/databricks/account_intelligence_sources/20_account_ai_enrichment_output.sql" ]] \
  || fail "Databricks account-intelligence-sources workspace is missing account AI enrichment SQL"
[[ -f "$workspace/account-intelligence-sources/contracts/synthetic_enterprise_source_pack.schema.json" ]] \
  || fail "Databricks account-intelligence-sources workspace is missing synthetic enterprise source contract"
[[ -f "$workspace/account-intelligence-sources/contracts/account_intelligence_ai_enrichment_output.schema.json" ]] \
  || fail "Databricks account-intelligence-sources workspace is missing account intelligence AI output contract"
[[ -f "$workspace/csp-smart-city/databricks.yml" ]] \
  || fail "Databricks csp-smart-city workspace is missing databricks.yml"
[[ -f "$workspace/csp-smart-city/sql/databricks/csp_smart_city/10_smart_city_proposition_readiness.sql" ]] \
  || fail "Databricks csp-smart-city workspace is missing proposition readiness SQL"
[[ -f "$workspace/csp-smart-city/contracts/csp_smart_city_proposition_signal.schema.json" ]] \
  || fail "Databricks csp-smart-city workspace is missing proposition signal contract"
[[ -f "$workspace/governance-evidence/databricks.yml" ]] \
  || fail "Databricks governance-evidence workspace is missing databricks.yml"
[[ -f "$workspace/governance-evidence/sql/databricks/governance_evidence/10_account_intelligence_governance_evidence.sql" ]] \
  || fail "Databricks governance-evidence workspace is missing governance evidence SQL"
[[ -f "$workspace/governance-evidence/contracts/account_intelligence_governance_evidence.schema.json" ]] \
  || fail "Databricks governance-evidence workspace is missing governance evidence contract"

grep -Fq 'pulse360-salesforce-ingestion' "$workspace/salesforce-ingestion/databricks.yml" \
  || fail "Databricks salesforce-ingestion bundle is missing its bundle name"
grep -Fq 'pulse360-account-intelligence-export' "$workspace/account-intelligence-export/databricks.yml" \
  || fail "Databricks account-intelligence-export bundle is missing its bundle name"
grep -Fq 'pulse360-identity-resolution' "$workspace/identity-resolution/databricks.yml" \
  || fail "Databricks identity-resolution bundle is missing its bundle name"
grep -Fq 'pulse360-firmographic-enrichment' "$workspace/firmographic-enrichment/databricks.yml" \
  || fail "Databricks firmographic-enrichment bundle is missing its bundle name"
grep -Fq 'pulse360-account-intelligence-sources' "$workspace/account-intelligence-sources/databricks.yml" \
  || fail "Databricks account-intelligence-sources bundle is missing its bundle name"
grep -Fq 'pulse360-csp-smart-city' "$workspace/csp-smart-city/databricks.yml" \
  || fail "Databricks csp-smart-city bundle is missing its bundle name"
grep -Fq 'pulse360-governance-evidence' "$workspace/governance-evidence/databricks.yml" \
  || fail "Databricks governance-evidence bundle is missing its bundle name"

pass "Databricks package layout validation completed"
