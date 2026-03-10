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
SOURCE_CRM="${SOURCE_CRM:-pulse360_s4.intelligence.crm_accounts_raw}"
SOURCE_DUP="${SOURCE_DUP:-pulse360_s4.intelligence.duplicate_candidate_pairs}"
SOURCE_ENR="${SOURCE_ENR:-pulse360_s4.intelligence.firmographic_enrichment}"
SOURCE_GOV="${SOURCE_GOV:-pulse360_s4.intelligence.governance_ops_metrics}"
TARGET_TABLE="${TARGET_TABLE:-pulse360_s4.intelligence.datacloud_export_accounts}"
RUN_ID="${RUN_ID:-run_$(date -u +%Y%m%d_%H%M%S)}"
MODEL_VERSION="${MODEL_VERSION:-dbx-dc-export-v1.0.0}"

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
    fail "Databricks SQL statement failed: $stmt_id ($state)"
  fi

  echo "$response"
}

create_sql="
CREATE TABLE IF NOT EXISTS $TARGET_TABLE (
  canonical_account_id STRING,
  source_account_id STRING,
  deterministic_key STRING,
  account_name STRING,
  unified_profile_id STRING,
  identity_confidence DOUBLE,
  group_revenue_rollup DOUBLE,
  health_score DOUBLE,
  cross_sell_propensity DOUBLE,
  coverage_gap_flag BOOLEAN,
  competitor_risk_signal DOUBLE,
  primary_brand_name STRING,
  active_product_count INT,
  engagement_intensity_score DOUBLE,
  open_opportunity_count INT,
  last_engagement_timestamp TIMESTAMP,
  last_synced_timestamp TIMESTAMP,
  ingestion_metadata_label STRING,
  run_id STRING,
  run_timestamp TIMESTAMP,
  model_version STRING
)
USING DELTA
"

populate_sql="
INSERT OVERWRITE $TARGET_TABLE
WITH latest_gov AS (
  SELECT *
  FROM $SOURCE_GOV
  ORDER BY metric_ts DESC
  LIMIT 1
),
dup_by_account AS (
  SELECT
    source_account_id,
    AVG(duplicate_confidence_score) AS avg_duplicate_confidence,
    COUNT(*) AS duplicate_pair_count
  FROM (
    SELECT left_source_account_id AS source_account_id, duplicate_confidence_score FROM $SOURCE_DUP
    UNION ALL
    SELECT right_source_account_id AS source_account_id, duplicate_confidence_score FROM $SOURCE_DUP
  ) d
  GROUP BY source_account_id
),
base AS (
  SELECT
    c.source_account_id,
    c.account_name,
    regexp_replace(lower(c.account_name), '[^a-z0-9 ]', '') AS normalized_account_name,
    e.validity_score,
    e.review_flag,
    coalesce(d.avg_duplicate_confidence, 85.0) AS avg_duplicate_confidence,
    coalesce(d.duplicate_pair_count, 0) AS duplicate_pair_count,
    e.industry,
    e.country_code,
    c.ingest_ts
  FROM $SOURCE_CRM c
  LEFT JOIN $SOURCE_ENR e
    ON c.source_account_id = e.source_account_id
  LEFT JOIN dup_by_account d
    ON c.source_account_id = d.source_account_id
),
scored AS (
  SELECT
    source_account_id,
    account_name,
    normalized_account_name,
    coalesce(validity_score, 75.0) AS validity_score,
    coalesce(avg_duplicate_confidence, 85.0) AS avg_duplicate_confidence,
    duplicate_pair_count,
    coalesce(review_flag, true) AS review_flag,
    coalesce(industry, 'General Business') AS industry,
    coalesce(country_code, 'US') AS country_code,
    ingest_ts
  FROM base
)
SELECT
  concat('acc_canon_', lpad(cast(row_number() OVER (ORDER BY source_account_id) AS string), 3, '0')) AS canonical_account_id,
  source_account_id,
  sha2(concat(source_account_id, '|', normalized_account_name), 256) AS deterministic_key,
  account_name,
  concat('ucp_', source_account_id) AS unified_profile_id,
  round((avg_duplicate_confidence * 0.6) + (validity_score * 0.4), 2) AS identity_confidence,
  round(1000000 + (duplicate_pair_count * 250000), 2) AS group_revenue_rollup,
  round((avg_duplicate_confidence * 0.4) + (validity_score * 0.4) + ((100 - (CASE WHEN review_flag THEN 40 ELSE 10 END)) * 0.2), 2) AS health_score,
  round((duplicate_pair_count * 20) + (validity_score * 0.5), 2) AS cross_sell_propensity,
  review_flag AS coverage_gap_flag,
  round((CASE WHEN review_flag THEN 65 ELSE 25 END), 2) AS competitor_risk_signal,
  concat(industry, ' Core') AS primary_brand_name,
  greatest(1, duplicate_pair_count + 1) AS active_product_count,
  round((validity_score * 0.55) + (avg_duplicate_confidence * 0.45), 2) AS engagement_intensity_score,
  CASE WHEN review_flag THEN 2 ELSE 1 END AS open_opportunity_count,
  ingest_ts AS last_engagement_timestamp,
  current_timestamp() AS last_synced_timestamp,
  concat('Databricks Enrichment — Last ingested: ', date_format(current_timestamp(), 'yyyy-MM-dd HH:mm:ss'), ' UTC') AS ingestion_metadata_label,
  '$RUN_ID' AS run_id,
  current_timestamp() AS run_timestamp,
  '$MODEL_VERSION' AS model_version
FROM scored
"

summary_sql="
SELECT
  run_id,
  model_version,
  COUNT(*) AS exported_accounts,
  MAX(last_synced_timestamp) AS last_synced_timestamp
FROM $TARGET_TABLE
GROUP BY run_id, model_version
ORDER BY last_synced_timestamp DESC
LIMIT 5
"

run_sql "$create_sql" >/dev/null
pass "Ensured Data Cloud export table exists: $TARGET_TABLE"

populate_resp="$(run_sql "$populate_sql")"
populate_stmt="$(jq -r '.statement_id' <<<"$populate_resp")"
pass "Refreshed Data Cloud account export table (statement_id=$populate_stmt)"

summary_resp="$(run_sql "$summary_sql")"
summary_stmt="$(jq -r '.statement_id' <<<"$summary_resp")"
summary_rows="$(jq -r '.manifest.total_row_count // 0' <<<"$summary_resp")"
pass "Collected export summary (statement_id=$summary_stmt, rows=$summary_rows)"
echo "$summary_resp" | jq -c '.result.data_array // []'
