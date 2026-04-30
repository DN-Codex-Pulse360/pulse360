# Public Regional Demo Bootstrap

This bootstrap package anchors the Pulse360 demo on public named examples from Singapore
and the Philippines while keeping GPT enrichment provenance-first.

## Anchors
- Singtel Group
- Ayala Corporation
- JG Summit Holdings, Inc.

## Canonical files
- `data/samples/databricks_enrichment_sample.csv`
- `data/samples/datacloud_activation_sample.json`
- `data/samples/regional_public_examples/*.json`
- `config/openai/pulse360-gpt-enrichment-spec.json`

## Public source set
- Singtel FY2025 annual report and FY2025 management discussion:
  - https://www.singtel.com/about-us/investor-relations/annual-report-fy2025
  - https://www.singtel.com/content/dam/singtel/investorRelations/stockExchange/2025/FY25-MDA.pdf
- Singtel public careers page:
  - https://groupcareers.singtel.com/go/Jobs-at-Singtel/4567910/
- Ayala 2024 Integrated Report and public stories page:
  - https://ayala.com/app/uploads/2025/04/Ayala_IR2024_Full-Report_1004.pdf
  - https://ayala.com/stories/
- JG Summit 2024 annual report and digital transformation section:
  - https://www.jgsummit.com.ph/annualreport2024/documents/JG%20Summit%202024%20Annual%20%26%20Sustainability%20Report%20%5BInteractive%20PDF%5D.pdf
  - https://www.jgsummit.com.ph/annualreport2024/strategic-enablers/digital-transformation-customer-centricity

## GPT enrichment rules
- Use OpenAI Responses API.
- Default models:
  - `gpt-5.4` for reasoning, narrative generation, and ranked actions
  - `gpt-5.4-nano` for high-volume extraction and normalization
- Every narrative and action must reference bound `source_id` values present in `source_refs`.
- Do not present GPT output as a direct quote from a company source.

## Notes
- The sample payloads are implementation-oriented and may be loaded through the Data Cloud path or used as direct demo fixtures where runtime setup is not available.
- The seller hierarchy payload now carries entity-level `coverage_status`, `signal`, and `suggested_play` fields so Salesforce can render whitespace-ready group context without a separate hierarchy microservice.
- Covered entities now carry `crm_record_id` in `hierarchy_payload`, and action payloads should carry `target_record_id` when the next move can deep-link to an existing Salesforce record.
- `accessed_at` is pinned to `2026-03-28T00:00:00Z` for repeatability.

## Non-Prod Validation
1. Seed the demo fixtures in a sandbox or scratch org with `TARGET_ORG=<alias> ./scripts/seed-public-regional-demo-fixtures.sh`.
2. Rebuild the Databricks export views from [10_account_export_base.sql](/Users/danielnortje/Documents/Pulse360/sql/databricks/gold/10_account_export_base.sql) and [30_datacloud_export_accounts.sql](/Users/danielnortje/Documents/Pulse360/sql/databricks/gold/30_datacloud_export_accounts.sql).
3. Refresh the Data Cloud stream so `Hierarchy_Payload__c` and `AI_Recommended_Actions__c` carry the updated runtime JSON.
4. Open the seeded `Singtel Group` Account in Salesforce and confirm:
   - clicking `NCS Pte. Ltd.` in the seller workspace opens the real Account record
   - the top NCS action carries a populated `target_record_id`
   - uncovered entities like `Optus` stay in-context rather than attempting record navigation
5. Open the seeded `Ayala Corporation` Account and confirm the governance follow-up opens the seeded `Governance_Case__c` record.
