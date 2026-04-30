# Databricks Governance Evidence SQL

These SQL files create the Pulse360 governance evidence layer for Databricks account intelligence outputs.

## Order

Run the files in this order:

1. `00_create_gold_schema.sql`
2. `10_account_intelligence_governance_evidence.sql`
3. `20_activation_eligibility_review_queue.sql`
4. `30_datacloud_activation_review_queue.sql`
5. `40_governance_case_metrics.sql`

## Output Views

- `pulse360_s4.gold.account_intelligence_governance_evidence`
- `pulse360_s4.gold.activation_eligibility_review_queue`
- `pulse360_s4.intelligence.datacloud_activation_review_queue`
- `pulse360_s4.intelligence.governance_case_metrics`

## Design Rules

- Every row must preserve source refs, confidence, freshness, run metadata, model metadata, and lineage status.
- Rows with no CRM-safe activation key must not activate to Salesforce.
- Review queue rows should expose candidate CRM anchors when name/country evidence
  can narrow the stewarding task, but ambiguous candidates must remain blocked.
- Low-confidence or unsupported GPT rows must stay in review.
- Latest runtime rows from `pulse360_s4.gold.account_genai_enrichment_output_runtime`
  are included as `firmographic_genai_runtime` evidence so Claude output is
  visible to stewardship before it is eligible for Account activation.
- Synthetic multi-source rows from
  `pulse360_s4.gold_account_intelligence.account_ai_enrichment_output` are
  included as `account_intelligence_ai_synthetic` evidence so ERP, EPM,
  support, contract, telemetry, intent, and hierarchy scenarios enter the same
  review queue as firmographic enrichment.
- CSP smart-city proposition rows from
  `pulse360_s4.gold_smart_city.smart_city_proposition_readiness` are included
  as `csp_smart_city_proposition_readiness` evidence. Activation-safe and
  review-required smart-city rows flow to the Data Cloud handoff table; blocked
  smart-city rows remain in Databricks until more evidence is present.
- CSP smart-city rows expose first-class action fields in the Data Cloud
  handoff: target entity, country, market, offering family, offer bundle, B2B
  target customer IDs and names, recommended next actions, and review priority.
  Non-CSP rows leave these fields null.
- Activation block reasons must be explicit and machine-readable.
- The Data Cloud handoff table serializes arrays as JSON strings so candidate
  IDs, candidate names, source refs, confidence components, and block reasons
  remain visible through DLO/DMO mapping surfaces.
- Salesforce stewardship decisions ingested back into Databricks are summarized
  through `governance_case_metrics` for dashboard reporting; this feedback view
  must not bypass activation eligibility guardrails.
