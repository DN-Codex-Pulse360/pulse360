#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

contract="$repo_root/contracts/m1_account_hierarchy_output.schema.json"
sample="$repo_root/data/samples/account_hierarchy/m1_account_hierarchy_output_sample.json"
members="$repo_root/config/packages/databricks/account-hierarchy-intelligence.members.txt"
sql_dir="$repo_root/sql/databricks/account_hierarchy"
runbook="$repo_root/docs/runbook/pulse360-m1-account-hierarchy-runbook.md"
salesforce_runbook="$repo_root/docs/runbook/salesforce-m1-account-hierarchy-validation-runbook.md"
evidence="$repo_root/docs/evidence/dan-330-m1-account-hierarchy-kickoff-2026-05-08.md"
runtime_evidence="$repo_root/docs/evidence/dan-332-m1-account-hierarchy-runtime-validation-2026-05-08.md"
salesforce_evidence="$repo_root/docs/evidence/dan-334-m1-data-cloud-salesforce-validation-2026-05-09.md"
runtime_check="$repo_root/scripts/run-m1-account-hierarchy-runtime-check.sh"
salesforce_surface_check="$repo_root/scripts/validate-m1-data-cloud-salesforce-surface.sh"
m1_data_cloud_setup="$repo_root/config/data-cloud/m1-account-hierarchy-dlo-dmo-setup.csv"
m1_dmo_field_mapping="$repo_root/config/data-cloud/m1-account-hierarchy-dmo-field-mapping.csv"
m1_activation_mapping="$repo_root/config/data-cloud/m1-account-hierarchy-activation-field-mapping.csv"
m1_report_config="$repo_root/config/salesforce/m1-account-hierarchy-validation-reports.csv"
m1_surface_config="$repo_root/config/salesforce/m1-account-hierarchy-surface.yaml"

[[ -f "$contract" ]] || fail "Missing M1 hierarchy contract"
[[ -f "$sample" ]] || fail "Missing M1 hierarchy sample"
[[ -f "$members" ]] || fail "Missing M1 Databricks package membership"
[[ -d "$sql_dir" ]] || fail "Missing M1 SQL directory"
[[ -f "$runbook" ]] || fail "Missing M1 runbook"
[[ -f "$salesforce_runbook" ]] || fail "Missing M1 Salesforce/Data Cloud runbook"
[[ -f "$evidence" ]] || fail "Missing M1 kickoff evidence"
[[ -f "$runtime_evidence" ]] || fail "Missing M1 runtime evidence"
[[ -f "$salesforce_evidence" ]] || fail "Missing M1 Salesforce/Data Cloud evidence"
[[ -f "$runtime_check" ]] || fail "Missing M1 runtime check"
[[ -f "$salesforce_surface_check" ]] || fail "Missing M1 Salesforce/Data Cloud validator"
[[ -f "$m1_data_cloud_setup" ]] || fail "Missing M1 Data Cloud setup config"
[[ -f "$m1_dmo_field_mapping" ]] || fail "Missing M1 DMO field mapping"
[[ -f "$m1_activation_mapping" ]] || fail "Missing M1 Account activation mapping"
[[ -f "$m1_report_config" ]] || fail "Missing M1 Salesforce report config"
[[ -f "$m1_surface_config" ]] || fail "Missing M1 Salesforce surface config"
pass "M1 source files exist"

for file in \
  "00_create_schema.sql" \
  "10_m1_account_hierarchy_edge.sql" \
  "20_m1_account_group_rollup.sql" \
  "30_m1_account_hierarchy_activation.sql" \
  "40_m1_account_hierarchy_activation_export.sql" \
  "50_m1_account_group_rollup_export.sql" \
  "60_m1_account_hierarchy_edge_export.sql"; do
  [[ -f "$sql_dir/$file" ]] || fail "Missing M1 SQL file: $file"
done
pass "M1 SQL run-order files exist"

