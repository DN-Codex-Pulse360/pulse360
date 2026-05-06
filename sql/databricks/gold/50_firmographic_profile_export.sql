CREATE OR REPLACE TABLE pulse360_s4.intelligence.firmographic_profile_export AS
WITH account_gpt_firmographic_latest AS (
  SELECT
    source_account_id,
    party_id,
    legal_name,
    jurisdiction_country_code,
    from_json(
      firmographic_profile_json,
      'struct<registration_status:string,legal_form:string,incorporation_date:string,dissolution_date:string,primary_industry_label:string,business_category:string,business_description:string,registered_address:struct<address_line_1:string,address_line_2:string,city:string,state_province:string,postal_code:string,country_code:string,latitude:double,longitude:double>,operational_address:struct<address_line_1:string,address_line_2:string,city:string,state_province:string,postal_code:string,country_code:string,latitude:double,longitude:double>,annual_revenue_local:double,annual_revenue_usd:double,revenue_currency:string,revenue_year:int,revenue_indicator:string,share_capital:double,financial_year_end:string,latest_financial_results_summary:string,latest_financial_results_period:string,latest_fin_results_presentation_date:string,latest_financial_results_source_url:string,investor_updates_summary:string,investor_updates_source_urls:array<string>,employees_total:int,employees_total_indicator:string,employees_on_site:int,employee_range:string,import_export_code:string,import_export_label:string,location_type:string,subsidiary_flag:boolean,local_headquarter_id:string,national_headquarter_id:string,global_headquarter_id:string,group_company_count:int,ultimate_parent_name:string,primary_source_name:string,primary_source_url:string,source_count:int,conflict_count:int,confidence:double>'
    ) AS gpt_profile,
    overall_confidence,
    CAST(last_verified_at AS TIMESTAMP) AS gpt_last_verified_at,
    run_id,
    model_version
  FROM pulse360_s4.gold.account_gpt_firmographic_latest
  WHERE gpt_status = 'schema_valid'
),
child_counts AS (
  SELECT
    parent_account_id AS crm_account_id,
    COUNT(DISTINCT child_account_id) AS child_count
  FROM pulse360_s4.silver_salesforce.crm_account_hierarchy_edge
  WHERE parent_account_id IS NOT NULL
  GROUP BY parent_account_id
),
profile_quality AS (
  SELECT
    a.crm_account_id,
    CASE
      WHEN g.gpt_profile.confidence >= 0.50
        AND g.gpt_profile.business_description IS NOT NULL
        AND trim(g.gpt_profile.business_description) <> ''
        AND lower(g.gpt_profile.business_description) NOT RLIKE 'insufficient|does not contain|not determined|approved discovery|search candidates|to avoid unsupported|verification-pending|remain unactivated|pending verification'
      THEN true
      ELSE false
    END AS use_gpt_profile,
    CASE
      WHEN a.crm_account_name IS NOT NULL AND a.crm_website IS NOT NULL AND a.crm_industry IS NOT NULL THEN CAST(0.72 AS DOUBLE)
      WHEN a.crm_account_name IS NOT NULL AND a.crm_industry IS NOT NULL THEN CAST(0.65 AS DOUBLE)
      ELSE CAST(0.55 AS DOUBLE)
    END AS crm_profile_confidence
  FROM pulse360_s4.silver_salesforce.crm_account a
  LEFT JOIN account_gpt_firmographic_latest g
    ON a.crm_account_id = g.source_account_id
)
SELECT
  concat('fprof_', lower(a.crm_account_id)) AS firmographic_profile_id,
  COALESCE(g.party_id, concat('party_', lower(a.crm_account_id))) AS party_id,
  a.crm_account_id AS source_account_id,
  COALESCE(g.legal_name, a.crm_account_name) AS legal_name,
  COALESCE(a.crm_account_name, g.legal_name, '') AS trade_name,
  COALESCE(g.jurisdiction_country_code, substr(COALESCE(a.crm_billing_country, a.crm_shipping_country, 'ZZ'), 1, 2)) AS jurisdiction_country_code,
  CASE WHEN q.use_gpt_profile THEN COALESCE(g.gpt_profile.registration_status, 'unknown') ELSE 'crm_only' END AS registration_status,
  COALESCE(g.gpt_profile.legal_form, a.crm_account_type, '') AS legal_form,
  CAST(g.gpt_profile.incorporation_date AS DATE) AS incorporation_date,
  CAST(g.gpt_profile.dissolution_date AS DATE) AS dissolution_date,
  COALESCE(NULLIF(NULLIF(g.gpt_profile.primary_industry_label, 'Unknown'), 'unknown'), a.crm_industry, 'Unknown') AS primary_industry_label,
  COALESCE(NULLIF(NULLIF(g.gpt_profile.business_category, 'Unknown'), 'unknown'), a.crm_industry, 'Unknown') AS business_category,
  CASE
    WHEN q.use_gpt_profile THEN g.gpt_profile.business_description
    WHEN a.crm_description IS NOT NULL AND trim(a.crm_description) <> '' THEN a.crm_description
    WHEN a.crm_industry IS NOT NULL THEN concat(COALESCE(a.crm_account_name, 'This account'), ' is tracked in Salesforce in the ', a.crm_industry, ' industry.')
    ELSE concat(COALESCE(a.crm_account_name, 'This account'), ' is tracked in Salesforce as a customer account.')
  END AS business_description,
  to_json(
    COALESCE(
      g.gpt_profile.registered_address,
      named_struct(
        'address_line_1', COALESCE(a.crm_billing_street, ''),
        'address_line_2', '',
        'city', COALESCE(a.crm_billing_city, ''),
        'state_province', COALESCE(a.crm_billing_state, ''),
        'postal_code', COALESCE(a.crm_billing_postal_code, ''),
        'country_code', substr(COALESCE(a.crm_billing_country, 'ZZ'), 1, 2),
        'latitude', CAST(NULL AS DOUBLE),
        'longitude', CAST(NULL AS DOUBLE)
      )
    )
  ) AS registered_address_json,
  to_json(
    COALESCE(
      g.gpt_profile.operational_address,
      named_struct(
        'address_line_1', COALESCE(a.crm_shipping_street, a.crm_billing_street, ''),
        'address_line_2', '',
        'city', COALESCE(a.crm_shipping_city, a.crm_billing_city, ''),
        'state_province', COALESCE(a.crm_shipping_state, a.crm_billing_state, ''),
        'postal_code', COALESCE(a.crm_shipping_postal_code, a.crm_billing_postal_code, ''),
        'country_code', substr(COALESCE(a.crm_shipping_country, a.crm_billing_country, 'ZZ'), 1, 2),
        'latitude', CAST(NULL AS DOUBLE),
        'longitude', CAST(NULL AS DOUBLE)
      )
    )
  ) AS operational_address_json,
  COALESCE(g.gpt_profile.annual_revenue_local, CAST(a.crm_annual_revenue AS DOUBLE)) AS annual_revenue_local,
  COALESCE(g.gpt_profile.annual_revenue_usd, CAST(a.crm_annual_revenue AS DOUBLE)) AS annual_revenue_usd,
  COALESCE(NULLIF(g.gpt_profile.revenue_currency, ''), CASE WHEN a.crm_annual_revenue IS NOT NULL THEN 'USD' ELSE '' END) AS revenue_currency,
  g.gpt_profile.revenue_year AS revenue_year,
  COALESCE(NULLIF(g.gpt_profile.revenue_indicator, 'unknown'), CASE WHEN a.crm_annual_revenue IS NOT NULL THEN 'crm_reported' ELSE 'unknown' END) AS revenue_indicator,
  g.gpt_profile.share_capital AS share_capital,
  COALESCE(g.gpt_profile.financial_year_end, '') AS financial_year_end,
  CASE WHEN g.gpt_profile.latest_financial_results_source_url IS NOT NULL AND trim(g.gpt_profile.latest_financial_results_source_url) <> '' THEN COALESCE(g.gpt_profile.latest_financial_results_summary, '') ELSE '' END AS latest_financial_results_summary,
  CASE WHEN g.gpt_profile.latest_financial_results_source_url IS NOT NULL AND trim(g.gpt_profile.latest_financial_results_source_url) <> '' THEN COALESCE(g.gpt_profile.latest_financial_results_period, '') ELSE '' END AS latest_financial_results_period,
  CAST(g.gpt_profile.latest_fin_results_presentation_date AS DATE) AS latest_fin_results_presentation_date,
  COALESCE(g.gpt_profile.latest_financial_results_source_url, '') AS latest_financial_results_source_url,
  CASE WHEN size(COALESCE(g.gpt_profile.investor_updates_source_urls, CAST(array() AS ARRAY<STRING>))) > 0 THEN COALESCE(g.gpt_profile.investor_updates_summary, '') ELSE '' END AS investor_updates_summary,
  COALESCE(g.gpt_profile.investor_updates_source_urls, CAST(array() AS ARRAY<STRING>)) AS investor_updates_source_urls,
  COALESCE(g.gpt_profile.employees_total, CAST(a.crm_number_of_employees AS INT)) AS employees_total,
  COALESCE(NULLIF(g.gpt_profile.employees_total_indicator, 'unknown'), CASE WHEN a.crm_number_of_employees IS NOT NULL THEN 'crm_reported' ELSE 'unknown' END) AS employees_total_indicator,
  g.gpt_profile.employees_on_site AS employees_on_site,
  COALESCE(
    NULLIF(g.gpt_profile.employee_range, ''),
    CASE
      WHEN a.crm_number_of_employees IS NULL THEN ''
      WHEN a.crm_number_of_employees < 50 THEN '1-49'
      WHEN a.crm_number_of_employees < 250 THEN '50-249'
      WHEN a.crm_number_of_employees < 500 THEN '250-499'
      WHEN a.crm_number_of_employees < 1000 THEN '500-999'
      WHEN a.crm_number_of_employees < 5000 THEN '1000-4999'
      ELSE '5000+'
    END
  ) AS employee_range,
  COALESCE(g.gpt_profile.import_export_code, '') AS import_export_code,
  COALESCE(g.gpt_profile.import_export_label, '') AS import_export_label,
  COALESCE(
    NULLIF(g.gpt_profile.location_type, 'unknown'),
    CASE
      WHEN a.crm_parent_account_id IS NOT NULL THEN 'subsidiary'
      WHEN COALESCE(cc.child_count, 0) > 0 THEN 'parent_company'
      ELSE 'single_location'
    END
  ) AS location_type,
  COALESCE(g.gpt_profile.subsidiary_flag, CASE WHEN a.crm_parent_account_id IS NOT NULL THEN true ELSE false END) AS subsidiary_flag,
  COALESCE(g.gpt_profile.local_headquarter_id, CASE WHEN a.crm_parent_account_id IS NULL THEN concat('party_', lower(a.crm_account_id)) ELSE '' END) AS local_headquarter_id,
  COALESCE(g.gpt_profile.national_headquarter_id, CASE WHEN a.crm_parent_account_id IS NULL THEN concat('party_', lower(a.crm_account_id)) ELSE '' END) AS national_headquarter_id,
  COALESCE(g.gpt_profile.global_headquarter_id, CASE WHEN a.crm_parent_account_id IS NULL THEN concat('party_', lower(a.crm_account_id)) ELSE concat('party_', lower(a.crm_parent_account_id)) END) AS global_headquarter_id,
  COALESCE(g.gpt_profile.group_company_count, CAST(COALESCE(cc.child_count, 0) + 1 AS INT)) AS group_company_count,
  COALESCE(g.gpt_profile.ultimate_parent_name, CASE WHEN a.crm_parent_account_id IS NULL THEN a.crm_account_name ELSE '' END) AS ultimate_parent_name,
  COALESCE(g.gpt_profile.source_count, CAST(1 AS INT)) AS source_count,
  COALESCE(g.gpt_profile.primary_source_name, 'Salesforce Account') AS primary_source_name,
  COALESCE(g.gpt_profile.primary_source_url, concat('salesforce://Account/', a.crm_account_id)) AS primary_source_url,
  COALESCE(g.gpt_last_verified_at, current_timestamp()) AS last_verified_at,
  CASE
    WHEN q.use_gpt_profile THEN COALESCE(g.gpt_profile.confidence, g.overall_confidence, q.crm_profile_confidence)
    ELSE q.crm_profile_confidence
  END AS confidence,
  COALESCE(g.gpt_profile.conflict_count, CAST(0 AS INT)) AS conflict_count,
  COALESCE(g.run_id, b.run_id) AS run_id,
  COALESCE(g.model_version, 'pulse360-sovereign-firmographic-v1.0.0') AS model_version
FROM pulse360_s4.silver_salesforce.crm_account a
LEFT JOIN account_gpt_firmographic_latest g
  ON a.crm_account_id = g.source_account_id
LEFT JOIN child_counts cc
  ON a.crm_account_id = cc.crm_account_id
LEFT JOIN profile_quality q
  ON a.crm_account_id = q.crm_account_id
LEFT JOIN pulse360_s4.gold.account_export_base b
  ON a.crm_account_id = b.source_account_id;
