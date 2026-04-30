#!/usr/bin/env bash
set -euo pipefail

TARGET_ORG="${TARGET_ORG:-pulse360-dev}"
SF_BIN="${SF_BIN:-sf}"
API_VERSION="${API_VERSION:-66.0}"

org_display_json="$("$SF_BIN" org display --target-org "$TARGET_ORG" --verbose --json)"
INSTANCE_URL="$(jq -r '.result.instanceUrl' <<<"$org_display_json")"
ACCESS_TOKEN="$(jq -r '.result.accessToken' <<<"$org_display_json")"

create_sobject() {
  local sobject="$1"
  local payload="$2"
  local response
  response="$(curl -sS \
    -X POST \
    "$INSTANCE_URL/services/data/v$API_VERSION/sobjects/$sobject" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$payload")"
  jq -e -r '.id // empty' <<<"$response" || {
    echo "$response" >&2
    return 1
  }
}

update_sobject() {
  local sobject="$1"
  local record_id="$2"
  local payload="$3"
  local response
  response="$(curl -sS \
    -X PATCH \
    "$INSTANCE_URL/services/data/v$API_VERSION/sobjects/$sobject/$record_id" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$payload" \
    -o /dev/null \
    -w "%{http_code}")"
  [[ "$response" == "204" ]] || {
    echo "Failed to update $sobject/$record_id (HTTP $response)" >&2
    return 1
  }
}

create_account() {
  local payload="$1"
  create_sobject "Account" "$payload"
}

create_case() {
  local payload="$1"
  create_sobject "Governance_Case__c" "$payload"
}

singtel_sources='[{"source_id":"singtel_fy2025_results","source_name":"Singtel FY2025 Financial Results","source_type":"annual_report","source_url":"https://www.singtel.com/content/dam/singtel/investorRelations/stockExchange/2025/FY25-MDA.pdf","document_date":"2025-05-22","accessed_at":"2026-03-28T00:00:00Z","excerpt":"Operating revenue remained stable for FY2025 while net profit increased.","jurisdiction":"SG"},{"source_id":"singtel_aida_jobs","source_name":"Singtel AIDA Jobs","source_type":"careers","source_url":"https://groupcareers.singtel.com/go/Jobs-at-Singtel/4567910/","document_date":"2026-02-15","accessed_at":"2026-03-28T00:00:00Z","excerpt":"Singtel advertised AIDA and AI platform engineering roles in Singapore.","jurisdiction":"SG"}]'
singtel_actions='[{"rank":1,"action_type":"create_opportunity","target":"NCS data and AI modernization program","reasoning":"FY2025 disclosures and current AI hiring support the account opportunity.","estimated_revenue_impact":"S$12M influenced pipeline","confidence":0.84,"source_ids":["singtel_fy2025_results","singtel_aida_jobs"]}]'
singtel_hierarchy='{"group_id":"grp_singtel","parent_account_id":null,"canonical_account_id":"ent_sg_001","account_name":"Singtel Group","children":[{"entity_id":"ent_sg_001","name":"Singtel Group","role":"Current account anchor","coverage_status":"covered","in_crm":true,"signal":"Core Singtel coverage exists in CRM, but the operating group is only partially represented."},{"entity_id":"ent_sg_002","name":"NCS Pte. Ltd.","role":"CRM-covered delivery subsidiary","coverage_status":"covered","in_crm":true,"signal":"NCS is already represented in CRM and is the clearest data and AI expansion path.","suggested_play":"Data and AI modernization"},{"entity_id":"ent_sg_003","name":"Optus","role":"Whitespace growth entity","coverage_status":"uncovered","in_crm":false,"signal":"Public disclosures position Optus as a growth engine, but the seller cannot work it directly from CRM yet.","suggested_play":"Group coverage follow-up"}]}'
singtel_signal='{"routing_version":"pulse360-intent-routing-v1","signal_score":75,"signal_label":"Coverage-led review","threshold_label":"Coverage gaps and commercial potential crossed the routed-review threshold.","route_to":"account_owner_plus_coverage","routing_confidence":0.91,"why_now":"Singtel combines whitespace potential with a group coverage gap, so the routed follow-up should confirm who actually owns the next motion.","drafted_outreach":"Pulse360 flagged Singtel Group because coverage is incomplete across the commercial group and the next owner needs to be confirmed. Lead with Singtel and validate the next sponsor path.","channel_readiness":"salesforce_preview","top_drivers":["Whitespace readiness is elevated.","Engagement context suggests the account can absorb routed follow-up now.","Coverage is incomplete across the group, so route clarity needs review."],"generated_at":"2026-03-28T09:00:00Z"}'

