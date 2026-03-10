#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

HOST="${DATABRICKS_HOST:-$(awk -F' *= *' '/^host/{print $2; exit}' ~/.databrickscfg)}"
TOKEN="${DATABRICKS_TOKEN:-$(awk -F' *= *' '/^token/{print $2; exit}' ~/.databrickscfg)}"
WAREHOUSE_ID="${DATABRICKS_WAREHOUSE_ID:-7052914888c7e86c}"
SOURCE_ACCOUNT_ID="${SOURCE_ACCOUNT_ID:-sf_acc_1001}"

[[ -n "$HOST" ]] || fail "Databricks host is not configured"
[[ -n "$TOKEN" ]] || fail "Databricks token is not configured"
[[ -n "$WAREHOUSE_ID" ]] || fail "Databricks warehouse ID is not configured"

run_sql() {
  local sql="$1"
  local payload response state stmt_id poll_resp poll_state i

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
    fail "Databricks SQL statement failed for cross-sell quick-create runtime"
  fi
  echo "$response"
}

quality_sql="
SELECT
  COUNT(*) AS rows_count,
  SUM(CASE WHEN unified_profile_id IS NULL OR unified_profile_id = '' THEN 1 ELSE 0 END) AS missing_profile,
  SUM(CASE WHEN cross_sell_propensity IS NULL OR cross_sell_propensity < 0 OR cross_sell_propensity > 100 THEN 1 ELSE 0 END) AS bad_propensity,
  SUM(CASE WHEN coverage_gap_flag IS NULL THEN 1 ELSE 0 END) AS missing_coverage_flag,
  SUM(CASE WHEN open_opportunity_count IS NULL OR open_opportunity_count < 0 THEN 1 ELSE 0 END) AS bad_open_opps,
  SUM(CASE WHEN last_synced_timestamp IS NULL THEN 1 ELSE 0 END) AS missing_last_synced
FROM pulse360_s4.intelligence.datacloud_export_accounts
WHERE source_account_id = '$SOURCE_ACCOUNT_ID'
"

sample_sql="
SELECT
  source_account_id,
  unified_profile_id,
  cross_sell_propensity,
  coverage_gap_flag,
  open_opportunity_count,
  open_opportunity_count + 1 AS projected_open_opportunity_count_after_create,
  CASE
    WHEN cross_sell_propensity >= 80 THEN 'show_recommendation'
    WHEN cross_sell_propensity >= 60 THEN 'show_info_only'
    ELSE 'hide'
  END AS banner_state,
  'datacloud_group_profile_link' AS linkage_type,
  'opportunity_created' AS refresh_trigger_event,
  5 AS expected_recompute_window_minutes,
  last_synced_timestamp,
  run_id,
  run_timestamp,
  model_version
FROM pulse360_s4.intelligence.datacloud_export_accounts
WHERE source_account_id = '$SOURCE_ACCOUNT_ID'
ORDER BY run_timestamp DESC
LIMIT 1
"

quality_resp="$(run_sql "$quality_sql")"
rows="$(jq -r '.result.data_array[0][0] // "0"' <<<"$quality_resp")"
missing_profile="$(jq -r '.result.data_array[0][1] // "0"' <<<"$quality_resp")"
bad_propensity="$(jq -r '.result.data_array[0][2] // "0"' <<<"$quality_resp")"
missing_coverage="$(jq -r '.result.data_array[0][3] // "0"' <<<"$quality_resp")"
bad_open_opps="$(jq -r '.result.data_array[0][4] // "0"' <<<"$quality_resp")"
missing_synced="$(jq -r '.result.data_array[0][5] // "0"' <<<"$quality_resp")"

[[ "$rows" != "0" ]] || fail "No rows found for source account $SOURCE_ACCOUNT_ID"
[[ "$missing_profile" == "0" ]] || fail "Missing unified_profile_id found"
[[ "$bad_propensity" == "0" ]] || fail "Invalid cross_sell_propensity found"
[[ "$missing_coverage" == "0" ]] || fail "Missing coverage_gap_flag found"
[[ "$bad_open_opps" == "0" ]] || fail "Invalid open_opportunity_count found"
[[ "$missing_synced" == "0" ]] || fail "Missing last_synced_timestamp found"
pass "Cross-sell quick-create runtime source checks passed for $SOURCE_ACCOUNT_ID"

sample_resp="$(run_sql "$sample_sql")"
pass "Cross-sell quick-create sample query succeeded"
echo "$sample_resp" | jq -c '.result.data_array // []'
