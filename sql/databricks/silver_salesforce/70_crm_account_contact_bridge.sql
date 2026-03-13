CREATE OR REPLACE VIEW pulse360_s4.silver_salesforce.crm_account_contact_bridge AS
SELECT
  md5(concat_ws('||', crm_account_id, crm_contact_id)) AS account_contact_id,
  crm_account_id,
  crm_contact_id,
  CAST(false AS boolean) AS is_primary_contact,
  crm_contact_title AS contact_role,
  source_system
FROM pulse360_s4.silver_salesforce.crm_contact
WHERE crm_account_id IS NOT NULL
  AND crm_contact_id IS NOT NULL;

