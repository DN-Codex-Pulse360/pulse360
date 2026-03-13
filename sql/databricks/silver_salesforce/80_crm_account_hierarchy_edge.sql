CREATE OR REPLACE VIEW pulse360_s4.silver_salesforce.crm_account_hierarchy_edge AS
SELECT
  md5(concat_ws('||', crm_parent_account_id, crm_account_id)) AS hierarchy_edge_id,
  crm_parent_account_id AS parent_account_id,
  crm_account_id AS child_account_id,
  'ParentAccount' AS relationship_type,
  CASE
    WHEN crm_parent_account_id IS NULL THEN 0
    ELSE 1
  END AS hierarchy_depth,
  CASE
    WHEN crm_parent_account_id IS NULL THEN crm_account_id
    ELSE concat(crm_parent_account_id, '>', crm_account_id)
  END AS hierarchy_path
FROM pulse360_s4.silver_salesforce.crm_account;

