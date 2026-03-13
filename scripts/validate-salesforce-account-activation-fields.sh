#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

field_dir="force-app/main/default/objects/Account/fields"
mapping="config/data-cloud/activation-field-mapping.csv"

[[ -f "sfdx-project.json" ]] || fail "Missing sfdx-project.json"
[[ -d "$field_dir" ]] || fail "Missing Salesforce Account field metadata directory"
[[ -f "$mapping" ]] || fail "Missing activation field mapping"

required_fields=(
  "Unified_Profile_Id__c"
  "Identity_Confidence__c"
  "Group_Revenue_Rollup__c"
  "Health_Score__c"
  "Cross_Sell_Propensity__c"
  "Coverage_Gap_Flag__c"
  "Competitor_Risk_Signal__c"
  "Primary_Brand_Name__c"
  "Active_Product_Count__c"
  "Engagement_Intensity_Score__c"
  "Open_Opportunity_Count__c"
  "Last_Engagement_Timestamp__c"
  "DataCloud_Last_Synced__c"
)

for field in "${required_fields[@]}"; do
  [[ -f "$field_dir/${field}.field-meta.xml" ]] || fail "Missing metadata file for $field"
done
pass "Salesforce Account activation field metadata files exist"

for field in "${required_fields[@]}"; do
  grep -q ",Account,${field}," "$mapping" || fail "Activation mapping missing Account target field $field"
done
pass "Activation mapping references all Account target fields"

if [[ -n "${TARGET_ORG:-}" ]]; then
  SF_BIN="${SF_BIN:-sf}"
  developer_names=()
  for field in "${required_fields[@]}"; do
    developer_names+=("'${field%__c}'")
  done
  developer_names_csv="$(IFS=,; echo "${developer_names[*]}")"
  query="SELECT DeveloperName FROM CustomField WHERE TableEnumOrId = 'Account' AND DeveloperName IN (${developer_names_csv})"
  actual_names="$("$SF_BIN" data query --use-tooling-api --target-org "$TARGET_ORG" --query "$query" --json \
    | jq -r '.result.records[].DeveloperName' | sort)"
  for field in "${required_fields[@]}"; do
    developer_name="${field%__c}"
    echo "$actual_names" | grep -qx "$developer_name" \
      || fail "Account field not present in org '$TARGET_ORG': $field"
  done
  pass "Account target fields exist in org '$TARGET_ORG'"
fi

pass "Salesforce Account activation field validation completed"
