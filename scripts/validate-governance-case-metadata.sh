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
snapshot_dir="force-app/main/default/lwc/pulse360GovernanceSnapshot"
match_evidence_dir="force-app/main/default/lwc/pulse360GovernanceMatchEvidence"
decision_workspace_dir="force-app/main/default/lwc/pulse360GovernanceDecisionWorkspace"
audit_outcome_dir="force-app/main/default/lwc/pulse360GovernanceAuditOutcome"
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
[[ -d "$snapshot_dir" ]] || fail "Missing pulse360GovernanceSnapshot LWC bundle"
[[ -d "$match_evidence_dir" ]] || fail "Missing pulse360GovernanceMatchEvidence LWC bundle"
[[ -d "$decision_workspace_dir" ]] || fail "Missing pulse360GovernanceDecisionWorkspace LWC bundle"
[[ -d "$audit_outcome_dir" ]] || fail "Missing pulse360GovernanceAuditOutcome LWC bundle"
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
  "Source_Product__c"
  "Data_Cloud_Review_Queue_Id__c"
  "Data_Cloud_Source_Record_Id__c"
  "Target_Entity_Name__c"
  "Country_Code__c"
  "Market__c"
  "Offering_Family__c"
  "Offer_Bundle__c"
  "Target_B2B_Customer_Ids__c"
  "Target_B2B_Customer_Names__c"
  "Recommended_Next_Actions__c"
  "Review_Priority__c"
  "Activation_Block_Reasons__c"
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

for dir in \
  "$snapshot_dir" \
  "$match_evidence_dir" \
  "$decision_workspace_dir" \
  "$audit_outcome_dir"; do
  base_name="$(basename "$dir")"
  for ext in html js js-meta.xml css; do
    [[ -f "$dir/${base_name}.${ext}" ]] || fail "Missing ${base_name} bundle file: ${base_name}.${ext}"
  done
done
pass "Pulse360 governance modular LWC bundles exist"

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
  "NEEDS_POLICY_DECISION" \
  "CSP_ACCOUNT_MAPPING_CONFIRMED" \
  "CSP_PROPOSITION_QUALIFIED" \
  "CSP_GOVERNANCE_REVIEW_REQUIRED" \
  "CSP_INSUFFICIENT_EVIDENCE"; do
  search_fixed "$token" "$field_dir/Decision_Reason_Code__c.field-meta.xml" \
    || fail "Missing decision reason code picklist value: $token"
done

for token in \
  "Approve Merge" \
  "Review" \
  "Reject Match" \
  "Map Account" \
  "Qualify Proposition" \
  "Governance Review"; do
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
  "Recommended_Action__c"; do
  search_fixed "$token" "$validation_rule_dir"/Require_*Account*.validationRule-meta.xml \
    || fail "Missing merge-only validation rule guard token: $token"
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
  "recordPulse360GovernanceDecision" \
  "getPulse360DataCloudReviewEvidence" \
  "LightningConfirm" \
  "notifyRecordUpdateAvailable" \
  "ShowToastEvent" \
  "isCasePairAccount" \
  "External_Legal_Name__c" \
  "AI_Citation_Count__c" \
  "External Evidence"; do
  search_fixed "$token" "$lwc_dir/governanceCaseReview.js-meta.xml" "$lwc_dir/governanceCaseReview.js" \
    "$lwc_dir/governanceCaseReview.html" || fail "Missing LWC token: $token"
done
pass "governanceCaseReview bundle includes expected exposure and event contract"

for token in \
  "Governance Snapshot" \
  "getPulse360ReviewContext" \
  "getPulse360DataCloudReviewEvidence" \
  "Direct Data Cloud evidence" \
  "Governance Review Manager"; do
  search_fixed "$token" "$snapshot_dir/pulse360GovernanceSnapshot.js-meta.xml" \
    "$snapshot_dir/pulse360GovernanceSnapshot.js" "$snapshot_dir/pulse360GovernanceSnapshot.html" \
    || fail "Missing governance snapshot token: $token"
done

for token in \
  "Match Evidence" \
  "External Evidence" \
  "Top Match Features" \
  "External_Legal_Name__c" \
  "AI_Citation_Count__c" \
  "CSP Smart City Proposition Evidence" \
  "Target B2B Customers"; do
  search_fixed "$token" "$match_evidence_dir/pulse360GovernanceMatchEvidence.js-meta.xml" \
    "$match_evidence_dir/pulse360GovernanceMatchEvidence.js" "$match_evidence_dir/pulse360GovernanceMatchEvidence.html" \
    || fail "Missing governance match evidence token: $token"
done

for token in \
  "Decision Workspace" \
  "recordPulse360GovernanceDecision" \
  "getPulse360DataCloudReviewEvidence" \
  "LightningConfirm" \
  "notifyRecordUpdateAvailable" \
  "isCasePairAccount" \
  "csp_smart_city_proposition_readiness" \
  "targetB2bCustomerNames" \
  "reviewPriority"; do
  search_fixed "$token" "$decision_workspace_dir/pulse360GovernanceDecisionWorkspace.js-meta.xml" \
    "$decision_workspace_dir/pulse360GovernanceDecisionWorkspace.js" "$decision_workspace_dir/pulse360GovernanceDecisionWorkspace.html" \
    || fail "Missing governance decision workspace token: $token"
done

for token in \
  "Audit and Outcome" \
  "Decision Status" \
  "Merge Execution"; do
  search_fixed "$token" "$audit_outcome_dir/pulse360GovernanceAuditOutcome.js-meta.xml" \
    "$audit_outcome_dir/pulse360GovernanceAuditOutcome.js" "$audit_outcome_dir/pulse360GovernanceAuditOutcome.html" \
    || fail "Missing governance audit outcome token: $token"
done
pass "Governance modular LWCs include expected contracts"

for token in \
  "<masterLabel>Governance Case Record Page</masterLabel>" \
  "<sobjectType>Governance_Case__c</sobjectType>" \
  "c:pulse360GovernanceSnapshot" \
  "c:pulse360GovernanceMatchEvidence" \
  "c:pulse360GovernanceDecisionWorkspace" \
  "c:pulse360GovernanceAuditOutcome"; do
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
  "Governance_Case__c.Source_Product__c" \
  "Governance_Case__c.Target_B2B_Customer_Names__c" \
  "Governance_Case__c.Review_Priority__c" \
  "Account.External_Legal_Name__c" \
  "Account.Validity_Score_External__c" \
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
