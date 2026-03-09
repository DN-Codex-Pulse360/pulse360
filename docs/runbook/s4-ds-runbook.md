# S4 Demo Runbook (DS-01 / DS-02 / DS-03)

## Runtime Target
All scenarios complete in 15 minutes or less.
Primary presenter script: `docs/runbook/ds-01-02-03-walkthrough-script.md`
E2E QA timing runner: `scripts/run-e2e-qa-timing.sh`

## DS-01 Fragmentation Discovery
1. Salesforce before-state: fragmented account records.
2. Databricks: duplicate and enrichment evidence.
3. Execute duplicate candidate build and runtime validation:
- `scripts/build-duplicate-candidate-pairs.sh`
- `scripts/validate-duplicate-detection-runtime.sh`
4. Data Cloud: unified profile and hierarchy context.
5. Agentforce: health scan API response.
6. Agentforce Health Scan runtime evidence:
- `scripts/validate-agentforce-health-scan-runtime.sh`

Expected proof:
- Duplicate metrics visible.
- `pulse360_s4.intelligence.duplicate_candidate_pairs` has non-zero rows with `duplicate_confidence_score` in `0-100`.
- Duplicate rows include run metadata (`run_id`, `run_timestamp`, `model_version`).
- Validity scores shown.
- AI impact linkage shown.
- Agentforce action response includes duplicate evidence, cross-sell estimate, health score, and explicit non-blocking failure-mode metadata.

## DS-02 Governance Case Resolution
1. Databricks duplicate candidate evidence.
2. Build and validate firmographic enrichment evidence:
- `scripts/build-firmographic-enrichment.sh`
- `scripts/validate-firmographic-enrichment-runtime.sh`
3. Build and validate native governance metrics:
- `scripts/build-governance-ops-metrics.sh`
- `scripts/validate-governance-ops-metrics-runtime.sh`
4. Salesforce governance case pre-enriched.
5. Data Cloud identity confidence panel.
6. Human-approved merge with audit trail.
7. Databricks governance trend panel.
8. Governance side-by-side payload validation:
- `scripts/validate-governance-case-runtime.sh`

Expected proof:
- Merge decision backed by confidence/validity.
- `pulse360_s4.intelligence.firmographic_enrichment` includes legal/profile attributes and `validity_score`.
- Low-confidence enrichment rows (`validity_score < 90`) are flagged with `review_flag = true`.
- Governance comparison dataset (`firmographic_candidate_comparisons`) is queryable for side-by-side candidate review.
- Governance side-by-side payload contract is satisfied (`salesforce_governance_case_lwc.schema.json` + runtime join checks).
- `pulse360_s4.intelligence.governance_ops_metrics` includes native DS-02 metrics (`cases_resolved`, `avg_resolution_minutes`, `backlog_open`, `quality_score`).
- Audit metadata captured.

## DS-03 Account 360 Moment
1. Salesforce before-state BU-limited account view.
2. Databricks hierarchy stitching evidence.
3. Data Cloud group rollup and insights.
4. Agentforce cross-sell action in Salesforce (create opportunity).
5. Data Cloud insights recompute and re-activation in session.
6. Account 360 hierarchy payload runtime validation:
- `scripts/validate-account360-lwc-runtime.sh`
7. Cross-sell banner and quick-create runtime validation:
- `scripts/validate-cross-sell-quick-create-runtime.sh`

Expected proof:
- Last synced timestamp visible.
- Opportunity creation from live insights.
- Competitor risk signal visible in Account 360 context.
- Recompute occurs from `opportunity_created` trigger within session target window (`<= 5` minutes).
- Account 360 hierarchy payload includes live hierarchy, rollup, propensity, coverage gap, and degraded-mode message handling.
- Cross-sell banner state is driven by live propensity/coverage fields, quick-create keeps account context, and linkage uses Data Cloud group profile key.
