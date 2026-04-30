#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

search_fixed() {
  local needle="$1"
  shift

  if command -v rg >/dev/null 2>&1; then
    rg -Fq "$needle" "$@"
  else
    grep -Fq -- "$needle" "$@"
  fi
}

flexipage="force-app/main/default/flexipages/Account_Record_Page.flexipage-meta.xml"
permset="force-app/main/default/permissionsets/Pulse360_Account_Intelligence_User.permissionset-meta.xml"
account_workspace_header_lwc="force-app/main/default/lwc/pulse360AccountWorkspaceHeader"
account_summary_lwc="force-app/main/default/lwc/pulse360AccountSummaryPanel"
account_summary_js="$account_summary_lwc/pulse360AccountSummaryPanel.js"
agent_panel_lwc="force-app/main/default/lwc/pulse360AgentPanel"
recommended_move_lwc="force-app/main/default/lwc/pulse360RecommendedMovePanel"
timeline_panel_lwc="force-app/main/default/lwc/pulse360AccountTimelinePanel"
entity_focus_lwc="force-app/main/default/lwc/pulse360EntityFocusPanel"
trust_panel_lwc="force-app/main/default/lwc/pulse360TrustPanel"
renewal_panel_lwc="force-app/main/default/lwc/pulse360RenewalRiskPanel"
account_workspace_guidance_lwc="force-app/main/default/lwc/pulse360AccountWorkspaceGuidance"
seller_workspace_v2_lwc="force-app/main/default/lwc/pulse360SellerWorkspaceV2"
renewal_workspace_lwc="force-app/main/default/lwc/pulse360RenewalRiskWorkspace"
health_scan_lwc="force-app/main/default/lwc/pulse360HealthScan"
seller_workspace_class="force-app/main/default/classes/Pulse360SellerWorkspaceService.cls"
seller_workspace_test="force-app/main/default/classes/Pulse360SellerWorkspaceServiceTest.cls"
seller_play_object="force-app/main/default/objects/Pulse360_Seller_Play__mdt/Pulse360_Seller_Play__mdt.object-meta.xml"
hierarchy_field="force-app/main/default/objects/Account/fields/Hierarchy_Payload__c.field-meta.xml"

[[ -f "$flexipage" ]] || fail "Missing Account Lightning Record Page metadata"
[[ -f "$permset" ]] || fail "Missing Pulse360 account intelligence permission set"
[[ -d "$account_workspace_header_lwc" ]] || fail "Missing pulse360AccountWorkspaceHeader LWC"
[[ -d "$account_summary_lwc" ]] || fail "Missing pulse360AccountSummaryPanel LWC"
[[ -d "$agent_panel_lwc" ]] || fail "Missing pulse360AgentPanel LWC"
[[ -d "$recommended_move_lwc" ]] || fail "Missing pulse360RecommendedMovePanel LWC"
[[ -d "$timeline_panel_lwc" ]] || fail "Missing pulse360AccountTimelinePanel LWC"
[[ -d "$entity_focus_lwc" ]] || fail "Missing pulse360EntityFocusPanel LWC"
[[ -d "$trust_panel_lwc" ]] || fail "Missing pulse360TrustPanel LWC"
[[ -d "$renewal_panel_lwc" ]] || fail "Missing pulse360RenewalRiskPanel LWC"
[[ -d "$account_workspace_guidance_lwc" ]] || fail "Missing pulse360AccountWorkspaceGuidance LWC"
[[ -d "$seller_workspace_v2_lwc" ]] || fail "Missing pulse360SellerWorkspaceV2 LWC"
[[ -d "$renewal_workspace_lwc" ]] || fail "Missing pulse360RenewalRiskWorkspace LWC"
[[ -d "$health_scan_lwc" ]] || fail "Missing pulse360HealthScan LWC"
[[ -f "$seller_workspace_class" ]] || fail "Missing Pulse360SellerWorkspaceService Apex class"
[[ -f "$seller_workspace_test" ]] || fail "Missing Pulse360SellerWorkspaceService Apex test class"
[[ -f "$seller_play_object" ]] || fail "Missing Pulse360 seller play custom metadata type"
[[ -f "$hierarchy_field" ]] || fail "Missing Account hierarchy payload field metadata"

for token in \
  "c:pulse360AccountWorkspaceHeader" \
  "c:pulse360AccountSummaryPanel" \
  "c:pulse360AgentPanel" \
  "c:pulse360RecommendedMovePanel" \
  "c:pulse360AccountTimelinePanel" \
  "c:pulse360EntityFocusPanel" \
  "c:pulse360TrustPanel" \
  "c:pulse360RenewalRiskPanel" \
  "c:pulse360HealthScan" \
  "c:pulse360AccountWorkspaceGuidance"; do
  search_fixed "$token" "$flexipage" || fail "Missing Account flexipage component reference: $token"