ayala_sources='[{"source_id":"ayala_ir_2024","source_name":"Ayala Integrated Report 2024","source_type":"annual_report","source_url":"https://ayala.com/app/uploads/2025/04/Ayala_IR2024_Full-Report_1004.pdf","document_date":"2025-04-11","accessed_at":"2026-03-28T00:00:00Z","excerpt":"Sale of goods and rendering services increased 12 percent to PHP 325.7 billion and core net income reached PHP 45.0 billion.","jurisdiction":"PH"},{"source_id":"ayala_internship_2026","source_name":"Ayala 2026 Internship Announcement","source_type":"news","source_url":"https://ayala.com/stories/","document_date":"2026-02-27","accessed_at":"2026-03-28T00:00:00Z","excerpt":"Ayala highlighted investment in next-generation talent through its 2026 internship announcement.","jurisdiction":"PH"}]'
ayala_actions='[{"rank":1,"action_type":"create_task","target":"Validate uncovered Ayala group coverage","reasoning":"The public portfolio is broader than the current CRM footprint represented in the prototype.","estimated_revenue_impact":"Improved account planning accuracy","confidence":0.82,"source_ids":["ayala_ir_2024"]},{"rank":2,"action_type":"escalate_governance","target":"Review Ayala duplicate pair","reasoning":"Two CRM records map to the same externally validated legal entity.","estimated_revenue_impact":"Higher data trust for account teams","confidence":0.91,"source_ids":["ayala_ir_2024","ayala_internship_2026"]}]'
ayala_hierarchy='{"group_id":"grp_ayala","parent_account_id":null,"canonical_account_id":"ent_ph_001","account_name":"Ayala Corporation","children":[{"entity_id":"ent_ph_001","name":"Ayala Corporation","role":"Current account anchor","coverage_status":"covered","in_crm":true,"signal":"This anchor account is in CRM, but the wider Ayala operating footprint is not fully action-ready."},{"entity_id":"ent_ph_001_dup","name":"Ayala Corp.","role":"Duplicate CRM variant","coverage_status":"duplicate","in_crm":true,"signal":"A second CRM variant exists for the same commercial group, which can dilute seller trust and ownership clarity.","suggested_play":"Resolve duplicate ownership"},{"entity_id":"ent_ph_003","name":"ACMobility","role":"Mobility whitespace entity","coverage_status":"uncovered","in_crm":false,"signal":"Ayala portfolio disclosures point to mobility expansion that is not represented as a seller-ready entity in CRM.","suggested_play":"Mobility data platform whitespace"},{"entity_id":"ent_ph_004","name":"AC Logistics","role":"Logistics whitespace entity","coverage_status":"uncovered","in_crm":false,"signal":"Public portfolio evidence shows logistics expansion that is still absent from the current CRM coverage map.","suggested_play":"Logistics planning and visibility review"}]}'
ayala_signal='{"routing_version":"pulse360-intent-routing-v1","signal_score":81,"signal_label":"Route now","threshold_label":"Whitespace and engagement crossed the route-now threshold.","route_to":"account_owner_plus_coverage","routing_confidence":0.88,"why_now":"Ayala has enough commercial room, engagement, and coverage complexity to justify an immediate routed follow-up.","drafted_outreach":"Pulse360 flagged Ayala Corporation because the wider group opportunity is larger than the current CRM footprint. Lead with group coverage validation and confirm the next sponsor path.","channel_readiness":"salesforce_preview","top_drivers":["Whitespace readiness is elevated.","Engagement context suggests the account can absorb routed follow-up now.","Coverage is incomplete across the group, so route clarity needs review."],"generated_at":"2026-03-28T09:00:00Z"}'

