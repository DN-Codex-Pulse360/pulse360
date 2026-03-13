# Contract: Salesforce CRM -> Databricks Pulse360 Source Ingestion

## Purpose
Define the comprehensive Salesforce CRM source data that Pulse360 should ingest into Databricks before cleaning, enrichment, identity, hierarchy stitching, governance scoring, and activation-ready export to Data Cloud and Salesforce CRM.

This contract expands the earlier Account-only requirement into a broader Pulse360 source model aligned with:
- the live Salesforce CRM schema in `pulse360-dev`
- the Data Cloud canonical model in `docs/contracts/b2b-customer360-canonical-model-v2.md`
- the standard Data Cloud subject areas for Party, Product, Sales Order, and Data Cloud Overview
- the downstream need to activate enriched account context back into Salesforce CRM

## Point of View
Pulse360 should ingest more source CRM data, not less.

The right pattern is:
1. Ingest broad Salesforce CRM source domains into Databricks.
2. Preserve native CRM keys and relationships unchanged in bronze/silver.
3. Build cleaned, enriched, and intelligence-ready gold outputs that still retain CRM-writeback-safe associations.
4. Publish canonical and extension exports to Data Cloud.
5. Activate account-centric derived values back to Salesforce CRM only when the match key remains deterministic.

Databricks-origin synthetic entity IDs are acceptable for internal analytics and graph processing, but they are not acceptable as the sole CRM writeback key.

## Data Cloud Model Alignment
Pulse360 should align its upstream Salesforce-to-Databricks ingestion model to these standard Data Cloud subject areas:

### Party / Identity Domain
Key standard entities highlighted by Salesforce:
- Account
- Account Contact
- Individual
- Lead
- Contact Point Address
- Contact Point Email
- Contact Point Phone
- Identity Match
- Unified Individual

Pulse360 implication:
- Account and person/contact ingestion must be broad enough to support both enterprise account analytics and person-level relationship context.
- Databricks should preserve account-contact-person keys needed to rebuild or enrich Account -> Account Contact -> Individual relationships in Data Cloud.

### Product Domain
Key standard entities highlighted by Salesforce:
- Brand
- Goods Product
- Master Product
- Bundle Product
- Product Catalog
- Product Category
- Product Category Product
- Opportunity Product
- Sales Order Product
- Product Browse Engagement

Pulse360 implication:
- Product and brand should not be treated as optional add-ons; they are part of the core Pulse360 commercial and cross-sell model.
- Databricks should retain enough source or derived keys to populate canonical product, brand, and product-engagement structures in Data Cloud.

### Sales Order / Commercial Domain
Key standard entities highlighted by Salesforce:
- Sales Order
- Sales Order Product
- Opportunity
- Account
- Account Contact
- Brand
- Goods Product
- Master Product

Pulse360 implication:
- Opportunity and order context should be modeled as commercial events around the account, not just scalar fields on Account.
- Databricks ingestion should retain order/opportunity/product/account relationships so Account 360 views can roll up spend, product ownership, and cross-sell context with traceable lineage.

### Data Cloud Overview Domain
Key standard entities highlighted by Salesforce:
- Account
- Account Contact
- Case
- Contact Point Address/Email/Phone/App
- Device / Device Application Engagement
- Goods Product / Bundle Product / Master Product
- Product Browse Engagement
- Product Order Engagement
- Sales Order / Sales Order Product
- Shopping Cart Engagement
- Unified Individual

Pulse360 implication:
- The Pulse360 source model should be intentionally broader than Account-only CRM replication.
- DS-01, DS-02, and DS-03 should be able to draw on party, service, engagement, and product/order context without redesigning the upstream ingestion contract.

## Source-of-Truth and Keying Rules

### Required CRM Writeback Keys
- Preferred writeback key: native Salesforce `Account.Id`
- Allowed alternative: a dedicated Salesforce External ID field present on `Account`
- The approved CRM writeback key must be preserved unchanged from CRM -> Databricks -> Data Cloud -> CRM activation

