CREATE OR REPLACE VIEW pulse360_s4.gold.account_export_base AS
WITH contact_rollup AS (
  SELECT
    crm_account_id,
    COUNT(DISTINCT crm_contact_id) AS contact_count,
    MAX(crm_contact_last_modified_at) AS last_contact_ts
  FROM pulse360_s4.silver_salesforce.crm_contact
  GROUP BY crm_account_id
),
opportunity_rollup AS (
  SELECT
    crm_account_id,
    COUNT(DISTINCT CASE WHEN COALESCE(crm_is_closed, false) = false THEN crm_opportunity_id END) AS open_opportunity_count,
    COUNT(DISTINCT crm_opportunity_id) AS opportunity_count,
    MAX(crm_last_modified_at) AS last_opportunity_ts,
    AVG(COALESCE(crm_probability, 0)) AS avg_probability,
    MAX(CASE WHEN crm_is_won THEN 1 ELSE 0 END) AS has_won_opportunity,
    MAX(CASE WHEN crm_opportunity_name IS NOT NULL THEN 1 ELSE 0 END) AS has_commercial_activity,
    MAX(CASE WHEN crm_contact_id IS NOT NULL THEN 1 ELSE 0 END) AS has_direct_contact_link,
    MAX(CASE WHEN crm_stage_name IS NOT NULL THEN 1 ELSE 0 END) AS has_stage_signal,
    MAX(CASE WHEN crm_amount IS NOT NULL THEN 1 ELSE 0 END) AS has_amount_signal
  FROM pulse360_s4.silver_salesforce.crm_opportunity
  GROUP BY crm_account_id
),
line_item_rollup AS (
  SELECT
    o.crm_account_id,
    COUNT(DISTINCT li.crm_product_id) AS active_product_count,
    MAX(li.crm_last_modified_at) AS last_line_item_ts
  FROM pulse360_s4.silver_salesforce.crm_opportunity_line_item li
  INNER JOIN pulse360_s4.silver_salesforce.crm_opportunity o
    ON li.crm_opportunity_id = o.crm_opportunity_id
  GROUP BY o.crm_account_id
),
brand_rollup AS (
  SELECT
    o.crm_account_id,
    COALESCE(
      MAX(p.crm_product_family),
      MAX(p.crm_product_type),
      'Unassigned Brand'
    ) AS primary_brand_name
  FROM pulse360_s4.silver_salesforce.crm_opportunity_line_item li
  INNER JOIN pulse360_s4.silver_salesforce.crm_opportunity o
    ON li.crm_opportunity_id = o.crm_opportunity_id
  LEFT JOIN pulse360_s4.silver_salesforce.crm_product p
    ON li.crm_product_id = p.crm_product_id
  GROUP BY o.crm_account_id
),
child_revenue_rollup AS (
  SELECT
    parent_account_id AS crm_account_id,
    SUM(child.crm_annual_revenue) AS child_group_revenue
  FROM pulse360_s4.silver_salesforce.crm_account_hierarchy_edge h
  INNER JOIN pulse360_s4.silver_salesforce.crm_account child
    ON h.child_account_id = child.crm_account_id
  WHERE parent_account_id IS NOT NULL
  GROUP BY parent_account_id
)
SELECT
  a.crm_account_id,
  concat('acc_', lower(a.crm_account_id)) AS canonical_account_id,
  a.crm_account_id AS ssot_id,
  a.crm_account_id AS source_account_id,
  concat_ws(
    '_',
    COALESCE(upper(regexp_replace(a.crm_account_name, '[^A-Za-z0-9]+', '_')), a.crm_account_id),
    COALESCE(upper(a.crm_billing_country), 'NA'),
    COALESCE(NULLIF(a.crm_duns_number, ''), a.crm_account_id)
  ) AS deterministic_key,
  a.crm_account_name AS account_name,
  a.crm_parent_account_id AS parent_account_id,
  COALESCE(a.crm_industry, 'Unknown') AS industry,
  substr(COALESCE(a.crm_billing_country, 'ZZ'), 1, 2) AS country_code,
  CASE
    WHEN a.crm_duns_number IS NOT NULL AND a.crm_website IS NOT NULL THEN 96
    WHEN a.crm_website IS NOT NULL AND a.crm_phone IS NOT NULL THEN 93
    WHEN a.crm_website IS NOT NULL THEN 90
    WHEN a.crm_account_number IS NOT NULL THEN 87
    ELSE 82
  END AS identity_confidence,
  CASE
    WHEN a.crm_description IS NOT NULL AND a.crm_website IS NOT NULL AND a.crm_duns_number IS NOT NULL THEN 94
    WHEN a.crm_website IS NOT NULL AND a.crm_industry IS NOT NULL THEN 90
    WHEN a.crm_industry IS NOT NULL OR a.crm_account_number IS NOT NULL THEN 85
    ELSE 76
  END AS validity_score,
  concat('ucp_', a.crm_account_id) AS unified_profile_id,
  CAST(COALESCE(a.crm_annual_revenue, 0) + COALESCE(cr.child_group_revenue, 0) AS DOUBLE) AS group_revenue_rollup,
  CAST(
    LEAST(
      100,
      35
      + CASE WHEN a.crm_rating IN ('Hot', 'Warm') THEN 10 ELSE 0 END
      + LEAST(COALESCE(c.contact_count, 0) * 5, 20)
      + LEAST(COALESCE(o.open_opportunity_count, 0) * 8, 24)
      + CASE WHEN a.crm_annual_revenue IS NOT NULL THEN 6 ELSE 0 END
      + CASE WHEN COALESCE(o.has_won_opportunity, 0) = 1 THEN 5 ELSE 0 END
    )
    AS DOUBLE
  ) AS health_score,
  CAST(
    LEAST(
      100,
      20
      + LEAST(COALESCE(o.open_opportunity_count, 0) * 12, 36)
      + LEAST(COALESCE(li.active_product_count, 0) * 7, 21)
      + CASE WHEN COALESCE(o.avg_probability, 0) >= 60 THEN 15 ELSE 5 END
      + CASE WHEN COALESCE(o.has_commercial_activity, 0) = 1 THEN 8 ELSE 0 END
    )
    AS DOUBLE
  ) AS cross_sell_propensity,
  CASE
    WHEN a.crm_parent_account_id IS NOT NULL AND COALESCE(c.contact_count, 0) = 0 THEN true
    WHEN a.crm_parent_account_id IS NULL AND COALESCE(o.open_opportunity_count, 0) = 0 THEN true
    ELSE false
  END AS coverage_gap_flag,
  CAST(
    CASE
      WHEN COALESCE(o.has_stage_signal, 0) = 1 AND COALESCE(o.has_amount_signal, 0) = 1 THEN 58
      WHEN COALESCE(o.has_stage_signal, 0) = 1 THEN 44
      ELSE 18
    END
    AS DOUBLE
  ) AS competitor_risk_signal,
  COALESCE(br.primary_brand_name, 'Unassigned Brand') AS primary_brand_name,
  COALESCE(li.active_product_count, 0) AS active_product_count,
  CAST(
    LEAST(
      100,
      15
      + LEAST(COALESCE(c.contact_count, 0) * 8, 40)
      + LEAST(COALESCE(o.opportunity_count, 0) * 10, 30)
      + CASE WHEN COALESCE(o.has_direct_contact_link, 0) = 1 THEN 10 ELSE 0 END
    )
    AS DOUBLE
  ) AS engagement_intensity_score,
  COALESCE(o.open_opportunity_count, 0) AS open_opportunity_count,
  GREATEST(
    COALESCE(o.last_opportunity_ts, CAST('1900-01-01' AS TIMESTAMP)),
    COALESCE(c.last_contact_ts, CAST('1900-01-01' AS TIMESTAMP)),
    COALESCE(li.last_line_item_ts, CAST('1900-01-01' AS TIMESTAMP)),
    COALESCE(a.crm_last_modified_at, CAST('1900-01-01' AS TIMESTAMP))
  ) AS last_engagement_timestamp,
  current_timestamp() AS last_synced_timestamp,
  concat('Databricks CRM export refresh - ', CAST(current_date() AS STRING)) AS ingestion_metadata_label,
  concat('run_', date_format(current_timestamp(), 'yyyyMMdd_HHmmss')) AS run_id,
  current_timestamp() AS run_ts,
  current_timestamp() AS run_timestamp,
  'dc-canonical-v2.crm-keyed' AS model_version
FROM pulse360_s4.silver_salesforce.crm_account a
LEFT JOIN contact_rollup c
  ON a.crm_account_id = c.crm_account_id
LEFT JOIN opportunity_rollup o
  ON a.crm_account_id = o.crm_account_id
LEFT JOIN line_item_rollup li
  ON a.crm_account_id = li.crm_account_id
LEFT JOIN brand_rollup br
  ON a.crm_account_id = br.crm_account_id
LEFT JOIN child_revenue_rollup cr
  ON a.crm_account_id = cr.crm_account_id;