jgs_sources='[{"source_id":"jgs_ir_2024","source_name":"JG Summit 2024 Annual and Sustainability Report","source_type":"annual_report","source_url":"https://www.jgsummit.com.ph/annualreport2024/documents/JG%20Summit%202024%20Annual%20%26%20Sustainability%20Report%20%5BInteractive%20PDF%5D.pdf","document_date":"2024-12-31","accessed_at":"2026-03-28T00:00:00Z","excerpt":"JG Summit reported 2024 revenues of PHP 378.6 billion and highlighted digital and ecosystem programs.","jurisdiction":"PH"},{"source_id":"jgs_digital_transformation_2024","source_name":"JG Summit Digital Transformation and Customer Centricity","source_type":"annual_report_section","source_url":"https://www.jgsummit.com.ph/annualreport2024/strategic-enablers/digital-transformation-customer-centricity","document_date":"2024-12-31","accessed_at":"2026-03-28T00:00:00Z","excerpt":"JG Summit highlighted GenAI, data science, and digital transformation programs across the group.","jurisdiction":"PH"}]'
jgs_actions='[{"rank":1,"action_type":"create_opportunity","target":"GoTyme and rewards analytics account review","reasoning":"Annual report evidence shows analytics and fintech expansion in the group.","estimated_revenue_impact":"PHP 120M influenced expansion pipeline","confidence":0.79,"source_ids":["jgs_ir_2024","jgs_digital_transformation_2024"]}]'
jgs_hierarchy='{"group_id":"grp_jgs","parent_account_id":null,"canonical_account_id":"ent_ph_002","account_name":"JG Summit Holdings, Inc.","children":[{"entity_id":"ent_ph_002","name":"JG Summit Holdings, Inc.","role":"Current account anchor","coverage_status":"covered","in_crm":true,"signal":"The parent account is in CRM, but most of the commercial group is still outside the seller operating surface."},{"entity_id":"ent_ph_003","name":"Cebu Pacific","role":"Travel and loyalty whitespace entity","coverage_status":"uncovered","in_crm":false,"signal":"Travel and ecosystem signals create room for loyalty, customer data, and digital engagement plays.","suggested_play":"Customer data and loyalty modernization"},{"entity_id":"ent_ph_004","name":"Universal Robina Corporation","role":"Consumer analytics whitespace entity","coverage_status":"uncovered","in_crm":false,"signal":"Consumer-scale group operations suggest an unmet analytics and planning opportunity outside the current CRM footprint.","suggested_play":"Consumer demand and retail analytics"},{"entity_id":"ent_ph_005","name":"GoTyme Bank","role":"Digital banking whitespace entity","coverage_status":"uncovered","in_crm":false,"signal":"Annual report evidence ties the group to digital banking and rewards momentum, making GoTyme the clearest next commercial move.","suggested_play":"Rewards analytics and digital banking growth"}]}'
jgs_signal='{"routing_version":"pulse360-intent-routing-v1","signal_score":70,"signal_label":"Queue for review","threshold_label":"The account has enough context to justify a routed review instead of another manual pass.","route_to":"account_owner_plus_coverage","routing_confidence":0.84,"why_now":"JG Summit has enough engagement and whitespace context to justify a routed review before another manual portfolio pass.","drafted_outreach":"Pulse360 flagged JG Summit Holdings, Inc. because digital and ecosystem growth signals justify a targeted follow-up. Lead with the most credible group play and confirm the next sponsor conversation.","channel_readiness":"salesforce_preview","top_drivers":["Commercial room exists but still needs qualification.","Engagement context suggests the account can absorb routed follow-up now.","Coverage is incomplete across the group, so route clarity needs review."],"generated_at":"2026-03-28T09:00:00Z"}'

