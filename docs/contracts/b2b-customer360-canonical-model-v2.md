# Contract: B2B Customer 360 Canonical Model (Data Cloud Aligned)

## Purpose
Define a canonical enterprise model where Salesforce Data Cloud standard DMOs are the primary data contract for downstream Salesforce CRM and Agentforce use cases.

## Decision
- Canonical model authority: Salesforce Data Cloud standard DMOs (`ssot__*__dlm`).
- Current Databricks intelligence outputs remain required, but become extension entities linked to canonical DMOs.
- CRM activation remains Account-centered while preserving product, brand, hierarchy, and engagement context.

## Scope
This canonical model supports DS-01/DS-02/DS-03 and broader B2B Customer 360 for enterprise accounts.

## Canonical Object Domains

### 1) Enterprise Identity and Account Core (Primary)
| Domain | DMO | Role in Canonical Model |
| --- | --- | --- |
| Account core | `ssot__Account__dlm` (Account) | Primary business entity for B2B customer 360 |
| Account-person bridge | `ssot__AccountContact__dlm` (Account Contact) | Role-based person relationship to account |
| Person profile | `ssot__Individual__dlm` (Individual) | Person identity behind account contacts |
| Contact channels | `Contact Point Email/Phone/Address/App` | Reachability and communication context |
| Case context | `ssot__Case__dlm` (Case) | Service and governance interaction anchor |

### 2) Product and Brand Domain (Primary Related)
| Domain | DMO | Role in Canonical Model |
| --- | --- | --- |
| Product master | `ssot__MasterProduct__dlm` (Master Product) | Enterprise product family/master |
| Sellable SKU | `ssot__GoodsProduct__dlm` (Goods Product) | Concrete sellable product |
| Bundles | `Bundle Product` | Product packages and bundles |
| Brand | `ssot__Brand__dlm` (Brand) | Brand taxonomy linked to products |
| Order header | `ssot__SalesOrder__dlm` (Sales Order) | Commercial transaction header |
| Order lines | `ssot__SalesOrderProduct__dlm` (Sales Order Product) | Product-level transaction detail |

### 3) Engagement and Intent Domain (Primary Related)
| Domain | DMO | Role in Canonical Model |
| --- | --- | --- |
| Opportunity lifecycle | `ssot__Opportunity__dlm` | B2B pipeline intent and commercial state |
| Opportunity line items | `ssot__OpportunityProduct__dlm` | Product-level opportunity intent |
| Email engagement | `ssot__EmailEngagement__dlm` | Marketing and channel intent signal |
| App engagement | `ssot__DeviceApplicationEngagement__dlm` | Digital product/app behavior signal |
| Product browse engagement | `ssot__ProductBrowseEngagement__dlm` | Product interest signal |
| Product order engagement | `ssot__ProductOrderEngagement__dlm` | Purchase/order action signal |
| Shopping cart engagement | `ssot__ShoppingCartEngagement__dlm` | Commerce journey intent signal |

### 4) Intelligence Extensions (Pulse360-Specific)
These are not canonical masters; they are extension datasets linked to canonical keys.

| Extension Dataset | Existing Source | Canonical Link |
| --- | --- | --- |
| Duplicate candidate pairs | `gold.duplicate_candidate_pairs` | Account/AccountContact/Individual IDs |
| Hierarchy graph output | `gold.entity_hierarchy_graph` | Account ID + Parent Account ID |
| Firmographic enrichment | `gold.firmographic_enrichment` | Account ID |
| Governance metrics | `gold.governance_ops_metrics` | Account/Case/Run metadata |

## Required Canonical Relationships
1. Account -> Account (parent-child) for enterprise hierarchy rollups.
2. Account -> Account Contact -> Individual for B2B buyer/decision-maker mapping.
3. Account -> Sales Order -> Sales Order Product -> Goods/Master/Bundle Product.
4. Goods/Master/Bundle Product -> Brand.
5. Opportunity -> Opportunity Product -> Goods/Master Product.
6. Engagement DMOs -> Account Contact/Individual and relevant Product/Case where available.
7. All extension intelligence records must resolve to canonical Account (and optionally Account Contact/Individual).

## Canonical Keys and Survivorship
1. Canonical business key: Data Cloud Account ID (`ssot__Id__c`) with deterministic external key persisted for replay-safe mapping.
2. Identity scoring and survivorship remain rule-based (current `identity-resolution-rules.json`), but output writes must reference canonical DMO IDs.
3. Master record selection can remain `highest_validity_score` for merge recommendation; final merged representation must land in canonical DMO-aligned objects.

