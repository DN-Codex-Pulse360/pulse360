CREATE OR REPLACE TABLE pulse360_s4.intelligence.firmographic_profile_export AS
WITH child_counts AS (
  SELECT
    parent_account_id AS crm_account_id,
    COUNT(DISTINCT child_account_id) AS child_count
  FROM pulse360_s4.silver_salesforce.crm_account_hierarchy_edge
  WHERE parent_account_id IS NOT NULL
  GROUP BY parent_account_id
)
SELECT
  concat('fprof_', lower(a.crm_account_id)) AS firmographic_profile_id,
  concat('party_', lower(a.crm_account_id)) AS party_id,
  a.crm_account_id AS source_account_id,
  a.crm_account_name AS legal_name,
  a.crm_account_name AS trade_name,
  substr(COALESCE(a.crm_billing_country, a.crm_shipping_country, 'ZZ'), 1, 2) AS jurisdiction_country_code,
  'unknown' AS registration_status,
  COALESCE(a.crm_account_type, '') AS legal_form,
  CAST(NULL AS DATE) AS incorporation_date,
  CAST(NULL AS DATE) AS dissolution_date,
  COALESCE(a.crm_industry, 'Unknown') AS primary_industry_label,
  COALESCE(a.crm_industry, 'Unknown') AS business_category,
  COALESCE(a.crm_description, '') AS business_description,
  to_json(named_struct(
    'address_line_1', COALESCE(a.crm_billing_street, ''),
    'city', COALESCE(a.crm_billing_city, ''),
    'state_province', COALESCE(a.crm_billing_state, ''),
    'postal_code', COALESCE(a.crm_billing_postal_code, ''),
    'country_code', substr(COALESCE(a.crm_billing_country, 'ZZ'), 1, 2)
  )) AS registered_address_json,
  to_json(named_struct(
    'address_line_1', COALESCE(a.crm_shipping_street, a.crm_billing_street, ''),
    'city', COALESCE(a.crm_shipping_city, a.crm_billing_city, ''),
    'state_province', COALESCE(a.crm_shipping_state, a.crm_billing_state, ''),
    'postal_code', COALESCE(a.crm_shipping_postal_code, a.crm_billing_postal_code, ''),
    'country_code', substr(COALESCE(a.crm_shipping_country, a.crm_billing_country, 'ZZ'), 1, 2)
  )) AS operational_address_json,
  CAST(a.crm_annual_revenue AS DOUBLE) AS annual_revenue_local,
  CAST(a.crm_annual_revenue AS DOUBLE) AS annual_revenue_usd,
  'USD' AS revenue_currency,
  CAST(NULL AS INT) AS revenue_year,
  CASE WHEN a.crm_annual_revenue IS NOT NULL THEN 'crm_reported' ELSE 'unknown' END AS revenue_indicator,
  CAST(NULL AS DOUBLE) AS share_capital,
  '' AS financial_year_end,
  '' AS latest_financial_results_summary,
  '' AS latest_financial_results_period,
  CAST(NULL AS DATE) AS latest_fin_results_presentation_date,
  '' AS latest_financial_results_source_url,
  '' AS investor_updates_summary,
  CAST(array() AS ARRAY<STRING>) AS investor_updates_source_urls,
  CAST(a.crm_number_of_employees AS INT) AS employees_total,
  CASE WHEN a.crm_number_of_employees IS NOT NULL THEN 'crm_reported' ELSE 'unknown' END AS employees_total_indicator,
  CAST(NULL AS INT) AS employees_on_site,
  CASE
    WHEN a.crm_number_of_employees IS NULL THEN ''
    WHEN a.crm_number_of_employees < 50 THEN '1-49'
    WHEN a.crm_number_of_employees < 250 THEN '50-249'
    WHEN a.crm_number_of_employees < 500 THEN '250-499'
    WHEN a.crm_number_of_employees < 1000 THEN '500-999'
    WHEN a.crm_number_of_employees < 5000 THEN '1000-4999'
    ELSE '5000+'
  END AS employee_range,
  '' AS import_export_code,
  '' AS import_export_label,
  CASE
    WHEN a.crm_parent_account_id IS NOT NULL THEN 'subsidiary'
    WHEN COALESCE(cc.child_count, 0) > 0 THEN 'parent_company'
    ELSE 'single_location'
  END AS location_type,
  CASE WHEN a.crm_parent_account_id IS NOT NULL THEN true ELSE false END AS subsidiary_flag,
  CASE WHEN a.crm_parent_account_id IS NULL THEN concat('party_', lower(a.crm_account_id)) ELSE '' END AS local_headquarter_id,
  CASE WHEN a.crm_parent_account_id IS NULL THEN concat('party_', lower(a.crm_account_id)) ELSE '' END AS national_headquarter_id,
  CASE
    WHEN a.crm_parent_account_id IS NULL THEN concat('party_', lower(a.crm_account_id))
    ELSE concat('party_', lower(a.crm_parent_account_id))
  END AS global_headquarter_id,
  CAST(COALESCE(cc.child_count, 0) + 1 AS INT) AS group_company_count,
  CASE WHEN a.crm_parent_account_id IS NULL THEN a.crm_account_name ELSE '' END AS ultimate_parent_name,
  CAST(1 AS INT) AS source_count,
  'Salesforce Account' AS primary_source_name,
  concat('salesforce://Account/', a.crm_account_id) AS primary_source_url,
  current_timestamp() AS last_verified_at,
  CAST(
    CASE
      WHEN a.crm_account_name IS NOT NULL AND a.crm_website IS NOT NULL AND a.crm_industry IS NOT NULL THEN 0.72
      WHEN a.crm_account_name IS NOT NULL AND a.crm_industry IS NOT NULL THEN 0.65
      ELSE 0.55
    END
    AS DOUBLE
  ) AS confidence,
  CAST(0 AS INT) AS conflict_count,
  b.run_id,
  'pulse360-sovereign-firmographic-v1.0.0' AS model_version
FROM pulse360_s4.silver_salesforce.crm_account a
LEFT JOIN child_counts cc
  ON a.crm_account_id = cc.crm_account_id
LEFT JOIN pulse360_s4.gold.account_export_base b
  ON a.crm_account_id = b.source_account_id;
