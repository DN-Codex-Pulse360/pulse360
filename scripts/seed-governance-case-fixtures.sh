#!/usr/bin/env bash
set -euo pipefail

TARGET_ORG="${TARGET_ORG:-pulse360-dev}"

create_account() {
  local name="$1"
  local website="$2"
  local country="$3"
  local response
  response="$(sf data create record \
    --target-org "$TARGET_ORG" \
    --sobject Account \
    --values "Name='$name' Website='$website' BillingCountry='$country'" \
    --json)"
  jq -e -r '.result.id // empty' <<<"$response"
}

create_case() {
  local values="$1"
  local response
  response="$(sf data create record \
    --target-org "$TARGET_ORG" \
    --sobject Governance_Case__c \
    --values "$values" \
    --json)"
  jq -e -r '.result.id // empty' <<<"$response"
}

acme_primary_id="$(create_account "Acme Industrial Holdings" "https://acme-industrial.example.com" "United States")"
acme_duplicate_id="$(create_account "Acme Industrial Holding Ltd" "https://acme-industrial.example.com" "United States")"
globex_parent_id="$(create_account "Globex APAC Holdings" "https://globex-apac.example.com" "Singapore")"
globex_sub_id="$(create_account "Globex APAC Pte Ltd" "https://globex-apac.example.com/sg" "Singapore")"

approve_case_id="$(create_case "Candidate_Pair_Id__c='PAIR-ACME-001' Status__c='Ready for Review' Priority__c='High' Left_Account__c='$acme_primary_id' Right_Account__c='$acme_duplicate_id' Surviving_Account__c='$acme_primary_id' Merged_Account__c='$acme_duplicate_id' Duplicate_Confidence__c='98.4' Confidence_Band__c='High' Recommended_Action__c='Approve Merge' Review_Flag__c='false' Top_Match_Features__c='name_exact,domain_exact,address_similarity' Feature_Explanations__c='Exact website and near-identical legal names indicate duplicate corporate accounts.' Attribute_Validity_Payload__c='domain_score:99; billing_country_score:96' Hierarchy_Conflict_Flag__c='false' Hierarchy_Impact_Summary__c='No hierarchy conflict detected. Merge into the surviving top-level account.' Source_Snapshot_Id__c='snapshot_acme_001' Evidence_Run_Id__c='run_acme_001' Evidence_Run_Timestamp__c='2026-03-11T07:30:00.000Z' Model_Version__c='pulse360-dedupe-v1' Merge_Execution_Status__c='Not Started'")"

review_case_id="$(create_case "Candidate_Pair_Id__c='PAIR-GLOBEX-001' Status__c='Ready for Review' Priority__c='Medium' Left_Account__c='$globex_parent_id' Right_Account__c='$globex_sub_id' Duplicate_Confidence__c='78.2' Confidence_Band__c='Medium' Recommended_Action__c='Review' Review_Flag__c='true' Top_Match_Features__c='brand_match,regional_domain_overlap,parent_name_similarity' Feature_Explanations__c='Records may represent a parent and subsidiary rather than a duplicate.' Attribute_Validity_Payload__c='brand_name_score:87; billing_country_score:94; legal_entity_score:61' Hierarchy_Conflict_Flag__c='true' Hierarchy_Impact_Summary__c='Potential parent-child structure detected. Validate hierarchy before merge.' Source_Snapshot_Id__c='snapshot_globex_001' Evidence_Run_Id__c='run_globex_001' Evidence_Run_Timestamp__c='2026-03-11T07:30:00.000Z' Model_Version__c='pulse360-dedupe-v1' Merge_Execution_Status__c='Skipped'")"

cat <<EOF
Seeded Accounts:
- Acme Industrial Holdings: $acme_primary_id
- Acme Industrial Holding Ltd: $acme_duplicate_id
- Globex APAC Holdings: $globex_parent_id
- Globex APAC Pte Ltd: $globex_sub_id

Seeded Governance Cases:
- Approve Merge example: $approve_case_id
- Hierarchy Review example: $review_case_id
EOF
