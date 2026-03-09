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
TARGET_TABLE="${TARGET_TABLE:-pulse360_s4.intelligence.duplicate_candidate_pairs}"

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
  AND table_name = 'duplicate_candidate_pairs'
"

quality_sql="
SELECT
  COUNT(*) AS pair_count,
  SUM(CASE WHEN duplicate_confidence_score BETWEEN 0 AND 100 THEN 0 ELSE 1 END) AS bad_score_rows,
  SUM(CASE WHEN run_id IS NULL OR run_id = '' THEN 1 ELSE 0 END) AS missing_run_id_rows,
  SUM(CASE WHEN run_timestamp IS NULL THEN 1 ELSE 0 END) AS missing_run_timestamp_rows,
  SUM(CASE WHEN model_version IS NULL OR model_version = '' THEN 1 ELSE 0 END) AS missing_model_version_rows
FROM $TARGET_TABLE
"

distribution_sql="
SELECT confidence_band, COUNT(*) AS pair_count
FROM $TARGET_TABLE
GROUP BY confidence_band
ORDER BY pair_count DESC, confidence_band
"

existence_resp="$(run_sql "$existence_sql")"
exists_count="$(jq -r '.result.data_array[0][0] // "0"' <<<"$existence_resp")"
[[ "$exists_count" != "0" ]] || fail "Table does not exist: $TARGET_TABLE"
pass "Table exists: $TARGET_TABLE"

quality_resp="$(run_sql "$quality_sql")"
pair_count="$(jq -r '.result.data_array[0][0] // "0"' <<<"$quality_resp")"
bad_score_rows="$(jq -r '.result.data_array[0][1] // "0"' <<<"$quality_resp")"
missing_run_id_rows="$(jq -r '.result.data_array[0][2] // "0"' <<<"$quality_resp")"
missing_run_ts_rows="$(jq -r '.result.data_array[0][3] // "0"' <<<"$quality_resp")"
missing_model_rows="$(jq -r '.result.data_array[0][4] // "0"' <<<"$quality_resp")"

[[ "$pair_count" != "0" ]] || fail "No duplicate pairs generated"
[[ "$bad_score_rows" == "0" ]] || fail "Found confidence scores outside 0-100"
[[ "$missing_run_id_rows" == "0" ]] || fail "Found rows missing run_id"
[[ "$missing_run_ts_rows" == "0" ]] || fail "Found rows missing run_timestamp"
[[ "$missing_model_rows" == "0" ]] || fail "Found rows missing model_version"
pass "Runtime quality checks passed (pair_count=$pair_count)"

dist_resp="$(run_sql "$distribution_sql")"
pass "Confidence band distribution query succeeded"
echo "$dist_resp" | jq -c '.result.data_array // []'
