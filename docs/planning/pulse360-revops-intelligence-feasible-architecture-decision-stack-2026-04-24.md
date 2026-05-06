# Pulse360 RevOps Intelligence Feasible Architecture Decision Stack

## Purpose

This document converts the revised Pulse360 RevOps Intelligence proposition into a source-backed build decision stack.

It deliberately separates four kinds of claims:

- `built`: already present in repo or current connected runtime.
- `feasible`: supported by current Databricks or Salesforce platform capabilities, but not necessarily implemented in this repo.
- `gated`: feasible, but dependent on customer entitlement, region availability, provider contract, target-org capability, or human setup.
- `roadmap`: plausible future or later-phase scope that should not block the first implementation slice.

The goal is to guide implementation from the industry-feasible solution, not merely from the existing prototype.

## Source Inputs

- Value proposition: `/Users/danielnortje/Desktop/Huron/AI CoE/Account360/pulse360-revops-value-proposition.html`
- Existing UX realignment program: `docs/improvements/pulse360-research-led-ux-realignment-program-2026-04-19.md`
- Current Databricks CRM ingestion plan: `docs/planning/databricks-salesforce-crm-ingestion-implementation-plan.md`
- Current Databricks to Data Cloud contract: `docs/contracts/databricks-to-datacloud-contract.md`
- Current Salesforce CRM to Databricks contract: `docs/contracts/salesforce-crm-to-databricks-account-ingestion-contract.md`
- Firmographic evidence/GPT enrichment design: `docs/planning/pulse360-databricks-firmographic-provider-genai-design-2026-04-25.md`
- Linear parent: `DAN-280`
- Linear implementation spine: `DAN-281` through `DAN-292`

## External Platform References

Use official product sources as the feasibility basis:

- Databricks Lakeflow Connect Salesforce ingestion: https://docs.databricks.com/en/ingestion/lakeflow-connect/salesforce/salesforce-ingestion/index.html
- Databricks Unity Catalog lineage: https://docs.databricks.com/aws/en/data-governance/unity-catalog/data-lineage
- Databricks Delta Sharing: https://docs.databricks.com/aws/en/delta-sharing
- Databricks Clean Rooms: https://docs.databricks.com/aws/en/clean-rooms
- Databricks Feature Store: https://docs.databricks.com/aws/en/machine-learning/feature-store
- Databricks Mosaic AI Model Serving: https://docs.databricks.com/aws/en/machine-learning/model-serving/
- Databricks Vector Search: https://docs.databricks.com/aws/en/vector-search/vector-search
- Salesforce Data 360 extensibility readiness matrix: https://developer.salesforce.com/docs/data/data-cloud-dmo-mapping/guide/c360a-api-isv-readiness-data.html
- Salesforce Databricks Model Builder/BYOM example: https://developer.salesforce.com/blogs/2024/03/use-model-builder-to-integrate-databricks-models-with-salesforce
- Salesforce Agentforce actions: https://developer.salesforce.com/docs/ai/agentforce/guide/get-started-actions.html
- Salesforce Agentforce citations: https://developer.salesforce.com/docs/ai/agentforce/guide/citations.html
- Salesforce Einstein Trust Layer: https://developer.salesforce.com/docs/ai/agentforce/guide/trust.html

Firmographic provider API specifications are used only to infer common evidence structures such as company identity, official identifiers, location, classification, legal status, financials, hierarchy hints, contact/web presence, technographic signals, reliability, freshness, and license metadata. No paid-provider endpoint or vendor-specific runtime is hardwired into the design.

## Architecture North Star

Pulse360 should become a RevOps intelligence platform where:

1. Identity is anchored on sovereign or regulator-issued identifiers where available.
2. CRM-safe IDs are preserved so enriched intelligence can still activate back to Salesforce.
3. Enrichment is plural: registry, commercial provider, customer-internal, internet research, and collaborative data may contribute.
4. Attribute values are weighted, explainable, fresh, and source-traceable.
5. Databricks holds the full graph and signal detail.
6. Data Cloud/Data 360 holds the curated operational profile.
7. Salesforce shows the altitude-3 weighted summary and workflow actions.
8. Agentforce is used only when native runtime is available and verified; otherwise the experience is described as custom assistant/action UI.

## Three-Altitude Mapping

