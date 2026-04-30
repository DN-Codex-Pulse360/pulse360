# DAN-328 Account Payload Exception Activation Runbook

Date: 2026-04-30

## Purpose

This runbook defines the non-Copy-Field activation path for Account payload and
narrative fields that native Data Cloud Copy Field Enrichment cannot write in
the current org.

Native Copy Field remains the activation path for proven scalar fields. This
runbook covers only the payload exception fields selected in DAN-327.

## Fields

| Source field | Account field | Write path |
| --- | --- | --- |
| `ai_narrative` | `AI_Narrative__c` | Payload API/runbook |
| `ai_recommended_actions` | `AI_Recommended_Actions__c` | Payload API/runbook |
| `source_refs` | `AI_Source_Refs__c` | Payload API/runbook |
| `hierarchy_payload` | `Hierarchy_Payload__c` | Payload API/runbook |
| `intent_signal_payload` | `Intent_Signal_Payload__c` | Payload API/runbook |

The payload write path must preserve these provenance and freshness fields from
the same source row:

| Source field | Account field |
| --- | --- |
| `enrichment_run_id` | `Enrichment_Run_Id__c` |
| `ai_narrative_generated_at` | `AI_Narrative_Generated__c` |
| `model_id` | `AI_Model_Id__c` |
| `prompt_version` | `AI_Prompt_Version__c` |
| `citation_count` | `AI_Citation_Count__c` |

## Guardrails

1. Do not use this path to write native Copy Field scalar values.
2. Do not run Account updates until a dry-run validator passes.
3. Do not write rows whose `source_account_id__c` does not resolve to a target
   org `Account.Id`.
4. Do not write payload values without the provenance and freshness fields from
   the same source row.
5. Preserve JSON strings exactly for serialized fields. The validator parses
   the JSON fields only to confirm shape; it does not normalize or rewrite them.
6. Treat this as a CRM API/runbook path, not an Agentforce agent and not a Data
   Cloud native Copy Field job.

## Dry-Run Validation

Run the validator before any payload write:

```bash
./scripts/validate-account-payload-exception-activation.sh
```

The validator is read-only. It checks:

- the payload exception mappings still use `payload_api_runbook`
- the Data Cloud source object exposes the five payload fields
- the target Account object exposes the five payload fields plus provenance
- every source row resolves to a target Account ID
- payload fields are nonblank
- provenance and freshness fields are nonblank
- serialized JSON payload fields parse successfully

## Write Procedure

1. Run the dry-run validator.
2. Export candidate rows from the Data Cloud source object using
   `source_account_id__c` as the only target key.
3. Prepare an Account update payload that includes only:
   - `Id`
   - the five payload fields
   - the five provenance/freshness fields
4. Review the row count, target Account IDs, and sample payload values.
5. Obtain explicit approval before running any `sf data update`, bulk API job,
   Apex script, or other mutating operation.
6. After approval and write execution, run a post-write read-only query that
   confirms row count, non-null payload fields, and matching provenance values.

## Rollback

If a payload write must be reverted, use the exported pre-write Account values
as the rollback source. A rollback must be handled as a separate approved CRM
mutation with the same target Account ID review.
