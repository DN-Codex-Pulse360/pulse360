# Pulse360 M1 Data Cloud Operational Profile Contract

## Purpose

Define the Data Cloud operational profile for M1 Account Hierarchy Intelligence.

This contract turns the Databricks hierarchy outputs into an Account-centered Data Cloud shape that can support:

- Account 360 summary fields
- coverage-gap planning
- stewardship review
- source/evidence drill-through
- CRM-safe activation back to Salesforce Account fields

It deliberately keeps raw graph evidence in Data Cloud/Databricks drill-through unless a Salesforce surface explicitly requires it.

## Source Outputs

Primary Databricks views:

- `pulse360_s4.identity_resolution.resolved_entity`
- `pulse360_s4.identity_resolution.weighted_attribute_resolution`
- `pulse360_s4.identity_resolution.entity_hierarchy_edge`
- `pulse360_s4.identity_resolution.entity_hierarchy_rollup`

Required source guarantees:

- CRM-safe account identifiers are preserved where Salesforce activation is possible.
- Sovereign or registry identities do not replace Salesforce `Account.Id` for CRM writeback.
- Every visible summary has confidence, freshness, source contribution, run ID, timestamp, and model version evidence.

## Operational Profile Shape

Target profile record: `pulse360_m1_account_hierarchy_operational_profile`

Primary Data Cloud target:

- `ssot__Account__dlm` plus Pulse360 extension attributes already tracked in `config/data-cloud/dmo-account-field-mapping.csv`

Primary CRM activation target:

- `Account`, limited to existing execution-safe summary fields in `config/data-cloud/activation-field-mapping.csv`

## Required Fields

| Field | Type | Source | Data Cloud role | CRM activation |
| --- | --- | --- | --- | --- |
| `operational_profile_id` | string | generated from `group_entity_id` and anchor account | Stable Data Cloud row key | No |
| `group_entity_id` | string | `entity_hierarchy_rollup.group_entity_id` | Group identity key | No |
| `primary_anchor_account_id` | string or null | selected CRM-safe account from covered group | Account DMO linkage when present | Match key only |
| `crm_anchor_account_ids` | string array, can be empty | hierarchy edges / resolved entities | Covered CRM accounts | No |
| `unified_profile_id` | string | generated Data Cloud profile key | Unified profile reference | Yes |
| `identity_confidence` | number | `resolved_entity.identity_confidence` | Identity evidence | Yes |
| `hierarchy_confidence` | number | `entity_hierarchy_rollup.hierarchy_confidence` | Hierarchy evidence | No by default |
| `validity_score_external` | number | minimum of identity, hierarchy, freshness scores | Summary confidence | Yes |
| `group_revenue_rollup` | number | `entity_hierarchy_rollup.group_revenue_visible` | Commercial summary | Yes |
| `group_revenue_visible` | number | `entity_hierarchy_rollup.group_revenue_visible` | CRM-covered revenue basis | Yes |
| `group_known_subsidiary_count` | integer | `entity_hierarchy_rollup.known_subsidiary_count` | Group breadth | Yes |
| `crm_covered_subsidiary_count` | integer | `entity_hierarchy_rollup.crm_covered_subsidiary_count` | CRM coverage | Yes |
| `external_subsidiaries_found` | integer | `entity_hierarchy_rollup.uncovered_subsidiary_count` | Uncovered entities | Yes |
| `coverage_gap_flag` | boolean | `entity_hierarchy_rollup.coverage_gap_flag` | Planning signal | Yes |
| `hierarchy_payload` | string | serialized rollup children payload | Drill-through graph summary | Optional only |
| `source_refs` | string | compacted `source_contributions` citations | Evidence summary | Yes |
| `freshness_status` | string | `entity_hierarchy_rollup.freshness_status` | Freshness cue | No by default |
| `last_synced_timestamp` | datetime | operational profile run timestamp | Activation freshness | Yes |
| `enrichment_run_id` | string | `entity_hierarchy_rollup.run_id` | Replay metadata | Yes |
| `model_id` | string | `entity_hierarchy_rollup.model_version` | Model lineage | Yes |
| `run_id` | string | Databricks job run | Replay metadata | No |
| `run_timestamp` | datetime | Databricks job timestamp | Replay metadata | No |
| `model_version` | string | profile transform version | Contract version | No |

## Activation Rules

1. Use `primary_anchor_account_id` or another approved Salesforce External ID as the CRM match key.
2. Never use `group_entity_id`, `operational_profile_id`, or another Databricks-only synthetic ID as the Salesforce Account match key.
3. Copy only summary fields already present in `config/data-cloud/activation-field-mapping.csv`.
4. Keep `hierarchy_payload`, full `source_contributions`, and all edge rows in Data Cloud/Databricks drill-through by default.
5. If a Salesforce surface needs raw hierarchy detail, treat `hierarchy_payload` as explicit UX scope and not as a default writeback field.
6. If `primary_anchor_account_id` is null, do not activate the row to CRM Account until a covered Salesforce Account anchor or approved External ID exists.

## M1 Transform Rules

| Source field | Profile field | Rule |
| --- | --- | --- |
| `group_entity_id` | `group_entity_id` | Preserve exactly. |
| `group_entity_id` | `unified_profile_id` | Prefix with `pulse360_m1_group:` for Data Cloud profile stability. |
| `group_revenue_visible` | `group_revenue_rollup` | Use visible revenue for first M1 slice until external revenue source is approved. |
| `group_revenue_visible` | `group_revenue_visible` | Preserve CRM-covered revenue basis. |
| `known_subsidiary_count` | `group_known_subsidiary_count` | Preserve count. |
| `crm_covered_subsidiary_count` | `crm_covered_subsidiary_count` | Preserve count. |
| `uncovered_subsidiary_count` | `external_subsidiaries_found` | Use existing activation field as the uncovered-entity count. |
| `coverage_gap_flag` | `coverage_gap_flag` | Preserve boolean. |
| `hierarchy_confidence` | `validity_score_external` | First slice uses hierarchy confidence as the external validity basis, capped by freshness. |
| `source_contributions` | `source_refs` | Serialize compact citations and source IDs only. |
| `hierarchy_payload` | `hierarchy_payload` | Serialize as Data Cloud detail/drill-through payload. |

## Acceptance Criteria

1. The M1 operational profile can be generated without changing Salesforce org configuration.
2. Required CRM activation fields map to existing source field names in `activation-field-mapping.csv`.
3. DMO/detail fields map to `dmo-account-field-mapping.csv` or are explicitly marked as Data Cloud drill-through only.
4. Raw hierarchy evidence is not required for default Salesforce Account writeback.
5. The contract is validated by `scripts/validate-m1-data-cloud-operational-profile.sh`.
