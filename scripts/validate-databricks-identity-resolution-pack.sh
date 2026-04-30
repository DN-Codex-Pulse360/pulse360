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
  "sql/databricks/identity_resolution/00_create_schema.sql"
  "sql/databricks/identity_resolution/05_registry_identity_source_sample.sql"
  "sql/databricks/identity_resolution/10_identity_source_xref_base.sql"
  "sql/databricks/identity_resolution/20_resolved_entity.sql"
  "sql/databricks/identity_resolution/30_weighted_attribute_resolution.sql"
  "sql/databricks/identity_resolution/40_entity_hierarchy_edge.sql"
  "sql/databricks/identity_resolution/50_entity_hierarchy_rollup.sql"
  "sql/databricks/identity_resolution/60_m1_account_hierarchy_operational_profile.sql"
  "sql/databricks/identity_resolution/README.md"
  "contracts/sovereign_identity_spine.schema.json"
  "contracts/registry_identity_source.schema.json"
  "contracts/weighted_attribute_resolution.schema.json"
  "contracts/m1_account_hierarchy_operational_profile.schema.json"
  "data/samples/registry_identity_source_sample.json"
  "data/samples/sovereign_identity_spine_sample.json"
  "data/samples/weighted_attribute_resolution_sample.json"
  "docs/setup/databricks-identity-resolution-runbook.md"
)

for path in "${required_files[@]}"; do
  [[ -f "$path" ]] || fail "Missing identity resolution package artifact: $path"
done
pass "Databricks identity resolution package artifacts exist"

schema_sql="sql/databricks/identity_resolution/00_create_schema.sql"
registry_sql="sql/databricks/identity_resolution/05_registry_identity_source_sample.sql"
xref_sql="sql/databricks/identity_resolution/10_identity_source_xref_base.sql"
entity_sql="sql/databricks/identity_resolution/20_resolved_entity.sql"
weighted_sql="sql/databricks/identity_resolution/30_weighted_attribute_resolution.sql"
edge_sql="sql/databricks/identity_resolution/40_entity_hierarchy_edge.sql"
rollup_sql="sql/databricks/identity_resolution/50_entity_hierarchy_rollup.sql"
m1_profile_sql="sql/databricks/identity_resolution/60_m1_account_hierarchy_operational_profile.sql"
readme="sql/databricks/identity_resolution/README.md"
runbook="docs/setup/databricks-identity-resolution-runbook.md"

for token in \
  "CREATE SCHEMA IF NOT EXISTS pulse360_s4.identity_resolution"; do
  search_fixed "$token" "$schema_sql" || fail "Missing token in identity schema SQL: $token"
done

for token in \
  "pulse360_s4.identity_resolution.registry_identity_source_sample" \
  "registry_source_id" \
  "national_id_type" \
  "national_id_value" \
  "source_refs"; do
  search_fixed "$token" "$registry_sql" || fail "Missing token in registry source SQL: $token"
done

for token in \
  "pulse360_s4.identity_resolution.identity_source_xref_base" \
  "source_identifier_type" \
  "source_confidence" \
  "last_refreshed_at" \
  "is_identity_anchor"; do
  search_fixed "$token" "$xref_sql" || fail "Missing token in identity xref SQL: $token"
done

for token in \
  "pulse360_s4.identity_resolution.resolved_entity" \
  "sovereign_identity_key" \
  "crm_safe_fallback" \
  "deterministic_sovereign_id" \
  "source_identifiers" \
  "crm_account_ids" \
  "run_id" \
  "model_version"; do
  search_fixed "$token" "$entity_sql" || fail "Missing token in resolved entity SQL: $token"
done

for token in \
  "pulse360_s4.identity_resolution.weighted_attribute_resolution" \
  "source_contributions" \
  "freshness_status" \
  "attribute_confidence" \
  "winning_source_id" \
  "survivorship_rule"; do
  search_fixed "$token" "$weighted_sql" || fail "Missing token in weighted attribute SQL: $token"
done
pass "Identity SQL definitions preserve contract fields"

for token in \
  "pulse360_s4.identity_resolution.entity_hierarchy_edge" \
  "hierarchy_edge_id" \
  "parent_entity_id" \
  "child_entity_id" \
  "relationship_type" \
  "child_coverage_status" \
  "source_contributions" \
  "freshness_status" \
  "model_version"; do
  search_fixed "$token" "$edge_sql" || fail "Missing token in hierarchy edge SQL: $token"
done

for token in \
  "pulse360_s4.identity_resolution.entity_hierarchy_rollup" \
  "group_entity_id" \
  "known_subsidiary_count" \
  "crm_covered_subsidiary_count" \
  "uncovered_subsidiary_count" \
  "coverage_gap_flag" \
  "hierarchy_payload" \
  "source_contributions"; do
  search_fixed "$token" "$rollup_sql" || fail "Missing token in hierarchy rollup SQL: $token"
done
pass "Hierarchy SQL definitions preserve M1 rollup fields"

for token in \
  "pulse360_s4.identity_resolution.m1_account_hierarchy_operational_profile" \
  "primary_anchor_account_id" \
  "crm_anchor_account_ids" \
  "try_element_at" \
  "coalesce(a.crm_anchor_account_ids, array())" \
  "source_refs" \
  "m1-data-cloud-operational-profile-v1"; do
  search_fixed "$token" "$m1_profile_sql" || fail "Missing token in M1 operational profile SQL: $token"
done
pass "M1 operational profile SQL preserves Data Cloud anchor fields"

for token in \
  "CRM_SAFE_FALLBACK" \
  "registry_identity_source_sample" \
  "contracts/sovereign_identity_spine.schema.json" \
  "contracts/registry_identity_source.schema.json" \
  "contracts/weighted_attribute_resolution.schema.json" \
  "60_m1_account_hierarchy_operational_profile.sql"; do
  search_fixed "$token" "$readme" "$runbook" || fail "Missing documentation token: $token"
done
pass "Identity README and runbook document fallback posture and contracts"

pass "Databricks identity resolution pack validation completed"
