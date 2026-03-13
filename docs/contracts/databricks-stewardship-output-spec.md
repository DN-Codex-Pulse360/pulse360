# Spec: Databricks Stewardship Outputs

## Purpose
Define the Databricks output specification required to implement the first Pulse360 product slice: stewardship.

This spec turns the stewardship contract into implementation-facing Databricks deliverables:
- gold objects to create
- required columns and semantics
- source and join rules
- refresh behavior
- validation expectations

## Scope
This spec covers the Databricks objects needed to power `DS-02 Governance Case Resolution` and the supporting discovery evidence from `DS-01`.

It does not define the Salesforce UX itself. It defines the Databricks outputs that UX must consume.

## Current implementation baseline
The repo currently includes a Databricks gold export path for:
- `pulse360_s4.gold.account_export_base`
- `pulse360_s4.gold.account_core_export`
- `pulse360_s4.intelligence.datacloud_export_accounts`

The stewardship slice requires additional intelligence outputs that are referenced in product and contract docs but are not yet represented as implementation-ready SQL artifacts in this repo:
- `pulse360_s4.intelligence.duplicate_candidate_pairs`
- `pulse360_s4.intelligence.firmographic_enrichment`
- `pulse360_s4.intelligence.entity_hierarchy_graph`
- `pulse360_s4.intelligence.governance_ops_metrics`
- `pulse360_s4.intelligence.stewardship_case_payload`

## Design intent
Databricks is the enterprise stewardship intelligence layer.

It should:
- assemble evidence from CRM and other trusted sources
- compute match confidence, attribute trust, and hierarchy implications
- package that evidence into replay-safe, lineage-backed outputs
- stop short of making the final stewardship decision

## Output set

### 1. `pulse360_s4.intelligence.duplicate_candidate_pairs`
Purpose:
- record one row per candidate duplicate pair with decision-grade pair evidence

Grain:
- one row per `candidate_pair_id`

Required columns:
| Column | Type | Description |
| --- | --- | --- |
| `candidate_pair_id` | string | Stable deterministic pair key |
| `left_account_id` | string | CRM-safe left `Account.Id` |
| `right_account_id` | string | CRM-safe right `Account.Id` |
| `left_account_name` | string | Left account display name |
| `right_account_name` | string | Right account display name |
| `duplicate_confidence_score` | decimal(5,2) | Match confidence from `0-100` |
| `confidence_band` | string | `high`, `medium`, or `low` |
| `top_match_features` | string | JSON array of top feature keys and weights |
| `feature_explanations` | string | JSON array of steward-readable explanation snippets |
| `recommended_action` | string | `approve_merge`, `review`, or `reject_match` |
| `review_required_flag` | boolean | Manual review requirement |
| `left_parent_account_id` | string | Left-side current parent |
| `right_parent_account_id` | string | Right-side current parent |
| `source_snapshot_id` | string | Replay-safe source snapshot key |
| `run_id` | string | Pipeline run key |
| `run_ts` | timestamp | Pipeline run timestamp |
| `model_version` | string | Duplicate model/rules version |

Derivation rules:
- `candidate_pair_id` should be deterministic and order-safe, for example based on sorted account IDs.
- `left_account_id` and `right_account_id` must always be native Salesforce `Account.Id` values carried from CRM ingestion.
- `confidence_band` should be derived from explicit thresholds documented in the blueprint, not inferred ad hoc in UI code.
- `top_match_features` and `feature_explanations` should be serialized in a UI-safe format that can be passed through Data Cloud without reconstruction.

Primary source inputs:
- `pulse360_s4.silver_salesforce.crm_account`
- future identity/matching feature set built from standardized account attributes

### 2. `pulse360_s4.intelligence.firmographic_enrichment`
Purpose:
- record attribute-level trust evidence for steward review

Grain:
- one row per `candidate_pair_id` + `account_id` + `attribute_name`

Required columns:
| Column | Type | Description |
| --- | --- | --- |
| `candidate_pair_id` | string | Join key back to duplicate pair |
| `account_id` | string | CRM-safe `Account.Id` |
| `attribute_name` | string | Compared field name |
| `attribute_value` | string | Observed or proposed field value |
| `validity_score` | decimal(5,2) | Trust score from `0-100` |
| `review_required_flag` | boolean | Whether this field requires review |
| `source_name` | string | Evidence source name |
| `source_priority` | int | Source ranking if available |
| `explanation_text` | string | Steward-readable field trust explanation |
| `run_id` | string | Pipeline run key |
| `run_ts` | timestamp | Pipeline run timestamp |
| `model_version` | string | Enrichment/validity logic version |

First-slice attribute scope:
- `legal_name`
- `website`
- `domain`
- `billing_city`
- `billing_state`
- `billing_country`
- `parent_account_id`
- `duns_number`

Derivation rules:
- only attributes that materially influence merge confidence or downstream commercial truth should be included in the first slice
- `explanation_text` must be derived in Databricks or precomputed upstream, not improvised in Salesforce

Primary source inputs:
- `pulse360_s4.silver_salesforce.crm_account`
- approved third-party or enterprise reference data when available

### 3. `pulse360_s4.intelligence.entity_hierarchy_graph`
Purpose:
- expose hierarchy structure and hierarchy conflict evidence that affects stewardship decisions

Grain:
- one row per `candidate_pair_id` + impacted hierarchy relationship

