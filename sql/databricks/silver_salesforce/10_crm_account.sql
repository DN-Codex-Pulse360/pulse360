CREATE OR REPLACE VIEW pulse360_s4.silver_salesforce.crm_account AS
SELECT
  Id AS crm_account_id,
  ParentId AS crm_parent_account_id,
  OwnerId AS crm_owner_id,
  Name AS crm_account_name,
  Type AS crm_account_type,
  Industry AS crm_industry,
  AccountNumber AS crm_account_number,
  Website AS crm_website,
  BillingStreet AS crm_billing_street,
  BillingCity AS crm_billing_city,
  COALESCE(BillingStateCode, BillingState) AS crm_billing_state,
  BillingPostalCode AS crm_billing_postal_code,
  COALESCE(BillingCountryCode, BillingCountry) AS crm_billing_country,
  ShippingStreet AS crm_shipping_street,
  ShippingCity AS crm_shipping_city,
  COALESCE(ShippingStateCode, ShippingState) AS crm_shipping_state,
  ShippingPostalCode AS crm_shipping_postal_code,
  COALESCE(ShippingCountryCode, ShippingCountry) AS crm_shipping_country,
  Phone AS crm_phone,
  AccountSource AS crm_account_source,
  AnnualRevenue AS crm_annual_revenue,
  NumberOfEmployees AS crm_number_of_employees,
  Description AS crm_description,
  Rating AS crm_rating,
  DunsNumber AS crm_duns_number,
  CreatedDate AS crm_created_at,
  LastModifiedDate AS crm_last_modified_at,
  SystemModstamp AS crm_system_modstamp,
  'salesforce' AS source_system
FROM pulse360_s4.bronze_salesforce.account
WHERE COALESCE(IsDeleted, false) = false;

