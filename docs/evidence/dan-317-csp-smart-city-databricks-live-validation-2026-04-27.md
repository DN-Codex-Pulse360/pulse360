# DAN-317 CSP Smart City Databricks Live Validation

Date: 2026-04-27

## Purpose

Validate the first CSP smart-city proposition intelligence slice in live
Databricks.

This evidence supports the Pulse360 pivot from IT-services RevOps account
intelligence toward ASEAN communications-provider smart-city proposition
intelligence.

## Scope

Applied the CSP smart-city SQL pack:

1. `sql/databricks/csp_smart_city/00_create_schemas.sql`
2. `sql/databricks/csp_smart_city/05_smart_city_signal_sample.sql`
3. `sql/databricks/csp_smart_city/10_smart_city_proposition_readiness.sql`

## Warehouse

Databricks SQL warehouse:

```text
7052914888c7e86c
```

## Created Or Refreshed Objects

- `pulse360_s4.bronze_smart_city.smart_city_signal_sample`
- `pulse360_s4.bronze_smart_city.smart_city_b2b_customer_sample`
- `pulse360_s4.gold_smart_city.smart_city_proposition_readiness`

## Statement Evidence

Initial schema and view creation:

| SQL file | Statement ID |
| --- | --- |
| `00_create_schemas.sql` | `01f141dc-2bca-14ac-acb8-cdf1906997f1` |
| `00_create_schemas.sql` | `01f141dc-2d28-1c46-898d-3ffbac4ed1d3` |
| `00_create_schemas.sql` | `01f141dc-2e58-19f3-856d-f5aeaf916a36` |
| `05_smart_city_signal_sample.sql` | `01f141dc-2f5c-119b-b76c-3d118e815001` |
| `10_smart_city_proposition_readiness.sql` | `01f141dc-30d6-1a3b-8320-2aa0b2f19985` |

Refreshed after adding cross-source demo evidence:

| SQL file | Statement ID |
| --- | --- |
| `05_smart_city_signal_sample.sql` | `01f141dc-80cc-1795-aad5-ecf2a5295cb9` |
| `10_smart_city_proposition_readiness.sql` | `01f141dc-823f-1bca-9ce8-31e58dc71b49` |

Verification query:

```text
01f141dc-838a-1614-a1ea-8793fc0f0011
```

## Verification Query

```sql
SELECT
  target_entity_id,
  target_entity_name,
  country_code,
  offering_family,
  proposition_readiness_score,
  activation_state,
  activation_block_reasons,
  signal_count,
  source_families,
  consent_classes
FROM pulse360_s4.gold_smart_city.smart_city_proposition_readiness
ORDER BY proposition_readiness_score DESC, target_entity_id, offering_family;
```

## Result Summary

| Target | Country | Offering | Score | State | Evidence pattern |
| --- | --- | --- | ---: | --- | --- |
| Ho Chi Minh City IoT Locality | VN | `intelligent_parking` | `0.8257` | `activation_safe` | Cross-source CSP network, municipal open data, IoT telemetry, and public-sector trigger |
| Singapore Smart Nation Urban Mobility | SG | `urban_data_brokerage` | `0.7515` | `review_required` | Mobility data, data marketplace, and public-sector trigger with governance review |
| Kuala Lumpur Urban Mobility | MY | `intelligent_parking` | `0.6747` | `review_required` | Parking/access regulation signal requires governance review |
| AMATA City Chonburi | TH | `connected_city_iot_platform` | `0.6267` | `blocked` | Single-source CSP network evidence only |
| Singapore Smart Nation Urban Mobility | SG | `intelligent_parking` | `0.6137` | `blocked` | Single-source municipal open-data evidence only |
| Kuala Lumpur Urban Mobility | MY | `connected_city_iot_platform` | `0.6072` | `blocked` | Single-source partner ecosystem evidence only |
| Metro Manila IoT Platform Opportunity | PH | `connected_city_iot_platform` | `0.6007` | `blocked` | Single-source IoT telemetry evidence only |

