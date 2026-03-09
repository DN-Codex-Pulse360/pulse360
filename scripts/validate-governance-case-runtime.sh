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
    fail "Databricks SQL statement failed for governance runtime validation"
  fi

  echo "$response"
}

sql="
WITH pair_join AS (
  SELECT
    d.left_source_account_id,
    d.right_source_account_id,
    d.duplicate_confidence_score AS pair_confidence,
    le.validity_score AS left_validity_score,
    re.validity_score AS right_validity_score,
    x.identity_confidence,
    d.run_id,
    d.run_timestamp,
    d.model_version
  FROM pulse360_s4.intelligence.duplicate_candidate_pairs d
  JOIN pulse360_s4.intelligence.firmographic_enrichment le
    ON d.left_source_account_id = le.source_account_id
  JOIN pulse360_s4.intelligence.firmographic_enrichment re
    ON d.right_source_account_id = re.source_account_id
  LEFT JOIN pulse360_s4.intelligence.datacloud_export_accounts x
    ON x.source_account_id = d.left_source_account_id
)
SELECT
  COUNT(*) AS candidate_pairs,
  SUM(CASE WHEN pair_confidence < 0 OR pair_confidence > 100 THEN 1 ELSE 0 END) AS bad_pair_confidence,
  SUM(CASE WHEN left_validity_score < 0 OR left_validity_score > 100 THEN 1 ELSE 0 END) AS bad_left_validity,
  SUM(CASE WHEN right_validity_score < 0 OR right_validity_score > 100 THEN 1 ELSE 0 END) AS bad_right_validity,
  SUM(CASE WHEN identity_confidence IS NULL OR identity_confidence < 0 OR identity_confidence > 100 THEN 1 ELSE 0 END) AS bad_identity_confidence,
  SUM(CASE WHEN run_id IS NULL OR run_id = '' THEN 1 ELSE 0 END) AS missing_run_id,
  SUM(CASE WHEN run_timestamp IS NULL THEN 1 ELSE 0 END) AS missing_run_timestamp,
  SUM(CASE WHEN model_version IS NULL OR model_version = '' THEN 1 ELSE 0 END) AS missing_model_version
FROM pair_join
"

sample_sql="
SELECT
  d.left_source_account_id,
  d.right_source_account_id,
  d.duplicate_confidence_score,
  le.validity_score AS left_validity_score,
  re.validity_score AS right_validity_score,
  x.identity_confidence,
  d.run_id,
  d.run_timestamp
FROM pulse360_s4.intelligence.duplicate_candidate_pairs d
JOIN pulse360_s4.intelligence.firmographic_enrichment le
  ON d.left_source_account_id = le.source_account_id
JOIN pulse360_s4.intelligence.firmographic_enrichment re
  ON d.right_source_account_id = re.source_account_id
LEFT JOIN pulse360_s4.intelligence.datacloud_export_accounts x
  ON x.source_account_id = d.left_source_account_id
ORDER BY d.run_timestamp DESC
LIMIT 3
"

resp="$(run_sql "$sql")"
pairs="$(jq -r '.result.data_array[0][0] // "0"' <<<"$resp")"
bad_pair="$(jq -r '.result.data_array[0][1] // "0"' <<<"$resp")"
bad_lvalid="$(jq -r '.result.data_array[0][2] // "0"' <<<"$resp")"
bad_rvalid="$(jq -r '.result.data_array[0][3] // "0"' <<<"$resp")"
bad_identity="$(jq -r '.result.data_array[0][4] // "0"' <<<"$resp")"
missing_run_id="$(jq -r '.result.data_array[0][5] // "0"' <<<"$resp")"
missing_run_ts="$(jq -r '.result.data_array[0][6] // "0"' <<<"$resp")"
missing_model_version="$(jq -r '.result.data_array[0][7] // "0"' <<<"$resp")"

[[ "$pairs" != "0" ]] || fail "No candidate pairs found for governance side-by-side payload"
[[ "$bad_pair" == "0" ]] || fail "Pair confidence outside 0-100 found"
[[ "$bad_lvalid" == "0" ]] || fail "Left validity score outside 0-100 found"
[[ "$bad_rvalid" == "0" ]] || fail "Right validity score outside 0-100 found"
[[ "$bad_identity" == "0" ]] || fail "Identity confidence missing/outside 0-100 found"
[[ "$missing_run_id" == "0" ]] || fail "Missing run_id in governance payload source"
[[ "$missing_run_ts" == "0" ]] || fail "Missing run_timestamp in governance payload source"
[[ "$missing_model_version" == "0" ]] || fail "Missing model_version in governance payload source"
pass "Governance side-by-side runtime checks passed (pairs=$pairs)"

sample_resp="$(run_sql "$sample_sql")"
pass "Governance sample query succeeded"
echo "$sample_resp" | jq -c '.result.data_array // []'
