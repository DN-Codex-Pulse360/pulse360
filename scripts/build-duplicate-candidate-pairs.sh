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
SOURCE_TABLE="${SOURCE_TABLE:-pulse360_s4.intelligence.crm_accounts_raw}"
RUN_ID="${RUN_ID:-run_$(date -u +%Y%m%d_%H%M%S)}"
MODEL_VERSION="${MODEL_VERSION:-dbx-duplicate-v1.0.0}"

[[ -n "$HOST" ]] || fail "Databricks host is not configured"
[[ -n "$TOKEN" ]] || fail "Databricks token is not configured"
[[ -n "$WAREHOUSE_ID" ]] || fail "Databricks warehouse ID is not configured"

run_sql() {
  local sql="$1"
  local payload
  local response
  local state
  local stmt_id

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
  if [[ "$state" != "SUCCEEDED" ]]; then
    echo "$response" | jq .
    fail "Databricks SQL statement failed: $stmt_id ($state)"
  fi

  echo "$response"
}

create_sql="
CREATE TABLE IF NOT EXISTS $TARGET_TABLE (
  pair_id STRING,
  left_source_account_id STRING,
  right_source_account_id STRING,
  left_account_name STRING,
  right_account_name STRING,
  left_source_system STRING,
  right_source_system STRING,
  duplicate_confidence_score INT,
  confidence_band STRING,
  score_reason STRING,
  run_id STRING,
  run_timestamp TIMESTAMP,
  model_version STRING
)
USING DELTA
"

insert_sql="
INSERT OVERWRITE $TARGET_TABLE
WITH account_features AS (
  SELECT
    source_account_id,
    account_name,
    source_system,
    ingest_ts,
    regexp_replace(lower(account_name), '[^a-z0-9 ]', '') AS account_name_key,
    lower(regexp_extract(account_name, '^([A-Za-z0-9]+)', 1)) AS family_key
  FROM $SOURCE_TABLE
),
pair_candidates AS (
  SELECT
    a.source_account_id AS left_source_account_id,
    b.source_account_id AS right_source_account_id,
    a.account_name AS left_account_name,
    b.account_name AS right_account_name,
    a.source_system AS left_source_system,
    b.source_system AS right_source_system,
    CASE
      WHEN a.account_name_key = b.account_name_key THEN 98
      WHEN a.family_key = b.family_key AND a.source_system = b.source_system THEN 92
      WHEN a.family_key = b.family_key THEN 86
      ELSE 78
    END AS duplicate_confidence_score,
    CASE
      WHEN a.account_name_key = b.account_name_key THEN 'exact_normalized_name_match'
      WHEN a.family_key = b.family_key AND a.source_system = b.source_system THEN 'family_name_match_same_source'
      WHEN a.family_key = b.family_key THEN 'family_name_match_cross_source'
      ELSE 'weak_name_signal'
    END AS score_reason
  FROM account_features a
  JOIN account_features b
    ON a.source_account_id < b.source_account_id
   AND a.family_key IS NOT NULL
   AND b.family_key IS NOT NULL
   AND a.family_key <> ''
   AND a.family_key = b.family_key
)
SELECT
  sha2(concat(left_source_account_id, '|', right_source_account_id), 256) AS pair_id,
  left_source_account_id,
  right_source_account_id,
  left_account_name,
  right_account_name,
  left_source_system,
  right_source_system,
  duplicate_confidence_score,
  CASE
    WHEN duplicate_confidence_score >= 95 THEN '95-100'
    WHEN duplicate_confidence_score >= 90 THEN '90-94'
    WHEN duplicate_confidence_score >= 80 THEN '80-89'
    ELSE '<80'
  END AS confidence_band,
  score_reason,
  '$RUN_ID' AS run_id,
  current_timestamp() AS run_timestamp,
  '$MODEL_VERSION' AS model_version
FROM pair_candidates
"

count_sql="
SELECT
  run_id,
  model_version,
  COUNT(*) AS pair_count,
  AVG(duplicate_confidence_score) AS avg_duplicate_confidence
FROM $TARGET_TABLE
GROUP BY run_id, model_version
ORDER BY pair_count DESC
LIMIT 5
"

run_sql "$create_sql" >/dev/null
pass "Ensured target table exists: $TARGET_TABLE"

count_response="$(run_sql "$insert_sql")"
insert_stmt="$(jq -r '.statement_id' <<<"$count_response")"
pass "Refreshed duplicate candidate pairs (statement_id=$insert_stmt)"

summary_response="$(run_sql "$count_sql")"
summary_stmt="$(jq -r '.statement_id' <<<"$summary_response")"
summary_rows="$(jq -r '.manifest.total_row_count // 0' <<<"$summary_response")"
pass "Collected duplicate run summary (statement_id=$summary_stmt, rows=$summary_rows)"

echo "$summary_response" | jq -c '.result.data_array // []'