### General Rules
1. Databricks must ingest actual Salesforce CRM source records for every domain used in DS-01/DS-02/DS-03.
2. Bronze layer must preserve source keys and relationship keys exactly as received from Salesforce.
3. Silver/gold layers may normalize and enrich records, but must not replace or silently remap CRM source keys.
4. If a downstream CRM writeback path lacks either native `Account.Id` or an approved External ID, the path is invalid for acceptance.

## Pulse360 Source Domains

### 1) Account Core
Primary source object: Salesforce `Account`

Live schema review in `pulse360-dev` confirms relevant fields including:
- `Id`
- `Name`
- `Type`
- `ParentId`
- `OwnerId`
- `Industry`
- `AccountNumber`
- `Website`
- `Billing*`
- `Shipping*`
- `AnnualRevenue`
- `NumberOfEmployees`
- `AccountSource`
- `Rating`
- `Description`
- `DunsNumber`
- `CreatedDate`
- `LastModifiedDate`
- `SystemModstamp`

#### Required Fields
| Salesforce field | Required | Role |
| --- | --- | --- |
| `Id` | Yes | Preferred CRM writeback key |
| `Name` | Yes | Account identity |
| `ParentId` | Yes | Hierarchy baseline |
| `OwnerId` | Yes | Sales ownership |
| `Type` | Yes | Account classification |
| `Industry` | Yes | Firmographic context |
| `AccountNumber` | Recommended | Business identifier and duplicate support |
| `Website` | Recommended | Duplicate/enrichment support |
| `BillingCity` | Recommended | Geographic normalization |
| `BillingState` or `BillingStateCode` | Recommended | Geographic normalization |
| `BillingCountry` or `BillingCountryCode` | Recommended | Geographic normalization |
| `ShippingCity` | Optional | Fulfillment context |
| `ShippingState` or `ShippingStateCode` | Optional | Fulfillment context |
| `ShippingCountry` or `ShippingCountryCode` | Optional | Fulfillment context |
| `AnnualRevenue` | Recommended | Commercial rollup context |
| `NumberOfEmployees` | Recommended | Firmographic context |
| `AccountSource` | Recommended | Source-system quality context |
| `Rating` | Optional | Sales prioritization context |
| `Description` | Optional | Human-entered context for enrichment/audit |
| `DunsNumber` | Recommended | External firmographic key |
| `CreatedDate` | Yes | Replay/audit |
| `LastModifiedDate` | Yes | Replay/audit |
| `SystemModstamp` | Yes | Incremental watermark |

#### Databricks Landing Columns
| Databricks column | Source field |
| --- | --- |
| `crm_account_id` | `Account.Id` |
| `crm_parent_account_id` | `Account.ParentId` |
| `crm_owner_id` | `Account.OwnerId` |
| `crm_account_name` | `Account.Name` |
| `crm_account_type` | `Account.Type` |
| `crm_industry` | `Account.Industry` |
| `crm_account_number` | `Account.AccountNumber` |
| `crm_website` | `Account.Website` |
| `crm_billing_city` | `Account.BillingCity` |
| `crm_billing_state` | `Account.BillingState` or `Account.BillingStateCode` |
| `crm_billing_country` | `Account.BillingCountry` or `Account.BillingCountryCode` |
| `crm_shipping_city` | `Account.ShippingCity` |
| `crm_shipping_state` | `Account.ShippingState` or `Account.ShippingStateCode` |
| `crm_shipping_country` | `Account.ShippingCountry` or `Account.ShippingCountryCode` |
| `crm_annual_revenue` | `Account.AnnualRevenue` |
| `crm_number_of_employees` | `Account.NumberOfEmployees` |
| `crm_account_source` | `Account.AccountSource` |
| `crm_rating` | `Account.Rating` |
| `crm_description` | `Account.Description` |
| `crm_duns_number` | `Account.DunsNumber` |
| `crm_created_at` | `Account.CreatedDate` |
| `crm_last_modified_at` | `Account.LastModifiedDate` |
| `crm_system_modstamp` | `Account.SystemModstamp` |

### 2) Contact and Person Context
Primary source object: Salesforce `Contact`

