#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }
warn() { echo "[WARN] $1"; }

search_fixed() {
  local needle="$1"
  shift

  if command -v rg >/dev/null 2>&1; then
    rg -Fq "$needle" "$@"
  else
    grep -Fq -- "$needle" "$@"
  fi
}

service="force-app/main/default/classes/Pulse360SignalRoutingWorkspaceService.cls"
test_class="force-app/main/default/classes/Pulse360SignalRoutingServiceTest.cls"
lwc_dir="force-app/main/default/lwc/pulse360SignalRoutingWorkspace"
tab_file="force-app/main/default/tabs/Pulse360_Signal_Routing.tab-meta.xml"
field_file="force-app/main/default/objects/Account/fields/Intent_Signal_Payload__c.field-meta.xml"
permset="force-app/main/default/permissionsets/Pulse360_Account_Intelligence_User.permissionset-meta.xml"
activation_mapping="config/data-cloud/activation-field-mapping.csv"
account_contract="contracts/datacloud_to_salesforce_agentforce.schema.json"
handoff_contract="contracts/databricks_to_datacloud.schema.json"

[[ -f "$service" ]] || fail "Missing Pulse360SignalRoutingWorkspaceService Apex class"
[[ -f "$test_class" ]] || fail "Missing Pulse360SignalRoutingServiceTest Apex test"
[[ -d "$lwc_dir" ]] || fail "Missing pulse360SignalRoutingWorkspace LWC"
[[ -f "$tab_file" ]] || fail "Missing Pulse360_Signal_Routing tab metadata"
[[ -f "$field_file" ]] || fail "Missing Intent_Signal_Payload__c field metadata"
[[ -f "$permset" ]] || fail "Missing Pulse360 account intelligence permission set"
[[ -f "$activation_mapping" ]] || fail "Missing activation field mapping"
[[ -f "$account_contract" ]] || fail "Missing Data Cloud to Salesforce contract schema"
[[ -f "$handoff_contract" ]] || fail "Missing Databricks to Data Cloud contract schema"

search_fixed "intent_signal_payload,Account,Intent_Signal_Payload__c" "$activation_mapping" \
  || fail "Activation field mapping is missing intent_signal_payload"
search_fixed "\"intent_signal_payload\"" "$account_contract" "$handoff_contract" \
  || fail "Contract schemas do not reference intent_signal_payload"
pass "Contracts and activation mapping include intent signal payload support"

for token in \
  "@AuraEnabled(cacheable=true)" \
  "getRoutingQueue" \
  "getRoutingWorkspace" \
  "Intent_Signal_Payload__c" \
  "salesforce_preview"; do
  search_fixed "$token" "$service" || fail "Missing signal-routing Apex token: $token"
done
pass "Signal-routing Apex service exposes the expected workspace contract"

for token in \
  "returnsPayloadBackedRoutingWorkspace" \
  "returnsSortedFallbackQueueWhenPayloadIsAbsent" \
  "Intent_Signal_Payload__c"; do
  search_fixed "$token" "$test_class" || fail "Missing signal-routing test coverage token: $token"
done
pass "Signal-routing Apex tests cover payload-backed and fallback paths"

for token in \
  "Pulse360 Signal Routing Workspace" \
  "Create routed task" \
  "Target contacts" \
  "What is grounded and what is still provisional"; do
  search_fixed "$token" "$lwc_dir/pulse360SignalRoutingWorkspace.html" \
    || fail "Missing signal-routing UI token: $token"
done
pass "Signal-routing LWC exposes the core routed-alert experience"

search_fixed "lightning__Tab" "$lwc_dir/pulse360SignalRoutingWorkspace.js-meta.xml" \
  || fail "Signal-routing LWC is not tab-exposed"
search_fixed "<object>Account</object>" "$lwc_dir/pulse360SignalRoutingWorkspace.js-meta.xml" \
  || fail "Signal-routing LWC is not Account record exposed"
search_fixed "Pulse360SignalRoutingWorkspaceService" "$permset" \
  || fail "Permission set missing Pulse360SignalRoutingWorkspaceService access"
search_fixed "Account.Intent_Signal_Payload__c" "$permset" \
  || fail "Permission set missing Intent_Signal_Payload__c field access"
search_fixed "Pulse360_Signal_Routing" "$permset" \
  || fail "Permission set missing Pulse360_Signal_Routing tab visibility"
pass "Signal-routing metadata is permissioned and exposed"

if [[ -n "${TARGET_ORG:-}" ]]; then
  SF_BIN="${SF_BIN:-sf}"

  tabs_json="$("$SF_BIN" org list metadata --target-org "$TARGET_ORG" --metadata-type CustomTab --json)"
  echo "$tabs_json" | jq -e '.result[] | select(.fullName == "Pulse360_Signal_Routing")' >/dev/null \
    || fail "Pulse360_Signal_Routing tab not found in org '$TARGET_ORG'"
  pass "Signal-routing tab exists in org '$TARGET_ORG'"

  perm_json="$("$SF_BIN" data query --target-org "$TARGET_ORG" --query "SELECT Assignee.Username FROM PermissionSetAssignment WHERE PermissionSet.Name = 'Pulse360_Account_Intelligence_User'" --json)"
  assigned_count="$(echo "$perm_json" | jq -r '.result.totalSize // 0')"
  [[ "$assigned_count" -ge 1 ]] || fail "Pulse360_Account_Intelligence_User is not assigned in org '$TARGET_ORG'"
  pass "Pulse360 account intelligence permission set is assigned in org '$TARGET_ORG'"

  account_json="$("$SF_BIN" data query --target-org "$TARGET_ORG" --query "SELECT Id, Name, Cross_Sell_Propensity__c, Engagement_Intensity_Score__c, Coverage_Gap_Flag__c, Intent_Signal_Payload__c FROM Account ORDER BY LastModifiedDate DESC LIMIT 20" --json)"
  preview_count="$(echo "$account_json" | jq -r '[.result.records[] | select(.Cross_Sell_Propensity__c != null or .Engagement_Intensity_Score__c != null or .Coverage_Gap_Flag__c == true)] | length')"
  [[ "$preview_count" -ge 1 ]] || fail "No candidate Accounts found for the signal-routing workspace in org '$TARGET_ORG'"
  payload_count="$(echo "$account_json" | jq -r '[.result.records[] | select(.Intent_Signal_Payload__c != null)] | length')"
  if [[ "$payload_count" -ge 1 ]]; then
    pass "Intent signal payload is populated on at least one Account in org '$TARGET_ORG'"
  else
    warn "Intent signal payload is not populated yet in org '$TARGET_ORG'; the deployed workspace will run in Salesforce-first preview mode"
  fi
fi

pass "Signal-routing workspace validation completed"
