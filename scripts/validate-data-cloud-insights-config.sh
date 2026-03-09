#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

cfg="config/data-cloud/calculated-insights.yaml"
mapping="config/data-cloud/activation-field-mapping.csv"
stream_manifest="config/data-cloud/stream-manifest.yaml"

[[ -f "$cfg" ]] || fail "Missing calculated insights config"
[[ -f "$mapping" ]] || fail "Missing activation field mapping"
[[ -f "$stream_manifest" ]] || fail "Missing stream manifest"

for metric in health_score cross_sell_propensity coverage_gap_flag competitor_risk_signal; do
  grep -q "name: $metric" "$cfg" || fail "Missing metric in calculated insights config: $metric"
done

for field in unified_profile_id identity_confidence group_revenue_rollup health_score cross_sell_propensity coverage_gap_flag competitor_risk_signal primary_brand_name active_product_count engagement_intensity_score open_opportunity_count last_engagement_timestamp last_synced_timestamp; do
  grep -q "^$field," "$mapping" || fail "Missing activation mapping for: $field"
done

grep -q "mode: near_real_time" "$cfg" || fail "Activation mode must be near_real_time"
grep -q "max_sync_latency_minutes: 5" "$cfg" || fail "Missing max sync latency guardrail"
grep -q "recompute_trigger:" "$cfg" || fail "Missing recompute trigger section"
grep -q -- "- opportunity_created" "$cfg" || fail "Missing opportunity_created recompute trigger"
grep -q -- "- governance_merge_approved" "$cfg" || fail "Missing governance_merge_approved recompute trigger"

for token in \
  "salesforce_account_stream:" \
  "databricks_enrichment_stream:" \
  "source_table: pulse360_s4.intelligence.datacloud_export_accounts" \
  "ingestion_metadata_label_field: ingestion_metadata_label"; do
  grep -q "$token" "$stream_manifest" || fail "Missing stream manifest token: $token"
done

pass "Data Cloud calculated insights and activation mapping config validated"