singtel_payload="$(jq -n \
  --arg name "Singtel Group" \
  --arg billingCountry "Singapore" \
  --arg unifiedProfileId "ucp_singtel_001" \
  --arg externalLegalName "Singapore Telecommunications Limited" \
  --arg aiNarrative "Singtel public disclosures and current AI hiring signal a strong SG anchor account with partial CRM group coverage." \
  --arg aiNarrativeGeneratedAt "2026-03-28T09:00:00.000Z" \
  --arg enrichmentRunId "run_public_regional_20260328" \
  --arg aiModelId "gpt-5.4" \
  --arg aiPromptVersion "pulse360-public-regional-v1" \
  --arg aiSourceRefs "$singtel_sources" \
  --arg aiRecommendedActions "$singtel_actions" \
  --arg hierarchyPayload "$singtel_hierarchy" \
  --arg intentSignalPayload "$singtel_signal" \
  '{
    Name: $name,
    BillingCountry: $billingCountry,
    Unified_Profile_Id__c: $unifiedProfileId,
    Identity_Confidence__c: 97,
    Group_Revenue_Rollup__c: 14146100000,
    Group_Revenue_Visible__c: 10400000000,
    Health_Score__c: 88,
    Cross_Sell_Propensity__c: 82,
    Coverage_Gap_Flag__c: true,
    Competitor_Risk_Signal__c: 67,
    Primary_Brand_Name__c: "Singtel",
    Active_Product_Count__c: 9,
    Engagement_Intensity_Score__c: 79,
    Open_Opportunity_Count__c: 4,
    Last_Engagement_Timestamp__c: "2026-03-01T00:00:00.000Z",
    DataCloud_Last_Synced__c: "2026-03-28T09:00:00.000Z",
    External_Legal_Name__c: $externalLegalName,
    Externally_Validated__c: true,
    Validity_Score_External__c: 93,
    External_Subsidiaries_Found__c: 1,
    AI_Narrative__c: $aiNarrative,
    AI_Recommended_Actions__c: $aiRecommendedActions,
    AI_Narrative_Generated__c: $aiNarrativeGeneratedAt,
    Enrichment_Run_Id__c: $enrichmentRunId,
    Regulatory_Readiness_Score__c: 72,
    Duplicate_Exposure_Count__c: 0,
    Group_Known_Subsidiary_Count__c: 3,
    CRM_Covered_Subsidiary_Count__c: 2,
    External_Revenue_Confirmed__c: 14146100000,
    AI_Model_Id__c: $aiModelId,
    AI_Prompt_Version__c: $aiPromptVersion,
    AI_Source_Refs__c: $aiSourceRefs,
    AI_Citation_Count__c: 2,
    Hierarchy_Payload__c: $hierarchyPayload,
    Intent_Signal_Payload__c: $intentSignalPayload
  }')"
singtel_id="$(create_account "$singtel_payload")"

ncs_payload="$(jq -n \
  --arg parentId "$singtel_id" \
  '{
    Name: "NCS Pte. Ltd.",
    ParentId: $parentId,
    BillingCountry: "Singapore",
    Unified_Profile_Id__c: "ucp_singtel_002",
    Identity_Confidence__c: 93,
    Health_Score__c: 81,
    Group_Revenue_Rollup__c: 14146100000,
    Group_Revenue_Visible__c: 10400000000,
    Primary_Brand_Name__c: "NCS",
    External_Legal_Name__c: "NCS Pte. Ltd.",
    Externally_Validated__c: true,
    Validity_Score_External__c: 90,
    AI_Model_Id__c: "gpt-5.4",
    AI_Prompt_Version__c: "pulse360-public-regional-v1"
  }')"
ncs_id="$(create_account "$ncs_payload")"

singtel_actions_live="$(jq -cn --arg ncsId "$ncs_id" '[
  {
    rank: 1,
    action_type: "create_opportunity",
    target: "NCS data and AI modernization program",
    target_record_id: $ncsId,
    reasoning: "FY2025 disclosures and current AI hiring support the account opportunity.",
    estimated_revenue_impact: "S$12M influenced pipeline",
    confidence: 0.84,
    source_ids: ["singtel_fy2025_results", "singtel_aida_jobs"]
  }
]')"
singtel_hierarchy_live="$(jq -cn --arg singtelId "$singtel_id" --arg ncsId "$ncs_id" '{
  group_id: "grp_singtel",
  parent_account_id: null,
  canonical_account_id: "ent_sg_001",
  account_name: "Singtel Group",
  children: [
    {
      entity_id: "ent_sg_001",
      crm_record_id: $singtelId,
      name: "Singtel Group",
      role: "Current account anchor",
      coverage_status: "covered",
      in_crm: true,
      signal: "Core Singtel coverage exists in CRM, but the operating group is only partially represented."
    },
    {
      entity_id: "ent_sg_002",
      crm_record_id: $ncsId,
      name: "NCS Pte. Ltd.",
      role: "CRM-covered delivery subsidiary",
      coverage_status: "covered",
      in_crm: true,
      signal: "NCS is already represented in CRM and is the clearest data and AI expansion path.",
      suggested_play: "Data and AI modernization"
    },
    {
      entity_id: "ent_sg_003",
      crm_record_id: null,
      name: "Optus",
      role: "Whitespace growth entity",
      coverage_status: "uncovered",
      in_crm: false,
      signal: "Public disclosures position Optus as a growth engine, but the seller cannot work it directly from CRM yet.",
      suggested_play: "Group coverage follow-up"
    }
  ]
}')"
update_sobject "Account" "$singtel_id" "$(jq -cn --arg aiRecommendedActions "$singtel_actions_live" --arg hierarchyPayload "$singtel_hierarchy_live" --arg intentSignalPayload "$singtel_signal" '{AI_Recommended_Actions__c: $aiRecommendedActions, Hierarchy_Payload__c: $hierarchyPayload, Intent_Signal_Payload__c: $intentSignalPayload}')"

