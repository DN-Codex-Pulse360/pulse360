# Pulse360 Databricks Firmographic Evidence And Gen AI Enrichment Design

## Purpose

This design adds firmographic evidence and GPT-assisted enrichment to the Databricks layer without binding Pulse360 to any paid provider, endpoint, or vendor-specific runtime.

Commercial provider API specifications are used only to infer the common **shape of firmographic evidence** that Pulse360 should accept. The architecture remains provider-neutral.

The target is:

1. Databricks ingests firmographic evidence from approved sources as governed records.
2. Databricks normalizes evidence into identity, firmographic, hierarchy, financial, location, classification, and signal facts.
3. Weighted attribute resolution chooses survivorship values with source contribution metadata.
4. GPT/OpenAI runs only after source facts exist, producing structured extraction, narrative, and recommended-action outputs bound to source IDs.
5. GPT outputs receive a robust confidence score based on source quality, corroboration, freshness, conflicts, and output validation.
6. Data Cloud receives curated operational profiles; Salesforce receives only summary/action fields.

## Firmographic Evidence Shape

Provider examples suggest that Pulse360 should expect firmographic data in these categories, independent of the provider used:

| Category | Examples | GPT prompt role |
| --- | --- | --- |
| Provider/source identity | source name, source record ID, source dataset/version, source field-set version | Bind every fact to a traceable source row. |
| Company identity | provider company ID, registered legal name, trade name, local name, normalized name | Candidate matching and narrative context. |
| Official identifiers | registration number, tax/VAT number, national ID type/value, jurisdiction | High-weight identity evidence when explicitly sourced. |
| Location | country, region/state, city, postal code, street address, headquarters/branch flag | Matching, territory, coverage, and routing context. |
| Classification | industry codes, sector, category, business description | ICP, fit, and recommended-action context. |
| Legal/operating status | active/inactive flag, legal form, incorporation date, status date | Trust, risk, and activation eligibility context. |
| Financials | revenue, currency, fiscal period, source period, confidence/reliability indicator | Group revenue and commercial priority context. |
| Workforce/scale | employee count, count band, location count | Size and fit context. |
| Hierarchy hints | parent, subsidiary, branch, headquarters, ultimate parent, ownership indicator | Candidate hierarchy edges, never final graph truth by itself. |
| Contact/web presence | website, domain, phone, email, marketability/contactability flags | Matching and engagement context. |
| Digital/technographic signals | technology tags, job/posting signals, web flags | Intent/fit features, not identity keys. |
| Provider confidence metadata | reliability code, match score, completeness flags, freshness, last updated | Confidence scoring inputs. |
| License/use metadata | contract reference, allowed use, retention, redistribution limits | Governance and activation guardrail. |

## Databricks Target Architecture

### Bronze Evidence Zone

Create a provider-neutral bronze pattern:

| Table/View | Purpose |
| --- | --- |
| `bronze_firmographic.evidence_request_log` | One row per approved source retrieval/import. |
| `bronze_firmographic.raw_company_evidence` | Raw JSON/CSV/XML-derived source records keyed by source system, source record ID, country, and run IDs. |
| `bronze_firmographic.reference_code` | Normalized reference vocabularies such as legal status, industry/category, geography, reliability, national ID type, and technographic tag. |
| `bronze_firmographic.license_snapshot` | Allowed use, retention, field availability, refresh SLA, and redistribution constraints. |

Minimum bronze metadata:

- `source_system`
- `source_dataset`
- `source_record_id`
- `source_country_code`
- `source_payload_json`
- `field_set_version`
- `license_or_contract_reference`
- `source_retrieved_at`
- `ingested_at`
- `run_id`
- `run_timestamp`

### Silver Normalization

Normalize source outputs into stable facts:

| View | Purpose |
| --- | --- |
| `silver_firmographic.company_candidate` | Candidate company rows from any approved source. |
| `silver_firmographic.identity_xref` | Provider/source IDs, national IDs, registration numbers, websites/domains, addresses, and CRM candidate keys. |
| `silver_firmographic.firmographic_fact` | Legal name, trade name, address, city, country, industry, employee count, revenue, website, legal status, branch/headquarters/subsidiary flags. |
| `silver_firmographic.hierarchy_hint` | Parent, headquarters, branch, subsidiary, and group hints. |
| `silver_firmographic.signal_fact` | Technographic, hiring, digital, marketability, and other licensed signals. |

Required silver columns:

