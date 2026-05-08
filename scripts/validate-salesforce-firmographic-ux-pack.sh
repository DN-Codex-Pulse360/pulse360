#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

contract="$repo_root/docs/contracts/salesforce-firmographic-intelligence-ux-contract.md"
runbook="$repo_root/docs/runbook/salesforce-firmographic-intelligence-ux-runbook.md"
report_config="$repo_root/config/salesforce/firmographic-intelligence-reports.csv"
surface_config="$repo_root/config/salesforce/account-firmographic-intelligence-surface.yaml"
evidence="$repo_root/docs/evidence/pulse360-live-data-platform-status-2026-05-01.md"

[[ -f "$contract" ]] || fail "Missing Salesforce firmographic UX contract"
[[ -f "$runbook" ]] || fail "Missing Salesforce firmographic UX runbook"
[[ -f "$report_config" ]] || fail "Missing Salesforce report/dashboard config"
[[ -f "$surface_config" ]] || fail "Missing Account firmographic surface config"
[[ -f "$evidence" ]] || fail "Missing live platform evidence document"

required_reports=(
  "Account_and_Firmographic"
  "Account_and_Evidence"
  "Account_and_Classification"
  "Account_and_Corporate_Linkage"
  "Account_and_Sovereign_Identifier"
)

required_dmos=(
  "Pulse360_Firmographic_Profile__dlm"
  "Pulse360_Firmographic_Source_Evidenc__dlm"
  "Pulse_360_Company_Classification__dlm"
  "Pulse360_Corporate_Linkage__dlm"
  "Pulse360_Sovereign_Identifier__dlm"
)

for report in "${required_reports[@]}"; do
  grep -Fq "$report" "$report_config" || fail "Report config missing $report"
done

for report_file in \
  "$repo_root/force-app/main/default/reports/Pulse360_Account_Intelligence_Validation/Account_and_Firmographic_iIW1.report-meta.xml" \
  "$repo_root/force-app/main/default/reports/Pulse360_Account_Intelligence_Validation/Account_and_Evidence_4W81.report-meta.xml" \
  "$repo_root/force-app/main/default/reports/Pulse360_Account_Intelligence_Validation/Account_and_Classification_qlX1.report-meta.xml" \
  "$repo_root/force-app/main/default/reports/Pulse360_Account_Intelligence_Validation/Account_and_Corporate_Linkage_U4F1.report-meta.xml" \
  "$repo_root/force-app/main/default/reports/Pulse360_Account_Intelligence_Validation/Account_and_Sovereign_Identifier_NOY1.report-meta.xml"; do
  [[ -f "$report_file" ]] || fail "Missing source-controlled report metadata: $report_file"
done

[[ -f "$repo_root/force-app/main/default/reports/Pulse360_Account_Intelligence_Validation-meta.xml" ]] \
  || fail "Missing source-controlled report folder metadata"
[[ -f "$repo_root/force-app/main/default/dashboards/Pulse360_Account_Intelligence_Validation-meta.xml" ]] \
  || fail "Missing source-controlled dashboard folder metadata"
dashboard_file="$repo_root/force-app/main/default/dashboards/Pulse360_Account_Intelligence_Validation/zZUAzaLhrPFnOpTDCJvUEUvPEQIohz.dashboard-meta.xml"
[[ -f "$dashboard_file" ]] || fail "Missing source-controlled dashboard metadata"

if grep -R "dnortje." "$repo_root/force-app/main/default/reports/Pulse360_Account_Intelligence_Validation-meta.xml" \
    "$repo_root/force-app/main/default/dashboards/Pulse360_Account_Intelligence_Validation-meta.xml" \
    "$dashboard_file" >/dev/null; then
  fail "Deployable folder/dashboard metadata must not include user-specific shares or running users"
fi

for dmo in "${required_dmos[@]}"; do
  grep -Fq "$dmo" "$contract" || fail "UX contract missing DMO $dmo"
  grep -Fq "$dmo" "$surface_config" || fail "Surface config missing DMO $dmo"
  grep -Fq "$dmo" "$evidence" || fail "Evidence document missing DMO $dmo"
done

grep -Fq "Pulse360 Account Intelligence Validation" "$report_config" \
  || fail "Report config missing target folder"
grep -Fq "Pulse360 Account Intelligence Validation" "$report_config" \
  || fail "Report config missing dashboard target"
grep -Fq "Accounts Enriched" "$dashboard_file" \
  || fail "Dashboard metadata missing Accounts Enriched scorecard tile"
grep -Fq "Sovereign IDs" "$dashboard_file" \
  || fail "Dashboard metadata missing Sovereign IDs scorecard tile"
grep -Fq "<dashboardType>LoggedInUser</dashboardType>" "$dashboard_file" \
  || fail "Dashboard metadata must avoid a user-specific running user"
grep -Fq "source_account_id__c -> Account.Id" "$contract" \
  || fail "UX contract missing Account relationship rule"
grep -Fq "source_account_id__c" "$surface_config" \
  || fail "Surface config missing Account join key"
grep -Fq "read-only" "$contract" \
  || fail "UX contract must keep Data Cloud intelligence read-only"
grep -Fq "editable: false" "$surface_config" \
  || fail "Surface config must make Data Cloud intelligence non-editable"
grep -Fq "Private Reports" "$runbook" \
  || fail "Runbook must document private-report promotion"
grep -Fq "Report execution validation through the Salesforce Analytics REST API" "$evidence" \
  || fail "Evidence document missing Salesforce report execution validation"

python3 - "$report_config" <<'PY'
import csv
import sys

path = sys.argv[1]
with open(path, newline="", encoding="utf-8") as handle:
    rows = list(csv.DictReader(handle))

reports = [row for row in rows if row["artifact_type"] == "report"]
dashboards = [row for row in rows if row["artifact_type"] == "dashboard"]

if len(reports) != 5:
    raise SystemExit(f"Expected 5 report rows, found {len(reports)}")
if len(dashboards) != 1:
    raise SystemExit(f"Expected 1 dashboard row, found {len(dashboards)}")
dashboard = dashboards[0]
if dashboard["promoted_report_id"] != "01ZdL00000ABncLUAT":
    raise SystemExit("Dashboard row must include the live dashboard id")
if dashboard["promoted_developer_name"] != "zZUAzaLhrPFnOpTDCJvUEUvPEQIohz":
    raise SystemExit("Dashboard row must include the live dashboard developer name")

expected_counts = {
    "Account_and_Firmographic": "18",
    "Account_and_Evidence": "140",
    "Account_and_Classification": "11",
    "Account_and_Corporate_Linkage": "2",
    "Account_and_Sovereign_Identifier": "0",
}
for row in reports:
    name = row["developer_name"]
    expected = expected_counts.get(name)
    if expected is None:
        raise SystemExit(f"Unexpected report {name}")
    if row["row_count_expectation"] != expected:
        raise SystemExit(
            f"{name} expected count {expected}, found {row['row_count_expectation']}"
        )
    if not row["promoted_report_id"].startswith("00O"):
        raise SystemExit(f"{name} is missing promoted report id")
    if not row["promoted_developer_name"]:
        raise SystemExit(f"{name} is missing promoted developer name")
    if "source_account_id__c" != row["relationship_key"]:
        raise SystemExit(f"{name} must join by source_account_id__c")
    if (
        "source_url__c" not in row["required_columns"]
        and "primary_source_url__c" not in row["required_columns"]
    ):
        raise SystemExit(f"{name} must expose source URL or provenance")

print("[PASS] Salesforce firmographic report/dashboard CSV contract is valid")
PY

pass "Salesforce firmographic UX pack validation completed"