## Interpretation

The live Databricks slice now proves the intended smart-city decision pattern:

- high-confidence, cross-source smart-city opportunity can be activation-safe
- data brokerage and automated identification motions can route to review even
  when the commercial opportunity is strong
- weak single-source propositions remain blocked until more evidence is present

This matches the Pulse360 trust standard: do not activate a smart-city
recommendation unless it is source-backed, confidence-scored, governed, and
safe for the next operating surface.

## Local Validation

The following local checks passed after the source changes:

```bash
scripts/validate-databricks-csp-smart-city-pack.sh
scripts/validate-contracts.sh
```

## Next Step

Extend the existing Data Cloud activation/review handoff to include
`pulse360_s4.gold_smart_city.smart_city_proposition_readiness`, starting with:

- `source_product = csp_smart_city_proposition_readiness`
- activation-safe row: Ho Chi Minh City intelligent parking
- review-required row: Singapore urban data brokerage
- blocked rows retained in Databricks but not pushed to activation

## Data Cloud Handoff Extension

The governance evidence and activation review queue have now been extended to
include `csp_smart_city_proposition_readiness`.

Updated source files:

- `contracts/account_intelligence_governance_evidence.schema.json`
- `sql/databricks/governance_evidence/10_account_intelligence_governance_evidence.sql`
- `sql/databricks/governance_evidence/20_activation_eligibility_review_queue.sql`
- `sql/databricks/governance_evidence/30_datacloud_activation_review_queue.sql`

Live Databricks statement IDs:

| SQL file | Statement ID |
| --- | --- |
| `10_account_intelligence_governance_evidence.sql` | `01f141de-51fd-1ae6-8912-aec3964caea9` |
| `20_activation_eligibility_review_queue.sql` | `01f141de-5543-1f15-ba9b-a70bee63e892` |
| `30_datacloud_activation_review_queue.sql` | `01f141de-584e-19bf-ad4c-d47e3a599146` |

Verification query:

```text
01f141de-6a74-1f33-9c9c-d3ef8542bb9c
```

Live Databricks handoff rows:

| Review queue ID | Confidence | Eligible | Block reasons |
| --- | ---: | --- | --- |
| `gov_csp_smart_city_city_hcmc_iot_locality_intelligent_parking` | `0.8257` | `true` | `[]` |
| `gov_csp_smart_city_city_singapore_smart_nation_urban_data_brokerage` | `0.7515` | `false` | `["governance_or_privacy_review_required"]` |
| `gov_csp_smart_city_city_kuala_lumpur_mobility_intelligent_parking` | `0.6747` | `false` | `["governance_or_privacy_review_required"]` |

Source-product count query:

```text
01f141de-6c73-1e22-a13a-c189c399ff75
```

`pulse360_s4.intelligence.datacloud_activation_review_queue` now contains:

| Source product | Row count |
| --- | ---: |
| `account_intelligence_ai_synthetic` | `1` |
| `csp_smart_city_proposition_readiness` | `3` |
| `firmographic_genai` | `1` |
| `firmographic_genai_runtime` | `2` |
| `m1_account_hierarchy` | `1` |

## Data Cloud Status

The Salesforce Data Cloud DMO did not yet show the CSP rows immediately after
the Databricks table refresh:

```sql
SELECT review_queue_id__c, source_product__c
FROM Pulse360_Activation_Review_Queue__dlm
WHERE source_product__c = 'csp_smart_city_proposition_readiness'
```

Result:

```text
0 rows
```

Current Data Stream status check:

```text
Name: Pulse360_Activation_Review_Queue
Status: ACTIVE
LastRefreshDate: 2026-04-27T01:45:02.000+0000
TotalRowsProcessed: 5
```

Conclusion: Databricks is ready, but Salesforce Data Cloud needs a Data Stream
refresh before the new `csp_smart_city_proposition_readiness` rows are visible
in `Pulse360_Activation_Review_Queue__dlm`.

