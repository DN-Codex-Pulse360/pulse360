#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

pass() {
  echo "[PASS] $1"
}

search_fixed() {
  local needle="$1"
  shift

  if command -v rg >/dev/null 2>&1; then
    rg -Fq "$needle" "$@"
  else
    grep -Fq -- "$needle" "$@"
  fi
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

account_flexipage="${repo_root}/force-app/main/default/flexipages/Account_Record_Page.flexipage-meta.xml"
account_header_html="${repo_root}/force-app/main/default/lwc/pulse360AccountWorkspaceHeader/pulse360AccountWorkspaceHeader.html"
account_header_meta="${repo_root}/force-app/main/default/lwc/pulse360AccountWorkspaceHeader/pulse360AccountWorkspaceHeader.js-meta.xml"
account_summary_html="${repo_root}/force-app/main/default/lwc/pulse360AccountSummaryPanel/pulse360AccountSummaryPanel.html"
account_summary_js="${repo_root}/force-app/main/default/lwc/pulse360AccountSummaryPanel/pulse360AccountSummaryPanel.js"
account_summary_meta="${repo_root}/force-app/main/default/lwc/pulse360AccountSummaryPanel/pulse360AccountSummaryPanel.js-meta.xml"
agent_panel_html="${repo_root}/force-app/main/default/lwc/pulse360AgentPanel/pulse360AgentPanel.html"
agent_panel_js="${repo_root}/force-app/main/default/lwc/pulse360AgentPanel/pulse360AgentPanel.js"
agent_panel_meta="${repo_root}/force-app/main/default/lwc/pulse360AgentPanel/pulse360AgentPanel.js-meta.xml"
recommended_move_html="${repo_root}/force-app/main/default/lwc/pulse360RecommendedMovePanel/pulse360RecommendedMovePanel.html"
recommended_move_meta="${repo_root}/force-app/main/default/lwc/pulse360RecommendedMovePanel/pulse360RecommendedMovePanel.js-meta.xml"
account_timeline_html="${repo_root}/force-app/main/default/lwc/pulse360AccountTimelinePanel/pulse360AccountTimelinePanel.html"
account_timeline_js="${repo_root}/force-app/main/default/lwc/pulse360AccountTimelinePanel/pulse360AccountTimelinePanel.js"
account_timeline_meta="${repo_root}/force-app/main/default/lwc/pulse360AccountTimelinePanel/pulse360AccountTimelinePanel.js-meta.xml"
entity_focus_html="${repo_root}/force-app/main/default/lwc/pulse360EntityFocusPanel/pulse360EntityFocusPanel.html"
entity_focus_meta="${repo_root}/force-app/main/default/lwc/pulse360EntityFocusPanel/pulse360EntityFocusPanel.js-meta.xml"
trust_panel_html="${repo_root}/force-app/main/default/lwc/pulse360TrustPanel/pulse360TrustPanel.html"
trust_panel_meta="${repo_root}/force-app/main/default/lwc/pulse360TrustPanel/pulse360TrustPanel.js-meta.xml"
renewal_panel_html="${repo_root}/force-app/main/default/lwc/pulse360RenewalRiskPanel/pulse360RenewalRiskPanel.html"
renewal_panel_meta="${repo_root}/force-app/main/default/lwc/pulse360RenewalRiskPanel/pulse360RenewalRiskPanel.js-meta.xml"
account_guidance_html="${repo_root}/force-app/main/default/lwc/pulse360AccountWorkspaceGuidance/pulse360AccountWorkspaceGuidance.html"

planner_flexipage="${repo_root}/force-app/main/default/flexipages/Pulse360_Portfolio_Dashboard.flexipage-meta.xml"
planner_workspace_html="${repo_root}/force-app/main/default/lwc/pulse360PlannerWorkspace/pulse360PlannerWorkspace.html"
planner_workspace_meta="${repo_root}/force-app/main/default/lwc/pulse360PlannerWorkspace/pulse360PlannerWorkspace.js-meta.xml"

for path in \
  "${account_flexipage}" \
  "${account_header_html}" \
  "${account_header_meta}" \
  "${account_summary_html}" \
  "${account_summary_js}" \
  "${account_summary_meta}" \
  "${agent_panel_html}" \
  "${agent_panel_js}" \
  "${agent_panel_meta}" \
  "${recommended_move_html}" \
  "${recommended_move_meta}" \
  "${account_timeline_html}" \
  "${account_timeline_js}" \
  "${account_timeline_meta}" \
  "${entity_focus_html}" \
  "${entity_focus_meta}" \
  "${trust_panel_html}" \
  "${trust_panel_meta}" \
  "${renewal_panel_html}" \
  "${renewal_panel_meta}" \
  "${account_guidance_html}" \
  "${planner_flexipage}" \
  "${planner_workspace_html}" \
  "${planner_workspace_meta}"; do
  [[ -f "${path}" ]] || fail "Missing required surface architecture artifact: ${path}"
done

python3 - "${account_flexipage}" "${planner_flexipage}" <<'PY'
import sys
import xml.etree.ElementTree as ET

ns = {"m": "http://soap.sforce.com/2006/04/metadata"}


def fail(message: str) -> None:
    print(f"[FAIL] {message}", file=sys.stderr)
    raise SystemExit(1)


def pass_(message: str) -> None:
    print(f"[PASS] {message}")


def custom_components_in_region(root: ET.Element, region_name: str) -> list[tuple[str, ET.Element]]:
    components = []
    for region in root.findall("m:flexiPageRegions", ns):
        if (region.findtext("m:name", default="", namespaces=ns) or "").strip() != region_name:
            continue
        for instance in region.findall(".//m:componentInstance", ns):
            name = (instance.findtext("m:componentName", default="", namespaces=ns) or "").strip()
            if name.startswith("c:"):
                components.append((name, instance))
    return components


account_root = ET.parse(sys.argv[1]).getroot()
account_main_components = custom_components_in_region(account_root, "main")
account_sidebar_components = custom_components_in_region(account_root, "sidebar")
account_main_names = [name for name, _ in account_main_components]
account_sidebar_names = [name for name, _ in account_sidebar_components]

expected_account_main_order = [
    "c:pulse360AccountWorkspaceHeader",
    "c:pulse360AccountSummaryPanel",
    "c:pulse360AgentPanel",
    "c:pulse360RecommendedMovePanel",
    "c:pulse360EntityFocusPanel",
    "c:pulse360HealthScan",
    "c:pulse360AccountWorkspaceGuidance",
]
if account_main_names[: len(expected_account_main_order)] != expected_account_main_order:
    fail(
        "Account record page must directly compose the Pulse360 account header, summary, visible agent panel, "
        "recommended move, entity focus, health scan, and guidance modules in the main region"
    )

expected_account_sidebar_order = [
    "c:pulse360AccountTimelinePanel",
    "c:pulse360TrustPanel",
    "c:pulse360RenewalRiskPanel",
]
if account_sidebar_names[: len(expected_account_sidebar_order)] != expected_account_sidebar_order:
    fail(
        "Account record page must place the Pulse360 timeline, trust, and renewal risk modules in the sidebar region"
    )

pass_("Account record page composes a main decision column and a sidebar support rail on the FlexiPage")

planner_root = ET.parse(sys.argv[2]).getroot()
planner_main_components = custom_components_in_region(planner_root, "main")

if len(planner_main_components) != 1 or planner_main_components[0][0] != "c:pulse360PlannerWorkspace":
    fail(
        "Portfolio dashboard must currently host exactly one modular planner shell component "
        "named c:pulse360PlannerWorkspace in the main region"
    )

planner_component = planner_main_components[0][1]
required_true = {
    "showSummaryPanel": "true",
    "showTimelinePanel": "true",
    "showActionRail": "true",
    "showExecutivePrompts": "true",
}
properties = {}
for prop in planner_component.findall("m:componentInstanceProperties", ns):
    name = (prop.findtext("m:name", default="", namespaces=ns) or "").strip()
    value = (prop.findtext("m:value", default="", namespaces=ns) or "").strip().lower()
    properties[name] = value

for name, expected in required_true.items():
    if properties.get(name) != expected:
        fail(
            f"Portfolio dashboard modular shell must enable {name}={expected} on the FlexiPage instance"
        )

pass_("Portfolio dashboard shell enables dashboard, action, and timeline modules at the page level")
PY

for token in \
  "Pulse360 Account Workspace" \
  "Open portfolio dashboard" \
  "Open governance cases"; do
  search_fixed "${token}" "${account_header_html}" \
    || fail "Missing account header token: ${token}"
done

for token in \
  "name=\"showPortfolioLink\"" \
  "name=\"showGovernanceLink\""; do
  search_fixed "${token}" "${account_header_meta}" \
    || fail "Missing account header configurability token: ${token}"
done

search_fixed "Account focus" "${account_summary_html}" \
  || fail "Missing account summary token: Account focus"
for token in \
  "Group revenue story" \
  "Whitespace readiness"; do
  search_fixed "${token}" "${account_summary_js}" \
    || fail "Missing account summary token: ${token}"
done

for token in \
  "Pulse360 Agent" \
  "Execution checklist"; do
  search_fixed "${token}" "${agent_panel_html}" \
    || fail "Missing agent panel token: ${token}"
done

for token in \
  "What should I do next?" \
  "Draft outreach" \
  "Test the evidence"; do
  search_fixed "${token}" "${agent_panel_js}" \
    || fail "Missing agent panel prompt token: ${token}"
done

for token in \
  "askPulse360SellerAgent" \
  "executePulse360SellerAction"; do
  search_fixed "${token}" "${agent_panel_js}" \
    || fail "Missing agent panel runtime token: ${token}"
done

for token in \
  "Recommended move" \
  "Top recommended move" \
  "Create opportunity"; do
  search_fixed "${token}" "${recommended_move_html}" \
    || fail "Missing recommended move token: ${token}"
done

for token in \
  "Timeline" \
  "Signal and account history"; do
  search_fixed "${token}" "${account_timeline_html}" \
    || fail "Missing account timeline token: ${token}"
done
search_fixed "AI narrative generated" "${account_timeline_js}" \
  || fail "Missing account timeline token: AI narrative generated"

for token in \
  "Entity focus" \
  "Choose the right entity before the seller moves" \
  "Suggested play"; do
  search_fixed "${token}" "${entity_focus_html}" \
    || fail "Missing entity focus token: ${token}"
done

for token in \
  "Evidence and trust" \
  "What is grounded versus what is uncertain" \
  "Freshness and provenance"; do
  search_fixed "${token}" "${trust_panel_html}" \
    || fail "Missing trust panel token: ${token}"
done

for token in \
  "Renewal risk" \
  "Recommended save move" \
  "Create save plan task"; do
  search_fixed "${token}" "${renewal_panel_html}" \
    || fail "Missing renewal risk token: ${token}"
done

for token in \
  "What this page should do" \
  "Before the call" \
  "After the call" \
  "Keep the seller anchored"; do
  search_fixed "${token}" "${account_guidance_html}" \
    || fail "Missing account guidance token: ${token}"
done

for path in \
  "${account_summary_meta}" \
  "${recommended_move_meta}" \
  "${account_timeline_meta}" \
  "${entity_focus_meta}" \
  "${trust_panel_meta}" \
  "${renewal_panel_meta}"; do
  search_fixed "lightning__RecordPage" "${path}" \
    || fail "Missing record-page exposure in ${path}"
  search_fixed "<object>Account</object>" "${path}" \
    || fail "Missing Account object target in ${path}"
done
pass "Account page modules expose direct composition and embedded controls"

for token in \
  "c-pulse360-planner-header" \
  "c-pulse360-planner-filter-bar" \
  "c-pulse360-planner-summary-panel" \
  "c-pulse360-planner-board" \
  "c-pulse360-planner-action-rail" \
  "c-pulse360-planner-timeline"; do
  search_fixed "${token}" "${planner_workspace_html}" \
    || fail "Missing planner modular composition token: ${token}"
done

for token in \
  "name=\"summaryMetricLimit\"" \
  "name=\"maxTimelineItems\"" \
  "name=\"showSummaryPanel\"" \
  "name=\"showTimelinePanel\"" \
  "name=\"showActionRail\"" \
  "name=\"showExecutivePrompts\""; do
  search_fixed "${token}" "${planner_workspace_meta}" \
    || fail "Missing planner workspace App Builder property token: ${token}"
done
pass "Planner workspace shell exposes dashboard and chronology controls"

pass "Surface architecture validation completed"