Live schema review in `pulse360-dev` confirms relevant fields including:
- `Id`
- `AccountId`
- `FirstName`
- `LastName`
- `Name`
- `Email`
- `Phone`
- `MobilePhone`
- `Title`
- `Department`
- `LeadSource`
- `Mailing*`
- `IndividualId`
- `CreatedDate`
- `LastModifiedDate`
- `SystemModstamp`

#### Required Fields
| Salesforce field | Required | Role |
| --- | --- | --- |
| `Id` | Yes | Contact key |
| `AccountId` | Yes | Account-contact relationship |
| `FirstName` | Recommended | Person identity |
| `LastName` | Yes | Person identity |
| `Name` | Yes | Presentation identity |
| `Email` | Recommended | Reachability and identity |
| `Phone` | Optional | Reachability |
| `MobilePhone` | Optional | Reachability |
| `Title` | Recommended | Role/decision-maker context |
| `Department` | Optional | Role context |
| `LeadSource` | Optional | Acquisition context |
| `MailingCity` | Optional | Geography |
| `MailingState` or `MailingStateCode` | Optional | Geography |
| `MailingCountry` or `MailingCountryCode` | Optional | Geography |
| `IndividualId` | Recommended | Link to canonical person/individual strategy |
| `CreatedDate` | Yes | Replay/audit |
| `LastModifiedDate` | Yes | Replay/audit |
| `SystemModstamp` | Yes | Incremental watermark |

#### Databricks Landing Columns
| Databricks column | Source field |
| --- | --- |
| `crm_contact_id` | `Contact.Id` |
| `crm_contact_account_id` | `Contact.AccountId` |
| `crm_contact_first_name` | `Contact.FirstName` |
| `crm_contact_last_name` | `Contact.LastName` |
| `crm_contact_name` | `Contact.Name` |
| `crm_contact_email` | `Contact.Email` |
| `crm_contact_phone` | `Contact.Phone` |
| `crm_contact_mobile_phone` | `Contact.MobilePhone` |
| `crm_contact_title` | `Contact.Title` |
| `crm_contact_department` | `Contact.Department` |
| `crm_contact_lead_source` | `Contact.LeadSource` |
| `crm_contact_mailing_city` | `Contact.MailingCity` |
| `crm_contact_mailing_state` | `Contact.MailingState` or `Contact.MailingStateCode` |
| `crm_contact_mailing_country` | `Contact.MailingCountry` or `Contact.MailingCountryCode` |
| `crm_individual_id` | `Contact.IndividualId` |
| `crm_contact_created_at` | `Contact.CreatedDate` |
| `crm_contact_last_modified_at` | `Contact.LastModifiedDate` |
| `crm_contact_system_modstamp` | `Contact.SystemModstamp` |

### 3) Opportunity and Commercial Intent
Primary source object: Salesforce `Opportunity`

Live schema review in `pulse360-dev` confirms relevant fields including:
- `Id`
- `AccountId`
- `OwnerId`
- `Name`
- `StageName`
- `Amount`
- `Probability`
- `ExpectedRevenue`
- `CloseDate`
- `Type`
- `LeadSource`
- `ForecastCategory`
- `Pricebook2Id`
- `ContactId`
- `IsClosed`
- `IsWon`
- `CreatedDate`
- `LastModifiedDate`
- `SystemModstamp`

#### Required Fields
| Salesforce field | Required | Role |
| --- | --- | --- |
| `Id` | Yes | Opportunity key |
| `AccountId` | Yes | Account linkage |
| `OwnerId` | Yes | Sales ownership |
| `Name` | Yes | Opportunity identity |
| `StageName` | Yes | Pipeline stage |
| `Amount` | Recommended | Commercial magnitude |
| `Probability` | Recommended | Commercial likelihood |
| `ExpectedRevenue` | Optional | Forecast view |
| `CloseDate` | Yes | Time context |
| `Type` | Recommended | Opportunity classification |
| `LeadSource` | Optional | Acquisition context |
| `ForecastCategory` or `ForecastCategoryName` | Recommended | Forecast rollups |
| `Pricebook2Id` | Optional | Product pricing context |
| `ContactId` | Optional | Direct contact association |
| `IsClosed` | Yes | Lifecycle state |
| `IsWon` | Yes | Outcome state |
| `CreatedDate` | Yes | Replay/audit |
| `LastModifiedDate` | Yes | Replay/audit |
| `SystemModstamp` | Yes | Incremental watermark |