ayala_primary_payload="$(jq -n \
  --arg aiNarrative "Ayala public evidence shows a broader PH operating footprint than the current CRM sample, creating coverage and whitespace opportunities." \
  --arg aiNarrativeGeneratedAt "2026-03-28T09:00:00.000Z" \
  --arg enrichmentRunId "run_public_regional_20260328" \
  --arg aiModelId "gpt-5.4" \
  --arg aiPromptVersion "pulse360-public-regional-v1" \
  --arg aiSourceRefs "$ayala_sources" \
  --arg aiRecommendedActions "$ayala_actions" \
  --arg hierarchyPayload "$ayala_hierarchy" \
  --arg intentSignalPayload "$ayala_signal" \
  '{
    Name: "Ayala Corporation",
    BillingCountry: "Philippines",
    Unified_Profile_Id__c: "ucp_ayala_001",
    Identity_Confidence__c: 95,
    Group_Revenue_Rollup__c: 325700000000,
    Group_Revenue_Visible__c: 184000000000,
    Health_Score__c: 84,
    Cross_Sell_Propensity__c: 86,
    Coverage_Gap_Flag__c: true,
    Competitor_Risk_Signal__c: 58,
    Primary_Brand_Name__c: "Ayala",
    Active_Product_Count__c: 11,
    Engagement_Intensity_Score__c: 76,
    Open_Opportunity_Count__c: 6,
    Last_Engagement_Timestamp__c: "2026-02-27T00:00:00.000Z",
    DataCloud_Last_Synced__c: "2026-03-28T09:00:00.000Z",
    External_Legal_Name__c: "Ayala Corporation",
    Externally_Validated__c: true,
    Validity_Score_External__c: 92,
    External_Subsidiaries_Found__c: 2,
    AI_Narrative__c: $aiNarrative,
    AI_Recommended_Actions__c: $aiRecommendedActions,
    AI_Narrative_Generated__c: $aiNarrativeGeneratedAt,
    Enrichment_Run_Id__c: $enrichmentRunId,
    Regulatory_Readiness_Score__c: 78,
    Duplicate_Exposure_Count__c: 1,
    Group_Known_Subsidiary_Count__c: 4,
    CRM_Covered_Subsidiary_Count__c: 2,
    External_Revenue_Confirmed__c: 325700000000,
    AI_Model_Id__c: $aiModelId,
    AI_Prompt_Version__c: $aiPromptVersion,
    AI_Source_Refs__c: $aiSourceRefs,
    AI_Citation_Count__c: 2,
    Hierarchy_Payload__c: $hierarchyPayload,
    Intent_Signal_Payload__c: $intentSignalPayload
  }')"
ayala_primary_id="$(create_account "$ayala_primary_payload")"

