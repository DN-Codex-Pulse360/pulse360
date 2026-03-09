#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

pass() {
  echo "[PASS] $1"
}

manifest="config/data-cloud/stream-manifest.yaml"
mapping="config/data-cloud/activation-field-mapping.csv"

[[ -f "$manifest" ]] || fail "Missing stream manifest: $manifest"
[[ -f "$mapping" ]] || fail "Missing activation mapping: $mapping"

for token in \
  "salesforce_account_stream:" \
  "databricks_enrichment_stream:" \
  "source_table: pulse360_s4.intelligence.datacloud_export_accounts" \
  "ingestion_metadata_label_field: ingestion_metadata_label" \
  "expected_latency_minutes: 15"; do
  rg -q "$token" "$manifest" || fail "Missing stream-manifest token: $token"
done
pass "Stream manifest contains required stream definitions"

for field in \
  unified_profile_id \
  identity_confidence \
  group_revenue_rollup \
  health_score \
  cross_sell_propensity \
  coverage_gap_flag \
  competitor_risk_signal \
  primary_brand_name \
  active_product_count \
  engagement_intensity_score \
  open_opportunity_count \
  last_engagement_timestamp \
  last_synced_timestamp; do
  rg -q "^$field," "$mapping" || fail "Missing activation mapping field: $field"
done
pass "Activation mapping includes required stream target fields"

HOST="${DATABRICKS_HOST:-$(awk -F' *= *' '/^host/{print $2; exit}' ~/.databrickscfg)}"
TOKEN="${DATABRICKS_TOKEN:-$(awk -F' *= *' '/^token/{print $2; exit}' ~/.databrickscfg)}"
WAREHOUSE_ID="${DATABRICKS_WAREHOUSE_ID:-7052914888c7e86c}"

[[ -n "$HOST" ]] || fail "Databricks host is not configured"
[[ -n "$TOKEN" ]] || fail "Databricks token is not configured"
[[ -n "$WAREHOUSE_ID" ]] || fail "Databricks warehouse ID is not configured"

run_sql() {
  local sql="$1"
  local payload
  local response
  local state
  local stmt_id
  local poll_resp
  local poll_state
  local i

  payload="$(jq -nc \
    --arg wid "$WAREHOUSE_ID" \
    --arg statement "$sql" \
    '{warehouse_id: $wid, statement: $statement, wait_timeout: "30s"}')"

  response="$(curl -sS -X POST \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    "$HOST/api/2.0/sql/statements" \
    -d "$payload")"

  state="$(jq -r '.status.state // "UNKNOWN"' <<<"$response")"
  stmt_id="$(jq -r '.statement_id // "n/a"' <<<"$response")"
  if [[ "$state" == "PENDING" || "$state" == "RUNNING" ]]; then
    for i in {1..30}; do
      sleep 2
      poll_resp="$(curl -sS -H "Authorization: Bearer $TOKEN" "$HOST/api/2.0/sql/statements/$stmt_id")"
      poll_state="$(jq -r '.status.state // "UNKNOWN"' <<<"$poll_resp")"
      if [[ "$poll_state" == "SUCCEEDED" ]]; then
        response="$poll_resp"
        state="$poll_state"
        break
      fi
      if [[ "$poll_state" == "FAILED" || "$poll_state" == "CANCELED" || "$poll_state" == "CLOSED" ]]; then
        response="$poll_resp"
        state="$poll_state"
        break
      fi
    done
  fi

  if [[ "$state" != "SUCCEEDED" ]]; then
    echo "$response" | jq .
    fail "Databricks SQL validation statement failed"
  fi

  echo "$response"
}

health_sql="
SELECT
  (SELECT COUNT(*) FROM pulse360_s4.intelligence.duplicate_candidate_pairs) AS duplicate_rows,
  (SELECT COUNT(*) FROM pulse360_s4.intelligence.firmographic_enrichment) AS enrichment_rows,
  (SELECT COUNT(*) FROM pulse360_s4.intelligence.governance_ops_metrics) AS governance_rows,
  (SELECT COUNT(*) FROM pulse360_s4.intelligence.datacloud_export_accounts) AS export_rows,
  (SELECT MAX(last_synced_timestamp) FROM pulse360_s4.intelligence.datacloud_export_accounts) AS export_last_synced,
  (SELECT MAX(ingestion_metadata_label) FROM pulse360_s4.intelligence.datacloud_export_accounts) AS ingestion_metadata_label
"

mapping_validation_sql="
SELECT
  SUM(CASE WHEN unified_profile_id IS NULL OR unified_profile_id = '' THEN 1 ELSE 0 END) AS missing_unified_profile_id,
  SUM(CASE WHEN identity_confidence < 0 OR identity_confidence > 100 THEN 1 ELSE 0 END) AS bad_identity_confidence,
  SUM(CASE WHEN last_synced_timestamp IS NULL THEN 1 ELSE 0 END) AS missing_last_synced,
  SUM(CASE WHEN ingestion_metadata_label IS NULL OR ingestion_metadata_label = '' THEN 1 ELSE 0 END) AS missing_ingestion_label
FROM pulse360_s4.intelligence.datacloud_export_accounts
"

health_resp="$(run_sql "$health_sql")"
dup_rows="$(jq -r '.result.data_array[0][0] // "0"' <<<"$health_resp")"
enr_rows="$(jq -r '.result.data_array[0][1] // "0"' <<<"$health_resp")"
gov_rows="$(jq -r '.result.data_array[0][2] // "0"' <<<"$health_resp")"
exp_rows="$(jq -r '.result.data_array[0][3] // "0"' <<<"$health_resp")"
last_synced="$(jq -r '.result.data_array[0][4] // ""' <<<"$health_resp")"
label="$(jq -r '.result.data_array[0][5] // ""' <<<"$health_resp")"

[[ "$dup_rows" != "0" ]] || fail "duplicate_candidate_pairs has zero rows"
[[ "$enr_rows" != "0" ]] || fail "firmographic_enrichment has zero rows"
[[ "$gov_rows" != "0" ]] || fail "governance_ops_metrics has zero rows"
[[ "$exp_rows" != "0" ]] || fail "datacloud_export_accounts has zero rows"
[[ -n "$last_synced" ]] || fail "Missing export last_synced_timestamp"
[[ -n "$label" ]] || fail "Missing ingestion metadata label"
[[ "$label" == Databricks\ Enrichment* ]] || fail "Ingestion label does not follow required prefix"
pass "Stream health checks passed for Databricks source tables"

mapping_resp="$(run_sql "$mapping_validation_sql")"
missing_profile="$(jq -r '.result.data_array[0][0] // "0"' <<<"$mapping_resp")"
bad_identity="$(jq -r '.result.data_array[0][1] // "0"' <<<"$mapping_resp")"
missing_synced="$(jq -r '.result.data_array[0][2] // "0"' <<<"$mapping_resp")"
missing_label="$(jq -r '.result.data_array[0][3] // "0"' <<<"$mapping_resp")"

[[ "$missing_profile" == "0" ]] || fail "Missing unified_profile_id rows found in export"
[[ "$bad_identity" == "0" ]] || fail "Identity confidence outside 0-100 found in export"
[[ "$missing_synced" == "0" ]] || fail "Missing last_synced_timestamp rows found in export"
[[ "$missing_label" == "0" ]] || fail "Missing ingestion metadata label rows found in export"
pass "Stream-to-contract field checks passed"

echo "$health_resp" | jq -c '.result.data_array // []'
