# Databricks Firmographic Gen AI Enrichment SQL

These SQL files create the provider-neutral firmographic research extraction,
evidence, and GPT-confidence skeleton for Pulse360.

The SQL slice is fixture-backed by design. It proves the contract, confidence scoring, source binding, and activation guardrails without depending on a paid provider endpoint or a live GPT API call.

The runtime slice is `notebooks/databricks/firmographic_genai_enrichment_job.py`.
It can run in deterministic fixture mode for demos and validation, or in live
Claude mode when `ANTHROPIC_API_KEY` is available through Databricks secrets.
Live mode calls the Anthropic Messages API with forced tool use and an
`input_schema`, validates the result against
`contracts/genai_firmographic_enrichment_output.schema.json`, and writes to the
staging table `pulse360_s4.gold.account_genai_enrichment_output_runtime`.

## Order

Run the files in this order:

1. `00_create_bronze_schema.sql`
2. `01_create_silver_schema.sql`
3. `02_create_gold_schema.sql`
4. `05_raw_research_document_sample.sql`
5. `10_firmographic_evidence_sample.sql`
6. `15_extracted_firmographic_fact.sql`
7. `20_firmographic_fact.sql`
8. `30_account_genai_enrichment_output.sql`

## Output Views

- `pulse360_s4.bronze_firmographic.raw_company_evidence_sample`
- `pulse360_s4.bronze_firmographic.raw_research_document`
- `pulse360_s4.silver_firmographic.extracted_firmographic_fact`
- `pulse360_s4.silver_firmographic.firmographic_fact`
- `pulse360_s4.gold.account_genai_enrichment_output`
- `pulse360_s4.gold.account_genai_enrichment_output_runtime` (runtime staging table)

## Research Extraction

The research layer accepts approved public URLs/PDFs, provider-neutral exports,
or manual research notes after they have document/access/license metadata. The
first build slice uses an approved public-report fixture row and normalizes it
into source-bound facts before Claude sees the evidence.

Required source controls:

- every document has `source_type`, `source_url`, `document_date`,
  `accessed_at`, and `license_or_use_basis`
- every extracted fact has `source_id`, `source_excerpt`,
  `extraction_confidence`, `source_confidence`, `freshness_status`, and
  `license_or_contract_reference`
- rejected or review-only documents do not feed the silver fact view
- paid firmographic provider endpoints and authentication shapes are not
  hardwired into the SQL or runtime

## Runtime Job

Local fixture validation:

```bash
python3 notebooks/databricks/firmographic_genai_enrichment_job.py --fixture-only
```

Databricks job behavior:

- Reads governed firmographic facts from `pulse360_s4.silver_firmographic.firmographic_fact`.
- Uses fixture mode unless `ANTHROPIC_API_KEY` is available from the
  `pulse360-ai` Databricks secret scope and `--fixture-only` is omitted.
- Rejects unsupported free-form claims through structured output validation.
- Emits `llm_input_hash`, `llm_output_hash`, prompt/model metadata, source refs,
  confidence components, and activation eligibility.
- Writes runtime rows to `pulse360_s4.gold.account_genai_enrichment_output_runtime`
  so the current demo fixture remains stable until promotion is approved.

## Design Rules

- Provider/source IDs are xrefs and evidence anchors, not Salesforce writeback keys.
- GPT output must bind claims and actions to supplied `source_id` values.
- GPT output must include `llm_result_confidence`, `business_action_confidence`, and component-level confidence evidence.
- Rows below confidence threshold remain in review and are not activated to Salesforce.
- This package must not hardwire paid-provider names, endpoints, or authentication shapes.
