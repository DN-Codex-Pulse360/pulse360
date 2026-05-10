# DAN-334 M1 Data Cloud and Salesforce Validation Evidence

## Summary

`DAN-334` is source-prepared but not live-complete. Read-only MCP validation on
2026-05-09 confirms the existing firmographic Salesforce validation layer is
healthy, while M1-specific Data Cloud streams and Salesforce report/dashboard
metadata still need to be created in the live org.

## MCP Checks

### Existing Data Streams

`list_data_streams` against `pulse360-agent-target` returned 9 streams.
Relevant active firmographic streams:

| Stream | Status | Last refresh | Rows |
| --- | --- | --- | ---: |
| `firmographic_profile_export_Pulse360_Dat` | `ACTIVE/SUCCESS` | `2026-05-09T02:12:06.000+0000` | 18 |
| `firmographic_source_evidence_export_Puls` | `ACTIVE/SUCCESS` | `2026-05-09T02:12:00.000+0000` | 140 |
| `company_classification_export_Pulse360_D` | `ACTIVE/SUCCESS` | `2026-05-09T02:12:01.000+0000` | 11 |
| `corporate_linkage_export_Pulse360_Databr` | `ACTIVE/SUCCESS` | `2026-05-09T02:12:00.000+0000` | 2 |
| `sovereign_identifier_export_Pulse360_Dat` | `ACTIVE/SUCCESS` | `2026-05-09T02:12:01.000+0000` | 0 |
| `Pulse360_Activation_Review_Queue` | `ACTIVE/SUCCESS` | `2026-05-09T02:15:01.000+0000` | 11 |

### M1 Stream Gap

The following `get_data_stream_status` checks returned `total_size: 0` before
the dedicated `_export` table contract was added:

- `m1_account_hierarchy_activation_Pulse360_Databricks`
- `m1_account_group_rollup_Pulse360_Databricks`
- `m1_account_hierarchy_edge_Pulse360_Databricks`

The source contract now points the first M1 Data Cloud stream at:

- `pulse360_s4.intelligence.m1_account_hierarchy_activation_export`

Runtime validation on 2026-05-09 created/replaced these three export tables and
confirmed they match the base M1 table row counts:

| Export table | Rows | Key validation |
| --- | ---: | --- |
| `m1_account_hierarchy_activation_export` | 18 | 18 distinct Account join keys, matching `m1_account_hierarchy_activation`. |
| `m1_account_group_rollup_export` | 17 | 18 total members and 10 coverage gaps, matching `m1_account_group_rollup`. |
| `m1_account_hierarchy_edge_export` | 2 | 1 parent and 1 child, matching `m1_account_hierarchy_edge`. |

The group rollup and hierarchy edge exports remain Databricks-only for the
current Salesforce UX. They should not be promoted to Data Cloud DLO/DMO
objects unless a future report, segment, or activation workflow proves that
Salesforce users need those grains directly.

MCP checks for the proposed activation export stream name still returned
`total_size: 0` after Databricks export-table creation, confirming that the next
live step is Data Cloud stream creation:

- `m1_account_hierarchy_activation_export_Pulse360_Databricks`

### Existing Salesforce Reports and Dashboard

SOQL confirmed the five promoted firmographic reports still exist in
`Pulse360 Account Intelligence Validation`:

- `Account_and_Firmographic_iIW1`
- `Account_and_Evidence_4W81`
- `Account_and_Classification_qlX1`
- `Account_and_Corporate_Linkage_U4F1`
- `Account_and_Sovereign_Identifier_NOY1`

SOQL also confirmed the dashboard:

- Id: `01ZdL00000ABncLUAT`
- DeveloperName: `zZUAzaLhrPFnOpTDCJvUEUvPEQIohz`
- Title: `Pulse360 Account Intelligence Validation`
- Folder: `Pulse360 Account Intelligence Validation`

M1 report/dashboard searches returned zero rows, which is expected before M1
Data Cloud streams are created.

### Account Field Readiness

`list_account_fields` confirmed the target org has the Account fields needed for
M1 activation review:

- `Group_Revenue_Rollup__c`
- `Group_Known_Subsidiary_Count__c`
- `Coverage_Gap_Flag__c`
- `Group_Revenue_Visible__c`
- `Hierarchy_Payload__c`
- `DataCloud_Last_Synced__c`

## Source Artifacts Added

- `config/data-cloud/m1-account-hierarchy-dlo-dmo-setup.csv`
- `config/data-cloud/m1-account-hierarchy-dmo-field-mapping.csv`
- `config/data-cloud/m1-account-hierarchy-activation-field-mapping.csv`
- `config/salesforce/m1-account-hierarchy-validation-reports.csv`
- `config/salesforce/m1-account-hierarchy-surface.yaml`
- `docs/runbook/salesforce-m1-account-hierarchy-validation-runbook.md`
- `scripts/validate-m1-data-cloud-salesforce-surface.sh`

Follow-on hardening added dedicated Databricks export tables with field names
kept at or below 40 characters:

- `m1_account_hierarchy_activation_export`
- `m1_account_group_rollup_export`
- `m1_account_hierarchy_edge_export`

The source validator now checks these export SQL files directly so Data Cloud
field-name length and expected handoff columns stay source-controlled.

Follow-on field-mapping hardening added
`config/data-cloud/m1-account-hierarchy-dmo-field-mapping.csv` so the live Data
Cloud setup has an exact source-controlled mapping for the activation export
fields, primary key, relationship key, field types, and key qualifier.

Package-layout validation now also checks that the generated Databricks bundle
contains the three M1 export SQL files, includes them in `databricks.yml`
run-order output, and carries the M1 activation DMO field mapping into the
generated workspace.

The Salesforce/Data Cloud surface was then simplified so only
`Pulse360_M1_Hierarchy_Activation__dlm` is planned for the live Data Cloud
surface. `m1_account_group_rollup_export` and
`m1_account_hierarchy_edge_export` stay in Databricks as lineage/debugging
outputs until a Salesforce use case proves that a separate DLO/DMO is needed.

## Current Decision

No existing Data Cloud DMO relationship changes are required for the five
firmographic reports or dashboard. M1 should be introduced through one new
runbook-controlled activation Direct Access stream and a separate M1 validation
dashboard after live stream creation.
