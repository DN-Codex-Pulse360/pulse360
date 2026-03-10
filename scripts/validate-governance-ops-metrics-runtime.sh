#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

pass() {
  echo "[PASS] $1"
}

HOST="${DATABRICKS_HOST:-$(awk -F' *= *' '/^host/{print $2; exit}' ~/.databrickscfg)}"
TOKEN="${DATABRICKS_TOKEN:-$(awk -F' *= *' '/^token/{print $2; exit}' ~/.databrickscfg)}"
WAREHOUSE_ID="${DATABRICKS_WAREHOUSE_ID:-7052914888c7e86c}"
TARGET_TABLE="${TARGET_TABLE:-pulse360_s4.intelligence.governance_ops_metrics}"

[[ -n "$HOST" ]] || fail "Databricks host is not configured"
[[ -n "$TOKEN" ]] || fail "Databricks token is not configured"
[[ -n "$WAREHOUSE_ID" ]] || fail "Databricks warehouse ID is not configured"

run_sql() {
  local sql="$1"
  local payload
  local response
  local state

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
  if [[ "$state" != "SUCCEEDED" ]]; then
    echo "$response" | jq .
    fail "Databricks SQL validation statement failed"
  fi

  echo "$response"
}

existence_sql="
SELECT COUNT(*) AS table_exists
FROM pulse360_s4.information_schema.tables
WHERE table_schema = 'intelligence'
  AND table_name = 'governance_ops_metrics'
"

quality_sql="
SELECT
  COUNT(*) AS rows_count,
  SUM(CASE WHEN cases_opened < 0 THEN 1 ELSE 0 END) AS bad_cases_opened_rows,
  SUM(CASE WHEN cases_resolved < 0 THEN 1 ELSE 0 END) AS bad_cases_resolved_rows,
  SUM(CASE WHEN backlog_open < 0 THEN 1 ELSE 0 END) AS bad_backlog_rows,
  SUM(CASE WHEN quality_score < 0 OR quality_score > 100 THEN 1 ELSE 0 END) AS bad_quality_rows,
  SUM(CASE WHEN merge_approval_rate < 0 OR merge_approval_rate > 100 THEN 1 ELSE 0 END) AS bad_approval_rows,
  SUM(CASE WHEN cases_resolved + backlog_open > cases_opened THEN 1 ELSE 0 END) AS case_balance_errors
FROM $TARGET_TABLE
"

metadata_sql="
SELECT
  SUM(CASE WHEN run_id IS NULL OR run_id = '' THEN 1 ELSE 0 END) AS missing_run_id_rows,
  SUM(CASE WHEN metric_ts IS NULL THEN 1 ELSE 0 END) AS missing_metric_ts_rows,
  SUM(CASE WHEN model_version IS NULL OR model_version = '' THEN 1 ELSE 0 END) AS missing_model_version_rows
FROM $TARGET_TABLE
"

latest_sql="
SELECT
  run_id,
  metric_ts,
  cases_opened,
  cases_resolved,
  backlog_open,
  avg_resolution_minutes,
  quality_score,
  merge_approval_rate
FROM $TARGET_TABLE
ORDER BY metric_ts DESC
LIMIT 1
"

exist_resp="$(run_sql "$existence_sql")"
exists_count="$(jq -r '.result.data_array[0][0] // "0"' <<<"$exist_resp")"
[[ "$exists_count" != "0" ]] || fail "Table does not exist: $TARGET_TABLE"
pass "Table exists: $TARGET_TABLE"

quality_resp="$(run_sql "$quality_sql")"
rows_count="$(jq -r '.result.data_array[0][0] // "0"' <<<"$quality_resp")"
bad_opened="$(jq -r '.result.data_array[0][1] // "0"' <<<"$quality_resp")"
bad_resolved="$(jq -r '.result.data_array[0][2] // "0"' <<<"$quality_resp")"
bad_backlog="$(jq -r '.result.data_array[0][3] // "0"' <<<"$quality_resp")"
bad_quality="$(jq -r '.result.data_array[0][4] // "0"' <<<"$quality_resp")"
bad_approval="$(jq -r '.result.data_array[0][5] // "0"' <<<"$quality_resp")"
balance_errors="$(jq -r '.result.data_array[0][6] // "0"' <<<"$quality_resp")"

[[ "$rows_count" != "0" ]] || fail "No governance metrics rows generated"
[[ "$bad_opened" == "0" ]] || fail "Negative cases_opened values found"
[[ "$bad_resolved" == "0" ]] || fail "Negative cases_resolved values found"
[[ "$bad_backlog" == "0" ]] || fail "Negative backlog_open values found"
[[ "$bad_quality" == "0" ]] || fail "quality_score outside 0-100 found"
[[ "$bad_approval" == "0" ]] || fail "merge_approval_rate outside 0-100 found"
[[ "$balance_errors" == "0" ]] || fail "cases_resolved + backlog_open exceeds cases_opened"
pass "Governance quality checks passed (rows=$rows_count)"

metadata_resp="$(run_sql "$metadata_sql")"
missing_run_id="$(jq -r '.result.data_array[0][0] // "0"' <<<"$metadata_resp")"
missing_metric_ts="$(jq -r '.result.data_array[0][1] // "0"' <<<"$metadata_resp")"
missing_model_version="$(jq -r '.result.data_array[0][2] // "0"' <<<"$metadata_resp")"
[[ "$missing_run_id" == "0" ]] || fail "Missing run_id values found"
[[ "$missing_metric_ts" == "0" ]] || fail "Missing metric_ts values found"
[[ "$missing_model_version" == "0" ]] || fail "Missing model_version values found"
pass "Metadata checks passed"

latest_resp="$(run_sql "$latest_sql")"
pass "Latest governance metrics query succeeded"
echo "$latest_resp" | jq -c '.result.data_array // []'