ayala_duplicate_payload="$(jq -n \
  --arg aiNarrative "This duplicate variant resolves to the same externally validated Ayala legal name and should be reviewed in governance." \
  --arg aiNarrativeGeneratedAt "2026-03-28T09:00:00.000Z" \
  --arg enrichmentRunId "run_public_regional_20260328" \
  --arg aiModelId "gpt-5.4" \
  --arg aiPromptVersion "pulse360-public-regional-v1" \
  --arg aiSourceRefs "$ayala_sources" \
  --arg aiRecommendedActions "$ayala_actions" \
  --arg hierarchyPayload "$ayala_hierarchy" \
  --arg intentSignalPayload "$ayala_signal" \
  '{
    Name: "Ayala Corp.",
    BillingCountry: "Philippines",
    Unified_Profile_Id__c: "ucp_ayala_001_dup",
    Identity_Confidence__c: 89,
    Group_Revenue_Rollup__c: 325700000000,
    Group_Revenue_Visible__c: 141000000000,
    Health_Score__c: 71,
    Cross_Sell_Propensity__c: 79,
    Coverage_Gap_Flag__c: true,
    Competitor_Risk_Signal__c: 61,
    Primary_Brand_Name__c: "Ayala",
    Active_Product_Count__c: 7,
    Engagement_Intensity_Score__c: 62,
    Open_Opportunity_Count__c: 2,
    Last_Engagement_Timestamp__c: "2026-02-27T00:00:00.000Z",
    DataCloud_Last_Synced__c: "2026-03-28T09:00:00.000Z",
    External_Legal_Name__c: "Ayala Corporation",
    Externally_Validated__c: true,
    Validity_Score_External__c: 91,
    External_Subsidiaries_Found__c: 2,
    AI_Narrative__c: $aiNarrative,
    AI_Recommended_Actions__c: $aiRecommendedActions,
    AI_Narrative_Generated__c: $aiNarrativeGeneratedAt,
    Enrichment_Run_Id__c: $enrichmentRunId,
    Regulatory_Readiness_Score__c: 74,
    Duplicate_Exposure_Count__c: 1,
    Group_Known_Subsidiary_Count__c: 4,
    CRM_Covered_Subsidiary_Count__c: 2,
    External_Revenue_Confirmed__c: 325700000000,
    AI_Model_Id__c: $aiModelId,
    AI_Prompt_Version__c: $aiPromptVersion,
    AI_Source_Refs__c: $aiSourceRefs,
    AI_Citation_Count__c: 2,
    Hierarchy_Payload__c: $hierarchyPayload,
    Intent_Signal_Payload__c: $intentSignalPayload
  }')"
ayala_duplicate_id="$(create_account "$ayala_duplicate_payload")"

jgs_payload="$(jq -n \
  --arg aiNarrative "JG Summit public evidence highlights a broad portfolio and digital transformation momentum that outpaces current CRM coverage." \
  --arg aiNarrativeGeneratedAt "2026-03-28T09:00:00.000Z" \
  --arg enrichmentRunId "run_public_regional_20260328" \
  --arg aiModelId "gpt-5.4" \
  --arg aiPromptVersion "pulse360-public-regional-v1" \
  --arg aiSourceRefs "$jgs_sources" \
  --arg aiRecommendedActions "$jgs_actions" \
  --arg hierarchyPayload "$jgs_hierarchy" \
  --arg intentSignalPayload "$jgs_signal" \
  '{
    Name: "JG Summit Holdings, Inc.",
    BillingCountry: "Philippines",
    Unified_Profile_Id__c: "ucp_jgs_001",
    Identity_Confidence__c: 92,
    Group_Revenue_Rollup__c: 378600000000,
    Group_Revenue_Visible__c: 126000000000,
    Health_Score__c: 79,
    Cross_Sell_Propensity__c: 74,
    Coverage_Gap_Flag__c: true,
    Competitor_Risk_Signal__c: 52,
    Primary_Brand_Name__c: "JG Summit",
    Active_Product_Count__c: 8,
    Engagement_Intensity_Score__c: 68,
    Open_Opportunity_Count__c: 3,
    Last_Engagement_Timestamp__c: "2026-03-28T00:00:00.000Z",
    DataCloud_Last_Synced__c: "2026-03-28T09:00:00.000Z",
    External_Legal_Name__c: "JG Summit Holdings, Inc.",
    Externally_Validated__c: true,
    Validity_Score_External__c: 89,
    External_Subsidiaries_Found__c: 3,
    AI_Narrative__c: $aiNarrative,
    AI_Recommended_Actions__c: $aiRecommendedActions,
    AI_Narrative_Generated__c: $aiNarrativeGeneratedAt,
    Enrichment_Run_Id__c: $enrichmentRunId,
    Regulatory_Readiness_Score__c: 69,
    Duplicate_Exposure_Count__c: 2,
    Group_Known_Subsidiary_Count__c: 4,
    CRM_Covered_Subsidiary_Count__c: 1,
    External_Revenue_Confirmed__c: 378600000000,
    AI_Model_Id__c: $aiModelId,
    AI_Prompt_Version__c: $aiPromptVersion,
    AI_Source_Refs__c: $aiSourceRefs,
    AI_Citation_Count__c: 2,
    Hierarchy_Payload__c: $hierarchyPayload,
    Intent_Signal_Payload__c: $intentSignalPayload
  }')"
