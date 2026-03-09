# S4 Demo Runbook (DS-01 / DS-02 / DS-03)

## Runtime Target
All scenarios complete in 15 minutes or less.

## DS-01 Fragmentation Discovery
1. Salesforce before-state: fragmented account records.
2. Databricks: duplicate and enrichment evidence.
3. Execute duplicate candidate build and runtime validation:
- `scripts/build-duplicate-candidate-pairs.sh`
- `scripts/validate-duplicate-detection-runtime.sh`
4. Data Cloud: unified profile and hierarchy context.
5. Agentforce: health scan API response.

Expected proof:
- Duplicate metrics visible.
- `pulse360_s4.intelligence.duplicate_candidate_pairs` has non-zero rows with `duplicate_confidence_score` in `0-100`.
- Duplicate rows include run metadata (`run_id`, `run_timestamp`, `model_version`).
- Validity scores shown.
- AI impact linkage shown.

## DS-02 Governance Case Resolution
1. Databricks duplicate candidate evidence.
2. Build and validate firmographic enrichment evidence:
- `scripts/build-firmographic-enrichment.sh`
- `scripts/validate-firmographic-enrichment-runtime.sh`
3. Salesforce governance case pre-enriched.
4. Data Cloud identity confidence panel.
5. Human-approved merge with audit trail.
6. Databricks governance trend panel.

Expected proof:
- Merge decision backed by confidence/validity.
- `pulse360_s4.intelligence.firmographic_enrichment` includes legal/profile attributes and `validity_score`.
- Low-confidence enrichment rows (`validity_score < 90`) are flagged with `review_flag = true`.
- Governance comparison dataset (`firmographic_candidate_comparisons`) is queryable for side-by-side candidate review.
- Audit metadata captured.

## DS-03 Account 360 Moment
1. Salesforce before-state BU-limited account view.
2. Databricks hierarchy stitching evidence.
3. Data Cloud group rollup and insights.
4. Agentforce cross-sell action in Salesforce (create opportunity).
5. Data Cloud insights recompute and re-activation in session.

Expected proof:
- Last synced timestamp visible.
- Opportunity creation from live insights.
- Competitor risk signal visible in Account 360 context.
- Recompute occurs from `opportunity_created` trigger within session target window (`<= 5` minutes).
