# Acceptance Checklist

## Environment Tests
- [ ] OAuth flows verified for Salesforce, Databricks, GitHub, Linear, and Notion.
- [ ] Token rotation and revocation behavior validated.
- [ ] MCP connectivity checks pass for each configured server.

## Functional Tests
- [ ] DS-01 runs end-to-end without hardcoded metrics.
- [ ] `pulse360_s4.intelligence.duplicate_candidate_pairs` is populated with non-zero rows.
- [ ] DS-01 duplicate confidence scores are bounded `0-100` and include run metadata (`run_id`, `run_timestamp`, `model_version`).
- [ ] Agentforce Account Health Scan action payload is contract-backed (`contracts/agentforce_account_health_scan_action.schema.json`) with response-card evidence and non-blocking failure mode fields.
- [ ] DS-02 runs end-to-end with governance audit trail.
- [ ] `pulse360_s4.intelligence.firmographic_enrichment` is populated with legal/profile attributes and `validity_score`.
- [ ] Low-confidence enrichment rows are flagged for review (`review_flag = true` when `validity_score < 90`).
- [ ] Candidate comparison evidence is queryable for governance (`firmographic_candidate_comparisons`).
- [ ] Governance case side-by-side payload is contract-backed (`contracts/salesforce_governance_case_lwc.schema.json`) and includes pair confidence, both validity scores, and audit metadata.
- [ ] `pulse360_s4.intelligence.governance_ops_metrics` is populated with DS-02 metrics (`cases_resolved`, `avg_resolution_minutes`, `backlog_open`, `quality_score`).
- [ ] Data Cloud stream source table `pulse360_s4.intelligence.datacloud_export_accounts` is populated with required activation fields.
- [ ] Databricks stream ingestion metadata label and `last_synced_timestamp` are populated for Data Cloud visibility.
- [ ] DS-03 runs end-to-end with live hierarchy and cross-sell flow.
- [ ] Account 360 hierarchy payload is contract-backed (`contracts/salesforce_account360_hierarchy_lwc.schema.json`) and includes rollup, propensity, coverage gap, last sync, and degraded-mode message behavior.
- [ ] Cross-sell banner quick-create payload is contract-backed (`contracts/salesforce_cross_sell_quick_create_action.schema.json`) with account-context opportunity create, Data Cloud linkage, and `opportunity_created` refresh trigger semantics.
- [ ] Lineage is visible from source to enriched outputs.
- [ ] Data Cloud insights recompute within session where required.

## Non-Functional Tests
- [ ] Full demo runtime <= 15 minutes.
- [ ] Cold-run rehearsal passes with non-builder presenter.
- [ ] Fallback path documented and tested for each external dependency.
- [ ] E2E QA timing evidence is captured and published (`docs/evidence/e2e-qa-latest.md`) from `scripts/run-e2e-qa-timing.sh`.
- [ ] DAN-70 implementation estimate + resource plan is published (`docs/planning/dan-70-implementation-estimate-and-resource-plan.md`) and validated with `scripts/validate-implementation-estimate-runtime.sh`.
- [ ] Walkthrough script published with exact DS-01/02/03 transitions, panel references, and fallback wording (`docs/runbook/ds-01-02-03-walkthrough-script.md`).
- [ ] Rehearsal checklist and scoring rubric published (`docs/qa/walkthrough-rehearsal-rubric.md`).
