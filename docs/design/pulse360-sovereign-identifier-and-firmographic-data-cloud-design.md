# Pulse360 Sovereign Identifier and Firmographic Data Cloud Design

Date: 2026-05-01

## Purpose

This design extends the current Pulse360 Account intelligence data model so
Customer Accounts can carry multiple sovereign identifier types and values, plus
rich firmographic enrichment, without making any commercial provider the system
of record.

The design is source-first and Data Cloud aligned:

- Salesforce CRM remains the execution surface.
- Data Cloud remains the operational profile layer.
- Databricks remains the full graph, evidence, weighting, and lineage layer.
- GPT enrichment is allowed only to extract and summarize high-confidence facts
  from cited sources. It must not invent identifiers, hierarchy, revenue, or
  legal status.

## Current Fit

The current runtime branch has a thin Account core contract:

- `contracts/datacloud_account_core_canonical_v2.schema.json`
- `contracts/databricks_to_datacloud.schema.json`
- `config/data-cloud/dmo-account-field-mapping.csv`
- `config/data-cloud/activation-field-mapping.csv`

These preserve CRM-safe Account IDs, identity confidence, hierarchy payloads,
and CRM activation fields. They do not yet model:

- multiple sovereign identifier values per Account
- identifier type taxonomy by jurisdiction
- official-identifier evidence and verification status
- broad firmographic profile attributes
- field-level source confidence and last verification
- company classification, hierarchy, executive, and digital-footprint children

## Salesforce KYC and KYB Pattern

Salesforce's Financial Services KYC model centers on a party and its
verification evidence. The official model includes objects such as `Account`,
`Identity Document`, `Party Identity Verification`, `Party Identity Verification
Step`, `Party Profile`, `Party Profile Address`, `Party Profile Risk`, and
screening summary/step objects.

For Data Cloud / Data 360, the standard pattern is more directly useful:

- `ssot__Party__dlm` represents the party abstraction.
- `ssot__Account__dlm` can relate to Party.
- `ssot__PartyIdentification__dlm` represents identifiers for a party.
- `ssot__PartyIdentification__dlm.ssot__Identificationnumber__c` is the
  identifier value and is also used for identity resolution.
- `ssot__PartyIdentification__dlm.ssot__PartyIdentificationTypeId__c`
  classifies the identifier type.
- `ssot__PartyIdentification__dlm` carries source, external record, issuing
  authority, issue/expiry, verified user, and verified date fields.

Pulse360 should follow this pattern instead of adding one custom field per
jurisdiction to Account. Account-level scalar fields are acceptable for CRM
activation, but the Data Cloud model must preserve the many-identifiers-per-party
shape.

## Provider Data Pattern Reviewed

The firmographic design reflects the public field patterns from BoldData /
CompanyData and InfobelPRO:

- identity: legal name, trade name, registration number, tax ID, legal form,
  status, incorporation date
- industry: SIC, NACE, NAICS, business category and descriptions
- location: registered and operational address, city, state/province, postal
  code, country, latitude/longitude
- financials: revenue, local currency revenue, USD revenue, revenue indicator,
  share capital, financial year
- size: employees on site, total employees, employee range, estimate indicator
- hierarchy: location type, subsidiary flag, local/national/global headquarter
  IDs and names, parent/subsidiary relationships, ownership chains, shareholding
  percentages
- contacts/executives: CEO, directors, board members, executive names, titles,
  roles, and optional contact points
- digital footprint: website, domain, social profiles, tech stack, domain age
- provenance: registry/source name, source URL, source jurisdiction,
  last-verified timestamp, confidence, source contribution

These attributes are modeled as Data Cloud operational entities and Databricks
lineage-backed evidence, not as a flat Account field explosion.

## Target Data Cloud Model

### 1. Account and Party Core

Use `ssot__Account__dlm` as the operational Account profile and relate it to a
Party identity abstraction.

Required operational fields:

| Field | Purpose |
| --- | --- |
| `ssot__Id__c` | Data Cloud Account primary key |
| `source_account_id` | Salesforce CRM Account ID or source Account key |
| `party_id` | Party key used to link identifiers and profile evidence |
| `account_name` | Display name from CRM or reconciled source |
| `country_code` | Primary registration or operating country |
| `identity_confidence` | Current identity confidence summary |
| `run_id` | Databricks enrichment run |
| `run_timestamp` | Run timestamp |
| `model_version` | Contract/model version |