## Data Cloud Refresh Proof

The Data Stream was refreshed from Salesforce Data Cloud.

Current Data Stream status:

```text
Name: Pulse360_Activation_Review_Queue
Status: ACTIVE
LastRefreshDate: 2026-04-27T02:21:14.000+0000
TotalRowsProcessed: 8
```

Post-refresh DMO query:

```sql
SELECT
  review_queue_id__c,
  source_product__c,
  source_record_id__c,
  resolved_entity_id__c,
  activation_resolution_hint__c,
  confidence_score__c,
  activation_eligible_flag__c,
  activation_block_reasons__c,
  lineage_status__c,
  model_id__c
FROM Pulse360_Activation_Review_Queue__dlm
WHERE source_product__c = 'csp_smart_city_proposition_readiness'
LIMIT 10;
```

Result:

```text
total_size = 3
```

Rows:

| Review queue ID | Resolved entity | Confidence | Eligible | Block reasons |
| --- | --- | ---: | --- | --- |
| `gov_csp_smart_city_city_hcmc_iot_locality_intelligent_parking` | `ent_city_hcmc_iot_locality` | `0.8257` | `true` | `[]` |
| `gov_csp_smart_city_city_singapore_smart_nation_urban_data_brokerage` | `ent_city_singapore_smart_nation` | `0.7515` | `false` | `["governance_or_privacy_review_required"]` |
| `gov_csp_smart_city_city_kuala_lumpur_mobility_intelligent_parking` | `ent_city_kuala_lumpur_mobility` | `0.6747` | `false` | `["governance_or_privacy_review_required"]` |

All three rows preserve:

- `source_product__c = csp_smart_city_proposition_readiness`
- `activation_resolution_hint__c = create_or_map_crm_account_required`
- `lineage_status__c = source_bound`
- `model_id__c = csp-smart-city-proposition-v1`

Conclusion: the CSP smart-city readiness slice is now visible in Salesforce Data
Cloud through the existing activation review DMO.

## Manila And B2B Target-Customer Extension

The CSP smart-city source pack was refreshed to include Manila / Metro Manila
propositions and associated B2B target-customer fixtures.

Updated source files:

- `contracts/csp_smart_city_proposition_signal.schema.json`
- `data/samples/csp_smart_city_proposition_signal_sample.json`
- `sql/databricks/csp_smart_city/05_smart_city_signal_sample.sql`
- `sql/databricks/csp_smart_city/10_smart_city_proposition_readiness.sql`
- `sql/databricks/governance_evidence/10_account_intelligence_governance_evidence.sql`
- `scripts/validate-databricks-csp-smart-city-pack.sh`
- `sql/databricks/csp_smart_city/README.md`
- `docs/planning/pulse360-csp-smart-city-pivot-2026-04-27.md`

Local validation:

```bash
./scripts/validate-databricks-csp-smart-city-pack.sh
./scripts/validate-contracts.sh
./scripts/validate-databricks-governance-evidence-pack.sh
./scripts/validate-databricks-package-layout.sh
./scripts/check-codex-operator-health.sh
```

All checks passed.

Live Databricks statement IDs:

| SQL file | Statement ID |
| --- | --- |
| `05_smart_city_signal_sample.sql` signal view | `01f141e5-c6dc-1da5-8ec5-420142d1e415` |
| `05_smart_city_signal_sample.sql` B2B customer view | `01f141e5-d913-1a2f-b95b-3229dc806bea` |
| `10_smart_city_proposition_readiness.sql` | `01f141e5-da8f-1aa1-82b8-5ea2a8c7cb41` |
| `10_account_intelligence_governance_evidence.sql` | `01f141e5-dd01-1c39-8ac7-9d110e28b21d` |
| `20_activation_eligibility_review_queue.sql` | `01f141e5-e253-1d64-9151-9eed74fde190` |
| `30_datacloud_activation_review_queue.sql` | `01f141e5-e593-14b4-ad07-01c0b2ec7c85` |

Manila readiness verification query:

```text
01f141e6-089f-1631-a4f4-0f1bffb3c110
```

Live Manila results:

| Target | Offering | Score | State | Signals | Target B2B customer IDs |
| --- | --- | ---: | --- | ---: | --- |
| `city_metro_manila_iot` | `connected_city_iot_platform` | `0.7602` | `review_required` | `3` | `b2b_ph_ayala_property_group`, `b2b_ph_mmda_mobility_office` |
| `city_metro_manila_iot` | `intelligent_parking` | `0.7450` | `review_required` | `3` | `b2b_ph_ayala_property_group`, `b2b_ph_manila_parking_operator`, `b2b_ph_mmda_mobility_office` |
| `city_metro_manila_iot` | `urban_data_brokerage` | `0.5968` | `review_required` | `2` | `b2b_ph_ayala_property_group`, `b2b_ph_mmda_mobility_office` |

Philippines B2B customer fixture query:

```text
01f141e6-0d6c-11ee-a36d-93d94213a989
```

Live Philippines fixture rows:

| B2B customer ID | Name | Type | Priority offerings |
| --- | --- | --- | --- |
| `b2b_ph_ayala_property_group` | Ayala Urban Property Group | `property_group` | IoT platform, intelligent parking, urban data brokerage |
| `b2b_ph_manila_parking_operator` | Manila Central Parking Operator | `parking_operator` | intelligent parking |
| `b2b_ph_mmda_mobility_office` | Metro Manila Development Authority Mobility Office | `transport_authority` | intelligent parking, urban data brokerage |

Data Cloud handoff verification query:

```text
01f141e6-0a2f-11d1-852e-ec2e31bee064
```

`pulse360_s4.intelligence.datacloud_activation_review_queue` now contains six
CSP smart-city rows:

| Source record | Confidence | Eligible | Block reasons |
| --- | ---: | --- | --- |
| `smart_city_readiness_city_hcmc_iot_locality_intelligent_parking` | `0.8257` | `true` | `[]` |
| `smart_city_readiness_city_kuala_lumpur_mobility_intelligent_parking` | `0.6747` | `false` | `["governance_or_privacy_review_required"]` |
| `smart_city_readiness_city_metro_manila_iot_connected_city_iot_platform` | `0.7602` | `false` | `[]` |
| `smart_city_readiness_city_metro_manila_iot_intelligent_parking` | `0.7450` | `false` | `[]` |
| `smart_city_readiness_city_metro_manila_iot_urban_data_brokerage` | `0.5968` | `false` | `["governance_or_privacy_review_required"]` |
| `smart_city_readiness_city_singapore_smart_nation_urban_data_brokerage` | `0.7515` | `false` | `["governance_or_privacy_review_required"]` |

Source-product count query:

```text
01f141e6-0bfa-10be-950a-92cac5037e7c
```

Current Databricks handoff counts:

| Source product | Row count |
| --- | ---: |
| `account_intelligence_ai_synthetic` | `1` |
| `csp_smart_city_proposition_readiness` | `6` |
| `firmographic_genai` | `1` |
| `firmographic_genai_runtime` | `2` |
| `m1_account_hierarchy` | `1` |

Initial Salesforce Data Cloud DMO status after Databricks refresh:

```text
Pulse360_Activation_Review_Queue__dlm still returns 3 CSP rows.
DataStreamStatus: ACTIVE
LastRefreshDate: 2026-04-27T02:45:02.000+0000
TotalRowsProcessed: 8
```

Conclusion: Databricks is refreshed and Data Cloud handoff is ready with
Manila rows, but the Salesforce Data Cloud Data Stream must be refreshed again
before the three new Manila CSP rows appear in
`Pulse360_Activation_Review_Queue__dlm`.

## Manila Data Cloud Refresh Proof

The Data Stream was refreshed from Salesforce Data Cloud after the Manila and
B2B target-customer extension.

Current Data Stream status:

