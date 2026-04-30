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

required_files=(
  "sql/databricks/silver_salesforce/00_create_schema.sql"
  "sql/databricks/silver_salesforce/10_crm_account.sql"
  "sql/databricks/silver_salesforce/20_crm_contact.sql"
  "sql/databricks/silver_salesforce/30_crm_opportunity.sql"
  "sql/databricks/silver_salesforce/40_crm_opportunity_contact_role.sql"
  "sql/databricks/silver_salesforce/50_crm_product.sql"
  "sql/databricks/silver_salesforce/60_crm_opportunity_line_item.sql"
  "sql/databricks/silver_salesforce/70_crm_account_contact_bridge.sql"
  "sql/databricks/silver_salesforce/80_crm_account_hierarchy_edge.sql"
  "sql/databricks/silver_salesforce/90_crm_governance_case.sql"
  "sql/databricks/silver_salesforce/README.md"
  "sql/databricks/gold/00_create_schemas.sql"
  "sql/databricks/gold/10_account_export_base.sql"
  "sql/databricks/gold/20_account_core_export.sql"
  "sql/databricks/gold/30_datacloud_export_accounts.sql"
  "sql/databricks/gold/README.md"
  "docs/setup/databricks-silver-salesforce-runbook.md"
  "docs/setup/databricks-gold-account-export-runbook.md"
)

for path in "${required_files[@]}"; do
  [[ -f "$path" ]] || fail "Missing required SQL package artifact: $path"
done
pass "Databricks Salesforce SQL package artifacts exist"

silver_readme="sql/databricks/silver_salesforce/README.md"
gold_readme="sql/databricks/gold/README.md"
silver_runbook="docs/setup/databricks-silver-salesforce-runbook.md"
gold_runbook="docs/setup/databricks-gold-account-export-runbook.md"
silver_account_sql="sql/databricks/silver_salesforce/10_crm_account.sql"
silver_governance_case_sql="sql/databricks/silver_salesforce/90_crm_governance_case.sql"
gold_export_base_sql="sql/databricks/gold/10_account_export_base.sql"
gold_export_sql="sql/databricks/gold/30_datacloud_export_accounts.sql"

for token in \
  "00_create_schema.sql" \
  "80_crm_account_hierarchy_edge.sql" \
  "90_crm_governance_case.sql" \
  "crm_account_id"; do
  search_fixed "$token" "$silver_readme" || fail "Missing token in silver README: $token"
done

for token in \
  "00_create_schemas.sql" \
  "30_datacloud_export_accounts.sql" \
  "source_account_id" \
  "crm_account_id"; do
  search_fixed "$token" "$gold_readme" || fail "Missing token in gold README: $token"
done
pass "SQL package READMEs document execution order and key rules"

for token in \
  "pulse360_s4.bronze_salesforce.account" \
  "Id AS crm_account_id" \
  "'salesforce' AS source_system"; do
  search_fixed "$token" "$silver_account_sql" || fail "Missing token in crm_account SQL: $token"
done

for token in \
  "CREATE OR REPLACE VIEW pulse360_s4.silver_salesforce.crm_governance_case AS" \
  "pulse360_s4.bronze_salesforce.governance_case__c" \
  "Id AS crm_governance_case_id" \
  "Decision_Status__c AS decision_status" \
  "Recommended_Action__c AS recommended_action" \
  "get_json_object(bronze_payload, '$.Source_Product__c') AS source_product" \
  "get_json_object(bronze_payload, '$.Data_Cloud_Source_Record_Id__c') AS data_cloud_source_record_id" \
  "get_json_object(bronze_payload, '$.Data_Cloud_Review_Queue_Id__c') AS data_cloud_review_queue_id" \
  "try_cast(Duplicate_Confidence__c AS DOUBLE) AS duplicate_confidence" \
  "Surviving_Account__c AS surviving_account_id" \
  "'salesforce' AS source_system"; do
  search_fixed "$token" "$silver_governance_case_sql" || fail "Missing token in crm_governance_case SQL: $token"
done

for token in \
  "a.crm_account_id AS source_account_id" \
  "concat('ucp_', a.crm_account_id) AS unified_profile_id" \
  "pulse360_s4.gold.account_genai_enrichment_output_runtime" \
  "eligible_genai_runtime" \
  "genai_runtime_steward_decisions" \
  "d.surviving_account_id IS NOT NULL" \
  "runtime.activation_eligible_flag = true" \
  "current_timestamp() AS last_synced_timestamp"; do
  search_fixed "$token" "$gold_export_base_sql" || fail "Missing token in account_export_base SQL: $token"
done

for token in \
  "CREATE OR REPLACE TABLE pulse360_s4.intelligence.datacloud_export_accounts AS" \
  "source_account_id" \
  "unified_profile_id" \
  "identity_confidence" \
  "group_revenue_rollup" \
  "health_score" \
  "cross_sell_propensity" \
  "coverage_gap_flag" \
  "competitor_risk_signal" \
  "primary_brand_name" \
  "active_product_count" \
  "engagement_intensity_score" \
  "open_opportunity_count" \
  "last_engagement_timestamp" \
  "last_synced_timestamp"; do
  search_fixed "$token" "$gold_export_sql" || fail "Missing token in datacloud export SQL: $token"
done
pass "SQL definitions preserve CRM-key-safe export fields"

for token in \
  "crm_account_id" \
  "pulse360_s4.silver_salesforce.crm_account_hierarchy_edge" \
  "pulse360_s4.silver_salesforce.crm_governance_case" \
  "The pipeline is ready for gold export refactoring"; do
  search_fixed "$token" "$silver_runbook" || fail "Missing token in silver runbook: $token"
done

for token in \
  "pulse360_s4.intelligence.datacloud_export_accounts" \
  "source_account_id" \
  "activation fields required by"; do
  search_fixed "$token" "$gold_runbook" || fail "Missing token in gold runbook: $token"
done
pass "Runbooks describe validation and expected outcomes"

pass "Databricks Salesforce SQL pack validation completed"