### 2. Sovereign Identifier Types and Values

Use standard `ssot__PartyIdentification__dlm` wherever the org supports it.
Model each identifier as one row.

| Pulse360 field | Data Cloud target | Notes |
| --- | --- | --- |
| `sovereign_identifier_id` | `ssot__Id__c` | Stable generated key |
| `party_id` | `ssot__PartyId__c` | Account/Party link |
| `identifier_type` | `ssot__PartyIdentificationTypeId__c` | Reference taxonomy |
| `identifier_name` | `ssot__Name__c` | Human-readable label |
| `identifier_value` | `ssot__Identificationnumber__c` | Normalized value |
| `issuing_authority` | `ssot__IssuedByAuthority__c` | Registry/tax authority |
| `issued_at_location` | `ssot__IssuedAtLocation__c` | Country/jurisdiction |
| `issued_date` | `ssot__IssuedDate__c` | Optional |
| `expiry_date` | `ssot__ExpiryDate__c` | Optional |
| `verified_date` | `ssot__VerifiedDate__c` | Verification timestamp |
| `source_system` | `ssot__DataSourceId__c` | CRM, registry, GPT research, etc. |
| `source_record_id` | `ssot__ExternalRecordId__c` | External evidence key |

Recommended identifier type taxonomy:

| Identifier type | Jurisdiction | Example authority | Usage |
| --- | --- | --- | --- |
| `PH_SEC_REGISTRATION_NUMBER` | PH | Philippine SEC | Company registration |
| `PH_TIN` | PH | BIR | Tax identity |
| `SG_UEN` | SG | ACRA | Unique Entity Number |
| `MY_SSM_REGISTRATION_NUMBER` | MY | SSM | Company registration |
| `ID_NIB` | ID | OSS | Business ID |
| `TH_TAX_ID` | TH | Revenue Department | Tax identity |
| `VN_ENTERPRISE_CODE` | VN | Business Registration Authority | Company registration |
| `HK_BRN` | HK | Companies Registry / IRD | Business registration |
| `GLOBAL_LEI` | Global | GLEIF | Legal Entity Identifier |
| `PROVIDER_BOLDDATA_ID` | Provider | BoldData / CompanyData | Provider reference, not sovereign |
| `PROVIDER_INFOBEL_ID` | Provider | InfobelPRO | Provider reference, not sovereign |
| `CRM_ACCOUNT_ID` | Internal | Salesforce | Activation key, not sovereign |

Provider IDs and CRM IDs are allowed as Party Identification rows, but must not
be marked as sovereign identifiers.

### 3. Identifier Evidence Extension

Standard Party Identification does not carry all Pulse360 confidence and
evidence needs. Add an extension DMO:

`Pulse360_Identifier_Evidence__dlm`

| Field | Type | Purpose |
| --- | --- | --- |
| `identifier_evidence_id` | text | Primary key |
| `party_identification_id` | text | Link to Party Identification |
| `source_name` | text | Registry/provider/source |
| `source_url` | url/text | Evidence URL |
| `source_type` | text | registry, tax_authority, filing, website, provider, crm |
| `jurisdiction_country_code` | text | ISO country |
| `raw_identifier_value` | text | Original value before normalization |
| `normalized_identifier_value` | text | Canonical value |
| `verification_status` | text | verified, probable, conflicting, unverified |
| `confidence` | number | 0-1 confidence |
| `evidence_excerpt` | long text | Short source excerpt |
| `last_verified_at` | datetime | Last evidence check |
| `run_id` | text | Databricks/GPT run |
| `model_version` | text | Extraction model/prompt version |

### 4. Firmographic Profile

Create a single current operational profile per Account/Party:

`Pulse360_Firmographic_Profile__dlm`

