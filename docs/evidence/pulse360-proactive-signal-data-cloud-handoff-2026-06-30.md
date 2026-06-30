# Pulse360 Proactive Signal Data Cloud Handoff

Date: 2026-06-30

## Status

Data Cloud activation is handoff-ready, but not live yet.

The proactive Data Cloud stream is not yet created or repointed. The current
live Salesforce surface remains a fixture-backed preview through the custom Salesforce LWC/Apex assistant and action panels.

## Evidence Used

| Layer | Evidence | Status |
| --- | --- | --- |
| Databricks projection | `pulse360_s4.gold_proactive_signal.datacloud_proactive_signal_projection` | Live checked, 1 Northstar row. |
| Existing Data Cloud Account stream | `datacloud_export_accounts_Pulse360_Datab` | Active Direct Access stream, 22 rows, no Northstar proactive row found. |
| Data Cloud mapping | `config/data-cloud/proactive-signal-field-mapping.csv` | Source-controlled handoff contract. |
| Salesforce preview | `pulse360-agent-target` seed evidence | Fixture-backed Account preview. |
| Agentforce runtime | Native runtime | Not verified; fallback surface remains active. |

## Databricks Facts

From `docs/evidence/pulse360-proactive-signal-databricks-live-check-2026-06-30.json`:

- Projection: `pulse360_s4.gold_proactive_signal.datacloud_proactive_signal_projection`
- Row count: `1`
- Account: `Northstar Foods Group`
- `source_account_id`: `001NST000000001AAA`
- `coverage_gap_flag`: `true`
- `citation_count`: `6`

## Salesforce Facts

From `docs/evidence/pulse360-proactive-signal-salesforce-seed-2026-06-29.json`:

- Target org: `pulse360-agent-target`
- Account URL:
  `https://orgfarm-d50863b207-dev-ed.develop.my.salesforce.com/lightning/r/Account/001dL00002HTb4cQAD/view`
- Signal routing URL:
  `https://orgfarm-d50863b207-dev-ed.develop.my.salesforce.com/lightning/n/Pulse360_Signal_Routing?c__previewRecordId=001dL00002HTb4cQAD`
- Seed mode: `fixture_backed_salesforce_preview`
- Native Agentforce runtime verified: `false`

## Data Cloud Facts

Salesforce CLI metadata and SOQL checks on `pulse360-agent-target` showed:

- Data Stream metadata type is visible through the CLI.
- Current fresh Account stream:
  `datacloud_export_accounts_Pulse360_Datab`
- Data Stream Id: `1dsdL000000TGJ7QAO`
- Stream type: `DIRECT_ACCESS_ACCELERATED`
- Status: `ACTIVE`
- Import run status: `SUCCESS`
- Total rows processed: `22`
- Last refresh: `2026-06-30T12:58:26.000+0000`
- Matching Data Lake Object:
  `datacloud_export_accounts_Pulse360_Datab__dll`
- Data Lake Object Id: `1dldL000007RYftQAG`
- Data Lake Object category: `Profile`
- Data Lake Object total records: `22`

The existing Account stream does not currently contain the Northstar proactive
signal row:

```sql
SELECT account_name__c, source_account_id__c, coverage_gap_flag__c,
       ai_narrative__c, ai_recommended_actions__c, source_refs__c,
       last_synced_timestamp__c
FROM datacloud_export_accounts_Pulse360_Datab__dll
WHERE account_name__c LIKE '%Northstar%'
LIMIT 10
```

Result: `0` records.

## Next Live Action

Create a new Data Cloud Data Stream from the existing `Pulse360 Databricks`
connection to:

```text
pulse360_s4.gold_proactive_signal.datacloud_proactive_signal_projection
```

Then map and activate fields using:

```text
config/data-cloud/proactive-signal-field-mapping.csv
```

The proof point to capture is that the Northstar row appears in a Data Cloud
DLO/DMO and that `Account.DataCloud_Last_Synced__c` is updated by Data
Cloud/Copy Field Enrichment rather than by the fixture seed script.
