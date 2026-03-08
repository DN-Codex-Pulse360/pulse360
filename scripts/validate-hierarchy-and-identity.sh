#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

pass() {
  echo "[PASS] $1"
}

hierarchy_file="data/samples/hierarchy/databricks_hierarchy_graph_sample.json"
identity_file="data/samples/datacloud_identity_resolution_sample.json"
rule_file="config/data-cloud/identity-resolution-rules.json"

[[ -f "$hierarchy_file" ]] || fail "Missing hierarchy sample file"
[[ -f "$identity_file" ]] || fail "Missing identity sample file"
[[ -f "$rule_file" ]] || fail "Missing identity rules config"
pass "Required hierarchy and identity files exist"

grep -q '"entity_id": "ent_' "$hierarchy_file" || fail "Hierarchy entities do not use deterministic ent_ IDs"
pass "Hierarchy entity IDs follow deterministic pattern"

grep -q '"relationship_type": "SUBSIDIARY_OF"' "$hierarchy_file" || fail "Hierarchy edges missing relationship types"
pass "Hierarchy edges include relationship types"

grep -q '"parent_entity_id": "ent_pacific_holdings"' "$hierarchy_file" || fail "Missing top-level hierarchy parent edge"
grep -q '"child_entity_id": "ent_pacific_capital_sg"' "$hierarchy_file" || fail "Missing level-2 hierarchy child"
grep -q '"parent_entity_id": "ent_pacific_capital_sg"' "$hierarchy_file" || fail "Missing level-2 parent edge for multi-level hierarchy"
grep -q '"child_entity_id": "ent_pacific_advisors"' "$hierarchy_file" || fail "Missing level-3 hierarchy child"
pass "Hierarchy sample demonstrates multi-level parent-child depth"

threshold=$(grep -E '"target_confidence_threshold"' "$rule_file" | sed -E 's/[^0-9]//g')
[[ "$threshold" -ge 90 ]] || fail "Identity threshold is below 90"
pass "Identity threshold meets >=90 requirement"

if ! awk '
/"key_demo_pairs"/ { in_pairs=1 }
in_pairs && /"identity_confidence"/ {
  gsub(/[^0-9]/, "", $0)
  if (($0+0) < 90) bad=1
  seen=1
}
in_pairs && /\],/ { in_pairs=0 }
END {
  if (!seen || bad) exit 1
}
' "$identity_file"; then
  fail "One or more key demo pairs are below 90 confidence"
fi
pass "All key demo identity pairs meet >= 90 confidence"

grep -q '"unified_profile_id"' "$identity_file" || fail "Missing unified_profile_id in hierarchy rollup output"
if ! awk '/"group_revenue_rollup"/ {gsub(/[^0-9]/, "", $0); if (($0+0) > 0) ok=1} END{exit(ok?0:1)}' "$identity_file"; then
  fail "Group revenue rollup is missing or not positive"
fi
pass "Hierarchy rollup output includes unified profile and group rollup evidence"

pass "Hierarchy and identity validation completed"