| Field group | Fields |
| --- | --- |
| Identity | `legal_name`, `trade_name`, `registration_status`, `legal_form`, `incorporation_date`, `dissolution_date` |
| Industry | `primary_industry_label`, `primary_sic_code`, `primary_naics_code`, `primary_nace_code`, `business_category`, `business_description` |
| Location | `registered_address_*`, `operational_address_*`, `latitude`, `longitude` |
| Financials | `annual_revenue_local`, `annual_revenue_usd`, `revenue_currency`, `revenue_year`, `revenue_indicator`, `share_capital`, `financial_year_end` |
| Size | `employees_total`, `employees_total_indicator`, `employees_on_site`, `employee_range` |
| Trade | `import_export_code`, `import_export_label` |
| Hierarchy summary | `location_type`, `subsidiary_flag`, `local_headquarter_id`, `national_headquarter_id`, `global_headquarter_id`, `group_company_count`, `ultimate_parent_name` |
| Digital footprint | `website`, `domain`, `social_profiles_json`, `technology_stack_json`, `domain_age_years` |
| Provenance | `source_count`, `primary_source_name`, `primary_source_url`, `last_verified_at`, `confidence`, `conflict_count`, `run_id`, `model_version` |

### 5. Repeatable Child DMOs

Use child DMOs instead of repeating fields where cardinality is naturally many:

| DMO | Purpose |
| --- | --- |
| `Pulse360_Company_Classification__dlm` | Multiple SIC/NACE/NAICS/local industry codes |
| `Pulse360_Corporate_Linkage__dlm` | Parent, subsidiary, branch, ownership, director-link edges |
| `Pulse360_Executive_Role__dlm` | CEO/director/board/key executive roles |
| `Pulse360_Firmographic_Source_Evidence__dlm` | Field-level evidence, source excerpts, URLs, confidence |
| `Pulse360_Digital_Footprint__dlm` | Website, domain, social, technographic observations |

## GPT Enrichment Rules

GPT may enrich values only when all of these are true:

1. The source is named and reachable from the evidence packet.
2. The value is explicitly present in the source or can be directly extracted
   without inference.
3. The output includes source URL, source type, retrieval date, confidence, and
   a short evidence excerpt.
4. Conflicting values are returned as conflicts, not silently reconciled.
5. Sovereign identifiers require the strictest threshold and must be marked
   `unverified` unless found in an official registry, filing, tax authority, or
   similarly authoritative source.

GPT must not:

- invent or normalize legal identifiers beyond formatting cleanup
- create parent/subsidiary links without source evidence
- infer revenue from vague market statements
- use a commercial provider's proprietary ID as the sovereign anchor
- output personally sensitive executive contact details unless source and
  lawful-use basis are explicitly approved for the engagement

## Data Cloud Activation Rules

1. CRM Account receives only altitude-3 summary fields.
2. Party identifiers and full firmographic evidence remain in Data Cloud and
   Databricks extension objects.
3. CRM can receive a small number of summary fields:
   - `External_Legal_Name__c`
   - `External_Registration_Number__c`
   - `Externally_Validated__c`
   - `Validity_Score_External__c`
   - `External_Subsidiaries_Found__c`
   - `External_Revenue_Confirmed__c`
   - `Enrichment_Run_Id__c`
4. JSON payload fields remain payload-runbook exceptions when native Copy Field
   cannot write them.

## Implementation Sequence

1. Add contracts for sovereign identifiers and firmographic enrichment output.
2. Add Data Cloud mapping artifact for Party Identification and firmographic
   extension DMOs.
3. Add GPT enrichment prompt/spec with source, confidence, and conflict rules.
4. Extend Databricks gold export with identifier and firmographic extension
   tables.
5. Create Data Cloud DLO/DMO mappings through a runbook where metadata is
   org-locked.
6. Add validators for:
   - identifier type taxonomy
   - Party Identification required fields
   - evidence confidence and source URL presence
   - no provider ID marked as sovereign
   - no GPT value without cited source evidence

## References

- Salesforce KYC data model:
  https://developer.salesforce.com/docs/platform/data-models/guide/know-your-customer.html
- Salesforce Party DMO:
  https://developer.salesforce.com/docs/data/data-cloud-dmo-mapping/guide/c360dm-party-dmo.html
- Salesforce Party Identification DMO:
  https://developer.salesforce.com/docs/data/data-cloud-dmo-mapping/guide/c360dm-party-identification-dmo.html
- InfobelPRO APIs:
  https://www.infobelpro.com/apis
- InfobelPRO business data:
  https://www.infobelpro.com/b2b-data
- InfobelPRO firmographic data:
  https://www.infobelpro.com/b2b-data/firmographic-data
- InfobelPRO group structure:
  https://www.infobelpro.com/b2b-data/group-structure
- BoldData / CompanyData API:
  https://docs.companydata.com/request-company
- BoldData / CompanyData response fields:
  https://docs.companydata.com/returned-fields