| Altitude | User Need | Platform Shape | Claim Status |
| --- | --- | --- | --- |
| Altitude 1 - Databricks full graph | Every source, signal, feature, run, model, and lineage detail | Unity Catalog tables/views, feature tables, model registry, lineage, notebooks/jobs, governed gold exports | `built` for CRM-source foundation; `feasible` for full plural graph |
| Altitude 2 - Data Cloud/Data 360 operational profile | Curated profile, segmentation, calculated insights, activation-ready attributes | DLO/DMO mapping, zero-copy or ingestion path, Calculated Insights, enrichments | `built` for existing account activation slice; `gated` for full zero-copy and DMO expansion |
| Altitude 3 - Salesforce weighted summary | What matters next and what action to take | Account/Opportunity/Home LWCs, actions, governance cases, optional Agentforce channels | `built` for selected custom surfaces; `gated` for native Agentforce runtime |

## Platform-Native, Custom, Gated, Roadmap Matrix

| Capability | Target Design | Classification | Delivery Notes | Linear |
| --- | --- | --- | --- | --- |
| Salesforce CRM ingestion into Databricks | Lakeflow Connect or equivalent governed CRM ingestion into bronze | `built` plus `native` | Current repo/runtime has Salesforce bronze ingestion; future work should keep it as the CRM source foundation. | `DAN-116`, `DAN-281` |
| Sovereign identity spine | Country + ID type + ID value + registered legal name | `custom implementation` | Databricks can implement the model, but country-specific registry data and matching rules must be built and governed. | `DAN-282` |
| Provider IDs as attributes | DUNS, ZoomInfo, BvD, Crunchbase, internal IDs as xrefs | `custom implementation` plus `gated` | Depends on provider contracts and data access. IDs must not replace the sovereign or CRM-safe keys. | `DAN-282`, `DAN-283` |
| Firmographic evidence adapters | Provider-neutral bronze/silver pattern for company identity, identifiers, location, classification, legal status, financials, hierarchy hints, contact/web presence, technographic signals, reliability, freshness, and license metadata | `custom implementation` plus `gated` | Provider API specs inform the evidence shape only. No endpoint, paid service, or vendor runtime is a design dependency. Raw payloads, request/import logs, license refs, field-set versions, and run metadata must be retained. | `DAN-283`, `DAN-285`, `DAN-290` |
| Plural enrichment ingestion | Registries, Marketplace providers, internal systems, research, clean rooms | `feasible` plus `gated` | Databricks supports Delta Sharing, Clean Rooms, connectors, and AI extraction patterns; contracts and licenses decide scope. | `DAN-283` |
| Internet research extraction | Structured facts from filings, websites, news, PDFs | `feasible` plus `custom implementation` | Use governed notebooks/jobs, document parsing, AI functions, Vector Search, and citation capture. | `DAN-283`, `DAN-290` |
| Entity resolution | Deterministic and probabilistic account resolution | `custom implementation` | Use blocking, exact sovereign-ID rules, fuzzy/legal-name matching, provider xrefs, and steward review for weak matches. | `DAN-284` |
| Hierarchy stitching | Parent-child graph with confidence and rollups | `custom implementation` | Databricks is a strong fit for graph-shaped tables and recursive/path rollups; conflict handling is custom. | `DAN-284` |
| Weighted attribute resolution | Per-attribute source weighting and survivorship | `custom implementation` | Differentiating product logic; must expose source contribution and freshness. | `DAN-285` |
| Feature engineering | Governed feature tables for models | `native` plus `custom implementation` | Databricks Feature Store supports feature governance; feature definitions are Pulse360-specific. | `DAN-286` |
| GPT/OpenAI firmographic reasoning | Source-bound extraction, narrative generation, recommended actions, and confidence scoring over governed firmographic/registry/CRM facts | `custom implementation` plus `gated` | GPT can summarize, extract, rank, and explain, but cannot create unsupported identifiers, revenue, employee count, or hierarchy facts. Every output requires source IDs, model ID, prompt version, input/output hashes, run metadata, confidence components, and cost/audit metadata. | `DAN-286`, `DAN-290` |
| Model serving | ICP, churn, propensity, routing, fuzzy-match models | `native` plus `custom implementation` | Mosaic AI Model Serving supports endpoints; model training, validation, and monitoring are custom. | `DAN-286` |
| Salesforce BYOM | Databricks model output consumed in Salesforce/Data Cloud | `feasible` plus `gated` | Depends on Salesforce org entitlement and Databricks endpoint readiness. | `DAN-286`, `DAN-287` |
| Data Cloud zero-copy | Data Cloud queries Databricks gold outputs | `feasible` plus `gated` | Supported in platform readiness material, but org/region/runtime setup must be validated per customer. | `DAN-287` |
| Data Cloud DMO/Calculated Insights | Operational account/contact/opportunity/product profile | `feasible` plus `custom implementation` | Mapping design and setup/runbooks are required. | `DAN-287` |
| Copy Field Enrichment | Summary fields copied down to Salesforce records | `built` for current slice; `gated` for full target | Keep summary-only rule; 1-to-many detail should use related-list/drill-through patterns. | `DAN-287`, `DAN-288` |
| Salesforce UX surfaces | Account, planner, signal, renewal, governance, buying committee surfaces | `built` for selected surfaces; `custom implementation` for full suite | Must keep weighted summary as the default, with drill-through to evidence. | `DAN-288` |
| Native Agentforce | Agentforce actions, citations, Trust Layer | `feasible` plus `gated` | Do not claim native Agentforce success until target org Builder/runtime support is verified. | `DAN-289` |
| Governance and lineage evidence | Defensible source, model, freshness, decision audit | `built` in parts; `custom implementation` for full coverage | Unity Catalog helps, but every external/LLM-derived fact also needs explicit source metadata. | `DAN-290` |
| Six module delivery | M1 hierarchy through M6 renewal risk | `custom implementation` | M1 should lead because hierarchy unlocks whitespace, coverage, and renewal context. | `DAN-291` |