#### Databricks Landing Columns
| Databricks column | Source field |
| --- | --- |
| `crm_opportunity_id` | `Opportunity.Id` |
| `crm_opportunity_account_id` | `Opportunity.AccountId` |
| `crm_opportunity_owner_id` | `Opportunity.OwnerId` |
| `crm_opportunity_name` | `Opportunity.Name` |
| `crm_opportunity_stage_name` | `Opportunity.StageName` |
| `crm_opportunity_amount` | `Opportunity.Amount` |
| `crm_opportunity_probability` | `Opportunity.Probability` |
| `crm_opportunity_expected_revenue` | `Opportunity.ExpectedRevenue` |
| `crm_opportunity_close_date` | `Opportunity.CloseDate` |
| `crm_opportunity_type` | `Opportunity.Type` |
| `crm_opportunity_lead_source` | `Opportunity.LeadSource` |
| `crm_opportunity_forecast_category` | `Opportunity.ForecastCategory` or `Opportunity.ForecastCategoryName` |
| `crm_pricebook_id` | `Opportunity.Pricebook2Id` |
| `crm_primary_contact_id` | `Opportunity.ContactId` |
| `crm_opportunity_is_closed` | `Opportunity.IsClosed` |
| `crm_opportunity_is_won` | `Opportunity.IsWon` |
| `crm_opportunity_created_at` | `Opportunity.CreatedDate` |
| `crm_opportunity_last_modified_at` | `Opportunity.LastModifiedDate` |
| `crm_opportunity_system_modstamp` | `Opportunity.SystemModstamp` |

### 3b) Sales Order Point of View
The live Salesforce org may not expose standard `Order`/sales-order objects in the same shape as Data Cloud’s Sales Order subject area, but Pulse360 should still design for that domain.

Pulse360 recommendation:
- Treat opportunity lifecycle as the minimum commercial intent source.
- Add order/sales-order ingestion when available from Salesforce CRM, commerce, ERP, or downstream order systems.
- Preserve the same relationship shape expected by the Data Cloud Sales Order subject area:
  - Account
  - Account Contact / Individual
  - Sales Order
  - Sales Order Product
  - Goods Product / Master Product / Bundle Product
  - Brand

Minimum future-ready fields for order ingestion:
| Field | Role |
| --- | --- |
| `sales_order_id` | Order key |
| `sales_order_account_id` | Account linkage |
| `sales_order_contact_id` | Buyer/contact linkage when available |
| `sales_order_date` | Order date |
| `sales_order_status` | Commercial lifecycle |
| `sales_order_currency_code` | Monetary context |
| `sales_order_total_amount` | Commercial rollup |
| `sales_order_product_id` | Product linkage |
| `sales_order_product_quantity` | Product quantity |
| `sales_order_product_amount` | Line-level amount |
| `brand_id` | Brand linkage |
| `master_product_id` | Product hierarchy linkage |

### 4) Opportunity Contact Roles
Primary source object: Salesforce `OpportunityContactRole`

Live schema review in `pulse360-dev` confirms relevant fields including:
- `OpportunityId`
- `ContactId`
- `Role`
- `IsPrimary`
- `CreatedDate`
- `LastModifiedDate`
- `SystemModstamp`

#### Required Fields
| Salesforce field | Required | Role |
| --- | --- | --- |
| `OpportunityId` | Yes | Opportunity relationship |
| `ContactId` | Yes | Contact relationship |
| `Role` | Recommended | Buying role context |
| `IsPrimary` | Recommended | Primary role designation |
| `CreatedDate` | Yes | Replay/audit |
| `LastModifiedDate` | Yes | Replay/audit |
| `SystemModstamp` | Yes | Incremental watermark |

