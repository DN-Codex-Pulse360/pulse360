#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

cfg="config/data-cloud/calculated-insights.yaml"
mapping="config/data-cloud/activation-field-mapping.csv"

[[ -f "$cfg" ]] || fail "Missing calculated insights config"
[[ -f "$mapping" ]] || fail "Missing activation field mapping"

for metric in health_score cross_sell_propensity coverage_gap_flag competitor_risk_signal; do
  grep -q "name: $metric" "$cfg" || fail "Missing metric in calculated insights config: $metric"
done

for field in unified_profile_id identity_confidence group_revenue_rollup health_score cross_sell_propensity coverage_gap_flag primary_brand_name active_product_count engagement_intensity_score open_opportunity_count last_engagement_timestamp last_synced_timestamp; do
  grep -q "^$field," "$mapping" || fail "Missing activation mapping for: $field"
done

grep -q "recompute_trigger:" "$cfg" || fail "Missing recompute trigger section"
pass "Data Cloud calculated insights and activation mapping config validated"