Required columns:
| Column | Type | Description |
| --- | --- | --- |
| `candidate_pair_id` | string | Join key back to duplicate pair |
| `left_account_id` | string | Left account in the reviewed pair |
| `right_account_id` | string | Right account in the reviewed pair |
| `left_parent_account_id` | string | Left-side current parent |
| `right_parent_account_id` | string | Right-side current parent |
| `hierarchy_conflict_flag` | boolean | Indicates inconsistent hierarchy interpretation |
| `hierarchy_impact_summary` | string | Plain-language merge consequence |
| `affected_group_count` | int | Number of related nodes affected |
| `hierarchy_depth` | int | Available hierarchy depth context |
| `run_id` | string | Pipeline run key |
| `run_ts` | timestamp | Pipeline run timestamp |
| `model_version` | string | Hierarchy logic version |

Derivation rules:
- the first slice may use shallow hierarchy implication logic
- hierarchy implication must still be explicit enough to tell the steward whether the decision affects group structure or rollup meaning

Primary source inputs:
- `pulse360_s4.silver_salesforce.crm_account_hierarchy_edge`
- any stitched hierarchy outputs available in Databricks

### 4. `pulse360_s4.intelligence.governance_ops_metrics`
Purpose:
- track stewardship operational value and trend evidence

Grain:
- one row per metric snapshot and reporting period

Required columns:
| Column | Type | Description |
| --- | --- | --- |
| `metric_date` | date | Reporting date |
| `metric_name` | string | Metric identifier |
| `metric_value` | decimal(18,2) | Metric value |
| `governance_case_id` | string | Optional case linkage |
| `decision_status` | string | Optional decision context |
| `run_id` | string | Pipeline run key |
| `run_ts` | timestamp | Pipeline run timestamp |

Minimum first-slice metrics:
- `median_resolution_time_hours`
- `governance_backlog_count`
- `steward_decisions_per_day`
- `deferred_case_rate`
- `reversed_merge_rate`

Primary source inputs:
- governance case outcomes from Salesforce/Data Cloud feedback path
- Databricks run metadata

### 5. `pulse360_s4.intelligence.stewardship_case_payload`
Purpose:
- provide one denormalized, UI-facing Databricks object that packages the first-slice evidence for downstream consumption

Grain:
- one row per `candidate_pair_id`

Required columns:
| Column | Type | Description |
| --- | --- | --- |
| `candidate_pair_id` | string | Stewardship case key |
| `left_account_id` | string | CRM-safe left account |
| `right_account_id` | string | CRM-safe right account |
| `duplicate_confidence_score` | decimal(5,2) | Pair confidence |
| `confidence_band` | string | Human-usable confidence label |
| `top_match_features` | string | JSON evidence payload |
| `feature_explanations` | string | JSON explanation payload |
| `attribute_validity_payload` | string | JSON array of compared fields and trust evidence |
| `hierarchy_conflict_flag` | boolean | Hierarchy inconsistency indicator |
| `hierarchy_impact_summary` | string | Hierarchy consequence text |
| `recommended_action` | string | System recommendation |
| `review_required_flag` | boolean | Manual review indicator |
| `source_snapshot_id` | string | Replay-safe source snapshot key |
| `run_id` | string | Pipeline run key |
| `run_ts` | timestamp | Pipeline run timestamp |
| `model_version` | string | Composite payload version |

Purpose of the denormalized object:
- reduce Salesforce and Data Cloud reconstruction logic
- make stewardship UX and validation simpler
- provide one acceptance target for the first slice

## Join and keying rules
1. Every stewardship output must use CRM-safe account identifiers, not Databricks-only synthetic entity IDs, as the operational join key.
2. `candidate_pair_id` must be stable across reruns when the underlying pair is unchanged.
3. `candidate_pair_id` is the join key across duplicate, enrichment, hierarchy, and UI payload outputs.
4. `run_id`, `run_ts`, and `model_version` are mandatory on every stewardship output.
5. If a source does not provide deterministic provenance, the record should be excluded or explicitly flagged for reduced trust.

## Refresh behavior
- prototype mode: daily batch refresh
- demo expectation: outputs are precomputed and queryable without notebook edits
- governance feedback metrics may lag the evidence payload by one batch cycle in the first slice

## Suggested SQL package expansion
Recommended future SQL artifacts:

1. `sql/databricks/gold/05_duplicate_candidate_pairs.sql`
2. `sql/databricks/gold/06_firmographic_enrichment.sql`
3. `sql/databricks/gold/07_entity_hierarchy_graph.sql`
4. `sql/databricks/gold/08_governance_ops_metrics.sql`
5. `sql/databricks/gold/09_stewardship_case_payload.sql`

Recommended run order:

1. `00_create_schemas.sql`
2. `05_duplicate_candidate_pairs.sql`
3. `06_firmographic_enrichment.sql`
4. `07_entity_hierarchy_graph.sql`
5. `08_governance_ops_metrics.sql`
6. `09_stewardship_case_payload.sql`
7. `10_account_export_base.sql`
8. `20_account_core_export.sql`
9. `30_datacloud_export_accounts.sql`

## Validation expectations
The first implementation pass should add validator coverage for:
- presence of all stewardship SQL artifacts
- presence of `crm_account_id`-safe fields in stewardship outputs
- presence of `candidate_pair_id`, `run_id`, `run_ts`, and `model_version`
- presence of explanation payload fields
- presence of hierarchy impact fields

## Acceptance test for Databricks outputs
The Databricks stewardship output layer is ready when:
1. one candidate pair can be traced from CRM-safe source account rows to pair evidence, field trust evidence, and hierarchy implication evidence
2. a single denormalized payload exists for downstream stewardship UX consumption
3. replay metadata and provenance are visible for every evidence object
4. outputs support the steward workflow without requiring Salesforce to derive or guess the evidence logic

## Related artifacts
- `docs/contracts/pulse360-stewardship-slice-contract.md`
- `docs/contracts/databricks-to-datacloud-contract.md`
- `docs/contracts/datacloud-to-salesforce-agentforce-contract.md`
- `docs/readout/pulse360-product-slice-definition.md`
