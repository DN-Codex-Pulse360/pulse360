# DAN-305 Priority 1 Account Intelligence Source Pack Evidence

Date: 2026-04-26

## Summary

The first Priority 1 build slice is in place for the broader account
intelligence data cycle. It adds a synthetic enterprise source pack and a
governed AI enrichment output contract that can feed the same Databricks
governance evidence and Data Cloud review path used by firmographic enrichment.

The source-backed package was validated locally and then executed in Databricks
through the Databricks SQL MCP endpoint.

## Added Contracts

- `contracts/synthetic_enterprise_source_pack.schema.json`
- `contracts/account_intelligence_ai_enrichment_output.schema.json`

The synthetic source contract covers:

- ERP
- EPM
- Support
- Contracts
- Product telemetry
- Marketing intent
- Internal hierarchy

The AI enrichment output contract preserves:

- source record IDs and source families
- inferred signals
- recommended actions
- `llm_result_confidence`
- `business_action_confidence`
- component-level confidence scoring
- activation state
- activation block reasons
- prompt/model/run metadata
- input/output hashes

## Added Samples

- `data/samples/synthetic_enterprise_source_pack_sample.json`
- `data/samples/account_intelligence_ai_enrichment_output_sample.json`

The sample scenario is intentionally review-required. It has a CRM anchor and
strong expansion signals, but support risk and subsidiary coverage gaps block
direct seller activation.

## Added Databricks SQL Pack

- `sql/databricks/account_intelligence_sources/00_create_schemas.sql`
- `sql/databricks/account_intelligence_sources/05_synthetic_enterprise_source_sample.sql`
- `sql/databricks/account_intelligence_sources/10_synthetic_source_signal.sql`
- `sql/databricks/account_intelligence_sources/20_account_ai_enrichment_output.sql`
- `sql/databricks/account_intelligence_sources/README.md`

Output views:

- `pulse360_s4.bronze_enterprise_sources.synthetic_enterprise_source_sample`
- `pulse360_s4.silver_enterprise_sources.synthetic_source_signal`
- `pulse360_s4.gold_account_intelligence.account_ai_enrichment_output`

## Governance Integration

Updated:

- `contracts/account_intelligence_governance_evidence.schema.json`
- `data/samples/account_intelligence_governance_evidence_sample.json`
- `sql/databricks/governance_evidence/10_account_intelligence_governance_evidence.sql`
- `sql/databricks/governance_evidence/README.md`

The governance evidence layer now accepts:

```text
account_intelligence_ai_synthetic
```

This lets synthetic ERP/EPM/support/contract/telemetry/intent/hierarchy evidence
enter the same activation/review path as M1 hierarchy and firmographic GenAI
outputs.

## Added Packaging And Validation

Added Databricks bundle member list:

- `config/packages/databricks/account-intelligence-sources.members.txt`

Updated package builder and layout validator:

- `scripts/build-databricks-package-workspace.sh`
- `scripts/validate-databricks-package-layout.sh`

Added validator:

- `scripts/validate-databricks-account-intelligence-sources-pack.sh`

Updated broader contract validation:

- `scripts/validate-contracts.sh`

## Validation Results

Commands run:

```bash
scripts/validate-databricks-account-intelligence-sources-pack.sh
scripts/validate-databricks-governance-evidence-pack.sh
scripts/validate-contracts.sh
scripts/validate-databricks-package-layout.sh
scripts/build-databricks-package-workspace.sh /tmp/pulse360-databricks-package-test
```

Result:

```text
PASS
```

Key validation proof:

- JSON schemas and samples parse.
- Source pack includes ERP, EPM, support, contracts, product telemetry,
  marketing intent, and internal hierarchy records.
- AI output includes confidence components and activation block reasons.
- SQL emits governed AI enrichment output.
- Governance evidence pack recognizes `account_intelligence_ai_synthetic`.
- Databricks package builder creates `pulse360-account-intelligence-sources`.
- No paid-provider endpoint or provider name is hardwired.

## Live Databricks Execution

Execution method:

