CREATE OR REPLACE VIEW pulse360_s4.silver_salesforce.crm_opportunity AS
SELECT
  Id AS crm_opportunity_id,
  AccountId AS crm_account_id,
  ContactId AS crm_contact_id,
  OwnerId AS crm_owner_id,
  Name AS crm_opportunity_name,
  StageName AS crm_stage_name,
  Amount AS crm_amount,
  Probability AS crm_probability,
  ExpectedRevenue AS crm_expected_revenue,
  CloseDate AS crm_close_date,
  Type AS crm_opportunity_type,
  ForecastCategoryName AS crm_forecast_category,
  Pricebook2Id AS crm_pricebook2_id,
  HasOpportunityLineItem AS crm_has_opportunity_line_item,
  IsClosed AS crm_is_closed,
  IsWon AS crm_is_won,
  CreatedDate AS crm_created_at,
  LastModifiedDate AS crm_last_modified_at,
  SystemModstamp AS crm_system_modstamp,
  'salesforce' AS source_system
FROM pulse360_s4.bronze_salesforce.opportunity
WHERE COALESCE(IsDeleted, false) = false;

