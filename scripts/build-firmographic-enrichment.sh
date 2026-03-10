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
SOURCE_TABLE="${SOURCE_TABLE:-pulse360_s4.intelligence.crm_accounts_raw}"
TARGET_TABLE="${TARGET_TABLE:-pulse360_s4.intelligence.firmographic_enrichment}"
COMPARISON_VIEW="${COMPARISON_VIEW:-pulse360_s4.intelligence.firmographic_candidate_comparisons}"
PAIRS_TABLE="${PAIRS_TABLE:-pulse360_s4.intelligence.duplicate_candidate_pairs}"
RUN_ID="${RUN_ID:-run_$(date -u +%Y%m%d_%H%M%S)}"
MODEL_VERSION="${MODEL_VERSION:-dbx-firmographic-v1.0.0}"

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

create_table_sql="
CREATE TABLE IF NOT EXISTS $TARGET_TABLE (
  entity_id STRING,
  source_account_id STRING,
  deterministic_key STRING,
  legal_name STRING,
  normalized_account_name STRING,
  industry STRING,
  country_code STRING,
  account_tier STRING,
  employee_band STRING,
  profile_completeness_score DOUBLE,
  source_confidence DOUBLE,
  validity_score DOUBLE,
  review_flag BOOLEAN,
  confidence_reason STRING,
  source_system STRING,
  run_id STRING,
  run_timestamp TIMESTAMP,
  model_version STRING
)
USING DELTA
"

populate_sql="
INSERT OVERWRITE $TARGET_TABLE
WITH base AS (
  SELECT
    source_account_id,
    account_name,
    source_system,
    regexp_replace(lower(account_name), '[^a-z0-9 ]', '') AS normalized_account_name,
    sha2(regexp_replace(lower(account_name), '[^a-z0-9 ]', ''), 256) AS deterministic_key,
    concat('ent_', lower(regexp_replace(account_name, '[^a-z0-9]+', '_'))) AS entity_id
  FROM $SOURCE_TABLE
),
profiled AS (
  SELECT
    entity_id,
    source_account_id,
    deterministic_key,
    account_name AS legal_name,
    normalized_account_name,
    CASE
      WHEN normalized_account_name LIKE '%securit%' THEN 'Financial Services'
      WHEN normalized_account_name LIKE '%advisor%' THEN 'Professional Services'
      WHEN normalized_account_name LIKE '%capital%' THEN 'Investment Management'
      WHEN normalized_account_name LIKE '%holding%' THEN 'Holding Company'
      ELSE 'General Business'
    END AS industry,
    CASE
      WHEN normalized_account_name LIKE '%singapore%' THEN 'SG'
      ELSE 'US'
    END AS country_code,
    CASE
      WHEN normalized_account_name LIKE '%holding%' THEN 'Enterprise'
      WHEN normalized_account_name LIKE '%capital%' THEN 'Upper Mid-Market'
      ELSE 'Mid-Market'
    END AS account_tier,
    CASE
      WHEN normalized_account_name LIKE '%holding%' THEN '500-1000'
      WHEN normalized_account_name LIKE '%capital%' THEN '200-500'
      ELSE '50-200'
    END AS employee_band,
    source_system
  FROM base
),
scored AS (
  SELECT
    *,
    (
      CASE WHEN legal_name IS NOT NULL AND legal_name <> '' THEN 25 ELSE 0 END +
      CASE WHEN industry IS NOT NULL AND industry <> '' THEN 25 ELSE 0 END +
      CASE WHEN country_code IS NOT NULL AND country_code <> '' THEN 25 ELSE 0 END +
      CASE WHEN account_tier IS NOT NULL AND account_tier <> '' THEN 25 ELSE 0 END
    ) AS profile_completeness_score,
    CASE
      WHEN source_system = 'salesforce' AND normalized_account_name LIKE '%securit%' THEN 78
      WHEN source_system = 'salesforce' THEN 90
      ELSE 82
    END AS source_confidence
  FROM profiled
)
SELECT
  entity_id,
  source_account_id,
  deterministic_key,
  legal_name,
  normalized_account_name,
  industry,
  country_code,
  account_tier,
  employee_band,
  profile_completeness_score,
  source_confidence,
  round((source_confidence * 0.6) + (profile_completeness_score * 0.4), 2) AS validity_score,
  round((source_confidence * 0.6) + (profile_completeness_score * 0.4), 2) < 90 AS review_flag,
  CASE
    WHEN round((source_confidence * 0.6) + (profile_completeness_score * 0.4), 2) >= 95 THEN 'high_source_confidence_complete_profile'
    WHEN round((source_confidence * 0.6) + (profile_completeness_score * 0.4), 2) >= 90 THEN 'good_source_confidence_profile_ok'
    ELSE 'needs_manual_review_low_validity'
  END AS confidence_reason,
  source_system,
  '$RUN_ID' AS run_id,
  current_timestamp() AS run_timestamp,
  '$MODEL_VERSION' AS model_version
