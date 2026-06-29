# Pulse360 Databricks Skill

## Purpose

Guide Databricks work for the Pulse360 proactive manufacturing signal demo.

This skill owns the source-backed intelligence layer:

- source-change fixtures,
- account identity and hierarchy,
- product and service footprint,
- proactive signal detection,
- confidence and lineage,
- Data Cloud export payloads.

It does not own Salesforce UX, user actions, or CRM mutations.

## Operating Rule

Databricks produces evidence and signal payloads. Salesforce decides how those
payloads are activated into user workflow.

Do not use Databricks outputs as direct Salesforce mutation keys unless the
field is an approved CRM-safe key such as `source_account_id`.

## Demo Scope

Target demo:

- fictional supplier: `Meridian Industrial Systems`,
- hero customer group: `Northstar Foods Group`,
- primary signal: `maintenance_coverage_gap`,
- signal source: ERP/service/warranty/distributor/CRM fixture changes,
- handoff target: Salesforce Data Cloud export payload.

## Required Outputs

### 1. Source-Change Fixture

Create deterministic fixture data for:

- account group,
- subsidiaries,
- factory/site assets,
- service cases,
- warranty expiry,
- maintenance contracts,
- distributor spare-parts sales,
- duplicate CRM records.

Each fixture row should include:

- stable source ID,
- source system family,
- event timestamp,
- entity/account key,
- source snapshot or run ID,
- simulation label.

### 2. Proactive Signal Output

Create or simulate an output equivalent to:

```text
pulse360_s4.intelligence.proactive_account_signals
```

Minimum fields:

| Field | Required | Purpose |
| --- | --- | --- |
| `signal_id` | Yes | Stable signal key. |
| `source_account_id` | Yes | CRM-safe Account key for activation. |
| `group_entity_id` | Yes | Group-level context key. |
| `account_name` | Yes | Human-readable account or group name. |
| `signal_type` | Yes | Example: `maintenance_coverage_gap`. |
| `source_event_type` | Yes | Example: warranty expiry, service asset, contract gap. |
| `why_now` | Yes | Seller-facing reason. |
| `confidence_score` | Yes | Numeric confidence, 0 to 100. |
| `priority` | Yes | Routing priority. |
| `recommended_action_type` | Yes | Example: `route_specialist`, `create_task`, `create_opportunity`. |
| `approval_required` | Yes | Whether mutation requires approval. |
| `source_refs` | Yes | JSON source references. |
| `run_id` | Yes | Pipeline run ID. |
| `run_ts` | Yes | Pipeline run timestamp. |
| `model_version` | Yes | Signal logic version. |

### 3. Export Payload

Map the top signal into the current export strategy using existing fields where
possible:

- `intent_signal_payload`,
- `coverage_gap_flag`,
- `ai_narrative`,
- `ai_recommended_actions`,
- `source_refs`,
- `last_synced_timestamp`,
- `run_id`,
- `run_ts`,
- `model_version`.

Add new fields only when existing payload fields cannot carry the signal
clearly.

Candidate extension fields:

- `primary_signal_type`,
- `primary_signal_reason`,
- `signal_priority`,
- `signal_generated_at`.

## Required Evidence

Every demo signal must have:

- at least one source event,
- a CRM-safe account key,
- an explanation of why it matters now,
- source references,
- freshness timestamp,
- run metadata,
- confidence score,
- action recommendation.

Do not allow a signal if it cannot be traced back to fixture or source rows.

## Validation Checklist

Before handoff to Salesforce:

- fixture rows are deterministic and replayable,
- no source row uses a real customer name,
- source IDs and CRM-safe IDs are stable,
- signal output has required fields,
- source refs are valid JSON,
- recommended action type is one of the Salesforce-supported action types,
- approval policy is carried in the payload,
- output can be represented in the Data Cloud export contract,
- run metadata is present.

## Recommended Local Checks

Run these after adding SQL, contracts, or samples:

```bash
./scripts/validate-contracts.sh
./scripts/validate-data-cloud-insights-config.sh
./scripts/validate-canonical-exports.sh
./scripts/validate-databricks-salesforce-sql-pack.sh
./scripts/validate-databricks-package-layout.sh
```

## Handoff Contract To Salesforce

The Salesforce lane may consume only:

- CRM-safe account key,
- signal payload,
- recommended action type,
- approval flag,
- source refs,
- freshness metadata,
- confidence and reason labels.

The Salesforce lane must not infer missing hierarchy, revenue, warranty, or
contract facts that Databricks did not provide.

## Anti-Patterns

Avoid:

- hardcoded demo claims without fixture rows,
- free-text signals without structured fields,
- opportunity creation recommendations without approval flag,
- source refs that are labels only and not IDs,
- new Account-level DLO/DMO shortcuts that bypass the intended runtime path,
- Agentforce-only calculations of deterministic signal fields.