done
! search_fixed "c:pulse360AccountWorkspace</componentName>" "$flexipage" || fail "Account flexipage still references the transitional account workspace shell"
! search_fixed "c:pulse360SellerWorkspace</componentName>" "$flexipage" || fail "Account flexipage still references the legacy seller workspace"
! search_fixed "c:pulse360SellerWorkspaceV2</componentName>" "$flexipage" || fail "Account flexipage still references the large seller workspace module"
! search_fixed "c:pulse360RenewalRiskWorkspace</componentName>" "$flexipage" || fail "Account flexipage still references the large renewal workspace module"
search_fixed "<name>sidebar</name>" "$flexipage" || fail "Account flexipage must define a sidebar region for the support rail"
pass "Account flexipage references focused Pulse360 record-page modules"

for file in \
  "$account_workspace_header_lwc/pulse360AccountWorkspaceHeader.js-meta.xml" \
  "$account_summary_lwc/pulse360AccountSummaryPanel.js-meta.xml" \
  "$agent_panel_lwc/pulse360AgentPanel.js-meta.xml" \
  "$recommended_move_lwc/pulse360RecommendedMovePanel.js-meta.xml" \
  "$timeline_panel_lwc/pulse360AccountTimelinePanel.js-meta.xml" \
  "$entity_focus_lwc/pulse360EntityFocusPanel.js-meta.xml" \
  "$trust_panel_lwc/pulse360TrustPanel.js-meta.xml" \
  "$renewal_panel_lwc/pulse360RenewalRiskPanel.js-meta.xml" \
  "$account_workspace_guidance_lwc/pulse360AccountWorkspaceGuidance.js-meta.xml"; do
  search_fixed "lightning__RecordPage" "$file" || fail "Missing record page exposure in $file"
  search_fixed "<object>Account</object>" "$file" || fail "Missing Account target in $file"
done
search_fixed "name=\"showPortfolioLink\"" "$account_workspace_header_lwc/pulse360AccountWorkspaceHeader.js-meta.xml" || fail "Missing configurable portfolio link property"
search_fixed "name=\"showGovernanceLink\"" "$account_workspace_header_lwc/pulse360AccountWorkspaceHeader.js-meta.xml" || fail "Missing configurable governance link property"
pass "Account workspace header and guidance are exposed on Account record pages"

for token in \
  "Pulse360 Account Workspace" \
  "Open portfolio dashboard" \
  "Open governance cases"; do
  search_fixed "$token" "$account_workspace_header_lwc/pulse360AccountWorkspaceHeader.html" \
    || fail "Missing account workspace header token: $token"
done
for token in \
  "What this page should do" \
  "Before the call" \
  "After the call" \
  "Keep the seller anchored"; do
  search_fixed "$token" "$account_workspace_guidance_lwc/pulse360AccountWorkspaceGuidance.html" \
    || fail "Missing account workspace guidance token: $token"
done
search_fixed "Account focus" "$account_summary_lwc/pulse360AccountSummaryPanel.html" \
  || fail "Missing account summary token: Account focus"
for token in \
  "Group revenue story" \
  "Whitespace readiness"; do
	  search_fixed "$token" "$account_summary_js" \
	    || fail "Missing account summary token: $token"
done
for token in \
  "Pulse360 Agent" \
  "Execution checklist"; do
  search_fixed "$token" "$agent_panel_lwc/pulse360AgentPanel.html" \
    || fail "Missing agent panel token: $token"
done
for token in \
  "What should I do next?" \
  "Draft outreach" \
  "Test the evidence"; do
  search_fixed "$token" "$agent_panel_lwc/pulse360AgentPanel.js" \
    || fail "Missing agent panel prompt token: $token"
done
search_fixed "askPulse360SellerAgent" "$agent_panel_lwc/pulse360AgentPanel.js" \
  || fail "Missing agent panel Apex ask integration"
search_fixed "executePulse360SellerAction" "$agent_panel_lwc/pulse360AgentPanel.js" \
  || fail "Missing agent panel execution integration"
for token in \
  "Timeline" \
  "Signal and account history"; do
  search_fixed "$token" "$timeline_panel_lwc/pulse360AccountTimelinePanel.html" \
    || fail "Missing timeline panel token: $token"
done
search_fixed "AI narrative generated" "$timeline_panel_lwc/pulse360AccountTimelinePanel.js" \
  || fail "Missing timeline panel token: AI narrative generated"