## Target Data Products

### Databricks Bronze

- `bronze_salesforce.*`: CRM source tables from Salesforce.
- `bronze_registry.*`: regulator and national registry snapshots.
- `bronze_firmographic.*`: approved firmographic evidence payloads, source/import logs, reference codes, identifiers, license snapshots, and run metadata.
- `bronze_internal.*`: customer-internal relationship, product, entitlement, usage, support, and contract sources.
- `bronze_research.*`: extracted internet/document facts with source URL, extraction timestamp, parser/model version, and citation text.
- `bronze_collaborative.*`: clean-room or consortium-derived aggregate signals where approved.

### Databricks Silver

- Normalized source-specific identity views.
- CRM account/contact/opportunity/product/commercial views.
- Sovereign identity candidate views.
- Provider xref views.
- Firmographic fact, hierarchy hint, reference-code, and technographic signal views.
- Contact/person candidate views.
- Research fact normalization views.

### Databricks Gold

- `resolved_entity`
- `resolved_entity_source_xref`
- `entity_match_candidate`
- `entity_hierarchy_edge`
- `entity_hierarchy_rollup`
- `weighted_attribute_resolution`
- `source_contribution`
- `account_firmographic_enrichment`
- `account_genai_enrichment_output`
- `account_feature_snapshot`
- `model_score_output`
- `datacloud_account_profile_export`
- `datacloud_relationship_export`
- `governance_resolution_candidate`

## Module Dependency Strategy

| Module | First Slice | Dependencies | Delivery Posture |
| --- | --- | --- | --- |
| M1 Account Hierarchy Intelligence | Sovereign/CRM-safe account identity, hierarchy edge, group revenue, coverage gap, Group Revenue Reveal | `DAN-282`, `DAN-284`, `DAN-287`, `DAN-288` | Start here |
| M2 ICP Fit and Account Scoring | Feature table, account score, top drivers, Account/Lead score surface | `DAN-283`, `DAN-285`, `DAN-286`, `DAN-288` | After source/feature contract |
| M3 Whitespace and Expansion | Product ownership, uncovered subsidiary/product grid, NBA action | M1 plus `DAN-286`, `DAN-288`, `DAN-289` | Depends on M1 |
| M4 Buying Committee | Contact/person resolution, role gaps, drafted outreach | `DAN-283`, `DAN-284`, `DAN-287`, `DAN-288` | Data-dependent |
| M5 Intent Routing | Intent inputs, thresholding, routing queue, Slack/Salesforce path | `DAN-283`, `DAN-286`, `DAN-288`, `DAN-289` | Can progress in parallel |
| M6 Renewal Risk | Engagement/support/usage features, risk model, save play | `DAN-283`, `DAN-286`, `DAN-287`, `DAN-288` | Depends on source availability |