- `source_system`
- `source_record_id`
- `fact_type`
- `fact_name`
- `fact_value`
- `fact_value_normalized`
- `fact_unit`
- `fact_period_start`
- `fact_period_end`
- `source_confidence`
- `source_reliability_code`
- `field_completeness_score`
- `freshness_status`
- `last_refreshed_at`
- `raw_payload_ref`
- `license_or_contract_reference`
- `run_id`
- `run_timestamp`

### Gold Weighted Attribute Resolution

Firmographic facts feed existing and future gold products:

- `identity_resolution.identity_source_xref_base`
- `identity_resolution.weighted_attribute_resolution`
- `identity_resolution.entity_hierarchy_edge`
- `identity_resolution.entity_hierarchy_rollup`
- `identity_resolution.m1_account_hierarchy_operational_profile`
- future `gold.account_firmographic_enrichment`
- future `gold.account_genai_enrichment_output`

Survivorship rules:

1. Sovereign/regulator ID beats provider/source ID for legal identity when available.
2. CRM Account ID remains the only default Salesforce writeback key.
3. Provider/source ID is an xref and evidence source.
4. Revenue, employee count, industry, legal status, and technographic values must carry source system, field age, confidence/reliability, and license reference.
5. Conflicting values produce candidate rows and review flags; they do not silently overwrite CRM.

## GPT Prompt Evidence Packet

GPT should receive a compact, structured evidence packet rather than raw provider payloads.

```json
{
  "account_context": {
    "crm_account_id": "001...",
    "crm_account_name": "Example Holdings",
    "country": "PH",
    "website_domain": "example.com"
  },
  "resolved_identity": {
    "resolved_entity_id": "ent_...",
    "sovereign_identity_key": "PH|SEC|...",
    "crm_safe_activation_key": "001...",
    "identity_confidence": 94
  },
  "firmographic_facts": [
    {
      "source_id": "src_001",
      "fact_type": "financial",
      "fact_name": "annual_revenue",
      "fact_value": 378600000000,
      "fact_unit": "PHP",
      "fact_period_end": "2024-12-31",
      "source_confidence": 0.91,
      "freshness_status": "fresh",
      "license_or_contract_reference": "approved-source-contract"
    }
  ],
  "hierarchy_context": {
    "known_subsidiary_count": 4,
    "crm_covered_subsidiary_count": 1,
    "external_subsidiaries_found": 3,
    "coverage_gap_flag": true
  },
  "source_refs": [
    {
      "source_id": "src_001",
      "source_type": "approved_firmographic_source",
      "document_date": "2024-12-31",
      "accessed_at": "2026-04-25T00:00:00Z"
    }
  ]
}
```

Prompt contract:

1. Use only supplied facts and source refs.
2. Return structured JSON, not free-form prose only.
3. Every narrative claim and recommended action must cite one or more `source_id` values.
4. If required evidence is missing, return an explicit `insufficient_evidence` finding rather than guessing.
5. Do not create legal identifiers, CRM match keys, revenue, employee count, or hierarchy edges.

## GPT Confidence Scoring

Each GPT output gets two confidence scores:

- `llm_result_confidence`: confidence that the generated narrative/action is well-supported by the supplied evidence.
- `business_action_confidence`: confidence that the recommended action is commercially appropriate and safe to surface.

### Output Schema

```json
{
  "llm_run_id": "llm_run_...",
  "model_id": "gpt-...",
  "prompt_version": "pulse360-firmographic-evidence-v1",
  "ai_narrative": "...",
  "ai_recommended_actions": [],
  "llm_result_confidence": 0.82,
  "business_action_confidence": 0.74,
  "confidence_components": {
    "source_reliability_score": 0.88,
    "evidence_coverage_score": 0.80,
    "corroboration_score": 0.75,
    "freshness_score": 0.90,
    "extraction_certainty_score": 0.84,
    "conflict_penalty": 0.10,
    "schema_validation_score": 1.00,
    "citation_binding_score": 1.00
  },
  "unsupported_claim_count": 0,
  "source_refs": ["src_001", "src_002"]
}
```

### Confidence Formula

Recommended first formula:

```text
llm_result_confidence =
  0.20 * source_reliability_score +
  0.20 * evidence_coverage_score +
  0.15 * corroboration_score +
  0.15 * freshness_score +
  0.15 * extraction_certainty_score +
  0.10 * citation_binding_score +
  0.05 * schema_validation_score
  - conflict_penalty
```

`business_action_confidence` should then combine:

