#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

contract_doc="docs/contracts/pulse360-m1-data-cloud-operational-profile-contract.md"
schema="contracts/m1_account_hierarchy_operational_profile.schema.json"
sample="data/samples/m1_account_hierarchy_operational_profile_sample.json"
mapping="config/data-cloud/m1-account-hierarchy-operational-profile-mapping.csv"
activation_mapping="config/data-cloud/activation-field-mapping.csv"
dmo_mapping="config/data-cloud/dmo-account-field-mapping.csv"
databricks_sql="sql/databricks/identity_resolution/60_m1_account_hierarchy_operational_profile.sql"

for file in "$contract_doc" "$schema" "$sample" "$mapping" "$activation_mapping" "$dmo_mapping" "$databricks_sql"; do
  [[ -f "$file" ]] || fail "Missing required file: $file"
done
pass "M1 Data Cloud operational profile files are present"

python3 -m json.tool "$schema" >/dev/null || fail "Invalid JSON schema: $schema"
python3 -m json.tool "$sample" >/dev/null || fail "Invalid JSON sample: $sample"
pass "M1 operational profile JSON files parse"

expected_header="profile_field,source_dataset,source_field,target_layer,target_object,target_field,data_type,required,crm_activation,crm_target_field,exposure,notes"
actual_header="$(head -n 1 "$mapping")"
[[ "$actual_header" == "$expected_header" ]] || fail "M1 mapping header mismatch"

for field in \
  operational_profile_id group_entity_id primary_anchor_account_id crm_anchor_account_ids \
  unified_profile_id identity_confidence hierarchy_confidence validity_score_external \
  group_revenue_rollup group_revenue_visible group_known_subsidiary_count \
  crm_covered_subsidiary_count external_subsidiaries_found coverage_gap_flag \
  hierarchy_payload source_refs freshness_status last_synced_timestamp enrichment_run_id \
  model_id run_id run_timestamp model_version; do
  grep -q "^$field," "$mapping" || fail "Missing M1 mapping row: $field"
  grep -q "\"$field\"" "$schema" || fail "Missing schema field: $field"
  grep -q "\"$field\"" "$sample" || fail "Missing sample field: $field"
done
pass "M1 mapping, schema, and sample contain required fields"

for token in m1_account_hierarchy_operational_profile primary_anchor_account_id crm_anchor_account_ids try_element_at; do
  grep -q "$token" "$databricks_sql" || fail "M1 Databricks SQL missing required token: $token"
done
pass "M1 Databricks SQL emits operational profile anchor fields"

for crm_field in \
  unified_profile_id identity_confidence validity_score_external group_revenue_rollup \
  group_revenue_visible group_known_subsidiary_count crm_covered_subsidiary_count \
  external_subsidiaries_found coverage_gap_flag source_refs last_synced_timestamp \
  enrichment_run_id model_id; do
  grep -q "^$crm_field," "$activation_mapping" || fail "CRM activation mapping missing required M1 field: $crm_field"
done
pass "M1 CRM activation fields exist in activation mapping"

for dmo_field in hierarchy_payload source_refs group_revenue_visible group_known_subsidiary_count crm_covered_subsidiary_count; do
  grep -q "^$dmo_field," "$dmo_mapping" || fail "DMO mapping missing required M1 field: $dmo_field"
done
pass "M1 Data Cloud DMO fields exist in DMO mapping"

grep -q '^hierarchy_payload,.*data_cloud,.*false,' "$mapping" || fail "Hierarchy payload must not be default CRM activation"
grep -q 'never use as CRM writeback key' "$mapping" || fail "Group entity ID must be marked non-CRM writeback"
grep -q 'Never use `group_entity_id`' "$contract_doc" || fail "Contract missing synthetic ID writeback guardrail"
grep -qi 'raw hierarchy evidence is not required' "$contract_doc" || fail "Contract missing raw hierarchy evidence guardrail"
pass "M1 guardrails keep raw graph detail out of default CRM writeback"

pass "M1 Data Cloud operational profile validation completed"