## First 30/60/90 Day Plan

### First 30 Days

- Complete `DAN-281` decision stack and keep it linked from Linear.
- Create contracts for sovereign identity, source contribution, weighted attributes, and Data Cloud operational profile.
- Choose the first module slice, recommended: M1 Account Hierarchy Intelligence.
- Select first source set: CRM + one registry/internal fixture + one provider-like fixture or sample.
- Lock firmographic evidence contract using provider API structures only as non-binding shape references.
- Create validators that reject missing source contribution, confidence, freshness, run metadata, and CRM-safe identifiers.

### First 60 Days

- Build first sovereign identity and hierarchy stitching pipeline slice.
- Build weighted attribute resolution for the M1 fields: legal name, parent, group revenue, coverage gap, hierarchy completeness, confidence.
- Add first neutral provider-shaped fixture and normalized firmographic facts, preserving provider/source IDs as xrefs.
- Design GPT/OpenAI enrichment job outputs for source-bound narratives and recommended actions.
- Publish a Data Cloud operational mapping and runbook for M1.
- Implement or refine Salesforce Group Revenue Reveal and planner/seller summaries.
- Capture lineage and governance evidence for M1 paths.

### First 90 Days

- Add one model-backed use case: ICP fit, intent routing, or renewal risk.
- Add one GPT-backed firmographic enrichment use case over governed firmographic/registry facts, with confidence components and rejection thresholds.
- Register model outputs with feature/model lineage and versioned score payloads.
- Validate BYOM or document the org/entitlement gate.
- Expand module delivery to M2 or M5 based on data availability.
- Produce a customer-ready architecture/readout packet that clearly marks built, feasible, gated, and roadmap items.

## Acceptance Gates

### Gate 1 - Decision Stack Lock

- This document is accepted as the build lens.
- Linear child issues remain linked under `DAN-280`.
- Prior prototype-only wording is not used as the product definition.

### Gate 2 - Contract Lock

- Identity, source contribution, weighted attributes, model score, Data Cloud profile, and Agentforce action contracts exist.
- Validators cover required metadata and key preservation.

### Gate 3 - First Module Lock

- M1 or another selected module has a scoped MVP, source dependencies, surface design, and acceptance tests.
- Platform-gated items are not hidden inside implementation assumptions.

### Gate 4 - Runtime Readiness

- Databricks outputs, Data Cloud mapping, Salesforce surfaces, and governance evidence can be shown together.
- If native Agentforce is not verified, the demo uses precise fallback language.

## Risk Register

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Provider coverage or contract gaps | Enrichment may be weaker than value proposition | Design provider-neutral contracts and start with samples or customer-approved sources. |
| Provider payload variability | Search/export field sets differ by package, country, and endpoint | Preserve raw provider payloads, field-set versions, and provider reference codes; normalize only contract-backed fields. |
| National registry access variability | Sovereign identity coverage differs by country | Make country adapters explicit and support CRM-safe fallback. |
| Data Cloud zero-copy availability | Architecture may need ingestion path instead of federation | Keep zero-copy as preferred, ingestion as fallback. |
| Salesforce BYOM entitlement gaps | Model output may need batch activation instead of real-time calls | Design batch scoring and Data Cloud activation path first. |
| Agentforce runtime unavailable | Native agent claims could be overstated | Keep custom assistant/action-panel fallback and capability gate. |
| Lineage gaps for LLM/research facts | Trust story weakens | Require source URL, extraction timestamp, prompt/model version, and citation payload for every extracted fact. |
| GPT unsupported inference | AI could overstate legal, revenue, or hierarchy facts | Require every GPT output to bind to existing `source_id` values and reject unsupported facts in validators. |
| Copy Field Enrichment limitations | 1-to-many details may be flattened poorly | Copy only altitude-3 summary fields; use related-list/drill-through for detail. |
| Data residency requirements | Region-specific deployments may block defaults | Add region gate to implementation runbooks. |

## Immediate Next Work

1. `DAN-282`: create the sovereign identity schema contract and first matching plan.
2. `DAN-285`: create the source contribution and weighted attribute schema.
3. `DAN-287`: create the Data Cloud operational profile mapping for M1.
4. `DAN-291`: choose the first module slice and dependency path.
5. `DAN-286`: add source-bound GPT/OpenAI enrichment design and job plan for provider-backed firmographic narratives/actions.
