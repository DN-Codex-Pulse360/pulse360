CREATE OR REPLACE VIEW pulse360_s4.silver_salesforce.crm_contact AS
SELECT
  Id AS crm_contact_id,
  AccountId AS crm_account_id,
  OwnerId AS crm_owner_id,
  FirstName AS crm_contact_first_name,
  LastName AS crm_contact_last_name,
  Name AS crm_contact_name,
  Email AS crm_contact_email,
  Phone AS crm_contact_phone,
  MobilePhone AS crm_contact_mobile_phone,
  Title AS crm_contact_title,
  Department AS crm_contact_department,
  LeadSource AS crm_contact_lead_source,
  MailingStreet AS crm_contact_mailing_street,
  MailingCity AS crm_contact_mailing_city,
  COALESCE(MailingStateCode, MailingState) AS crm_contact_mailing_state,
  MailingPostalCode AS crm_contact_mailing_postal_code,
  COALESCE(MailingCountryCode, MailingCountry) AS crm_contact_mailing_country,
  IndividualId AS crm_individual_id,
  CreatedDate AS crm_contact_created_at,
  LastModifiedDate AS crm_contact_last_modified_at,
  SystemModstamp AS crm_contact_system_modstamp,
  'salesforce' AS source_system
FROM pulse360_s4.bronze_salesforce.contact
WHERE COALESCE(IsDeleted, false) = false;

