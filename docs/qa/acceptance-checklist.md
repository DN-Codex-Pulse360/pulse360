# Acceptance Checklist

## Environment Tests
- [ ] OAuth flows verified for Salesforce, Databricks, GitHub, Linear, and Notion.
- [ ] Token rotation and revocation behavior validated.
- [ ] MCP connectivity checks pass for each configured server.

## Functional Tests
- [ ] DS-01 runs end-to-end without hardcoded metrics.
- [ ] `pulse360_s4.intelligence.duplicate_candidate_pairs` is populated with non-zero rows.
- [ ] DS-01 duplicate confidence scores are bounded `0-100` and include run metadata (`run_id`, `run_timestamp`, `model_version`).
- [ ] DS-02 runs end-to-end with governance audit trail.
- [ ] `pulse360_s4.intelligence.firmographic_enrichment` is populated with legal/profile attributes and `validity_score`.
- [ ] Low-confidence enrichment rows are flagged for review (`review_flag = true` when `validity_score < 90`).
- [ ] Candidate comparison evidence is queryable for governance (`firmographic_candidate_comparisons`).
- [ ] `pulse360_s4.intelligence.governance_ops_metrics` is populated with DS-02 metrics (`cases_resolved`, `avg_resolution_minutes`, `backlog_open`, `quality_score`).
- [ ] Data Cloud stream source table `pulse360_s4.intelligence.datacloud_export_accounts` is populated with required activation fields.
- [ ] Databricks stream ingestion metadata label and `last_synced_timestamp` are populated for Data Cloud visibility.
- [ ] DS-03 runs end-to-end with live hierarchy and cross-sell flow.
- [ ] Lineage is visible from source to enriched outputs.
- [ ] Data Cloud insights recompute within session where required.

## Non-Functional Tests
- [ ] Full demo runtime <= 15 minutes.
- [ ] Cold-run rehearsal passes with non-builder presenter.
- [ ] Fallback path documented and tested for each external dependency.
