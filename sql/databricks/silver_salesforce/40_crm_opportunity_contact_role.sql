CREATE OR REPLACE VIEW pulse360_s4.silver_salesforce.crm_opportunity_contact_role AS
SELECT
  Id AS crm_opportunity_contact_role_id,
  OpportunityId AS crm_opportunity_id,
  ContactId AS crm_contact_id,
  Role AS crm_role,
  IsPrimary AS crm_is_primary,
  CreatedDate AS crm_created_at,
  LastModifiedDate AS crm_last_modified_at,
  SystemModstamp AS crm_system_modstamp,
  'salesforce' AS source_system
FROM pulse360_s4.bronze_salesforce.opportunitycontactrole
WHERE COALESCE(IsDeleted, false) = false;