for key in \
  "account_group_id" \
  "source_account_id" \
  "group_anchor_source_account_id" \
  "hierarchy_edge_id" \
  "coverage_gap_flag" \
  "evidence_refs"; do
  grep -q "\"$key\"" "$contract" || fail "M1 contract missing key: $key"
done
pass "M1 contract contains required keys"

grep -q '"account_group_id": "agrp_' "$sample" || fail "Sample does not use agrp_ group IDs"
grep -q '"hierarchy_edge_id": "m1edge_' "$sample" || fail "Sample does not use m1edge_ edge IDs"
grep -q '"coverage_gap_id": "cgap_' "$sample" || fail "Sample does not use cgap_ coverage gap IDs"
grep -q '"source_account_id"' "$sample" || fail "Sample missing source_account_id"
pass "M1 sample uses deterministic ID prefixes and Account join key"

grep -Eq "source_account_id.*CRM-safe Account join key" "$sql_dir/README.md" \
  || fail "M1 SQL README must state Account join key rule"
grep -Eq "Sovereign identifiers.*not used as Account join keys" "$sql_dir/README.md" \
  || fail "M1 SQL README must prevent sovereign IDs as Account joins"
pass "M1 SQL README documents join-key controls"

while IFS= read -r member || [[ -n "$member" ]]; do
  [[ -z "$member" ]] && continue
  [[ "$member" =~ ^# ]] && continue
  [[ -e "$repo_root/$member" ]] || fail "M1 package member missing from repo: $member"
done <"$members"
pass "M1 package members resolve"

for required in \
  "sql/databricks/account_hierarchy" \
  "contracts/m1_account_hierarchy_output.schema.json" \
  "config/data-cloud/m1-account-hierarchy-dlo-dmo-setup.csv" \
  "config/data-cloud/m1-account-hierarchy-dmo-field-mapping.csv" \
  "config/salesforce/m1-account-hierarchy-validation-reports.csv" \
  "scripts/validate-m1-account-hierarchy-pack.sh" \
  "scripts/run-m1-account-hierarchy-runtime-check.sh" \
  "scripts/validate-m1-data-cloud-salesforce-surface.sh"; do
  grep -q "$required" "$members" || fail "M1 package missing member: $required"
done
pass "M1 package membership includes critical assets"

grep -q "DAN-330" "$evidence" || fail "Evidence missing DAN-330"
grep -q "codex/m1-account-hierarchy-intelligence" "$evidence" || fail "Evidence missing branch name"
grep -q "DAN-332" "$runtime_evidence" || fail "Runtime evidence missing DAN-332"
grep -q "m1_account_hierarchy_activation" "$runtime_evidence" || fail "Runtime evidence missing activation table"
grep -q "m1_account_hierarchy_activation_export" "$salesforce_evidence" || fail "Salesforce evidence missing activation export table"
grep -q "DAN-334" "$salesforce_evidence" || fail "Salesforce evidence missing DAN-334"
grep -q "not live-complete" "$salesforce_evidence" || fail "Salesforce evidence must distinguish source prep from live completion"
pass "M1 evidence references Linear, branch, runtime, and Salesforce/Data Cloud context"

if grep -R "PROVIDER_BOLDDATA_ID\|PROVIDER_INFOBEL_ID\|CRM_ACCOUNT_ID" "$contract" "$sample" "$sql_dir" >/dev/null; then
  fail "M1 assets must not promote provider/search/CRM pseudo-identifiers as sovereign identifiers"
fi
pass "M1 assets do not promote provider/search/CRM IDs as sovereign identifiers"

python3 - "$contract" "$sample" <<'PY'
import json
import sys

for path in sys.argv[1:]:
    with open(path, "r", encoding="utf-8") as handle:
        json.load(handle)
print("[PASS] M1 JSON assets parse")
PY

pass "M1 Account Hierarchy pack validation completed"
