# DAN-104 Milestone E Acceptance Evidence - 2026-05-08

## Scope

This note records the Milestone E acceptance evidence for `DAN-104` in
`pulse360-agent-target`.

No Salesforce metadata deployment, permission change, folder sharing change,
Data Cloud configuration mutation, or Databricks job mutation was performed as
part of this validation.

## Databricks Runtime Evidence

The two Milestone E Databricks dashboard URLs resolve through the Databricks
Lakeview API and are active on SQL warehouse `7052914888c7e86c`:

| Dashboard | Dashboard id | State |
| --- | --- | --- |
| `Pulse360 S4 - Use Case & Transition Dashboard (API Refreshed 2026-03-09)` | `01f11b56ed40102ea9232dfb2404fb1b` | `ACTIVE` |
| `Pulse360 S4 - Use Case & Transition Dashboard (Demo API Refreshed 2026-03-09)` | `01f11b5709051df5a21ba10e55942421` | `ACTIVE` |

Databricks SQL source-table snapshot:

| Table | Rows | Runtime timestamp | Run | Model |
| --- | ---: | --- | --- | --- |
| `pulse360_s4.intelligence.datacloud_export_accounts` | 18 | `2026-05-01T05:19:14.526Z` | `run_20260501_051914` | `dc-canonical-v2.crm-keyed` |

Current export counts:

| Table | Rows |
| --- | ---: |
| `pulse360_s4.intelligence.datacloud_export_accounts` | 18 |
| `pulse360_s4.intelligence.firmographic_profile_export` | 18 |
| `pulse360_s4.intelligence.firmographic_source_evidence_export` | 140 |
| `pulse360_s4.intelligence.company_classification_export` | 11 |
| `pulse360_s4.intelligence.corporate_linkage_export` | 2 |
| `pulse360_s4.intelligence.sovereign_identifier_export` | 0 |

The `0` sovereign identifier count is expected until official registry,
tax-authority, or filing evidence satisfies the verification gate.

## Data Cloud Runtime Evidence

Current Data Cloud stream status in `pulse360-agent-target`:

| Stream | Status | Last refresh | Rows |
| --- | --- | --- | ---: |
| `firmographic_profile_export_Pulse360_Dat` | `ACTIVE/SUCCESS` | `2026-05-08T04:12:01Z` | 18 |
| `firmographic_source_evidence_export_Puls` | `ACTIVE/SUCCESS` | `2026-05-08T04:12:02Z` | 140 |
| `company_classification_export_Pulse360_D` | `ACTIVE/SUCCESS` | `2026-05-08T04:12:02Z` | 11 |
| `corporate_linkage_export_Pulse360_Databr` | `ACTIVE/SUCCESS` | `2026-05-08T04:12:00Z` | 2 |
| `sovereign_identifier_export_Pulse360_Dat` | `ACTIVE/SUCCESS` | `2026-05-08T04:12:00Z` | 0 |
| `Pulse360_Activation_Review_Queue` | `ACTIVE/SUCCESS` | `2026-05-08T04:15:00Z` | 11 |
| `DC Export Accounts P360 V2` | `ACTIVE/SUCCESS` | `2026-04-29T14:23:19Z` | 18 |

No stream reported new fields available.

## Salesforce Runtime Evidence

The Salesforce validation dashboard is present:

| Field | Value |
| --- | --- |
| Dashboard id | `01ZdL00000ABncLUAT` |
| Title | `Pulse360 Account Intelligence Validation` |
| Developer name | `zZUAzaLhrPFnOpTDCJvUEUvPEQIohz` |
| Folder | `Pulse360 Account Intelligence Validation` |
| Runtime type | `SpecifiedUser` |

Both report and dashboard folders remain hidden in the live org:

| Folder type | Folder id | Developer name | Access type |
| --- | --- | --- | --- |
| Report | `00ldL00000NixwnQAB` | `Pulse360_Account_Intelligence_Validation` | `Hidden` |
| Dashboard | `00ldL00000NixyPQAR` | `Pulse360_Account_Intelligence_Validation` | `Hidden` |

The five promoted validation reports are present in the report folder:

| Report | Report id | Developer name |
| --- | --- | --- |
| `Account and Classification` | `00OdL00000PKsc9UAD` | `Account_and_Classification_qlX1` |
| `Account and Corporate Linkage` | `00OdL00000PKsaXUAT` | `Account_and_Corporate_Linkage_U4F1` |
| `Account and Evidence` | `00OdL00000PKsXJUA1` | `Account_and_Evidence_4W81` |
| `Account and Firmographic` | `00OdL00000PKsInUAL` | `Account_and_Firmographic_iIW1` |
| `Account and Sovereign Identifier` | `00OdL00000PKsYvUAL` | `Account_and_Sovereign_Identifier_NOY1` |

Milestone D UI deployment surfaces are present:

- `FlexiPage` `Account_Record_Page` exists as `Account Record Page`.
- `38` `pulse360%` Lightning component bundles exist in the target org,
  including the Account, Seller Workspace, Governance, Planner, and trust panel
  components.

Salesforce Account runtime activation evidence:

- `18` Account rows have `DataCloud_Last_Synced__c` populated.
- Maximum `DataCloud_Last_Synced__c` observed:
  `2026-04-27T11:53:30Z`.
- Maximum Account `LastModifiedDate` observed:
  `2026-04-29T22:39:52Z`.

## Cross-System Chain Proof

The acceptance chain is intact:

1. Databricks source table
   `pulse360_s4.intelligence.datacloud_export_accounts` has `18` rows, latest
   `last_synced_timestamp` `2026-05-01T05:19:14.526Z`, run
   `run_20260501_051914`.
2. Data Cloud stream `DC Export Accounts P360 V2` is `ACTIVE/SUCCESS`, last
   refreshed `2026-04-29T14:23:19Z`, with `18` processed rows.
3. Salesforce Account runtime has `18` populated synced Account rows, and the
   validation dashboard plus all five report components render from the live
   org metadata/report folder.

The firmographic extension stream chain is also current on `2026-05-08`, with
`18` profiles, `140` evidence rows, `11` classifications, `2` corporate linkage
rows, and `0` sovereign identifier rows.

## Gate Validation

The Milestone E gate script is now source-controlled at:

```bash
./scripts/validate-build-deploy-verify-close-gate.sh
```

The gate passed on `2026-05-08` and covered:

- core contracts and canonical exports
- hierarchy and identity
- Databricks SQL package, dashboard package, and GPT firmographic package
- sovereign/firmographic design
- Unity Catalog config
- Salesforce package layout
- Salesforce firmographic report/dashboard UX pack
- governance case metadata
- Data Cloud insights and Copy Field exception config
- live Salesforce Account activation fields
- live Data Cloud activation-key alignment
- live Data Cloud field path
- Account payload exception activation dry-run readiness
- `git diff --check`

The script intentionally skipped Salesforce deploy dry-run by default. A dry-run
deploy remains opt-in with `PULSE360_RUN_DEPLOY_DRY_RUN=1` after explicit
deployment approval.

## Acceptance Outcome

Recommended Linear outcome:

- Move `DAN-104` to Done as the Milestone E acceptance record.

Residual notes:

- The live dashboard's sovereign identifier component has no data by design
  until official evidence exists.
- The dashboard is validation-ready; a later demo-polish iteration can replace
  raw report tables with more compact scorecard-first visuals without changing
  DMO relationships or report joins.