jgs_id="$(create_account "$jgs_payload")"

jgs_hierarchy_live="$(jq -cn --arg jgsId "$jgs_id" '{
  group_id: "grp_jgs",
  parent_account_id: null,
  canonical_account_id: "ent_ph_002",
  account_name: "JG Summit Holdings, Inc.",
  children: [
    {
      entity_id: "ent_ph_002",
      crm_record_id: $jgsId,
      name: "JG Summit Holdings, Inc.",
      role: "Current account anchor",
      coverage_status: "covered",
      in_crm: true,
      signal: "The parent account is in CRM, but most of the commercial group is still outside the seller operating surface."
    },
    {
      entity_id: "ent_ph_003",
      crm_record_id: null,
      name: "Cebu Pacific",
      role: "Travel and loyalty whitespace entity",
      coverage_status: "uncovered",
      in_crm: false,
      signal: "Travel and ecosystem signals create room for loyalty, customer data, and digital engagement plays.",
      suggested_play: "Customer data and loyalty modernization"
    },
    {
      entity_id: "ent_ph_004",
      crm_record_id: null,
      name: "Universal Robina Corporation",
      role: "Consumer analytics whitespace entity",
      coverage_status: "uncovered",
      in_crm: false,
      signal: "Consumer-scale group operations suggest an unmet analytics and planning opportunity outside the current CRM footprint.",
      suggested_play: "Consumer demand and retail analytics"
    },
    {
      entity_id: "ent_ph_005",
      crm_record_id: null,
      name: "GoTyme Bank",
      role: "Digital banking whitespace entity",
      coverage_status: "uncovered",
      in_crm: false,
      signal: "Annual report evidence ties the group to digital banking and rewards momentum, making GoTyme the clearest next commercial move.",
      suggested_play: "Rewards analytics and digital banking growth"
    }
  ]
}')"
update_sobject "Account" "$jgs_id" "$(jq -cn --arg hierarchyPayload "$jgs_hierarchy_live" --arg intentSignalPayload "$jgs_signal" '{Hierarchy_Payload__c: $hierarchyPayload, Intent_Signal_Payload__c: $intentSignalPayload}')"

ayala_case_payload="$(jq -n \
  --arg leftAccountId "$ayala_primary_id" \
  --arg rightAccountId "$ayala_duplicate_id" \
  '{
    Candidate_Pair_Id__c: "PAIR-AYALA-001",
    Status__c: "Ready for Review",
    Priority__c: "High",
    Left_Account__c: $leftAccountId,
    Right_Account__c: $rightAccountId,
    Surviving_Account__c: $leftAccountId,
    Merged_Account__c: $rightAccountId,
    Duplicate_Confidence__c: 94.2,
    Confidence_Band__c: "High",
    Recommended_Action__c: "Approve Merge",
    Review_Flag__c: true,
    Top_Match_Features__c: "legal_name_similarity,portfolio_alignment,public_signal_overlap",
    Feature_Explanations__c: "Both records resolve to the same Ayala legal identity through the integrated report and public talent signals.",
    Attribute_Validity_Payload__c: "external_legal_name:92; public_citations:2; crm_coverage_gap:true",
    Hierarchy_Conflict_Flag__c: false,
    Hierarchy_Impact_Summary__c: "Approve the merge to keep Philippine group planning and enrichment aligned to the same parent entity.",
    Source_Snapshot_Id__c: "snapshot_ayala_public_001",
    Evidence_Run_Id__c: "run_public_regional_20260328",
    Evidence_Run_Timestamp__c: "2026-03-28T09:00:00.000Z",
    Model_Version__c: "pulse360-public-regional-v1",
    Merge_Execution_Status__c: "Not Started"
  }')"