for token in \
  "Recommended move" \
  "Top recommended move" \
  "Create opportunity"; do
  search_fixed "$token" "$recommended_move_lwc/pulse360RecommendedMovePanel.html" \
    || fail "Missing recommended move token: $token"
done
for token in \
  "Entity focus" \
  "Choose the right entity before the seller moves" \
  "Suggested play"; do
  search_fixed "$token" "$entity_focus_lwc/pulse360EntityFocusPanel.html" \
    || fail "Missing entity focus token: $token"
done
for token in \
  "Evidence and trust" \
  "What is grounded versus what is uncertain" \
  "Freshness and provenance"; do
  search_fixed "$token" "$trust_panel_lwc/pulse360TrustPanel.html" \
    || fail "Missing trust panel token: $token"
done
for token in \
  "Renewal risk" \
  "Recommended save move" \
  "Create save plan task"; do
  search_fixed "$token" "$renewal_panel_lwc/pulse360RenewalRiskPanel.html" \
    || fail "Missing renewal panel token: $token"
done
pass "Account workspace UI reflects the focused record-page modules"

for token in \
  "name=\"embeddedMode\"" \
  "lightning__RecordPage"; do
  search_fixed "$token" "$seller_workspace_v2_lwc/pulse360SellerWorkspaceV2.js-meta.xml" \
    || fail "Missing seller workspace v2 embedded-mode record-page token: $token"
  search_fixed "$token" "$renewal_workspace_lwc/pulse360RenewalRiskWorkspace.js-meta.xml" \
    || fail "Missing renewal workspace embedded-mode record-page token: $token"
done
pass "Standalone seller and renewal workspaces remain exposed for non-record-page use"

for token in \
  "Pulse360 Account Workspace" \
  "Open portfolio dashboard" \
  "Open governance cases"; do
  search_fixed "$token" "$account_workspace_header_lwc/pulse360AccountWorkspaceHeader.html" \
    || fail "Missing account workspace token: $token"
done

for token in \
  "Decision-ready seller view" \
  "Recommended move" \
  "Choose the right entity before the seller moves"; do
  search_fixed "$token" "$seller_workspace_v2_lwc/pulse360SellerWorkspaceV2.html" \
    || fail "Missing seller workspace v2 token: $token"
done
pass "Seller workspace v2 remains available as a separate deeper workspace"

for token in \
  "Pulse360 Renewal &amp; Risk Workspace" \
  "Recommended save play" \
  "What is grounded versus what is uncertain"; do
  search_fixed "$token" "$renewal_workspace_lwc/pulse360RenewalRiskWorkspace.html" \
    || fail "Missing renewal workspace token: $token"
done
pass "Renewal workspace remains available as a separate deeper workspace"

for token in \
  "Pulse360 Health Scan" \
  "Run Health Scan" \
  "AI Assessment"; do
  search_fixed "$token" "$health_scan_lwc/pulse360HealthScan.html" \
    || fail "Missing health scan token: $token"
done
pass "Health scan remains present inside the account experience"

for token in \
  "@AuraEnabled(cacheable=true)" \
  "getSellerWorkspace" \
  "Hierarchy_Payload__c" \
  "crmRecordId" \
  "coverageLabel" \
  "suggestedPlay" \
  "Pulse360_Seller_Play__mdt"; do
  search_fixed "$token" "$seller_workspace_class" || fail "Missing seller workspace Apex token: $token"
done
pass "Seller workspace Apex service exposes the expected account intelligence contract"

for token in \
  "buildsWorkspaceWithHierarchyAndMatchedPlay" \
  "Hierarchy_Payload__c" \
  "crm_record_id" \
  "AI_Recommended_Actions__c"; do
  search_fixed "$token" "$seller_workspace_test" || fail "Missing seller workspace test token: $token"
done
pass "Seller workspace Apex test covers the account intelligence payload"

search_fixed "<label>Pulse360 Seller Play</label>" "$seller_play_object" || fail "Missing Pulse360 seller play custom metadata label"
pass "Seller play configuration metadata exists"

search_fixed "<label>Pulse360 Account Intelligence User</label>" "$permset" || fail "Missing Pulse360 account intelligence permission set label"
search_fixed "Pulse360HealthScanService" "$permset" || fail "Missing Pulse360HealthScanService class access in permission set"
search_fixed "Pulse360SellerWorkspaceService" "$permset" || fail "Missing Pulse360SellerWorkspaceService class access in permission set"
search_fixed "Account.Hierarchy_Payload__c" "$permset" || fail "Missing Hierarchy_Payload__c field permission in permission set"
pass "Pulse360 account intelligence permission set exists"

pass "Account intelligence experience validation completed"