## Minimum Field Contract (Cross-Domain)
| Field Group | Minimum Fields |
| --- | --- |
| Identity | `ssot__Id__c`, external source ID, deterministic key, source system |
| Hierarchy | `Parent Account ID`, hierarchy depth/path attributes |
| Product context | Product ID, master product ID, bundle ID (when applicable), brand ID |
| Engagement context | engagement ID, timestamp, channel, related account/contact/person/product |
| Governance/traceability | run ID, run timestamp, model version, review flag, confidence/validity |

## Current Repo Fit Assessment
1. Feasible with high confidence: existing contracts already carry deterministic IDs, hierarchy links, confidence, and run metadata.
2. Current gap: contract schemas are intelligence-shaped (`entity_id`, `hierarchy_parent_id`, `validity_score`) instead of explicit DMO-shaped keys/relationships.
3. Current gap: product and brand entities are not first-class in the current handoff contract.
4. Current gap: engagement model is not yet defined as a canonical DMO set across email/app/browse/order/cart.

## Migration Approach (Recommended)
1. Keep existing contracts operational for DS-01/02/03 continuity.
2. Add a new Data Cloud-aligned export layer with DMO-oriented tables/files:
   - `account_core_export`
   - `account_contact_export`
   - `individual_export`
   - `product_brand_export`
   - `engagement_export`
3. Map current fields:
   - `entity_id` -> canonical Account ID/external deterministic key mapping table.
   - `hierarchy_parent_id`/`hierarchy_child_id` -> Account parent-child relationship mapping.
   - `duplicate_confidence`/`validity_score`/`review_flag` -> intelligence extension objects and CRM activation fields.
4. Update activation mapping to include account, product, brand, and engagement-derived rollups.
5. Add schema validation scripts for each canonical export and relationship integrity checks.

## Governance Rules
1. Salesforce CRM and Agentforce consume canonical + derived insights; they never become source-of-truth for core identity.
2. Every canonical record must be lineage-traceable to source and run metadata.
3. Confidence thresholds for auto-merge remain configurable and auditable.
4. Low-confidence or conflicting attributes require review workflow, not silent overwrite.

## Feasibility Conclusion
Yes, this is achievable and aligns with Data Cloud’s standard model strategy. The recommended architecture is:
1. Data Cloud DMOs as canonical enterprise model.
2. Databricks intelligence as extension layer linked to canonical keys.
3. CRM activation views derived from canonical + extension signals for B2B Customer 360.

## References
- Data model reference: https://developer.salesforce.com/docs/data/data-cloud-dmo-mapping/guide/c360dm-model-data.html
- Standard DMO index: https://developer.salesforce.com/docs/data/data-cloud-ref/guide/c360dm-datamodelobjects.html
- Account DMO: https://developer.salesforce.com/docs/data/data-cloud-ref/guide/c360dm-account-dmo.html
- Account Contact DMO: https://developer.salesforce.com/docs/data/data-cloud-ref/guide/c360dm-account-contact-dmo.htm
- Individual DMO: https://developer.salesforce.com/docs/data/data-cloud-ref/guide/c360dm-individual-dmo.html
- Brand DMO: https://developer.salesforce.com/docs/data/data-cloud-ref/guide/c360dm-brand-dmo.htm
- Goods Product DMO: https://developer.salesforce.com/docs/data/data-cloud-dmo-mapping/guide/c360dm-goods-product-dmo.html
- Master Product DMO: https://developer.salesforce.com/docs/data/data-cloud-dmo-mapping/guide/c360dm-base-product-dmo.html
- Opportunity DMO: https://developer.salesforce.com/docs/data/data-cloud-dmo-mapping/guide/c360dm-opportunity-dmo.html
- Opportunity Product DMO: https://developer.salesforce.com/docs/data/data-cloud-dmo-mapping/guide/c360dm-opportunity-product-dmo.html
- Sales Order DMO: https://developer.salesforce.com/docs/data/data-cloud-dmo-mapping/guide/c360dm-sales-order-dmo.html
- Sales Order Product DMO: https://developer.salesforce.com/docs/data/data-cloud-dmo-mapping/guide/c360dm-sales-order-product-dmo.html
- Email Engagement DMO: https://developer.salesforce.com/docs/data/data-cloud-ref/guide/c360dm-email-engagement-dmo.html
- Device Application Engagement DMO: https://developer.salesforce.com/docs/data/data-cloud-dmo-mapping/guide/c360dm-device-application-engagement-dmo.html
- Product Browse Engagement DMO: https://developer.salesforce.com/docs/data/data-cloud-dmo-mapping/guide/c360dm-product-browse-engagement-dmo.html
- Product Order Engagement DMO: https://developer.salesforce.com/docs/data/data-cloud-ref/guide/c360dm-product-order-engagement-dmo.html
- Shopping Cart Engagement DMO: https://developer.salesforce.com/docs/data/data-cloud-ref/guide/c360dm-shopping-cart-engagement-dmo.html