```text
business_action_confidence =
  0.60 * llm_result_confidence +
  0.20 * actionability_score +
  0.10 * crm_anchor_score +
  0.10 * policy_safety_score
```

Component definitions:

| Component | Meaning |
| --- | --- |
| `source_reliability_score` | Weighted reliability of the sources supporting the generated claim. |
| `evidence_coverage_score` | How much of the prompt's required evidence was present. |
| `corroboration_score` | Whether key claims are supported by more than one independent source/fact. |
| `freshness_score` | Recency relative to expected refresh cadence and fact type. |
| `extraction_certainty_score` | Model-reported confidence for extracted facts, capped by source confidence. |
| `citation_binding_score` | Share of claims/actions with valid source IDs in the supplied evidence packet. |
| `schema_validation_score` | Whether the model output passes structured-output schema validation. |
| `conflict_penalty` | Penalty for unresolved contradictory facts. |
| `actionability_score` | Whether the action has a target, owner path, next step, and expected business impact. |
| `crm_anchor_score` | Whether the action can be safely tied to a Salesforce Account/approved External ID. |
| `policy_safety_score` | Whether the action avoids unsupported writeback, restricted data, and license violations. |

Acceptance thresholds:

- `llm_result_confidence >= 0.80`: can show as standard narrative/action support.
- `0.60 <= llm_result_confidence < 0.80`: show with review/freshness warning.
- `< 0.60`: keep in Databricks/Data Cloud review queue; do not activate to Salesforce.
- `business_action_confidence < 0.70`: do not show as a recommended action; show as evidence-only insight if useful.

## Orchestration Sequence

1. CRM ingestion completes.
2. Approved firmographic evidence is imported or fetched under a governed source adapter.
3. Raw evidence and reference codes land in `bronze_firmographic`.
4. Silver normalization maps source-specific records into identity, firmographic, hierarchy, and signal facts.
5. Weighted attribute resolution calculates winning values, conflicts, and source contribution.
6. A structured GPT evidence packet is assembled from governed facts and source refs.
7. GPT/OpenAI returns structured extraction, narrative, actions, and self-reported evidence references.
8. Deterministic validators recompute confidence components and reject unsupported claims.
9. Gold/Data Cloud exports expose summary, confidence, freshness, source refs, and model metadata.
10. Salesforce receives only CRM-safe summary/action fields above threshold.

## Build Sequencing

| Slice | Deliverable | Linear |
| --- | --- | --- |
| Firmographic evidence contract | Bronze/silver evidence table contract and source adapter rules | `DAN-283` |
| First neutral fixture | Provider-shaped sample payloads and normalized silver views without vendor dependency | `DAN-283` |
| Weighted firmographic attributes | Evidence facts folded into weighted attribute resolution | `DAN-285` |
| GPT enrichment job design | OpenAI prompt contracts, confidence scoring, source-bound outputs, run/cost metadata | `DAN-286` |
| Governance evidence | Source logs, license refs, LLM run metadata, confidence components, lineage checks | `DAN-290` |

`DAN-283` is closed for the first governed source adapter slice by
`contracts/firmographic_source_adapter.schema.json`,
`data/samples/firmographic_source_adapters.json`, and
`config/databricks/firmographic-source-adapters.json`. Runtime connector setup
for commercial providers, customer-internal systems, and clean rooms remains
gated by entitlement, customer approval, and collaboration agreements.

`DAN-285` is closed for the first weighted attribute slice by
`contracts/weighted_attribute_resolution.schema.json`,
`config/databricks/weighted-attribute-resolution-rules.json`, and
`sql/databricks/firmographic_enrichment/25_weighted_attribute_resolution.sql`.
Served attribute candidates now have deterministic source contribution rows,
source weights, freshness, conflict counts, license references, and run
metadata before downstream GPT or Data Cloud promotion.

## Acceptance Criteria

1. No paid-provider endpoint or vendor-specific runtime is hardwired into the Pulse360 design.
2. Provider/source IDs are stored as xrefs, never as replacement CRM or sovereign keys.
3. Raw evidence remains available for audit and reprocessing.
4. Firmographic facts include freshness, confidence/reliability, run metadata, and license reference.
5. GPT outputs are bound to source IDs and cannot introduce unsupported facts.
6. GPT outputs include `llm_result_confidence`, `business_action_confidence`, and component-level confidence evidence.
7. Data Cloud and Salesforce receive only curated profile fields and safe activation keys.
8. Validators reject missing source refs, model metadata, prompt version, run ID, confidence components, and license reference for firmographic/GPT-derived outputs.
