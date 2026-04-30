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

permset="force-app/main/default/permissionsets/Pulse360_Account_Intelligence_User.permissionset-meta.xml"

planner_service="force-app/main/default/classes/Pulse360PlannerWorkspaceService.cls"
planner_test="force-app/main/default/classes/Pulse360PlannerWorkspaceServiceTest.cls"
planner_lwc_dir="force-app/main/default/lwc/pulse360PlannerWorkspace"
planner_tab="force-app/main/default/tabs/Pulse360_Planner.tab-meta.xml"
planner_app_page="force-app/main/default/flexipages/Pulse360_Portfolio_Dashboard.flexipage-meta.xml"

health_service="force-app/main/default/classes/Pulse360HealthScanService.cls"
health_test="force-app/main/default/classes/Pulse360HealthScanServiceTest.cls"
health_lwc_dir="force-app/main/default/lwc/pulse360HealthScan"

directory_service="force-app/main/default/classes/Pulse360SellerWorkspaceDirectoryService.cls"
directory_test="force-app/main/default/classes/Pulse360SellerDirServiceTest.cls"

seller_v2_lwc_dir="force-app/main/default/lwc/pulse360SellerWorkspaceV2"
seller_v2_tab="force-app/main/default/tabs/Pulse360_Seller_V2.tab-meta.xml"

renewal_lwc_dir="force-app/main/default/lwc/pulse360RenewalRiskWorkspace"
renewal_tab="force-app/main/default/tabs/Pulse360_Renewal_Risk.tab-meta.xml"

for path in \
  "$permset" \
  "$planner_service" \
  "$planner_test" \
  "$planner_lwc_dir" \
  "$planner_tab" \
  "$planner_app_page" \
  "$health_service" \
  "$health_test" \
  "$health_lwc_dir" \
  "$directory_service" \
  "$directory_test" \
  "$seller_v2_lwc_dir" \
  "$seller_v2_tab" \
  "$renewal_lwc_dir" \
  "$renewal_tab"; do
  [[ -e "$path" ]] || fail "Missing required multi-surface artifact: $path"
done
pass "Multi-surface workspace artifacts are present"

for token in \
  "@AuraEnabled(cacheable=true)" \
  "getPlannerWorkspace" \
  "Hierarchy_Payload__c" \
  "priorityScore" \
  "highlightedAction"; do
  search_fixed "$token" "$planner_service" || fail "Missing planner service token: $token"
done

for token in \
  "ranksGroupsAndBuildsPlannerQueue" \
  "returnsEmptyWorkspaceWhenPortfolioSignalsAreMissing" \
  "Assign owner to uncovered entities" \
  "Fresh"; do
  search_fixed "$token" "$planner_test" || fail "Missing planner test token: $token"
done

for token in \
  "Pulse360 Planner Workspace" \
  "Next planning move" \
  "Leadership-ready group view" \
  "What leadership should do next"; do
  search_fixed "$token" "$planner_lwc_dir/pulse360PlannerWorkspace.html" \
    || fail "Missing planner workspace UI token: $token"
done

search_fixed "@salesforce/apex/Pulse360PlannerWorkspaceService.getPlannerWorkspace" "$planner_lwc_dir/pulse360PlannerWorkspace.js" \
  || fail "Planner workspace LWC is not wired to the planner service"
search_fixed "lightning__AppPage" "$planner_lwc_dir/pulse360PlannerWorkspace.js-meta.xml" \
  || fail "Planner workspace LWC is not app-page exposed"
search_fixed "lightning__Tab" "$planner_lwc_dir/pulse360PlannerWorkspace.js-meta.xml" \
  || fail "Planner workspace LWC is not tab exposed"
search_fixed "<label>Pulse360 Planner</label>" "$planner_tab" \
  || fail "Planner tab label metadata is missing"
search_fixed "<flexiPage>Pulse360_Portfolio_Dashboard</flexiPage>" "$planner_tab" \
  || fail "Planner tab is not bound to the portfolio dashboard app page"
