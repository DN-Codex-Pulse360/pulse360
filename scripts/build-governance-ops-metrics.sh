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
COMPARISON_VIEW="${COMPARISON_VIEW:-pulse360_s4.intelligence.firmographic_candidate_comparisons}"
TARGET_TABLE="${TARGET_TABLE:-pulse360_s4.intelligence.governance_ops_metrics}"
RUN_ID="${RUN_ID:-run_$(date -u +%Y%m%d_%H%M%S)}"
MODEL_VERSION="${MODEL_VERSION:-dbx-governance-v1.0.0}"

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
  run_id STRING,
  metric_ts TIMESTAMP,
  cases_opened INT,
  cases_resolved INT,
  backlog_open INT,
  avg_resolution_minutes DOUBLE,
  quality_score DOUBLE,
  merge_approval_rate DOUBLE,
  model_version STRING
)
USING DELTA
"

populate_sql="
INSERT OVERWRITE $TARGET_TABLE
WITH candidate_cases AS (
  SELECT
    left_source_account_id,
    right_source_account_id,
    duplicate_confidence_score,
    left_validity_score,
    right_validity_score,
    needs_governance_review,
    run_id
  FROM $COMPARISON_VIEW
),
scored AS (
  SELECT
    run_id,
    COUNT(*) AS cases_opened,
    SUM(CASE WHEN needs_governance_review THEN 0 ELSE 1 END) AS cases_resolved,
    SUM(CASE WHEN needs_governance_review THEN 1 ELSE 0 END) AS backlog_open,
    AVG(CASE WHEN needs_governance_review THEN 45.0 ELSE 12.0 END) AS avg_resolution_minutes,
    AVG(
      ((coalesce(left_validity_score, 0) + coalesce(right_validity_score, 0)) / 2.0) * 0.55 +
      coalesce(duplicate_confidence_score, 0) * 0.45
    ) AS quality_score
  FROM candidate_cases
  GROUP BY run_id
)
SELECT
  coalesce(run_id, '$RUN_ID') AS run_id,
  current_timestamp() AS metric_ts,
  CAST(coalesce(cases_opened, 0) AS INT) AS cases_opened,
  CAST(coalesce(cases_resolved, 0) AS INT) AS cases_resolved,
  CAST(coalesce(backlog_open, 0) AS INT) AS backlog_open,
  round(coalesce(avg_resolution_minutes, 0), 2) AS avg_resolution_minutes,
  round(coalesce(quality_score, 0), 2) AS quality_score,
  round((coalesce(cases_resolved, 0) / nullif(coalesce(cases_opened, 0), 0)) * 100, 2) AS merge_approval_rate,
  '$MODEL_VERSION' AS model_version
FROM scored
"

summary_sql="
SELECT
  run_id,
  metric_ts,
  cases_opened,
  cases_resolved,
  backlog_open,
  avg_resolution_minutes,
  quality_score,
  merge_approval_rate,
  model_version
FROM $TARGET_TABLE
ORDER BY metric_ts DESC
LIMIT 5
"

run_sql "$create_sql" >/dev/null
pass "Ensured governance metrics table exists: $TARGET_TABLE"

populate_resp="$(run_sql "$populate_sql")"
populate_stmt="$(jq -r '.statement_id' <<<"$populate_resp")"
pass "Refreshed governance ops metrics (statement_id=$populate_stmt)"

summary_resp="$(run_sql "$summary_sql")"
summary_stmt="$(jq -r '.statement_id' <<<"$summary_resp")"
summary_rows="$(jq -r '.manifest.total_row_count // 0' <<<"$summary_resp")"
pass "Collected governance summary (statement_id=$summary_stmt, rows=$summary_rows)"
echo "$summary_resp" | jq -c '.result.data_array // []'
