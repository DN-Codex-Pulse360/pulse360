# Pulse360 Governance Evidence SQL

This package supports `DAN-290` by defining a defensibility envelope for served attributes, model scores, LLM narratives, and steward decisions.

## Execution Order

1. `00_create_schema.sql`
2. `10_governance_evidence_packet.sql`
3. `20_governance_evidence_from_firmographic.sql`

## Contract Rules

- Every served attribute must preserve `source_account_id`, `run_id`, `generated_at`, confidence, freshness, source contributions, and lineage references.
- Model-backed attributes must include feature snapshot, model family, model version, and registered model name.
- LLM-backed attributes must include provider, model, prompt version, input hash, output hash, and citation count.
- Salesforce steward decisions must preserve before/after values, reviewer, reason, timestamp, and downstream update status.
- `ready_for_external_audit` remains false until live Unity Catalog lineage and target-org audit exports are captured.

## Runtime Caveat

The SQL definitions are source-controlled. Live execution remains subject to Databricks SQL Warehouse availability and target workspace permissions.
