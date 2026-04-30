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
    -o /tmp/pulse360_patch_response.json \
    -w "%{http_code}" \
    -X PATCH \
    "$INSTANCE_URL/services/data/v$API_VERSION/sobjects/$sobject/$record_id" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$payload")"

  if [[ "$status_code" != "204" ]]; then
    cat /tmp/pulse360_patch_response.json >&2
    return 1
  fi
}

update_hierarchy_payload() {
  local account_name="$1"
  local hierarchy_payload="$2"
  local account_id

  account_id="$(query_account_id "$account_name")"
  if [[ -z "$account_id" ]]; then
    echo "[WARN] Skipping missing account: $account_name"
    return 0
  fi

  local payload
  payload="$(jq -n --arg hierarchy "$hierarchy_payload" '{Hierarchy_Payload__c: $hierarchy}')"
  patch_sobject "Account" "$account_id" "$payload"
  echo "[OK] Updated hierarchy payload for $account_name ($account_id)"
}

singtel_hierarchy='{"group_id":"grp_singtel","parent_account_id":null,"canonical_account_id":"ent_sg_001","account_name":"Singtel Group","children":[{"entity_id":"ent_sg_001","name":"Singtel Group","role":"Current account anchor","coverage_status":"covered","in_crm":true,"signal":"Core Singtel coverage exists in CRM, but the operating group is only partially represented."},{"entity_id":"ent_sg_002","name":"NCS Pte. Ltd.","role":"CRM-covered delivery subsidiary","coverage_status":"covered","in_crm":true,"signal":"NCS is already represented in CRM and is the clearest data and AI expansion path.","suggested_play":"Data and AI modernization"},{"entity_id":"ent_sg_003","name":"Optus","role":"Whitespace growth entity","coverage_status":"uncovered","in_crm":false,"signal":"Public disclosures position Optus as a growth engine, but the seller cannot work it directly from CRM yet.","suggested_play":"Group coverage follow-up"}]}'
ayala_hierarchy='{"group_id":"grp_ayala","parent_account_id":null,"canonical_account_id":"ent_ph_001","account_name":"Ayala Corporation","children":[{"entity_id":"ent_ph_001","name":"Ayala Corporation","role":"Current account anchor","coverage_status":"covered","in_crm":true,"signal":"This anchor account is in CRM, but the wider Ayala operating footprint is not fully action-ready."},{"entity_id":"ent_ph_001_dup","name":"Ayala Corp.","role":"Duplicate CRM variant","coverage_status":"duplicate","in_crm":true,"signal":"A second CRM variant exists for the same commercial group, which can dilute seller trust and ownership clarity.","suggested_play":"Resolve duplicate ownership"},{"entity_id":"ent_ph_003","name":"ACMobility","role":"Mobility whitespace entity","coverage_status":"uncovered","in_crm":false,"signal":"Ayala portfolio disclosures point to mobility expansion that is not represented as a seller-ready entity in CRM.","suggested_play":"Mobility data platform whitespace"},{"entity_id":"ent_ph_004","name":"AC Logistics","role":"Logistics whitespace entity","coverage_status":"uncovered","in_crm":false,"signal":"Public portfolio evidence shows logistics expansion that is still absent from the current CRM coverage map.","suggested_play":"Logistics planning and visibility review"}]}'
jgs_hierarchy='{"group_id":"grp_jgs","parent_account_id":null,"canonical_account_id":"ent_ph_002","account_name":"JG Summit Holdings, Inc.","children":[{"entity_id":"ent_ph_002","name":"JG Summit Holdings, Inc.","role":"Current account anchor","coverage_status":"covered","in_crm":true,"signal":"The parent account is in CRM, but most of the commercial group is still outside the seller operating surface."},{"entity_id":"ent_ph_003","name":"Cebu Pacific","role":"Travel and loyalty whitespace entity","coverage_status":"uncovered","in_crm":false,"signal":"Travel and ecosystem signals create room for loyalty, customer data, and digital engagement plays.","suggested_play":"Customer data and loyalty modernization"},{"entity_id":"ent_ph_004","name":"Universal Robina Corporation","role":"Consumer analytics whitespace entity","coverage_status":"uncovered","in_crm":false,"signal":"Consumer-scale group operations suggest an unmet analytics and planning opportunity outside the current CRM footprint.","suggested_play":"Consumer demand and retail analytics"},{"entity_id":"ent_ph_005","name":"GoTyme Bank","role":"Digital banking whitespace entity","coverage_status":"uncovered","in_crm":false,"signal":"Annual report evidence ties the group to digital banking and rewards momentum, making GoTyme the clearest next commercial move.","suggested_play":"Rewards analytics and digital banking growth"}]}'

update_hierarchy_payload "Singtel Group" "$singtel_hierarchy"
update_hierarchy_payload "Ayala Corporation" "$ayala_hierarchy"
update_hierarchy_payload "Ayala Corp." "$ayala_hierarchy"
update_hierarchy_payload "JG Summit Holdings, Inc." "$jgs_hierarchy"

singtel_id="$(query_account_id "Singtel Group")"
ncs_id="$(query_account_id "NCS Pte. Ltd.")"
if [[ -n "$singtel_id" && -n "$ncs_id" ]]; then
  patch_sobject "Account" "$ncs_id" "$(jq -n --arg parentId "$singtel_id" '{ParentId: $parentId}')"
  echo "[OK] Linked NCS Pte. Ltd. to Singtel Group in CRM hierarchy"
fi
