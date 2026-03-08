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

threshold=$(grep -E '"target_confidence_threshold"' "$rule_file" | sed -E 's/[^0-9]//g')
[[ "$threshold" -ge 90 ]] || fail "Identity threshold is below 90"
pass "Identity threshold meets >=90 requirement"

if ! awk '/"identity_confidence"/ {gsub(/[^0-9]/, "", $0); if ($0+0 >= 90) ok=1} END{exit(ok?0:1)}' "$identity_file"; then
  fail "No key demo pair has confidence >= 90"
fi
pass "Key demo identity pairs include confidence >= 90"

pass "Hierarchy and identity validation completed"
