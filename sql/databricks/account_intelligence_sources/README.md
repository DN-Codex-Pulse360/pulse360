# Databricks Account Intelligence Source Pack

This SQL pack creates the first Priority 1 synthetic enterprise source slice for
Pulse360.

It is fixture-backed by design. The goal is to prove the data flow and
confidence contract before connecting paid providers, customer ERP/EPM systems,
or live AI enrichment orchestration.

## Order

Run the files in this order:

1. `00_create_schemas.sql`
2. `05_synthetic_enterprise_source_sample.sql`
3. `10_synthetic_source_signal.sql`
4. `20_account_ai_enrichment_output.sql`

## Output Views

- `pulse360_s4.bronze_enterprise_sources.synthetic_enterprise_source_sample`
- `pulse360_s4.silver_enterprise_sources.synthetic_source_signal`
- `pulse360_s4.gold_account_intelligence.account_ai_enrichment_output`

## Source Families

The pack includes synthetic records for:

- ERP invoices and billing entities
- EPM forecast and coverage gaps
- Support cases and SLA risk
- Contract renewal windows
- Product telemetry and adoption
- Marketing intent and topic surge
- Internal hierarchy and subsidiary coverage

## Design Rules

- Synthetic rows must be explicitly marked with `synthetic_flag`.
- Every source record must preserve source family, system name, source
  confidence, payload, edge-case tags, run ID, and expected ground truth.
- AI enrichment output must include source refs, confidence components,
  activation state, activation block reasons, prompt/model/run metadata, and
  input/output hashes.
- Conflicting positive and negative signals should route to review, not direct
  seller activation.
- This pack must not depend on paid data-provider endpoints or customer
  production systems.
