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
TARGET_TABLE="${TARGET_TABLE:-pulse360_s4.intelligence.firmographic_enrichment}"
COMPARISON_VIEW="${COMPARISON_VIEW:-pulse360_s4.intelligence.firmographic_candidate_comparisons}"

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
  AND table_name = 'firmographic_enrichment'
"

quality_sql="
SELECT
  COUNT(*) AS enrichment_rows,
  SUM(CASE WHEN legal_name IS NULL OR legal_name = '' THEN 1 ELSE 0 END) AS missing_legal_name_rows,
  SUM(CASE WHEN industry IS NULL OR industry = '' THEN 1 ELSE 0 END) AS missing_industry_rows,
  SUM(CASE WHEN country_code IS NULL OR country_code = '' THEN 1 ELSE 0 END) AS missing_country_rows,
  SUM(CASE WHEN source_confidence IS NULL THEN 1 ELSE 0 END) AS missing_source_confidence_rows,
  SUM(CASE WHEN confidence_reason IS NULL OR confidence_reason = '' THEN 1 ELSE 0 END) AS missing_confidence_reason_rows,
  SUM(CASE WHEN validity_score < 0 OR validity_score > 100 THEN 1 ELSE 0 END) AS invalid_validity_rows,
  SUM(CASE WHEN validity_score < 90 AND review_flag = false THEN 1 ELSE 0 END) AS low_confidence_not_flagged_rows
FROM $TARGET_TABLE
"

metadata_sql="
SELECT
  SUM(CASE WHEN run_id IS NULL OR run_id = '' THEN 1 ELSE 0 END) AS missing_run_id_rows,
  SUM(CASE WHEN run_timestamp IS NULL THEN 1 ELSE 0 END) AS missing_run_timestamp_rows,
  SUM(CASE WHEN model_version IS NULL OR model_version = '' THEN 1 ELSE 0 END) AS missing_model_version_rows
FROM $TARGET_TABLE
"

comparison_sql="
SELECT COUNT(*) AS comparison_rows
FROM $COMPARISON_VIEW
"

distribution_sql="
SELECT review_flag, COUNT(*) AS row_count, AVG(validity_score) AS avg_validity
FROM $TARGET_TABLE
GROUP BY review_flag
ORDER BY review_flag DESC
"

existence_resp="$(run_sql "$existence_sql")"
exists_count="$(jq -r '.result.data_array[0][0] // "0"' <<<"$existence_resp")"
[[ "$exists_count" != "0" ]] || fail "Table does not exist: $TARGET_TABLE"
pass "Table exists: $TARGET_TABLE"

quality_resp="$(run_sql "$quality_sql")"
rows="$(jq -r '.result.data_array[0][0] // "0"' <<<"$quality_resp")"
missing_legal="$(jq -r '.result.data_array[0][1] // "0"' <<<"$quality_resp")"
missing_industry="$(jq -r '.result.data_array[0][2] // "0"' <<<"$quality_resp")"
missing_country="$(jq -r '.result.data_array[0][3] // "0"' <<<"$quality_resp")"
missing_src_conf="$(jq -r '.result.data_array[0][4] // "0"' <<<"$quality_resp")"
missing_reason="$(jq -r '.result.data_array[0][5] // "0"' <<<"$quality_resp")"
invalid_validity="$(jq -r '.result.data_array[0][6] // "0"' <<<"$quality_resp")"
low_conf_not_flagged="$(jq -r '.result.data_array[0][7] // "0"' <<<"$quality_resp")"

[[ "$rows" != "0" ]] || fail "No firmographic enrichment rows generated"
[[ "$missing_legal" == "0" ]] || fail "Missing legal_name values found"
[[ "$missing_industry" == "0" ]] || fail "Missing industry values found"
[[ "$missing_country" == "0" ]] || fail "Missing country_code values found"
[[ "$missing_src_conf" == "0" ]] || fail "Missing source_confidence values found"
[[ "$missing_reason" == "0" ]] || fail "Missing confidence_reason values found"
[[ "$invalid_validity" == "0" ]] || fail "Found validity_score outside 0-100"
[[ "$low_conf_not_flagged" == "0" ]] || fail "Found low-confidence rows not flagged for review"
pass "Enrichment quality checks passed (rows=$rows)"

metadata_resp="$(run_sql "$metadata_sql")"
missing_run_id="$(jq -r '.result.data_array[0][0] // "0"' <<<"$metadata_resp")"
missing_run_ts="$(jq -r '.result.data_array[0][1] // "0"' <<<"$metadata_resp")"
missing_model="$(jq -r '.result.data_array[0][2] // "0"' <<<"$metadata_resp")"
[[ "$missing_run_id" == "0" ]] || fail "Missing run_id values found"
[[ "$missing_run_ts" == "0" ]] || fail "Missing run_timestamp values found"
[[ "$missing_model" == "0" ]] || fail "Missing model_version values found"
pass "Run metadata checks passed"

comparison_resp="$(run_sql "$comparison_sql")"
comparison_rows="$(jq -r '.result.data_array[0][0] // "0"' <<<"$comparison_resp")"
[[ "$comparison_rows" != "0" ]] || fail "Comparison view has no rows"
pass "Governance comparison view populated (rows=$comparison_rows)"

distribution_resp="$(run_sql "$distribution_sql")"
pass "Review-flag distribution query succeeded"
echo "$distribution_resp" | jq -c '.result.data_array // []'