search_fixed "<masterLabel>Pulse360 Portfolio Dashboard</masterLabel>" "$planner_app_page" \
  || fail "Planner app page label metadata is missing"
search_fixed "<componentName>c:pulse360PlannerWorkspace</componentName>" "$planner_app_page" \
  || fail "Planner app page is not bound to the planner workspace LWC"
search_fixed "<type>AppPage</type>" "$planner_app_page" \
  || fail "Planner app page is not an AppPage"
pass "Planner workspace service, test, and metadata are aligned"

for token in \
  "@AuraEnabled(cacheable=true)" \
  "runHealthScan" \
  "Regulatory_Readiness_Score__c" \
  "AI_Recommended_Actions__c" \
  "AI_Source_Refs__c"; do
  search_fixed "$token" "$health_service" || fail "Missing health scan service token: $token"
done

for token in \
  "runsHealthScanForAccount" \
  "returnsEmptyCollectionsWhenJsonFieldsAreBlank" \
  "pulse360-public-regional-v1" \
  "gpt-5.4"; do
  search_fixed "$token" "$health_test" || fail "Missing health scan test token: $token"
done

for token in \
  "Pulse360 Health Scan" \
  "Run Health Scan" \
  "AI Assessment" \
  "Recommended Actions"; do
  search_fixed "$token" "$health_lwc_dir/pulse360HealthScan.html" \
    || fail "Missing health scan UI token: $token"
done

search_fixed "lightning__RecordPage" "$health_lwc_dir/pulse360HealthScan.js-meta.xml" \
  || fail "Health scan LWC is not record-page exposed"
search_fixed "lightning__AppPage" "$health_lwc_dir/pulse360HealthScan.js-meta.xml" \
  || fail "Health scan LWC is not app-page exposed"
search_fixed "<object>Account</object>" "$health_lwc_dir/pulse360HealthScan.js-meta.xml" \
  || fail "Health scan LWC is not Account-targeted"
pass "Health scan service, test, and metadata are aligned"

for token in \
  "@AuraEnabled(cacheable=true)" \
  "getPreviewAccounts" \
  "Group_Revenue_Rollup__c" \
  "Coverage_Gap_Flag__c" \
  "AI_Narrative_Generated__c"; do
  search_fixed "$token" "$directory_service" || fail "Missing preview directory service token: $token"
done

for token in \
  "returnsPreviewAccountsOrderedByCommercialWeight" \
  "returnsEmptyListWhenNoQualifiedAccountsExist" \
  "Singtel Group" \
  "Ayala Corporation"; do
  search_fixed "$token" "$directory_test" || fail "Missing preview directory test token: $token"
done
pass "Preview account directory service and tests exist"

for token in \
  "Pulse360 Seller Workspace V2" \
  "Decision-ready seller view" \
  "Open planner workspace" \
  "Choose the right entity before the seller moves"; do
  search_fixed "$token" "$seller_v2_lwc_dir/pulse360SellerWorkspaceV2.html" \
    || fail "Missing seller workspace v2 UI token: $token"
done

for token in \
  "@salesforce/apex/Pulse360SellerWorkspaceDirectoryService.getPreviewAccounts" \
  "@salesforce/apex/Pulse360SellerOrchestratorService.executePulse360SellerAction" \
  "previewRecordId" \
  "requiresApproval"; do
  search_fixed "$token" "$seller_v2_lwc_dir/pulse360SellerWorkspaceV2.js" \
    || fail "Missing seller workspace v2 JS token: $token"
done

search_fixed "lightning__RecordPage" "$seller_v2_lwc_dir/pulse360SellerWorkspaceV2.js-meta.xml" \
  || fail "Seller workspace v2 LWC is not record-page exposed"
search_fixed "lightning__AppPage" "$seller_v2_lwc_dir/pulse360SellerWorkspaceV2.js-meta.xml" \
  || fail "Seller workspace v2 LWC is not app-page exposed"
search_fixed "lightning__Tab" "$seller_v2_lwc_dir/pulse360SellerWorkspaceV2.js-meta.xml" \
  || fail "Seller workspace v2 LWC is not tab exposed"
