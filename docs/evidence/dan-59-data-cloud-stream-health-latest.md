# DAN-59 / DAN-114 Data Cloud Stream Health - Latest

Date: 2026-05-08

## Scope

Read-only validation of the current `pulse360-agent-target` Data Cloud to
Salesforce Account activation path after the duplicate Account DMO row blocker
was reported on `DAN-114`.

This note is the latest evidence handoff for `DAN-59`, `DAN-103`, and
`DAN-114`.

## Summary

The current live org state supports closing the Account activation blocker:

- Account activation fields exist in source metadata and in
  `pulse360-agent-target`.
- Data Cloud source object `pulse360_account_intelligence_export_v2__dll`
  contains `18` distinct CRM-safe activation IDs.
- Account DMO `ssot__Account__dlm` contains `18` distinct CRM-safe activation
  IDs.
- Duplicate activation ID count is now `0` in both the source object and
  `ssot__Account__dlm`.
- Required native Copy Field source and DMO fields are populated for all
  supported rows.
- Data Action `Pulse360_Account_Intelligence_Copy_Fields_20xo47` is `ACTIVE`.
- Latest Copy Field job `1A5dL0000001BFxSAM` completed with `18` processed,
  `18` updated, `0` failed, and `0` skipped.
- All `18` Salesforce Account records now have populated core activation
  fields, and the records were last modified by `Platform Integration User`.

The old `ActivationTarget` / `MktDataLakeMapping` objects remain empty in this
org. Current runtime evidence shows that the active implementation path is Data
Cloud Copy Field Enrichment, not the earlier failed ActivationTarget path.

## Repo Validators

Commands:

```bash
TARGET_ORG=pulse360-agent-target ./scripts/validate-salesforce-account-activation-fields.sh
TARGET_ORG=pulse360-agent-target ./scripts/validate-data-cloud-activation-key-alignment.sh
TARGET_ORG=pulse360-agent-target ./scripts/validate-data-cloud-copy-field-exceptions.sh
```

Results:

- Salesforce Account activation field metadata files exist.
- Activation mapping references all Account target fields.
- Account target fields exist in org `pulse360-agent-target`.
- Data Cloud activation keys resolve uniquely to target-org Account records.
- Supported source and DMO writeback fields are populated.
- Copy Field exception routing is documented in mapping files.

Important activation-key validator output:

| Check | Result |
| --- | ---: |
| Target Account rows | 18 |
| Source object total rows | 18 |
| Source distinct activation IDs | 18 |
| Source duplicate activation IDs | 0 |
| Source valid activation IDs | 18 |
| Source rows missing required supported fields | 0 |
| DMO total rows | 18 |
| DMO distinct activation IDs | 18 |
| DMO duplicate activation IDs | 0 |
| DMO valid activation IDs | 18 |
| DMO rows missing required supported fields | 0 |

## MCP / SOQL Runtime Checks

Account contract check through the Salesforce Data Cloud MCP:

| Check | Result |
| --- | ---: |
| Required Account sync fields | 31 |
| Mapped Account sync fields | 31 |
| Missing mappings | 0 |
| Missing Account target fields | 0 |

Live Data Stream check:

| Data Stream | Id | Status | Import status | Last refresh | Rows |
| --- | --- | --- | --- | --- | ---: |
| `DC Export Accounts P360 V2` | `1dsdL000000OMyfQAG` | `ACTIVE` | `SUCCESS` | `2026-04-29T14:23:19Z` | 18 |

Current firmographic validation streams:

| Data Stream | Status | Import status | Last refresh | Rows |
| --- | --- | --- | --- | ---: |
| `firmographic_profile_export_Pulse360_Dat` | `ACTIVE` | `SUCCESS` | `2026-05-08T03:12:02Z` | 18 |
| `firmographic_source_evidence_export_Puls` | `ACTIVE` | `SUCCESS` | `2026-05-08T03:12:02Z` | 140 |
| `company_classification_export_Pulse360_D` | `ACTIVE` | `SUCCESS` | `2026-05-08T03:12:02Z` | 11 |
| `corporate_linkage_export_Pulse360_Databr` | `ACTIVE` | `SUCCESS` | `2026-05-08T03:12:01Z` | 2 |
| `sovereign_identifier_export_Pulse360_Dat` | `ACTIVE` | `SUCCESS` | `2026-05-08T03:12:01Z` | 0 |
| `Pulse360_Activation_Review_Queue` | `ACTIVE` | `SUCCESS` | `2026-05-08T03:15:01Z` | 11 |

Copy Field Enrichment runtime:

| Artifact | Value |
| --- | --- |
| Data Action Id | `3o9dL0000000IL7QAM` |
| Data Action Name | `Pulse360_Account_Intelligence_Copy_Fields_20xo47` |
| Status | `ACTIVE` |
| Managed by | `DATA_CLOUD_USER` |
| Last status time | `2026-04-29T22:38:49Z` |

Latest Copy Field job:

| Job | Value |
| --- | --- |
| Job Id | `1A5dL0000001BFxSAM` |
| Name | `Pulse360_Account_Intelligence_Copy_Fields_1777502386443` |
| Status | `Completed` |
| Processed | 18 |
| Updated | 18 |
| Failed | 0 |
| Skipped | 0 |
| Started | `2026-04-29T22:39:46Z` |
| Ended | `2026-04-29T22:40:48Z` |

Account writeback proof:

| Check | Result |
| --- | ---: |
| Account rows | 18 |
| `Unified_Profile_Id__c` populated | 18 |
| `Identity_Confidence__c` populated | 18 |
| `Health_Score__c` populated | 18 |
| `Cross_Sell_Propensity__c` populated | 18 |
| `DataCloud_Last_Synced__c` populated | 18 |

Sample Accounts all show `LastModifiedBy.Name = Platform Integration User` and
`LastModifiedDate = 2026-04-29T22:39:52Z`.

## Interpretation

The `DAN-114` duplicate/null DMO row blocker is no longer present in
`pulse360-agent-target`. The current active and evidenced path is Copy Field
Enrichment from `ssot__Account__dlm` to Salesforce `Account`.

The earlier `ActivationTarget` and `MktDataLakeMapping` recovery criteria were
valid for the March activation-target path, but they are not the mechanism now
proving Account writeback. The completion evidence for the current path is:

1. Zero duplicate activation IDs in source and DMO.
2. Active Copy Field Data Action.
3. Latest Copy Field job completed with 18/18 updates and no failures.
4. All 18 target Accounts populated by the Platform Integration User.
5. Data Cloud stream and five firmographic validation streams active and
   successful.

## Recommended Linear Outcome

- Move `DAN-114` to Done.
- Unblock `DAN-103` and `DAN-61` for final acceptance review.
- Keep sovereign identifier coverage at `0` as expected until official
  registry, tax-authority, or filing evidence is available.