```text
Name: Pulse360_Activation_Review_Queue
Status: ACTIVE
LastRefreshDate: 2026-04-27T03:15:04.000+0000
TotalRowsProcessed: 11
```

Post-refresh DMO query:

```sql
SELECT
  source_record_id__c,
  source_product__c,
  confidence_score__c,
  activation_eligible_flag__c,
  activation_block_reasons__c,
  confidence_components__c
FROM Pulse360_Activation_Review_Queue__dlm
WHERE source_product__c = 'csp_smart_city_proposition_readiness'
ORDER BY source_record_id__c
LIMIT 20;
```

Result:

```text
total_size = 6
```

New Manila rows now visible in Salesforce Data Cloud:

| Source record | Confidence | Eligible | Block reasons | Target B2B customer IDs in confidence components |
| --- | ---: | --- | --- | --- |
| `smart_city_readiness_city_metro_manila_iot_connected_city_iot_platform` | `0.7602` | `false` | `[]` | `b2b_ph_ayala_property_group`, `b2b_ph_mmda_mobility_office` |
| `smart_city_readiness_city_metro_manila_iot_intelligent_parking` | `0.7450` | `false` | `[]` | `b2b_ph_ayala_property_group`, `b2b_ph_manila_parking_operator`, `b2b_ph_mmda_mobility_office` |
| `smart_city_readiness_city_metro_manila_iot_urban_data_brokerage` | `0.5968` | `false` | `["governance_or_privacy_review_required"]` | `b2b_ph_ayala_property_group`, `b2b_ph_mmda_mobility_office` |

Conclusion: the Manila / Metro Manila CSP smart-city propositions are now
visible in Salesforce Data Cloud through `Pulse360_Activation_Review_Queue__dlm`
with proposition confidence, governance state, and B2B target-customer evidence
preserved.

## First-Class CSP Action Field Extension

The Databricks handoff table was extended so CSP smart-city review fields are
available as first-class columns rather than only inside
`confidence_components`.

Updated source files:

- `contracts/databricks_activation_review_queue_to_datacloud.schema.json`
- `data/samples/databricks_activation_review_queue_to_datacloud_sample.json`
- `config/data-cloud/databricks-activation-review-queue-field-mapping.csv`
- `sql/databricks/governance_evidence/30_datacloud_activation_review_queue.sql`
- `sql/databricks/governance_evidence/README.md`
- `scripts/validate-databricks-governance-evidence-pack.sh`
- `docs/runbook/dan-317-data-cloud-csp-action-fields-runbook.md`

Local validation:

```bash
./scripts/validate-databricks-governance-evidence-pack.sh
./scripts/validate-contracts.sh
./scripts/validate-databricks-package-layout.sh
```

All checks passed.

Live Databricks statement ID:

```text
01f141ee-fdbf-10ae-9435-b5d16853d86c
```

Schema verification query:

```text
01f141ef-2bf5-1ea4-b8ac-a217bed76dff
```

Confirmed Databricks columns:

- `target_entity_name`
- `country_code`
- `market`
- `offering_family`
- `offer_bundle`
- `target_b2b_customer_ids`
- `target_b2b_customer_names`
- `recommended_next_actions`
- `review_priority`

CSP action-field verification query:

```text
01f141ef-2d76-146c-b09d-7d91523db123
```

Live Manila action fields:

| Source record | Offering | Target B2B names | Review priority |
| --- | --- | --- | --- |
| `smart_city_readiness_city_metro_manila_iot_connected_city_iot_platform` | `connected_city_iot_platform` | Ayala Urban Property Group, Metro Manila Development Authority Mobility Office | `account_mapping_review` |
| `smart_city_readiness_city_metro_manila_iot_intelligent_parking` | `intelligent_parking` | Ayala Urban Property Group, Manila Central Parking Operator, Metro Manila Development Authority Mobility Office | `account_mapping_review` |
| `smart_city_readiness_city_metro_manila_iot_urban_data_brokerage` | `urban_data_brokerage` | Ayala Urban Property Group, Metro Manila Development Authority Mobility Office | `governance_review` |

