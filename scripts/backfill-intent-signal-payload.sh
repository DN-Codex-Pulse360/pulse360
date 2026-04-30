#!/usr/bin/env bash
set -euo pipefail

TARGET_ORG="${TARGET_ORG:-pulse360-dev}"
SF_BIN="${SF_BIN:-sf}"
API_VERSION="${API_VERSION:-66.0}"

org_display_json="$("$SF_BIN" org display --target-org "$TARGET_ORG" --verbose --json)"
INSTANCE_URL="$(jq -r '.result.instanceUrl' <<<"$org_display_json")"
ACCESS_TOKEN="$(jq -r '.result.accessToken' <<<"$org_display_json")"

query_account_id() {
  local account_name="$1"
  "$SF_BIN" data query --target-org "$TARGET_ORG" \
    --query "SELECT Id FROM Account WHERE Name = '$account_name' LIMIT 1" \
    --json | jq -r '.result.records[0].Id // empty'
}

patch_sobject() {
  local sobject="$1"
  local record_id="$2"
  local payload="$3"
  local status_code

  status_code="$(curl -sS \
    -o /tmp/pulse360_signal_patch_response.json \
    -w "%{http_code}" \
    -X PATCH \
    "$INSTANCE_URL/services/data/v$API_VERSION/sobjects/$sobject/$record_id" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$payload")"

  if [[ "$status_code" != "204" ]]; then
    cat /tmp/pulse360_signal_patch_response.json >&2
    return 1
  fi
}

update_intent_signal_payload() {
  local account_name="$1"
  local signal_payload="$2"
  local account_id

  account_id="$(query_account_id "$account_name")"
  if [[ -z "$account_id" ]]; then
    echo "[WARN] Skipping missing account: $account_name"
    return 0
  fi

  local payload
  payload="$(jq -n --arg signalPayload "$signal_payload" '{Intent_Signal_Payload__c: $signalPayload}')"
  patch_sobject "Account" "$account_id" "$payload"
  echo "[OK] Updated intent signal payload for $account_name ($account_id)"
}

singtel_signal='{"routing_version":"pulse360-intent-routing-v1","signal_score":75,"signal_label":"Coverage-led review","threshold_label":"Coverage gaps and commercial potential crossed the routed-review threshold.","route_to":"account_owner_plus_coverage","routing_confidence":0.91,"why_now":"Singtel combines whitespace potential with a group coverage gap, so the routed follow-up should confirm who actually owns the next motion.","drafted_outreach":"Pulse360 flagged Singtel Group because coverage is incomplete across the commercial group and the next owner needs to be confirmed. Lead with Singtel and validate the next sponsor path.","channel_readiness":"salesforce_preview","top_drivers":["Whitespace readiness is elevated.","Engagement context suggests the account can absorb routed follow-up now.","Coverage is incomplete across the group, so route clarity needs review."],"generated_at":"2026-03-28T09:00:00Z"}'

ncs_signal='{"routing_version":"pulse360-intent-routing-v1","signal_score":68,"signal_label":"Queue for review","threshold_label":"The account has enough context to justify a routed review instead of another manual pass.","route_to":"account_owner","routing_confidence":0.83,"why_now":"NCS is already a CRM-covered delivery subsidiary, so the routed follow-up should turn current AI modernization relevance into a direct seller motion.","drafted_outreach":"Pulse360 flagged NCS Pte. Ltd. because existing delivery coverage and current AI modernization context justify a targeted follow-up. Lead with the data and AI modernization play and confirm the sponsor path.","channel_readiness":"salesforce_preview","top_drivers":["Commercial room exists and is already tied to a CRM-covered entity.","Engagement context suggests the account can absorb routed follow-up now.","Coverage is stable enough for a directed follow-up."],"generated_at":"2026-03-28T09:00:00Z"}'

ayala_signal='{"routing_version":"pulse360-intent-routing-v1","signal_score":81,"signal_label":"Route now","threshold_label":"Whitespace and engagement crossed the route-now threshold.","route_to":"account_owner_plus_coverage","routing_confidence":0.88,"why_now":"Ayala has enough commercial room, engagement, and coverage complexity to justify an immediate routed follow-up.","drafted_outreach":"Pulse360 flagged Ayala Corporation because the wider group opportunity is larger than the current CRM footprint. Lead with group coverage validation and confirm the next sponsor path.","channel_readiness":"salesforce_preview","top_drivers":["Whitespace readiness is elevated.","Engagement context suggests the account can absorb routed follow-up now.","Coverage is incomplete across the group, so route clarity needs review."],"generated_at":"2026-03-28T09:00:00Z"}'

ayala_duplicate_signal='{"routing_version":"pulse360-intent-routing-v1","signal_score":72,"signal_label":"Coverage-led review","threshold_label":"Coverage gaps and duplicate-account ambiguity crossed the routed-review threshold.","route_to":"account_owner_plus_coverage","routing_confidence":0.84,"why_now":"Ayala Corp. is a duplicate CRM variant inside the same commercial group, so any routed follow-up should confirm ownership and duplicate resolution first.","drafted_outreach":"Pulse360 flagged Ayala Corp. because duplicate-account ambiguity can weaken the next seller motion. Lead with ownership confirmation and duplicate-resolution context before outreach.","channel_readiness":"salesforce_preview","top_drivers":["Commercial room exists but is split across duplicate account variants.","Engagement context is usable, but ownership clarity still matters.","Coverage is incomplete across the group, so route clarity needs review."],"generated_at":"2026-03-28T09:00:00Z"}'

jgs_signal='{"routing_version":"pulse360-intent-routing-v1","signal_score":70,"signal_label":"Queue for review","threshold_label":"The account has enough context to justify a routed review instead of another manual pass.","route_to":"account_owner_plus_coverage","routing_confidence":0.84,"why_now":"JG Summit has enough engagement and whitespace context to justify a routed review before another manual portfolio pass.","drafted_outreach":"Pulse360 flagged JG Summit Holdings, Inc. because digital and ecosystem growth signals justify a targeted follow-up. Lead with the most credible group play and confirm the next sponsor conversation.","channel_readiness":"salesforce_preview","top_drivers":["Commercial room exists but still needs qualification.","Engagement context suggests the account can absorb routed follow-up now.","Coverage is incomplete across the group, so route clarity needs review."],"generated_at":"2026-03-28T09:00:00Z"}'

update_intent_signal_payload "Singtel Group" "$singtel_signal"
update_intent_signal_payload "NCS Pte. Ltd." "$ncs_signal"
update_intent_signal_payload "Ayala Corporation" "$ayala_signal"
update_intent_signal_payload "Ayala Corp." "$ayala_duplicate_signal"
update_intent_signal_payload "JG Summit Holdings, Inc." "$jgs_signal"
