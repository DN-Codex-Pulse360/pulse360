# Pulse360 Delivery Priority Stack

Date: 2026-04-26

Update: 2026-04-27 - the business lens is pivoting from IT-services RevOps
account intelligence toward communications-provider smart-city proposition
intelligence for ASEAN markets.

## Decision

Pulse360 delivery should now be sequenced around the data and intelligence
loop first, Agentforce second, and CRM UI/UX last.

This resets the work order after the prototype validation review. The goal is
to make the account intelligence foundation genuinely strong before polishing
the Salesforce experience.

## Priority 1: Data Flows And Account Enrichment

Build and harden the full account intelligence cycle:

```text
Databricks -> Salesforce Data Cloud -> Salesforce CRM -> Databricks
```

Include the Databricks-side sources and AI enrichment needed to test the wider
CSP smart-city value proposition:

- Salesforce CRM account and governance-case ingestion into Databricks
- Databricks duplicate detection, hierarchy stitching, and firmographic
  enrichment
- AI-assisted enrichment with source-bound evidence, confidence scoring,
  competing-evidence notes, and activation guardrails
- synthetic enterprise source packs for ERP, EPM, support, contracts,
  product telemetry, marketing intent, and internal hierarchy
- CSP smart-city source packs for municipal open data, CSP network readiness,
  IoT telemetry, public-sector triggers, partner ecosystem, mobility data,
  environmental data, and data-marketplace signals
- proposition readiness scoring for Intelligent Parking, Urban Data Brokerage,
  and Connected City IoT Platform offers
- Data Cloud-visible activation/review datasets
- CRM stewardship outcomes fed back into Databricks
- lineage, freshness, provenance, and model/prompt metadata on every output

This priority owns DAN-301 and DAN-304, and it should precede new CRM UI work.

Acceptance target:

- account records can be traced from original source rows through Databricks
  enrichment, Data Cloud activation/review, Salesforce CRM stewardship, and
  Databricks feedback metrics
- AI output is not treated as truth unless it is source-bound, confidence-scored,
  CRM-anchored, and passes activation guardrails
- synthetic non-CRM enterprise and CSP smart-city sources are available for
  realistic ASEAN proposition demos

## Priority 2: Agentforce And Headless 360

After the data foundation is credible, maximize Agentforce value against that
foundation:

- prove native Headless 360 / Agent API availability in the target org
- test whether native Agentforce runtime can be invoked headlessly
- ground agentic flows in Data Cloud and Databricks context
- define agentic fields and actions only where the data contract is stable
- preserve fallback language if the implementation is LWC/Apex-driven rather
  than native Agentforce runtime-driven

This priority owns DAN-302.

Acceptance target:

- Agentforce/Headless 360 capability is proven or explicitly ruled out in the
  target org
- agentic interactions consume governed evidence rather than guessed UI state
- limitations are documented without calling custom helper UI a native agent

## Priority 3: CRM UI And UX

CRM UI work should come last, after the data contracts and agentic capability
are stable.

The UI should focus on exposing the proven cycle:

- evidence-first account intelligence
- Data Cloud review visibility
- stewardship decisions
- agentic recommendations where Headless 360 support is proven
- clear confidence, provenance, freshness, and blocked-state cues

This priority includes dashboard polish and Salesforce workspace UX, including
DAN-303 only after Priority 1 data products are strong enough to visualize.

Acceptance target:

- UI does not invent intelligence that is not present in the data layer
- UX decisions make lineage, confidence, and next safe action easier to see
- visual polish supports operator trust rather than hiding prototype gaps

## Immediate Next Step

Proceed with Priority 1 by building the LLM evidence harness, synthetic
enterprise source pack, and CSP smart-city source pack together:

1. Define the canonical AI enrichment output contract.
2. Generate synthetic ERP/EPM/support/contract/product/intent source datasets.
3. Generate CSP smart-city source datasets for municipal open data, CSP network
   readiness, IoT telemetry, public-sector triggers, partner ecosystem, mobility
   data, environmental data, and data-marketplace signals.
4. Run Claude/GPT-style enrichment against approved public or synthetic inputs.
5. Write outputs into Databricks with confidence components and provenance.
6. Publish only activation-safe or review-safe rows into Data Cloud-facing
   datasets.
7. Feed CRM stewardship outcomes back into Databricks metrics.

## Progress

2026-04-26:

- Added the first synthetic enterprise source pack contract and sample.
- Added the broader account intelligence AI enrichment output contract and
  sample.
- Added fixture-backed Databricks SQL for bronze synthetic source rows, silver
  normalized signals, and gold AI enrichment output.
- Connected `account_intelligence_ai_synthetic` into the governance evidence
  layer so it can flow toward Data Cloud review.
- Added package validation and Databricks bundle packaging for
  `pulse360-account-intelligence-sources`.
- Executed the new SQL pack in Databricks through the Databricks SQL MCP
  endpoint.
- Live Databricks checks now show 7 bronze source rows, 7 silver signals, 1 gold
  AI enrichment row, 1 governance evidence row, 1 review queue row, and 1 Data
  Cloud handoff row for `account_intelligence_ai_synthetic`.
- Data Cloud still needs a stream refresh and `source_product` field mapping
  update before the new synthetic row is visible and filterable in the DMO.
- Evidence:
  `docs/evidence/dan-305-priority1-account-intelligence-source-pack-2026-04-26.md`.

2026-04-27:

- Added the CSP smart-city pivot decision artifact:
  `docs/planning/pulse360-csp-smart-city-pivot-2026-04-27.md`.
- Added a CSP smart-city proposition signal contract and ASEAN sample for
  Intelligent Parking, Urban Data Brokerage, and Connected City IoT Platform.
- Added a fixture-backed Databricks SQL pack for smart-city proposition
  readiness scoring.
- Added Databricks package workspace support and validators for
  `pulse360-csp-smart-city`.
- Executed the CSP smart-city SQL pack in live Databricks and verified
  `pulse360_s4.gold_smart_city.smart_city_proposition_readiness`.
- Live result now includes an activation-safe Ho Chi Minh City intelligent
  parking row, a review-required Singapore data-brokerage row, and blocked
  single-source opportunities.
- Extended the activation/review handoff and verified `3`
  `csp_smart_city_proposition_readiness` rows in Salesforce Data Cloud DMO
  `Pulse360_Activation_Review_Queue__dlm`.
- `Pulse360_Activation_Review_Queue` stream now reports `8` total processed
  records after refresh.
- Evidence:
  `docs/evidence/dan-317-csp-smart-city-databricks-live-validation-2026-04-27.md`.