### 5) Product and Commercial Line Items
Primary source objects:
- Salesforce `Product2`
- Salesforce `OpportunityLineItem`
- Salesforce `Pricebook2` (relationship/supporting reference)

Live schema review in `pulse360-dev` confirms:
- `Product2` fields: `Id`, `Name`, `ProductCode`, `Family`, `ExternalId`, `StockKeepingUnit`, `Type`, `ProductClass`, `IsActive`
- `OpportunityLineItem` fields: `Id`, `OpportunityId`, `PricebookEntryId`, `Product2Id`, `ProductCode`, `Name`, `Quantity`, `UnitPrice`, `ListPrice`, `TotalPrice`, `ServiceDate`

#### Product2 Required Fields
| Salesforce field | Required | Role |
| --- | --- | --- |
| `Id` | Yes | Product key |
| `Name` | Yes | Product identity |
| `ProductCode` | Recommended | Commercial product key |
| `Family` | Recommended | Product grouping |
| `StockKeepingUnit` | Optional | SKU support |
| `Type` | Optional | Product classification |
| `ProductClass` | Optional | Product taxonomy |
| `ExternalId` | Recommended | External product identity |
| `IsActive` | Yes | Product validity |
| `CreatedDate` | Yes | Replay/audit |
| `LastModifiedDate` | Yes | Replay/audit |
| `SystemModstamp` | Yes | Incremental watermark |

#### OpportunityLineItem Required Fields
| Salesforce field | Required | Role |
| --- | --- | --- |
| `Id` | Yes | Opportunity line key |
| `OpportunityId` | Yes | Opportunity relationship |
| `Product2Id` | Yes | Product relationship |
| `PricebookEntryId` | Recommended | Pricing relationship |
| `ProductCode` | Recommended | Product identity |
| `Name` | Recommended | Product display |
| `Quantity` | Yes | Commercial quantity |
| `UnitPrice` | Recommended | Commercial value |
| `ListPrice` | Optional | Pricing reference |
| `TotalPrice` | Recommended | Commercial value |
| `ServiceDate` | Optional | Time context |
| `CreatedDate` | Yes | Replay/audit |
| `LastModifiedDate` | Yes | Replay/audit |
| `SystemModstamp` | Yes | Incremental watermark |

### 6) Brand Point of View
Observed org objects include:
- `BusinessBrand`
- `CustomBrand`
- `BrandTemplate`

Data Cloud canonical model in the repo already targets:
- `ssot__Brand__dlm`
- `ssot__GoodsProduct__dlm`
- `ssot__MasterProduct__dlm`

#### Pulse360 Recommendation
- Do not force Salesforce `Brand*` objects to be the sole source of truth unless the implementation team confirms active business usage in CRM.
- For the prototype, support two acceptable brand paths:
  1. CRM-native brand objects where present and operationally owned
  2. Databricks- or MDM-derived brand/master-product relationships published to Data Cloud canonical product/brand exports

#### Required Brand/Product Relationship Contract
At minimum, Databricks and Data Cloud outputs must preserve:
| Field | Role |
| --- | --- |
| `product_id` | Product key |
| `master_product_id` | Master product grouping |
| `bundle_product_id` | Bundle context when relevant |
| `brand_id` | Brand key |
| `brand_name` | Human-readable brand |
| `relationship_type` | Product-brand linkage semantics |
| `is_active` | Validity flag |

### 7) Engagement Domain
Pulse360 should ingest and model engagement beyond just opportunities.

Minimum supported engagement categories:
- opportunity lifecycle events
- opportunity line item/product intent
- contact-role participation
- CRM activity-derived engagement when available
- product browse/order/cart engagement when available from commerce or downstream systems
- service/governance interactions where they materially affect account health and activation
- Data Cloud engagement exports already defined in the repo canonical contract

