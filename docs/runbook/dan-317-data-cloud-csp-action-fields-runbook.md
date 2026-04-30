# DAN-317 Data Cloud CSP Action Fields Runbook

Date: 2026-04-27

## Purpose

Make CSP smart-city review rows directly queryable in Salesforce Data Cloud by
adding first-class proposition and target-customer fields from Databricks.

Databricks already publishes these fields in:

```text
pulse360_s4.intelligence.datacloud_activation_review_queue
```

## Current State

The Data Stream `Pulse360_Activation_Review_Queue` is active and currently
mapped to the original review queue fields.

The following fields exist in Databricks but are not yet visible in
`Pulse360_Activation_Review_Queue__dlm`:

| Source field | Target Data Cloud field | Type |
| --- | --- | --- |
| `target_entity_name` | `target_entity_name__c` | Text |
| `country_code` | `country_code__c` | Text |
| `market` | `market__c` | Text |
| `offering_family` | `offering_family__c` | Text |
| `offer_bundle` | `offer_bundle__c` | Text |
| `target_b2b_customer_ids` | `target_b2b_customer_ids__c` | Text |
| `target_b2b_customer_names` | `target_b2b_customer_names__c` | Text |
| `recommended_next_actions` | `recommended_next_actions__c` | Text |
| `review_priority` | `review_priority__c` | Text |

## Salesforce Data Cloud Steps

1. Open Data Cloud.
2. Go to `Data Streams`.
3. Open `Pulse360_Activation_Review_Queue`.
4. Click `Add Source Fields`.
5. Select the nine fields listed above.
6. Save the Data Stream field update.
7. Open the Data Mapping panel.
8. Map each source field to the matching Data Cloud field API name listed
   above.
9. Confirm the mapped-field count increases by `9`.
10. Click `Refresh Now`.

## Validation Query

After refresh, run:

```sql
SELECT
  source_record_id__c,
  target_entity_name__c,
  country_code__c,
  market__c,
  offering_family__c,
  offer_bundle__c,
  target_b2b_customer_ids__c,
  target_b2b_customer_names__c,
  recommended_next_actions__c,
  review_priority__c,
  confidence_score__c,
  activation_block_reasons__c
FROM Pulse360_Activation_Review_Queue__dlm
WHERE source_product__c = 'csp_smart_city_proposition_readiness'
ORDER BY source_record_id__c
LIMIT 20;
```

Expected result:

- `6` CSP smart-city rows
- `3` Manila / Metro Manila rows
- Manila rows have non-empty `target_b2b_customer_ids__c`
- Manila rows have non-empty `target_b2b_customer_names__c`
- `review_priority__c` values include:
  - `account_mapping_review`
  - `governance_review`
  - `activation_candidate`

## Notes

- These fields are optional for non-CSP rows. Firmographic, M1 hierarchy, and
  synthetic account-intelligence rows can leave them blank.
- Keep `confidence_components__c` mapped. It remains the audit payload even
  after the action fields become first-class DMO fields.
- Do not map these fields to Salesforce Account yet. They belong first in the
  Data Cloud review queue; CRM writeback should follow only after stewardship
  decisions are captured.
