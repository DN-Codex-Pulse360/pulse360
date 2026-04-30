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
  "docs/planning/pulse360-csp-smart-city-pivot-2026-04-27.md"
  "contracts/csp_smart_city_proposition_signal.schema.json"
  "data/samples/csp_smart_city_proposition_signal_sample.json"
  "sql/databricks/csp_smart_city/00_create_schemas.sql"
  "sql/databricks/csp_smart_city/05_smart_city_signal_sample.sql"
  "sql/databricks/csp_smart_city/10_smart_city_proposition_readiness.sql"
  "sql/databricks/csp_smart_city/README.md"
  "config/packages/databricks/csp-smart-city.members.txt"
)

for path in "${required_files[@]}"; do
  [[ -f "$path" ]] || fail "Missing CSP smart-city package artifact: $path"
done
pass "CSP smart-city package artifacts exist"

python3 -m json.tool contracts/csp_smart_city_proposition_signal.schema.json >/dev/null \
  || fail "Invalid CSP smart-city proposition signal schema JSON"
python3 -m json.tool data/samples/csp_smart_city_proposition_signal_sample.json >/dev/null \
  || fail "Invalid CSP smart-city proposition signal sample JSON"
pass "CSP smart-city JSON artifacts parse"

for token in \
  "intelligent_parking" \
  "urban_data_brokerage" \
  "connected_city_iot_platform" \
  "municipal_open_data" \
  "csp_network" \
  "iot_telemetry" \
  "public_sector_trigger" \
  "partner_ecosystem" \
  "mobility_data" \
  "consent_privacy_classification" \
  "recommended_next_action"; do
  search_fixed "$token" \
    docs/planning/pulse360-csp-smart-city-pivot-2026-04-27.md \
    contracts/csp_smart_city_proposition_signal.schema.json \
    data/samples/csp_smart_city_proposition_signal_sample.json \
    sql/databricks/csp_smart_city \
    || fail "CSP smart-city pack missing token: $token"
done
pass "CSP smart-city pack includes offering, source, and governance tokens"

for token in \
  "city_singapore_smart_nation" \
  "city_kuala_lumpur_mobility" \
  "city_amata_chonburi" \
  "city_hcmc_iot_locality" \
  "city_metro_manila_iot" \
  "https://www.smartnation.gov.sg/initiatives/smart-city-solutions/" \
  "https://www.tmone.com.my/smart-services/smart-city/" \
  "https://international.viettel.vn/news-detail/viettel-builds-hcm-city-the-first-iot-based-locality-in-vietnam"; do
  search_fixed "$token" data/samples/csp_smart_city_proposition_signal_sample.json sql/databricks/csp_smart_city \
    || fail "CSP smart-city sample missing ASEAN evidence token: $token"
done
pass "CSP smart-city sample includes ASEAN market evidence"

for token in \
  "pulse360_s4.bronze_smart_city.smart_city_signal_sample" \
  "pulse360_s4.bronze_smart_city.smart_city_b2b_customer_sample" \
  "pulse360_s4.gold_smart_city.smart_city_proposition_readiness" \
  "proposition_readiness_score" \
  "activation_state" \
  "activation_block_reasons" \
  "source_refs" \
  "target_b2b_customer_ids" \
  "governance_or_privacy_review_required"; do
  search_fixed "$token" sql/databricks/csp_smart_city \
    || fail "CSP smart-city SQL missing output token: $token"
done
pass "CSP smart-city SQL emits governed proposition readiness output"

for token in \
  "associated_b2b_customers" \
  "b2b_ph_mmda_mobility_office" \
  "b2b_ph_manila_parking_operator" \
  "b2b_ph_ayala_property_group" \
  "ph_manila_parking_open_data_001" \
  "ph_metro_manila_iot_network_001" \
  "Metro Manila Intelligent Parking"; do
  search_fixed "$token" \
    contracts/csp_smart_city_proposition_signal.schema.json \
    data/samples/csp_smart_city_proposition_signal_sample.json \
    sql/databricks/csp_smart_city \
    || fail "CSP smart-city pack missing Manila or B2B target-customer token: $token"
done
pass "CSP smart-city pack includes Manila propositions and B2B target customers"

for forbidden in \
  "citizen_id" \
  "subscriber_msisdn" \
  "raw_location_trace" \
  "personal_location"; do
  if grep -Riq "$forbidden" \
    contracts/csp_smart_city_proposition_signal.schema.json \
    data/samples/csp_smart_city_proposition_signal_sample.json \
    sql/databricks/csp_smart_city; then
    fail "CSP smart-city pack must not include citizen-level or subscriber-level data token: $forbidden"
  fi
done
pass "CSP smart-city pack avoids citizen-level and subscriber-level data"

pass "Databricks CSP smart-city pack validation completed"
