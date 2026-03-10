#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

HOST="${DATABRICKS_HOST:-$(awk -F' *= *' '/^host/{print $2; exit}' ~/.databrickscfg 2>/dev/null)}"
TOKEN="${DATABRICKS_TOKEN:-$(awk -F' *= *' '/^token/{print $2; exit}' ~/.databrickscfg 2>/dev/null)}"
DASHBOARD_IDS="${DASHBOARD_IDS:-01f11b56ed40102ea9232dfb2404fb1b,01f11b5709051df5a21ba10e55942421}"
MIN_DATASETS="${MIN_DATASETS:-7}"
MIN_WIDGETS="${MIN_WIDGETS:-7}"
MIN_NON_TABLE_WIDGETS="${MIN_NON_TABLE_WIDGETS:-1}"
REQUIRED_TITLES="${REQUIRED_TITLES:-DS-01,DS-02,DS-03,Freshness,KPI}"

[[ -n "$HOST" ]] || fail "Databricks host is not configured"
[[ -n "$TOKEN" ]] || fail "Databricks token is not configured"

IFS=',' read -r -a ids <<<"$DASHBOARD_IDS"
[[ "${#ids[@]}" -gt 0 ]] || fail "No dashboard IDs provided"

api_get() {
  local path="$1"
  curl -sS -H "Authorization: Bearer $TOKEN" "$HOST$path"
}

for id in "${ids[@]}"; do
  id="$(echo "$id" | xargs)"
  [[ -n "$id" ]] || continue

  resp="$(api_get "/api/2.0/lakeview/dashboards/$id")"
  display_name="$(jq -r '.display_name // "unknown"' <<<"$resp")"
  lifecycle_state="$(jq -r '.lifecycle_state // "UNKNOWN"' <<<"$resp")"
  serialized="$(jq -r '.serialized_dashboard // ""' <<<"$resp")"
  [[ -n "$serialized" ]] || fail "Dashboard $id has empty serialized_dashboard"

  datasets_count="$(jq -r '.datasets | length' <<<"$serialized")"
  pages_count="$(jq -r '.pages | length' <<<"$serialized")"
  widgets_count="$(jq -r '[.pages[]?.layout[]?.widget] | length' <<<"$serialized")"
  non_table_count="$(jq -r '[.pages[]?.layout[]?.widget?.spec?.widgetType // empty | select(. != "table")] | length' <<<"$serialized")"

  [[ "$lifecycle_state" == "ACTIVE" ]] || fail "Dashboard $id is not ACTIVE (state=$lifecycle_state)"
  [[ "$datasets_count" -ge "$MIN_DATASETS" ]] || fail "Dashboard $id has too few datasets ($datasets_count < $MIN_DATASETS)"
  [[ "$pages_count" -ge 1 ]] || fail "Dashboard $id has no pages"
  [[ "$widgets_count" -ge "$MIN_WIDGETS" ]] || fail "Dashboard $id has too few widgets ($widgets_count < $MIN_WIDGETS)"
  [[ "$non_table_count" -ge "$MIN_NON_TABLE_WIDGETS" ]] || fail "Dashboard $id has no finalized visual widgets (non-table widgets=$non_table_count, required>=$MIN_NON_TABLE_WIDGETS)"

  IFS=',' read -r -a title_tokens <<<"$REQUIRED_TITLES"
  titles_text="$(jq -r '[.pages[]?.layout[]?.widget?.spec?.frame?.title // empty] | join(\" \")' <<<"$serialized")"
  for token in "${title_tokens[@]}"; do
    token="$(echo "$token" | xargs)"
    [[ -n "$token" ]] || continue
    grep -Fqi "$token" <<<"$titles_text" || fail "Dashboard $id missing expected titled panel token: $token"
  done

  pass "Dashboard visuals validated: $id ($display_name), datasets=$datasets_count, widgets=$widgets_count, non_table_widgets=$non_table_count"
done

pass "Databricks dashboard visual validation passed"