#### Minimum Engagement Landing Contract
| Databricks column | Role |
| --- | --- |
| `engagement_id` | Unique engagement key |
| `engagement_type` | Opportunity, meeting, task, email, order, browse, etc. |
| `engagement_timestamp` | Event time |
| `crm_account_id` | Account linkage |
| `crm_contact_id` | Contact/person linkage when available |
| `crm_opportunity_id` | Opportunity linkage when available |
| `product_id` | Product linkage when available |
| `brand_id` | Brand linkage when available |
| `engagement_score` | Derived intensity/value |
| `source_system` | Origin traceability |

## Data Cloud Alignment
This source-ingestion contract should feed the canonical Data Cloud-aligned export domains already defined in the repo:
- `account_core_export`
- `account_contact_export`
- `individual_export`
- `product_brand_export`
- `engagement_export`
- future order/commercial exports where available

The target canonical DMOs remain:
- `ssot__Account__dlm`
- `ssot__AccountContact__dlm`
- `ssot__Individual__dlm`
- `ssot__Opportunity__dlm`
- product/brand DMOs as applicable
- sales order/product DMOs where order sources are available

## Operational and Governance Metadata
Every ingested dataset must preserve:
| Field | Role |
| --- | --- |
| `source_system` | Provenance |
| `source_extract_ts` | Extract timestamp |
| `source_last_modified_ts` | Incremental replay watermark |
| `run_id` | Pipeline run |
| `run_timestamp` | Pipeline execution timestamp |
| `model_version` | Logic/version traceability |
| `ingestion_metadata_label` | Demo/runtime freshness visibility where relevant |

## Downstream Export Rules
1. Databricks cleaning and enrichment may add:
   - duplicate scores
   - hierarchy relationships
   - validity scores
   - review flags
   - product/brand rollups
   - engagement intensity
2. Databricks must not replace CRM source keys with synthetic-only identifiers in any export intended for CRM activation.
3. Activation-ready account exports must include:
   - `source_account_id = crm_account_id`, or
   - `source_account_external_id = approved CRM External ID`
4. Parent-child hierarchy outputs must preserve CRM account associations for both parent and child.
5. Contact-, opportunity-, product-, and engagement-linked exports must preserve the original CRM relationship keys necessary to rebuild canonical relationships in Data Cloud.

## Acceptance Criteria
1. Salesforce CRM Account, Contact, Opportunity, OpportunityContactRole, Product2, and OpportunityLineItem source ingestion is implemented upstream of Databricks enrichment.
2. Databricks preserves the approved CRM writeback key unchanged through bronze, silver, and gold outputs.
3. Data Cloud DMO mapping uses preserved CRM keys rather than Databricks-origin synthetic IDs for CRM activation paths.
4. Product, brand, contact, and engagement context remains relationship-safe through the export layer.
5. Enriched values activate back onto the intended Salesforce CRM `Account` records without manual record matching.

## Validation Checklist
1. Query Salesforce CRM source extracts and confirm native keys are present for:
   - `Account`
   - `Contact`
   - `Opportunity`
   - `OpportunityContactRole`
   - `Product2`
   - `OpportunityLineItem`
2. Query Databricks bronze/silver staging and confirm CRM keys are non-null and relationship-safe.
3. Query activation-ready account export and confirm `source_account_id` equals the ingested CRM `Account.Id`.
4. Reject any activation test where Databricks-origin synthetic account IDs are used as the CRM match key.
5. Validate canonical export relationship integrity across account, product, brand, and engagement outputs.

## Pulse360 Implementation Sequence
1. Ingest CRM source domains to Databricks bronze.
2. Normalize to silver while preserving CRM keys.
3. Build enrichment and intelligence in gold linked to CRM-safe keys.
4. Publish Data Cloud-aligned canonical exports.
5. Map DLO -> DMO including custom DMO fields for Pulse360 enrichment outputs.
6. Activate account-centric derived values back to Salesforce CRM.

## Reference Models
- Data Cloud Overview: https://developer.salesforce.com/docs/platform/data-models/guide/data-cloud-overview.html
- Party Overview: https://developer.salesforce.com/docs/platform/data-models/guide/party-overview.html
- Product: https://developer.salesforce.com/docs/platform/data-models/guide/product.html
- Sales Order: https://developer.salesforce.com/docs/platform/data-models/guide/sales-order.html
