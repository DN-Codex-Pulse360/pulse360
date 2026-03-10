#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

ORG_ALIAS="${ORG_ALIAS:-pulse360-dev}"
REQUIRED_LWC_BUNDLES="${REQUIRED_LWC_BUNDLES:-pulse360GovernanceCase,pulse360Account360,pulse360HealthScan,pulse360CrossSellBanner}"
REQUIRED_RECORD_PAGES="${REQUIRED_RECORD_PAGES:-Pulse360_Account_Record_Page}"
REQUIRED_ACCOUNT_ACTIONS="${REQUIRED_ACCOUNT_ACTIONS:-Pulse360_QuickCreateOpportunity,Pulse360_HealthScanAction}"

command -v sf >/dev/null 2>&1 || fail "Salesforce CLI (sf) is not installed"

org_resp="$(sf org display -o "$ORG_ALIAS" --json)"
org_status="$(jq -r '.status' <<<"$org_resp")"
[[ "$org_status" == "0" ]] || fail "Unable to access Salesforce org alias: $ORG_ALIAS"
instance_url="$(jq -r '.result.instanceUrl // "unknown"' <<<"$org_resp")"
pass "Connected to Salesforce org alias=$ORG_ALIAS instance=$instance_url"

query_tooling() {
  local sql="$1"
  sf data query --use-tooling-api -o "$ORG_ALIAS" --query "$sql" --json
}

query_core() {
  local sql="$1"
  sf data query -o "$ORG_ALIAS" --query "$sql" --json
}

lwc_resp="$(query_tooling "SELECT DeveloperName FROM LightningComponentBundle")"
lwc_names="$(jq -r '.result.records[]?.DeveloperName // empty' <<<"$lwc_resp")"

record_page_resp="$(query_tooling "SELECT DeveloperName FROM FlexiPage WHERE Type = 'RecordPage'")"
record_page_names="$(jq -r '.result.records[]?.DeveloperName // empty' <<<"$record_page_resp")"

actions_resp="$(query_core "SELECT ApiName FROM PlatformAction WHERE ActionListContext IN ('Record','RecordDetail') AND SourceEntity='Account'")"
action_names="$(jq -r '.result.records[]?.ApiName // empty' <<<"$actions_resp")"
weblink_resp="$(query_tooling "SELECT Name FROM WebLink WHERE Name LIKE 'Pulse360_%'")"
weblink_names="$(jq -r '.result.records[]?.Name // empty' <<<"$weblink_resp")"

missing=0

IFS=',' read -r -a required_lwcs <<<"$REQUIRED_LWC_BUNDLES"
for name in "${required_lwcs[@]}"; do
  name="$(echo "$name" | xargs)"
  [[ -n "$name" ]] || continue
  grep -Fxq "$name" <<<"$lwc_names" || { echo "[MISSING] LWC bundle: $name"; missing=1; }
done

IFS=',' read -r -a required_pages <<<"$REQUIRED_RECORD_PAGES"
for name in "${required_pages[@]}"; do
  name="$(echo "$name" | xargs)"
  [[ -n "$name" ]] || continue
  grep -Fxq "$name" <<<"$record_page_names" || { echo "[MISSING] Record page: $name"; missing=1; }
done

IFS=',' read -r -a required_actions <<<"$REQUIRED_ACCOUNT_ACTIONS"
for name in "${required_actions[@]}"; do
  name="$(echo "$name" | xargs)"
  [[ -n "$name" ]] || continue
  # PlatformAction API names may be org/global-prefixed (e.g., Global.Name).
  if ! grep -Fxq "$name" <<<"$action_names" \
    && ! grep -Fxq "Global.$name" <<<"$action_names" \
    && ! grep -Fxq "$name" <<<"$weblink_names"; then
    echo "[MISSING] Account action: $name"
    missing=1
  fi
done

[[ "$missing" -eq 0 ]] || fail "Salesforce deployment runtime validation failed (missing required metadata)"

pass "Salesforce deployment runtime validation passed"
