#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

HOST="${DATABRICKS_HOST:-$(awk -F' *= *' '/^host/{print $2; exit}' ~/.databrickscfg)}"
TOKEN="${DATABRICKS_TOKEN:-$(awk -F' *= *' '/^token/{print $2; exit}' ~/.databrickscfg)}"
WAREHOUSE_ID="${DATABRICKS_WAREHOUSE_ID:-7052914888c7e86c}"

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
    fail "Databricks SQL statement failed for Account 360 runtime validation"
  fi

  echo "$response"
}

quality_sql="
SELECT
  COUNT(*) AS rows_count,
  SUM(CASE WHEN unified_profile_id IS NULL OR unified_profile_id = '' THEN 1 ELSE 0 END) AS missing_profile,
  SUM(CASE WHEN group_revenue_rollup IS NULL OR group_revenue_rollup < 0 THEN 1 ELSE 0 END) AS bad_rollup,
  SUM(CASE WHEN cross_sell_propensity IS NULL OR cross_sell_propensity < 0 OR cross_sell_propensity > 100 THEN 1 ELSE 0 END) AS bad_propensity,
  SUM(CASE WHEN coverage_gap_flag IS NULL THEN 1 ELSE 0 END) AS missing_coverage_flag,
  SUM(CASE WHEN last_synced_timestamp IS NULL THEN 1 ELSE 0 END) AS missing_last_synced,
  SUM(CASE WHEN run_id IS NULL OR run_id = '' THEN 1 ELSE 0 END) AS missing_run_id,
  SUM(CASE WHEN run_timestamp IS NULL THEN 1 ELSE 0 END) AS missing_run_timestamp,
  SUM(CASE WHEN model_version IS NULL OR model_version = '' THEN 1 ELSE 0 END) AS missing_model_version
FROM pulse360_s4.intelligence.datacloud_export_accounts
"

degraded_sql="
SELECT
  SUM(
    CASE
      WHEN last_synced_timestamp < current_timestamp() - INTERVAL 30 MINUTES THEN 1
      ELSE 0
    END
  ) AS degraded_rows,
  COUNT(*) AS total_rows
FROM pulse360_s4.intelligence.datacloud_export_accounts
"

sample_sql="
SELECT
  unified_profile_id,
  source_account_id,
  account_name,
  group_revenue_rollup,
  cross_sell_propensity,
  coverage_gap_flag,
  last_synced_timestamp,
  CASE
    WHEN last_synced_timestamp < current_timestamp() - INTERVAL 30 MINUTES THEN 'degraded'
    ELSE 'healthy'
  END AS data_health_status,
  CASE
    WHEN last_synced_timestamp < current_timestamp() - INTERVAL 30 MINUTES THEN 'Data is delayed. Showing latest available snapshot.'
    ELSE ''
  END AS degraded_mode_message,
  run_id,
  run_timestamp,
  model_version
FROM pulse360_s4.intelligence.datacloud_export_accounts
ORDER BY run_timestamp DESC
LIMIT 3
"

quality_resp="$(run_sql "$quality_sql")"
rows="$(jq -r '.result.data_array[0][0] // "0"' <<<"$quality_resp")"
missing_profile="$(jq -r '.result.data_array[0][1] // "0"' <<<"$quality_resp")"
bad_rollup="$(jq -r '.result.data_array[0][2] // "0"' <<<"$quality_resp")"
bad_propensity="$(jq -r '.result.data_array[0][3] // "0"' <<<"$quality_resp")"
missing_coverage="$(jq -r '.result.data_array[0][4] // "0"' <<<"$quality_resp")"
missing_synced="$(jq -r '.result.data_array[0][5] // "0"' <<<"$quality_resp")"
missing_run_id="$(jq -r '.result.data_array[0][6] // "0"' <<<"$quality_resp")"
missing_run_ts="$(jq -r '.result.data_array[0][7] // "0"' <<<"$quality_resp")"
missing_model="$(jq -r '.result.data_array[0][8] // "0"' <<<"$quality_resp")"

[[ "$rows" != "0" ]] || fail "No rows available in datacloud_export_accounts"
[[ "$missing_profile" == "0" ]] || fail "Missing unified_profile_id found"
[[ "$bad_rollup" == "0" ]] || fail "Invalid group_revenue_rollup found"
[[ "$bad_propensity" == "0" ]] || fail "Invalid cross_sell_propensity found"
[[ "$missing_coverage" == "0" ]] || fail "Missing coverage_gap_flag found"
[[ "$missing_synced" == "0" ]] || fail "Missing last_synced_timestamp found"
[[ "$missing_run_id" == "0" ]] || fail "Missing run_id found"
[[ "$missing_run_ts" == "0" ]] || fail "Missing run_timestamp found"
[[ "$missing_model" == "0" ]] || fail "Missing model_version found"
pass "Account 360 live-field checks passed (rows=$rows)"

degraded_resp="$(run_sql "$degraded_sql")"
degraded_rows="$(jq -r '.result.data_array[0][0] // "0"' <<<"$degraded_resp")"
total_rows="$(jq -r '.result.data_array[0][1] // "0"' <<<"$degraded_resp")"
pass "Degraded-mode condition evaluated (degraded_rows=$degraded_rows, total_rows=$total_rows)"

sample_resp="$(run_sql "$sample_sql")"
pass "Account 360 sample query succeeded"
echo "$sample_resp" | jq -c '.result.data_array // []'