FROM scored
"

create_view_sql="
CREATE OR REPLACE VIEW $COMPARISON_VIEW AS
SELECT
  d.pair_id,
  d.left_source_account_id,
  d.right_source_account_id,
  d.duplicate_confidence_score,
  d.confidence_band,
  left_enr.legal_name AS left_legal_name,
  right_enr.legal_name AS right_legal_name,
  left_enr.industry AS left_industry,
  right_enr.industry AS right_industry,
  left_enr.country_code AS left_country_code,
  right_enr.country_code AS right_country_code,
  left_enr.validity_score AS left_validity_score,
  right_enr.validity_score AS right_validity_score,
  abs(left_enr.validity_score - right_enr.validity_score) AS validity_score_delta,
  left_enr.review_flag OR right_enr.review_flag AS needs_governance_review,
  d.run_id,
  d.run_timestamp,
  d.model_version
FROM $PAIRS_TABLE d
LEFT JOIN $TARGET_TABLE left_enr
  ON d.left_source_account_id = left_enr.source_account_id
LEFT JOIN $TARGET_TABLE right_enr
  ON d.right_source_account_id = right_enr.source_account_id
"

summary_sql="
SELECT
  run_id,
  model_version,
  COUNT(*) AS enrichment_rows,
  AVG(validity_score) AS avg_validity_score,
  SUM(CASE WHEN review_flag THEN 1 ELSE 0 END) AS review_rows
FROM $TARGET_TABLE
GROUP BY run_id, model_version
ORDER BY enrichment_rows DESC
LIMIT 5
"

comparison_count_sql="
SELECT COUNT(*) AS comparison_rows
FROM $COMPARISON_VIEW
"

run_sql "$create_table_sql" >/dev/null
pass "Ensured enrichment table exists: $TARGET_TABLE"

populate_resp="$(run_sql "$populate_sql")"
populate_stmt="$(jq -r '.statement_id' <<<"$populate_resp")"
pass "Refreshed firmographic enrichment output (statement_id=$populate_stmt)"

view_resp="$(run_sql "$create_view_sql")"
view_stmt="$(jq -r '.statement_id' <<<"$view_resp")"
pass "Created/updated governance comparison view (statement_id=$view_stmt)"

summary_resp="$(run_sql "$summary_sql")"
summary_stmt="$(jq -r '.statement_id' <<<"$summary_resp")"
summary_rows="$(jq -r '.manifest.total_row_count // 0' <<<"$summary_resp")"
pass "Collected enrichment summary (statement_id=$summary_stmt, rows=$summary_rows)"
echo "$summary_resp" | jq -c '.result.data_array // []'

comparison_resp="$(run_sql "$comparison_count_sql")"
comparison_stmt="$(jq -r '.statement_id' <<<"$comparison_resp")"
comparison_rows="$(jq -r '.result.data_array[0][0] // "0"' <<<"$comparison_resp")"
pass "Comparison view row count captured (statement_id=$comparison_stmt, rows=$comparison_rows)"