```text
Databricks SQL MCP endpoint
```

SQL files executed:

```text
sql/databricks/account_intelligence_sources/00_create_schemas.sql
sql/databricks/account_intelligence_sources/05_synthetic_enterprise_source_sample.sql
sql/databricks/account_intelligence_sources/10_synthetic_source_signal.sql
sql/databricks/account_intelligence_sources/20_account_ai_enrichment_output.sql
sql/databricks/governance_evidence/10_account_intelligence_governance_evidence.sql
sql/databricks/governance_evidence/20_activation_eligibility_review_queue.sql
sql/databricks/governance_evidence/30_datacloud_activation_review_queue.sql
```

Live row-count checks:

```text
pulse360_s4.bronze_enterprise_sources.synthetic_enterprise_source_sample: 7 rows
pulse360_s4.silver_enterprise_sources.synthetic_source_signal: 7 rows, 7 source families
pulse360_s4.gold_account_intelligence.account_ai_enrichment_output: 1 row
activation_state: review_required
minimum business_action_confidence: 0.8965757142857146
pulse360_s4.gold.account_intelligence_governance_evidence where source_product = account_intelligence_ai_synthetic: 1 row
pulse360_s4.gold.activation_eligibility_review_queue where source_product = account_intelligence_ai_synthetic: 1 row
pulse360_s4.intelligence.datacloud_activation_review_queue where source_product = account_intelligence_ai_synthetic: 1 row
```

Interpretation:

- The synthetic ERP/EPM/support/contract/telemetry/intent/hierarchy fixture is
  live in Databricks.
- The broader AI enrichment row is live in Databricks and intentionally routes
  to review.
- Governance evidence and Data Cloud handoff table paths include the synthetic
  evidence row.
- No direct seller activation was performed.

## Data Cloud Check

Initial Data Cloud MCP status check after the Databricks refresh showed the
stream had not yet processed the new row. After the Data Cloud refresh shown in
the UI, the MCP check now confirms the row is visible in the DMO.

Latest Data Cloud stream status:

```text
Data Stream: Pulse360_Activation_Review_Queue
ImportRunStatus: SUCCESS
LastRefreshDate: 2026-04-26T14:09:39.000+0000
TotalRowsProcessed: 5
```

DMO describe result:

```text
DMO: Pulse360_Activation_Review_Queue__dlm
Field count: 30
Confirmed new/needed fields:
- source_product__c
- source_record_id__c
- source_refs__c
- run_id__c
- run_timestamp__c
- source_run_timestamp__c
```

DMO row proof:

```text
Query:
SELECT review_queue_id__c, source_product__c, source_record_id__c,
resolved_entity_id__c, activation_resolution_hint__c, confidence_score__c,
activation_block_reasons__c, model_id__c
FROM Pulse360_Activation_Review_Queue__dlm
WHERE resolved_entity_id__c = 'ent_global_medical_asia'
LIMIT 5

total_size: 1
review_queue_id__c: gov_account_intelligence_ai_synthetic_ent_global_medical_asia
source_product__c: account_intelligence_ai_synthetic
source_record_id__c: ai_account_intelligence_ent_global_medical_asia
resolved_entity_id__c: ent_global_medical_asia
activation_resolution_hint__c: activation_key_available
confidence_score__c: 0.8965757142857146
activation_block_reasons__c: ["support_risk_present","subsidiary_gap_requires_stewardship","llm_result_confidence_below_threshold"]
model_id__c: synthetic-ai-enrichment-fixture
```

Interpretation:

- Data Cloud now sees the synthetic account-intelligence review row.
- `source_product__c` is mapped and filterable.
- The row remains review-required because support risk and subsidiary coverage
  gaps block direct activation.
- The Databricks -> Data Cloud handoff is proven for the first synthetic
  enterprise source scenario.

## Remaining Work

- Add live Claude/GPT orchestration for the broader account-intelligence output
  after the fixture contract is accepted.
- Add additional scenarios for blocked/no-anchor, activation-safe, and
  conflicting-source cases.
