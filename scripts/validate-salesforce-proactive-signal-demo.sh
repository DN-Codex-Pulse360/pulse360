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

required_files=(
  "data/samples/proactive_account_signal_northstar_sample.json"
  "scripts/seed-salesforce-proactive-signal-demo.sh"
  "force-app/main/default/classes/Pulse360SignalRoutingWorkspaceService.cls"
  "force-app/main/default/classes/Pulse360SignalRoutingServiceTest.cls"
  "force-app/main/default/lwc/pulse360SignalRoutingWorkspace/pulse360SignalRoutingWorkspace.js"
  "force-app/main/default/lwc/pulse360SignalRoutingWorkspace/pulse360SignalRoutingWorkspace.html"
  "force-app/main/default/permissionsets/Pulse360_Account_Intelligence_User.permissionset-meta.xml"
  "force-app/main/default/tabs/Pulse360_Signal_Routing.tab-meta.xml"
)

for path in "${required_files[@]}"; do
  [[ -f "$path" ]] || fail "Missing Salesforce proactive signal artifact: $path"
done
pass "Salesforce proactive signal artifacts exist"

python3 - <<'PY'
import json
from pathlib import Path

sample = json.loads(Path("data/samples/proactive_account_signal_northstar_sample.json").read_text())
projection = sample["data_cloud_projection"]
intent = projection["intent_signal_payload"]

required = {
    "routing_version",
    "signal_score",
    "signal_label",
    "threshold_label",
    "route_to",
    "routing_confidence",
    "why_now",
    "drafted_outreach",
    "channel_readiness",
    "top_drivers",
    "generated_at",
}
missing = sorted(required - set(intent))
if missing:
    raise SystemExit("Intent payload missing Salesforce routing fields: " + ", ".join(missing))
if sample["account_name"] != "Northstar Foods Group":
    raise SystemExit("Sample account name must stay Northstar Foods Group")
if sample["source_account_id"] != "001NST000000001AAA":
    raise SystemExit("Sample source_account_id must remain the CRM-safe demo id")
if intent["signal_label"] != "Coverage-led review":
    raise SystemExit("Signal label must match the existing Salesforce workspace label")
if projection["coverage_gap_flag"] is not True:
    raise SystemExit("coverage_gap_flag must stay true for the Salesforce demo")
if len(intent["top_drivers"]) < 3:
    raise SystemExit("Salesforce routing workspace needs at least three top drivers")
print("[PASS] Salesforce routing payload is Account workspace compatible")
PY

seed_script="scripts/seed-salesforce-proactive-signal-demo.sh"
for token in \
  'TARGET_ORG="${TARGET_ORG:-pulse360-agent-target}"' \
  "Intent_Signal_Payload__c" \
  "Coverage_Gap_Flag__c" \
  "AI_Narrative__c" \
  "AI_Recommended_Actions__c" \
  "AI_Source_Refs__c" \
  "DataCloud_Last_Synced__c"; do
  search_fixed "$token" "$seed_script" || fail "Seed script missing token: $token"
done
pass "Salesforce seed script preserves proactive signal evidence fields"

for token in \
  "Northstar Foods Group" \
  "create_opportunity" \
  "approval_required" \
  "custom Salesforce LWC/Apex assistant and action panels"; do
  search_fixed "$token" "data/samples/proactive_account_signal_northstar_sample.json" \
    || fail "Proactive signal sample missing token: $token"
done
pass "Proactive signal sample preserves scenario identity and fallback policy"

for field in \
  "Intent_Signal_Payload__c" \
  "Coverage_Gap_Flag__c" \
  "AI_Narrative__c" \
  "AI_Recommended_Actions__c" \
  "AI_Source_Refs__c" \
  "DataCloud_Last_Synced__c"; do
  [[ -f "force-app/main/default/objects/Account/fields/${field}.field-meta.xml" ]] \
    || fail "Missing Account field metadata for $field"
done
pass "Required Account signal fields exist"

permset="force-app/main/default/permissionsets/Pulse360_Account_Intelligence_User.permissionset-meta.xml"
for field in \
  "Account.Intent_Signal_Payload__c" \
  "Account.Coverage_Gap_Flag__c" \
  "Account.AI_Narrative__c" \
  "Account.AI_Recommended_Actions__c" \
  "Account.AI_Source_Refs__c" \
  "Account.DataCloud_Last_Synced__c"; do
  search_fixed "<editable>false</editable><field>${field}</field><readable>true</readable>" "$permset" \
    || fail "Permission set must keep $field read-only and readable"
done
pass "Evidence fields remain read-only in the Account Intelligence permission set"

search_fixed "Pulse360 Signal Routing Workspace" "force-app/main/default/lwc/pulse360SignalRoutingWorkspace/pulse360SignalRoutingWorkspace.html" \
  || fail "Signal routing workspace LWC missing expected title"
search_fixed "getRoutingWorkspace" "force-app/main/default/classes/Pulse360SignalRoutingWorkspaceService.cls" \
  || fail "Signal routing Apex service missing getRoutingWorkspace"
search_fixed "Pulse360_Signal_Routing" "$permset" \
  || fail "Permission set does not expose the signal routing tab"
pass "Existing Salesforce signal-routing surface is available for the seeded account"

if [[ -n "${TARGET_ORG:-}" ]]; then
  SF_BIN="${SF_BIN:-sf}"
  account_json="$("$SF_BIN" data query --target-org "$TARGET_ORG" --query "SELECT Id, Name, Coverage_Gap_Flag__c, Intent_Signal_Payload__c, AI_Recommended_Actions__c, DataCloud_Last_Synced__c FROM Account WHERE Name = 'Northstar Foods Group' LIMIT 1" --json)"
  total_size="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["result"]["totalSize"])' <<<"$account_json")"
  [[ "$total_size" -eq 1 ]] || fail "Northstar Foods Group Account is not present in org '$TARGET_ORG'"

  ACCOUNT_JSON="$account_json" python3 - <<'PY'
import json
import os
import sys

payload = json.loads(os.environ["ACCOUNT_JSON"])
record = payload["result"]["records"][0]
if record.get("Coverage_Gap_Flag__c") is not True:
    raise SystemExit("Northstar Account coverage gap flag is not true")
if not record.get("Intent_Signal_Payload__c"):
    raise SystemExit("Northstar Account is missing Intent_Signal_Payload__c")
if not record.get("AI_Recommended_Actions__c"):
    raise SystemExit("Northstar Account is missing AI_Recommended_Actions__c")
if not record.get("DataCloud_Last_Synced__c"):
    raise SystemExit("Northstar Account is missing DataCloud_Last_Synced__c")
print("[PASS] Live org Northstar Account has the proactive Salesforce fields populated")
PY
else
  warn "TARGET_ORG not set; skipped live Salesforce org validation"
fi

pass "Salesforce proactive signal demo validation completed"
