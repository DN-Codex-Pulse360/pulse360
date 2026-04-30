# Pulse360 Data Layer Closeout Evidence

Date: 2026-04-27
Org alias: `pulse360-agent-target`
Databricks SQL warehouse: `7052914888c7e86c`

## Scope

Close out the underpinning data layer for the current Pulse360 prototype path:

- Databricks account intelligence source layer
- identity and hierarchy resolution
- firmographic / GenAI enrichment design and runtime surface
- CSP smart-city proposition readiness
- governance evidence and activation review queue
- Data Cloud Account and CSP review queue handoff
- Salesforce CRM Account activation field path
- Salesforce governance feedback ingestion back into Databricks
- Salesforce CRM source refresh alignment for the active target org

## Source Changes

Added repeatable closeout gates:

- `scripts/check-databricks-data-layer-runtime.sh`
  - checks live Databricks SQL asset row counts
  - validates required columns on `datacloud_export_accounts`
  - validates required columns on `datacloud_activation_review_queue`
  - requires at least three Manila CSP action rows with B2B target-customer evidence
- `scripts/validate-data-layer-closeout.sh`
  - orchestrates operator health, Databricks pack validators, live Databricks runtime check, Data Cloud validators, Salesforce Account activation checks, canonical export checks, and contract checks

Updated Data Cloud MCP defaults to the validated V2 Account export path:

- source object: `pulse360_account_intelligence_export_v2__dll`
- data stream: `DC Export Accounts P360 V2`

## Validation Command

```bash
./scripts/validate-data-layer-closeout.sh
```

## Validation Result

```text
[PASS] Pulse360 data layer closeout validation completed
```

Key gates passed:

- Codex operator health
- Databricks package layout
- Databricks Salesforce SQL pack
- Databricks account intelligence sources
- Databricks identity resolution
- Databricks firmographic/GenAI pack
- Databricks governance evidence pack
- Databricks CSP smart-city pack
- Databricks dashboard pack
- Databricks live runtime
- Data Cloud DMO extension
- Data Cloud field path
- Salesforce/Data Cloud MCP surface
- Salesforce Account activation fields
- canonical exports
- contracts
- contract completeness

## Live Databricks Runtime

`scripts/check-databricks-data-layer-runtime.sh` verified:

| Asset | Row count |
| --- | ---: |
| `pulse360_s4.silver_salesforce.crm_account` | 18 |
| `pulse360_s4.silver_salesforce.crm_governance_case` | 1 |
| `pulse360_s4.identity_resolution.resolved_entity` | 19 |
| `pulse360_s4.identity_resolution.entity_hierarchy_rollup` | 2 |
| `pulse360_s4.identity_resolution.m1_account_hierarchy_operational_profile` | 2 |
| `pulse360_s4.gold.account_genai_enrichment_output` | 1 |
| `pulse360_s4.gold_smart_city.smart_city_proposition_readiness` | 9 |
| `pulse360_s4.intelligence.datacloud_export_accounts` | 18 |
| `pulse360_s4.intelligence.datacloud_activation_review_queue` | 11 |
| `pulse360_s4.intelligence.governance_case_metrics` | 1 |

Column checks passed for:

- `pulse360_s4.intelligence.datacloud_export_accounts`
- `pulse360_s4.intelligence.datacloud_activation_review_queue`

Manila CSP action rows:

```text
manila_csp_action_rows = 3
```

Additional source-alignment checks after refreshing the Databricks Salesforce
ingestion path:

| Check | Result |
| --- | ---: |
| Current-org Account IDs in `silver_salesforce.crm_account` | 18 |
| Stale Account IDs in `silver_salesforce.crm_account` | 0 |
| Current-org Account IDs in `intelligence.datacloud_export_accounts` | 18 |
| Stale Account IDs in `intelligence.datacloud_export_accounts` | 0 |
| Review queue rows with current CRM candidate IDs | 3 |
| Review queue rows with stale CRM candidate IDs | 0 |
| Current-org Opportunity rows exposed by `silver_salesforce.crm_opportunity` | 31 |
| Stale Opportunity rows exposed by `silver_salesforce.crm_opportunity` | 0 |

The managed Databricks Salesforce extract pipeline was repointed to the active
`pulse360` Salesforce connection and then refreshed successfully:

