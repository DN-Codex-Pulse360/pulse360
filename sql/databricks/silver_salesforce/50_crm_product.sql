CREATE OR REPLACE VIEW pulse360_s4.silver_salesforce.crm_product AS
SELECT
  Id AS crm_product_id,
  Name AS crm_product_name,
  ProductCode AS crm_product_code,
  Description AS crm_product_description,
  Family AS crm_product_family,
  ProductClass AS crm_product_class,
  Type AS crm_product_type,
  StockKeepingUnit AS crm_stock_keeping_unit,
  QuantityUnitOfMeasure AS crm_quantity_unit_of_measure,
  IsActive AS crm_is_active,
  CreatedDate AS crm_created_at,
  LastModifiedDate AS crm_last_modified_at,
  SystemModstamp AS crm_system_modstamp,
  'salesforce' AS source_system
FROM pulse360_s4.bronze_salesforce.product2
WHERE COALESCE(IsDeleted, false) = false;

