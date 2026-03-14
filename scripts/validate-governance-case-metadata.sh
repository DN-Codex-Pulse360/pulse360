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

object_meta="force-app/main/default/objects/Governance_Case__c/Governance_Case__c.object-meta.xml"
field_dir="force-app/main/default/objects/Governance_Case__c/fields"
validation_rule_dir="force-app/main/default/objects/Governance_Case__c/validationRules"
lwc_dir="force-app/main/default/lwc/governanceCaseReview"
flexipage_meta="force-app/main/default/flexipages/Governance_Case_Record_Page.flexipage-meta.xml"
tab_meta="force-app/main/default/tabs/Governance_Case__c.tab-meta.xml"
permset_meta="force-app/main/default/permissionsets/Governance_Case_Steward.permissionset-meta.xml"
decision_stamping_class="force-app/main/default/classes/GovernanceCaseDecisionStamping.cls"
decision_stamping_test_class="force-app/main/default/classes/GovernanceCaseDecisionStampingTest.cls"
decision_stamping_trigger="force-app/main/default/triggers/GovernanceCaseDecisionStamping.trigger"

[[ -f "sfdx-project.json" ]] || fail "Missing sfdx-project.json"
[[ -f "$object_meta" ]] || fail "Missing Governance_Case__c object metadata"
[[ -d "$field_dir" ]] || fail "Missing Governance_Case__c field metadata directory"
[[ -d "$validation_rule_dir" ]] || fail "Missing Governance_Case__c validation rule directory"
[[ -d "$lwc_dir" ]] || fail "Missing governanceCaseReview LWC bundle"
[[ -f "$flexipage_meta" ]] || fail "Missing Governance Case Lightning Record Page metadata"
[[ -f "$tab_meta" ]] || fail "Missing Governance Case custom tab metadata"
[[ -f "$permset_meta" ]] || fail "Missing Governance Case steward permission set metadata"
[[ -f "$decision_stamping_class" ]] || fail "Missing Governance Case decision stamping Apex class"
[[ -f "$decision_stamping_test_class" ]] || fail "Missing Governance Case decision stamping Apex test class"
[[ -f "$decision_stamping_trigger" ]] || fail "Missing Governance Case decision stamping trigger"

required_fields=(
  "Candidate_Pair_Id__c"
  "Status__c"
  "Priority__c"
  "Decision_Owner__c"
  "Decision_Status__c"
  "Left_Account__c"
  "Right_Account__c"
  "Surviving_Account__c"
  "Merged_Account__c"
  "Duplicate_Confidence__c"
  "Confidence_Band__c"
  "Recommended_Action__c"
  "Review_Flag__c"
  "Hierarchy_Conflict_Flag__c"
  "Hierarchy_Impact_Summary__c"
  "Source_Snapshot_Id__c"
  "Evidence_Run_Id__c"
  "Evidence_Run_Timestamp__c"
  "Model_Version__c"
  "Top_Match_Features__c"
  "Feature_Explanations__c"
  "Attribute_Validity_Payload__c"
  "Decision_Reason_Code__c"
  "Decision_Reason_Text__c"
  "Review_Followup_Required__c"
  "Decided_By__c"
  "Decided_At__c"
  "Audit_Event_Id__c"
  "Downstream_Update_Status__c"
  "Merge_Execution_Status__c"
  "Merge_Executed_By__c"
  "Merge_Executed_At__c"
)

for field in "${required_fields[@]}"; do
  [[ -f "$field_dir/${field}.field-meta.xml" ]] || fail "Missing Governance_Case__c field metadata: $field"
done
pass "Governance_Case__c field metadata files exist"

required_validation_rules=(
  "Require_Reason_On_Final_Decision"
  "Require_Surviving_Account_On_Approval"
  "Require_Merged_Account_On_Approval"
  "Require_Surviving_Account_From_Case_Pair"
  "Require_Merged_Account_From_Case_Pair"
  "Prevent_Same_Merge_Accounts"
)

for rule in "${required_validation_rules[@]}"; do
  [[ -f "$validation_rule_dir/${rule}.validationRule-meta.xml" ]] \
    || fail "Missing Governance_Case__c validation rule metadata: $rule"
done
pass "Governance_Case__c validation rule metadata exists"

for file in governanceCaseReview.html governanceCaseReview.js governanceCaseReview.js-meta.xml governanceCaseReview.css; do
  [[ -f "$lwc_dir/$file" ]] || fail "Missing governanceCaseReview bundle file: $file"