ayala_case_id="$(create_case "$ayala_case_payload")"

ayala_actions_live="$(jq -cn --arg ayalaCaseId "$ayala_case_id" '[
  {
    rank: 1,
    action_type: "create_task",
    target: "Validate uncovered Ayala group coverage",
    target_record_id: "",
    reasoning: "The public portfolio is broader than the current CRM footprint represented in the prototype.",
    estimated_revenue_impact: "Improved account planning accuracy",
    confidence: 0.82,
    source_ids: ["ayala_ir_2024"]
  },
  {
    rank: 2,
    action_type: "escalate_governance",
    target: "Review Ayala duplicate pair",
    target_record_id: $ayalaCaseId,
    reasoning: "Two CRM records map to the same externally validated legal entity.",
    estimated_revenue_impact: "Higher data trust for account teams",
    confidence: 0.91,
    source_ids: ["ayala_ir_2024", "ayala_internship_2026"]
  }
]')"
ayala_hierarchy_live="$(jq -cn --arg primaryId "$ayala_primary_id" --arg duplicateId "$ayala_duplicate_id" '{
  group_id: "grp_ayala",
  parent_account_id: null,
  canonical_account_id: "ent_ph_001",
  account_name: "Ayala Corporation",
  children: [
    {
      entity_id: "ent_ph_001",
      crm_record_id: $primaryId,
      name: "Ayala Corporation",
      role: "Current account anchor",
      coverage_status: "covered",
      in_crm: true,
      signal: "This anchor account is in CRM, but the wider Ayala operating footprint is not fully action-ready."
    },
    {
      entity_id: "ent_ph_001_dup",
      crm_record_id: $duplicateId,
      name: "Ayala Corp.",
      role: "Duplicate CRM variant",
      coverage_status: "duplicate",
      in_crm: true,
      signal: "A second CRM variant exists for the same commercial group, which can dilute seller trust and ownership clarity.",
      suggested_play: "Resolve duplicate ownership"
    },
    {
      entity_id: "ent_ph_003",
      crm_record_id: null,
      name: "ACMobility",
      role: "Mobility whitespace entity",
      coverage_status: "uncovered",
      in_crm: false,
      signal: "Ayala portfolio disclosures point to mobility expansion that is not represented as a seller-ready entity in CRM.",
      suggested_play: "Mobility data platform whitespace"
    },
    {
      entity_id: "ent_ph_004",
      crm_record_id: null,
      name: "AC Logistics",
      role: "Logistics whitespace entity",
      coverage_status: "uncovered",
      in_crm: false,
      signal: "Public portfolio evidence shows logistics expansion that is still absent from the current CRM coverage map.",
      suggested_play: "Logistics planning and visibility review"
    }
  ]
}')"
update_sobject "Account" "$ayala_primary_id" "$(jq -cn --arg aiRecommendedActions "$ayala_actions_live" --arg hierarchyPayload "$ayala_hierarchy_live" --arg intentSignalPayload "$ayala_signal" '{AI_Recommended_Actions__c: $aiRecommendedActions, Hierarchy_Payload__c: $hierarchyPayload, Intent_Signal_Payload__c: $intentSignalPayload}')"
update_sobject "Account" "$ayala_duplicate_id" "$(jq -cn --arg aiRecommendedActions "$ayala_actions_live" --arg hierarchyPayload "$ayala_hierarchy_live" --arg intentSignalPayload "$ayala_signal" '{AI_Recommended_Actions__c: $aiRecommendedActions, Hierarchy_Payload__c: $hierarchyPayload, Intent_Signal_Payload__c: $intentSignalPayload}')"

cat <<EOF
Seeded Accounts:
- Singtel Group: $singtel_id
- NCS Pte. Ltd.: $ncs_id
- Ayala Corporation: $ayala_primary_id
- Ayala Corp.: $ayala_duplicate_id
- JG Summit Holdings, Inc.: $jgs_id

Seeded Governance Case:
- Ayala duplicate review: $ayala_case_id
EOF