search_fixed "<object>Account</object>" "$seller_v2_lwc_dir/pulse360SellerWorkspaceV2.js-meta.xml" \
  || fail "Seller workspace v2 LWC is not Account-targeted"
search_fixed "name=\"previewRecordId\"" "$seller_v2_lwc_dir/pulse360SellerWorkspaceV2.js-meta.xml" \
  || fail "Seller workspace v2 app-page preview property is missing"
search_fixed "<label>Pulse360 Seller V2</label>" "$seller_v2_tab" \
  || fail "Seller workspace v2 tab label metadata is missing"
search_fixed "<lwcComponent>pulse360SellerWorkspaceV2</lwcComponent>" "$seller_v2_tab" \
  || fail "Seller workspace v2 tab is not bound to the LWC"
pass "Seller workspace v2 surface and navigation hooks are aligned"

for token in \
  "Recommended save play" \
  "Create save plan task" \
  "Open seller v2" \
  "What is grounded versus what is uncertain"; do
  search_fixed "$token" "$renewal_lwc_dir/pulse360RenewalRiskWorkspace.html" \
    || fail "Missing renewal workspace UI token: $token"
done

for token in \
  "@salesforce/apex/Pulse360SellerWorkspaceDirectoryService.getPreviewAccounts" \
  "@salesforce/apex/Pulse360SellerOrchestratorService.executePulse360SellerAction" \
  "previewRecordId" \
  "Manageable risk"; do
  search_fixed "$token" "$renewal_lwc_dir/pulse360RenewalRiskWorkspace.js" \
    || fail "Missing renewal workspace JS token: $token"
done

search_fixed "lightning__RecordPage" "$renewal_lwc_dir/pulse360RenewalRiskWorkspace.js-meta.xml" \
  || fail "Renewal workspace LWC is not record-page exposed"
search_fixed "lightning__AppPage" "$renewal_lwc_dir/pulse360RenewalRiskWorkspace.js-meta.xml" \
  || fail "Renewal workspace LWC is not app-page exposed"
search_fixed "lightning__Tab" "$renewal_lwc_dir/pulse360RenewalRiskWorkspace.js-meta.xml" \
  || fail "Renewal workspace LWC is not tab exposed"
search_fixed "<object>Account</object>" "$renewal_lwc_dir/pulse360RenewalRiskWorkspace.js-meta.xml" \
  || fail "Renewal workspace LWC is not Account-targeted"
search_fixed "name=\"previewRecordId\"" "$renewal_lwc_dir/pulse360RenewalRiskWorkspace.js-meta.xml" \
  || fail "Renewal workspace app-page preview property is missing"
search_fixed "<label>Pulse360 Renewal Risk</label>" "$renewal_tab" \
  || fail "Renewal workspace tab label metadata is missing"
search_fixed "<lwcComponent>pulse360RenewalRiskWorkspace</lwcComponent>" "$renewal_tab" \
  || fail "Renewal workspace tab is not bound to the LWC"
pass "Renewal workspace surface and navigation hooks are aligned"

for token in \
  "Pulse360HealthScanService" \
  "Pulse360SellerWorkspaceService" \
  "Pulse360SellerOrchestratorService" \
  "Pulse360PlannerWorkspaceService" \
  "Pulse360SellerWorkspaceDirectoryService"; do
  search_fixed "$token" "$permset" || fail "Missing permission-set Apex access: $token"
done

for token in \
  "Pulse360_Seller_V2" \
  "Pulse360_Renewal_Risk" \
  "Pulse360_Planner"; do
  search_fixed "$token" "$permset" || fail "Missing permission-set tab visibility: $token"
done

for token in \
  "Account.AI_Narrative__c" \
  "Account.Group_Revenue_Visible__c" \
  "Account.Health_Score__c" \
  "Account.Hierarchy_Payload__c"; do
  search_fixed "$token" "$permset" || fail "Missing permission-set field access: $token"
done
pass "Permission set covers the multi-surface seller experience"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"${script_dir}/validate-surface-architecture.sh"
pass "Surface architecture validator passed"

pass "Multi-surface seller experience validation completed"
