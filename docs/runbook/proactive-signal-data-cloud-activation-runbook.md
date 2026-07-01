# Proactive Signal Data Cloud Activation Runbook

Date: 2026-06-30

## Purpose

Move the Northstar proactive signal from the isolated Databricks projection into
Salesforce Data Cloud without disturbing the older Account export stream.

This is the Data Cloud bridge for the current demo target:

```text
pulse360_s4.gold_proactive_signal.datacloud_proactive_signal_projection
```

Current status: the proactive Data Cloud stream is not yet created or repointed.
The Salesforce preview is still fixture-backed through the custom Salesforce LWC/Apex assistant and action panels.

Live CLI check on 2026-06-30 found the existing
`datacloud_export_accounts_Pulse360_Datab` stream active and fresh, but it did
not contain a Northstar proactive signal row. That means the next Data Cloud
step is still the isolated proactive stream or an approved merge into the wider
`datacloud_export_accounts` export.

## Preferred Path

Create a new, isolated Databricks Data Stream for the proactive signal projection
rather than repointing the older `datacloud_export_accounts` stream first.

Use this path when the goal is UAT proof and demo safety:

1. In `pulse360-agent-target`, create a new Data Cloud Data Stream from the
   existing `Pulse360 Databricks` connection.
2. Select the Databricks table/view:

   ```text
   pulse360_s4.gold_proactive_signal.datacloud_proactive_signal_projection
   ```

3. Set stream type to Direct Access or Batch based on what the org offers for
   the Databricks connector.
4. Configure the Data Lake Object as a Profile-style object for the demo.
5. Use `source_account_id` as the relationship key to CRM `Account.Id`.
6. Map fields using:

   ```text
   config/data-cloud/proactive-signal-field-mapping.csv
   ```

7. Run or refresh Copy Field Enrichment for the writeback-ready fields,
   especially:

   ```text
   Intent_Signal_Payload__c
   Coverage_Gap_Flag__c
   AI_Narrative__c
   AI_Recommended_Actions__c
   AI_Source_Refs__c
   AI_Citation_Count__c
   DataCloud_Last_Synced__c
   Enrichment_Run_Id__c
   AI_Model_Id__c
   ```

8. Open the Northstar Salesforce Account and confirm
   `DataCloud_Last_Synced__c` is newer than the Databricks
   `last_synced_timestamp`.
9. Open the signal-routing workspace and confirm the Account is no longer only
   using fixture-backed evidence.

## Controlled Alternative

Use the existing `datacloud_export_accounts` path only if we deliberately choose
to merge the proactive projection into the broader Account intelligence export:

```text
pulse360_s4.intelligence.datacloud_export_accounts
```

This is closer to the product architecture, but it changes the broader export
contract. Use it only after release approval because it can affect the older
Data Cloud Account stream and Copy Field Enrichment path.

## Acceptance Evidence

Capture these items before claiming Data Cloud activation is done:

- Data Stream name and record URL.
- Data Lake Object API name.
- Data Model Object or relationship target.
- Refresh status and processed record count.
- Copy Field Enrichment run status.
- Salesforce Account URL for Northstar Foods Group.
- Signal-routing workspace URL.
- Before/after value of `Account.DataCloud_Last_Synced__c`.
- Confirmation that `source_account_id` joins to `Account.Id`.

## Validation

Run the static handoff gate:

```bash
./scripts/validate-proactive-signal-data-cloud-handoff.sh
```

After live Data Cloud activation, rerun:

```bash
TARGET_ORG=pulse360-agent-target ./scripts/validate-salesforce-proactive-signal-demo.sh
TARGET_ORG=pulse360-agent-target ./scripts/validate-m1-account-hierarchy-readiness-gate.sh
```

The M1 readiness gate can still fail on the older CRM freshness/writeback
boundary. That failure must not be used to invalidate this isolated proactive
signal stream, but it must stay visible in the demo narrative.

## Do Not Do

- Do not overwrite seller-editable CRM fields with uncertain signal data.
- Do not map `source_account_id` to a synthetic key; it must join to
  `Account.Id`.
- Do not claim native Agentforce runtime success from this Data Cloud step.
- Do not call stream success the same thing as CRM writeback success.
- Do not delete the existing `datacloud_export_accounts` evidence stream while
  the demo is still using it as historical context.