| Pipeline | Update | Result |
| --- | --- | --- |
| `pulse360-salesforce-extract` | `acc4fafe-e9a3-46f9-a729-5e5c03c6fd25` | Incremental refresh completed |
| `pulse360-salesforce-extract` | `e9ba7835-d243-4e15-ba6f-f226d88ec069` | Full refresh completed |

Post-refresh bronze checks:

| Bronze table | Rows | Current-org IDs | Stale IDs |
| --- | ---: | ---: | ---: |
| `account` | 18 | 18 | 0 |
| `contact` | 20 | 20 | 0 |
| `opportunity` | 31 | 31 | 0 |
| `opportunitycontactrole` | 0 | 0 | 0 |
| `opportunitylineitem` | 0 | 0 | 0 |
| `product2` | 17 | 17 | 0 |

The silver layer also filters opportunity-derived views through the current
`crm_account`, `crm_contact`, and `crm_opportunity` anchors so stale bronze
residue cannot flow into gold exports or Data Cloud handoff tables if a future
managed-ingestion retry lands partial state.

## Live Data Cloud Runtime

Data Streams:

| Data Stream | Status | Last refresh | Rows |
| --- | --- | --- | ---: |
| `DC Export Accounts P360 V2` | `ACTIVE / SUCCESS` | `2026-04-20T06:29:34.000+0000` | 43 |
| `Pulse360_Activation_Review_Queue` | `ACTIVE / SUCCESS` | `2026-04-27T07:15:03.000+0000` | 11 |
| `DC Export Accounts P360 Fix` | `ACTIVE / SUCCESS` | `2026-04-18T14:25:10.000+0000` | 4 |

The closeout default is now the V2 stream because it contains the validated
`intent_signal_payload` source field required by the Account activation path.
The older `Fix` stream is retained as historical recovery evidence only.

Data Cloud field-path status for V2:

```text
source_object.missing_field_count = 0
dmo.missing_mapping_count = 0
dmo.missing_target_field_count = 0
account.missing_mapping_count = 0
account.missing_target_field_count = 0
```

CSP review DMO:

```text
Pulse360_Activation_Review_Queue__dlm
source_product = csp_smart_city_proposition_readiness
row_count = 6
```

Verified Manila rows include:

- `connected_city_iot_platform`
- `intelligent_parking`
- `urban_data_brokerage`

with target B2B customers such as:

- Ayala Urban Property Group
- Manila Central Parking Operator
- Metro Manila Development Authority Mobility Office

## Live Salesforce CRM Runtime

Sampled CRM Accounts confirmed populated Account activation fields:

- `Singtel Group`
- `NCS Pte. Ltd.`
- `Ayala Corporation`
- `Ayala Corp.`
- `JG Summit Holdings, Inc.`

Validated field examples:

- `Intent_Signal_Payload__c`
- `AI_Narrative__c`
- `AI_Model_Id__c`
- `AI_Source_Refs__c`

Tooling metadata confirmed those Account fields exist.

## Closeout Decision

The underpinning data layer is now closed for the current prototype milestone.

Closed means:

- source contracts validate
- Databricks SQL assets are present and queryable
- Data Cloud Account V2 field path is aligned
- Data Cloud CSP activation review queue is active and populated
- Salesforce Account activation fields are populated on sampled records
- Salesforce governance feedback is visible in Databricks
- Databricks Salesforce source views are aligned to the active Salesforce org
  for Account and downstream opportunity-derived intelligence
- repeatable closeout validation exists in source
- Databricks-native scheduled validation now records runtime check evidence in
  `pulse360_s4.ops.data_layer_validation_runs`
- Unity Catalog lineage is visible for the key Account export and activation
  review queue paths

## Remaining Production Hardening

These are not blockers for the prototype data-layer closeout, but remain before
production-grade release:

- convert manual Data Cloud UI mapping operations into org-locked runbook gates
  where metadata deployment is unsupported
- promote the latest Claude/GenAI runtime output into the canonical Account V2
  refresh path before a final demo freeze
- add external alert routing for failed Databricks validation job runs
- capture Unity Catalog lineage screenshots for the final client demo deck
- increase Salesforce governance feedback sample volume beyond one case
