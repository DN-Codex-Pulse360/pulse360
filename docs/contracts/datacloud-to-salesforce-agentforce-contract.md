# Contract: Data Cloud -> Salesforce/Agentforce

## Purpose
Define fields and payload needed by Salesforce UX and Agentforce actions.

## Required Fields
| Field | Type | Description |
| --- | --- | --- |
| unified_profile_id | string | Data Cloud unified profile key |
| identity_confidence | number | Resolution confidence |
| hierarchy_payload | json | Group and subsidiary tree |
| group_revenue_rollup | number | Group-level revenue total |
| cross_sell_propensity | number | Calculated insight score |
| health_score | number | Account intelligence score |
| coverage_gap_flag | boolean | Subsidiary coverage gap indicator |
| competitor_risk_signal | number | Competitive pressure risk signal |
| primary_brand_name | string | Top brand affinity or ownership signal |
| active_product_count | integer | Active products linked to account |
| engagement_intensity_score | number | Composite engagement intensity score |
| open_opportunity_count | integer | Open opportunity count for account |
| last_engagement_timestamp | datetime | Most recent engagement touchpoint |
| last_synced_timestamp | datetime | Visible sync timestamp for UI |

## Rules
- Salesforce is execution surface, not source of truth.
- UI values must originate from Data Cloud or Databricks lineage-backed data.
- Activation contract is Account-centered but must include product, brand, and engagement rollups for B2B Customer 360 completeness.
- Activation mode is near real time (`<= 5` minute sync target) for DS-03 cross-sell workflows.
- Recompute triggers must include opportunity creation and governance merge approval events.

## Implemented Artifacts
- `contracts/datacloud_to_salesforce_agentforce.schema.json`
- `contracts/salesforce_governance_case_lwc.schema.json`
- `contracts/salesforce_account360_hierarchy_lwc.schema.json`
- `contracts/agentforce_account_health_scan_action.schema.json`
- `contracts/salesforce_cross_sell_quick_create_action.schema.json`
- `config/data-cloud/identity-resolution-rules.json`
- `config/data-cloud/calculated-insights.yaml`
- `config/data-cloud/activation-field-mapping.csv`
- `data/samples/datacloud_identity_resolution_sample.json`
- `data/samples/datacloud_activation_sample.json`
- `data/samples/salesforce_governance_case_lwc_sample.json`
- `data/samples/salesforce_account360_hierarchy_lwc_sample.json`
- `data/samples/agentforce_account_health_scan_action_sample.json`
- `data/samples/salesforce_cross_sell_quick_create_action_sample.json`
- `contracts/datacloud_account_core_canonical_v2.schema.json`
- `contracts/datacloud_product_brand_canonical_v2.schema.json`
- `contracts/datacloud_engagement_canonical_v2.schema.json`
- `scripts/validate-hierarchy-and-identity.sh`
- `scripts/validate-data-cloud-insights-config.sh`
- `scripts/validate-governance-case-config.sh`
- `scripts/validate-governance-case-runtime.sh`
- `scripts/validate-account360-lwc-config.sh`
- `scripts/validate-account360-lwc-runtime.sh`
- `scripts/validate-agentforce-health-scan-config.sh`
- `scripts/validate-agentforce-health-scan-runtime.sh`
- `scripts/validate-cross-sell-quick-create-config.sh`
- `scripts/validate-cross-sell-quick-create-runtime.sh`

## Governance Case Side-by-Side Payload (DAN-63)
The governance-case LWC payload contract is defined in:
- `contracts/salesforce_governance_case_lwc.schema.json`

Minimum live-sourced fields per candidate pair:
1. Pair confidence from Databricks duplicate output (`duplicate_confidence_score`).
2. Validity scores from Databricks enrichment output (`validity_score` for both sides).
3. Identity confidence from Data Cloud export (`identity_confidence`).
4. Run metadata (`run_id`, `run_timestamp`, `model_version`).
5. Human decision/audit metadata (`decision_status`, `decision_actor`, `decision_timestamp`, `audit_event_id`).

Sample payload:
- `data/samples/salesforce_governance_case_lwc_sample.json`

Validation:
- Static contract and documentation checks: `scripts/validate-governance-case-config.sh`
- Runtime source checks against Databricks tables: `scripts/validate-governance-case-runtime.sh`

## Account 360 Hierarchy LWC Payload (DAN-64)
The Account 360 hierarchy LWC payload contract is defined in:
- `contracts/salesforce_account360_hierarchy_lwc.schema.json`

Required live-sourced fields:
1. Hierarchy and rollup context from Data Cloud activation payload (`hierarchy_payload`, `group_revenue_rollup`).
2. Calculated insights for UI (`cross_sell_propensity`, `coverage_gap_flag`).
3. Sync freshness visibility (`last_synced_timestamp`).
4. Runtime metadata for traceability (`run_id`, `run_timestamp`, `model_version`).

Degraded mode behavior:
1. Compute `data_health_status` from freshness thresholds (for example, older than 30 minutes = `degraded`).
2. Provide `degraded_mode_message` for UI fallback wording when data is stale.
3. Preserve latest available snapshot values even when degraded mode is active.

Sample payload:
- `data/samples/salesforce_account360_hierarchy_lwc_sample.json`

Validation:
- Static contract/documentation checks: `scripts/validate-account360-lwc-config.sh`
- Runtime checks against Databricks export table: `scripts/validate-account360-lwc-runtime.sh`

## Agentforce Account Health Scan Action Payload (DAN-65)
The Agentforce action payload contract is defined in:
- `contracts/agentforce_account_health_scan_action.schema.json`

Required response-card evidence:
1. Duplicate evidence (`pair_count`, `max_confidence`, `confidence_band`).
2. Cross-sell estimate and health score from calculated insights.
3. Competitor risk signal and AI impact summary text.
4. API telemetry fields (`correlation_id`, `http_status`, `api_latency_ms`) for walkthrough evidence.

Failure mode handling:
1. Non-blocking degraded/failed status must still return a response card with latest snapshot context.
2. Explicit `error_code`, `user_message`, and `retry_disposition` must be present.
3. Walkthrough must show that action failure does not block user flow.

Sample payload:
- `data/samples/agentforce_account_health_scan_action_sample.json`

Validation:
- Static contract/documentation checks: `scripts/validate-agentforce-health-scan-config.sh`
- Runtime source checks and action evidence output: `scripts/validate-agentforce-health-scan-runtime.sh`

## Cross-Sell Banner and Quick Create Payload (DAN-66)
The cross-sell banner and quick-create payload contract is defined in:
- `contracts/salesforce_cross_sell_quick_create_action.schema.json`

Required banner fields:
1. `cross_sell_propensity` and `coverage_gap_flag` from Data Cloud calculated insights.
2. `open_opportunity_count` and `last_synced_timestamp` for context and freshness.
3. `banner_state` derived from propensity thresholds.

Quick-create context requirements:
1. Opportunity creation remains in account context (`context_account_id`).
2. Contact association uses Data Cloud group-profile linkage (`linkage_type=datacloud_group_profile_link`).
3. Payload includes opportunity basics (`name`, `stage_name`, `close_date`, `expected_value`).

Refresh trigger requirement:
1. Opportunity create event must map to `opportunity_created`.
2. Recompute window target remains `<=5` minutes.

Sample payload:
- `data/samples/salesforce_cross_sell_quick_create_action_sample.json`

Validation:
- Static contract/documentation checks: `scripts/validate-cross-sell-quick-create-config.sh`
- Runtime source checks and quick-create context proof: `scripts/validate-cross-sell-quick-create-runtime.sh`