done
pass "governanceCaseReview LWC bundle exists"

for token in \
  "FINAL_DECISION_STATUSES" \
  "Decided_By__c = UserInfo.getUserId()" \
  "Decided_At__c = System.now()" \
  "Merge_Execution_Status__c = 'Ready for Merge'"; do
  search_fixed "$token" "$decision_stamping_class" || fail "Missing decision stamping token: $token"
done

search_fixed "GovernanceCaseDecisionStamping.apply(Trigger.new, Trigger.oldMap);" "$decision_stamping_trigger" \
  || fail "Missing trigger handler invocation"

for token in \
  "@IsTest" \
  "stampsApprovedDecisionAndMergeStatus" \
  "stampsRejectedDecisionWithoutMergePreparation"; do
  search_fixed "$token" "$decision_stamping_test_class" || fail "Missing decision stamping test token: $token"
done
pass "Governance Case decision stamping automation exists"

for token in \
  "<label>Governance Case</label>" \
  "<pluralLabel>Governance Cases</pluralLabel>" \
  "<enableHistory>true</enableHistory>"; do
  search_fixed "$token" "$object_meta" || fail "Missing object metadata token: $token"
done
pass "Governance_Case__c object metadata includes required baseline"

for token in \
  "CLEAR_DUPLICATE_MATCH" \
  "FALSE_POSITIVE_MODEL_OUTPUT" \
  "NEEDS_POLICY_DECISION"; do
  search_fixed "$token" "$field_dir/Decision_Reason_Code__c.field-meta.xml" \
    || fail "Missing decision reason code picklist value: $token"
done

for token in \
  "Approve Merge" \
  "Review" \
  "Reject Match"; do
  search_fixed "$token" "$field_dir/Recommended_Action__c.field-meta.xml" \
    || fail "Missing recommended action picklist value: $token"
done

for token in \
  "New" \
  "Ready for Review" \
  "Closed"; do
  search_fixed "$token" "$field_dir/Status__c.field-meta.xml" \
    || fail "Missing case status picklist value: $token"
done

for token in \
  "Not Started" \
  "Ready for Merge" \
  "Completed"; do
  search_fixed "$token" "$field_dir/Merge_Execution_Status__c.field-meta.xml" \
    || fail "Missing merge execution status picklist value: $token"
done
pass "Picklist fields include required stewardship values"

for token in \
  "lightning__RecordPage" \
  "Governance_Case__c" \
  "decisionaction" \
  "updateRecord" \
  "ShowToastEvent" \
  "isCasePairAccount"; do
  search_fixed "$token" "$lwc_dir/governanceCaseReview.js-meta.xml" "$lwc_dir/governanceCaseReview.js" \
    || fail "Missing LWC token: $token"
done
pass "governanceCaseReview bundle includes expected exposure and event contract"

for token in \
  "<masterLabel>Governance Case Record Page</masterLabel>" \
  "<sobjectType>Governance_Case__c</sobjectType>" \
  "c:governanceCaseReview"; do
  search_fixed "$token" "$flexipage_meta" || fail "Missing FlexiPage token: $token"
done
pass "Governance Case Lightning Record Page metadata exists"

for token in \
  "<customObject>true</customObject>" \
  "Governance Case"; do
  search_fixed "$token" "$tab_meta" || fail "Missing custom tab token: $token"
done
pass "Governance Case custom tab metadata exists"

for token in \
  "<label>Governance Case Steward</label>" \
  "Governance_Case__c.Recommended_Action__c" \
  "<tab>Governance_Case__c</tab>"; do
  search_fixed "$token" "$permset_meta" || fail "Missing permission set token: $token"
done

for token in \
  "<editable>false</editable><field>Governance_Case__c.Decided_At__c</field>" \
  "<editable>false</editable><field>Governance_Case__c.Decided_By__c</field>" \
  "<editable>false</editable><field>Governance_Case__c.Merge_Executed_At__c</field>" \
  "<editable>false</editable><field>Governance_Case__c.Merge_Executed_By__c</field>" \
  "<editable>false</editable><field>Governance_Case__c.Merge_Execution_Status__c</field>"; do
  search_fixed "$token" "$permset_meta" || fail "Missing system-managed field protection token: $token"
done
pass "Governance Case steward permission set metadata exists"

pass "Governance case metadata validation completed"