Current Data Cloud field status:

```text
Pulse360_Activation_Review_Queue__dlm field count: 30
New CSP action fields are not yet present in the DMO.
```

Conclusion: Databricks now publishes the action-ready CSP fields. The remaining
step is the org-locked Data Cloud UI step to `Add Source Fields`, map the nine
new fields, and refresh the Data Stream.

## First-Class CSP Action Field Data Cloud Proof

The Data Cloud Data Stream was updated through the UI and refreshed.

Current Data Stream status:

```text
Name: Pulse360_Activation_Review_Queue
Status: ACTIVE
LastRefreshDate: 2026-04-27T05:15:06.000+0000
TotalRowsProcessed: 11
```

DMO field verification:

```text
Pulse360_Activation_Review_Queue__dlm field count: 39
```

The following fields now exist in Data Cloud:

- `target_entity_name__c`
- `country_code__c`
- `market__c`
- `offering_family__c`
- `offer_bundle__c`
- `target_b2b_customer_ids__c`
- `target_b2b_customer_names__c`
- `recommended_next_actions__c`
- `review_priority__c`

Post-refresh DMO query:

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

Result:

```text
total_size = 6
```

Verified Manila action rows:

| Source record | Offering | B2B target customers | Review priority |
| --- | --- | --- | --- |
| `smart_city_readiness_city_metro_manila_iot_connected_city_iot_platform` | `connected_city_iot_platform` | Ayala Urban Property Group, Metro Manila Development Authority Mobility Office | `account_mapping_review` |
| `smart_city_readiness_city_metro_manila_iot_intelligent_parking` | `intelligent_parking` | Ayala Urban Property Group, Manila Central Parking Operator, Metro Manila Development Authority Mobility Office | `account_mapping_review` |
| `smart_city_readiness_city_metro_manila_iot_urban_data_brokerage` | `urban_data_brokerage` | Ayala Urban Property Group, Metro Manila Development Authority Mobility Office | `governance_review` |

Conclusion: the CSP smart-city review queue is now Data Cloud-visible with
first-class proposition fields and B2B target-customer fields populated.

## CRM Stewardship Surface Source Validation

Timestamp: 2026-04-27 14:27:57 +08

Implemented source-backed CRM stewardship updates for CSP smart-city review rows:

- Added Governance Case evidence fields for Data Cloud review queue id, source record id, source product, target entity, market, offering family, offer bundle, target B2B customers, recommended next actions, review priority, and activation blockers.
- Added CSP decision reason codes and recommended action values for account mapping, proposition qualification, and governance review.
- Updated merge validation rules so surviving/merged Account requirements remain enforced for `Approve Merge`, but do not block CSP proposition reviews.
- Extended `Pulse360AgentOrchestratorService` to read CSP review evidence from `Pulse360_Activation_Review_Queue__dlm` by source record id or review queue id.
- Updated the Governance Snapshot, Match Evidence, and Decision Workspace LWCs to display CSP proposition evidence and allow non-merge CSP decisions.
- Updated the Governance Case Steward permission set with read access to the CSP evidence fields.

Validation commands:

```text
./scripts/check-codex-operator-health.sh
./scripts/validate-governance-case-metadata.sh
./scripts/validate-m1-salesforce-action-surface.sh
./scripts/validate-contracts.sh
sf project deploy validate --target-org pulse360-agent-target ... --test-level RunSpecifiedTests --tests Pulse360AgentOrchestratorServiceTest --wait 20
```

Validation results:

```text
Codex operator health check completed.
Governance case metadata validation completed.
M1 Salesforce action surface validation completed.
Contract validation completed.
Salesforce deploy validation: 0AfdL00000Zg47uSAB
Pulse360AgentOrchestratorServiceTest: Passing 19, Failing 0, Total 19
```

Conclusion: the Data Cloud-visible CSP review queue now has a validated CRM
stewardship surface in source. This is still a deploy validation, not a real
target-org deploy.
