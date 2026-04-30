CREATE OR REPLACE VIEW pulse360_s4.silver_salesforce.crm_opportunity_line_item AS
SELECT
  Id AS crm_opportunity_line_item_id,
  OpportunityId AS crm_opportunity_id,
  Product2Id AS crm_product_id,
  PricebookEntryId AS crm_pricebook_entry_id,
  ProductCode AS crm_product_code,
  Name AS crm_opportunity_line_item_name,
  Quantity AS crm_quantity,
  UnitPrice AS crm_unit_price,
  ListPrice AS crm_list_price,
  TotalPrice AS crm_total_price,
  ServiceDate AS crm_service_date,
  Description AS crm_description,
  CreatedDate AS crm_created_at,
  LastModifiedDate AS crm_last_modified_at,
  SystemModstamp AS crm_system_modstamp,
  'salesforce' AS source_system
FROM pulse360_s4.bronze_salesforce.opportunitylineitem
INNER JOIN pulse360_s4.silver_salesforce.crm_opportunity opportunity_anchor
  ON OpportunityId = opportunity_anchor.crm_opportunity_id
LEFT JOIN pulse360_s4.silver_salesforce.crm_product product_anchor
  ON Product2Id = product_anchor.crm_product_id
WHERE COALESCE(IsDeleted, false) = false;
