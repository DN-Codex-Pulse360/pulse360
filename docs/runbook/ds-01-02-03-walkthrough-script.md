# DS-01/DS-02/DS-03 Walkthrough Script (DAN-67)

## Runtime Budget
- Total target runtime: `<= 15` minutes
- Enforced budget:
  - DS-01: `4` minutes
  - DS-02: `5` minutes
  - DS-03: `4` minutes
  - Buffer/Q&A: `2` minutes

## Global Presenter Setup (30-60 seconds)
1. Confirm active run reference: `run_20260309_042146`.
2. Confirm Databricks dashboard IDs to open:
   - Main: `01f11b56ed40102ea9232dfb2404fb1b`
   - Demo: `01f11b5709051df5a21ba10e55942421`
3. Keep one fallback tab ready with runtime validators:
   - `scripts/validate-duplicate-detection-runtime.sh`
   - `scripts/validate-governance-case-runtime.sh`
   - `scripts/validate-account360-lwc-runtime.sh`
   - `scripts/validate-agentforce-health-scan-runtime.sh`
   - `scripts/validate-cross-sell-quick-create-runtime.sh`

Fallback wording:
- "If UI visuals lag, I will switch to the validated runtime evidence outputs for the same run ID."

---

## DS-01 Fragmentation Discovery (4 minutes)
Persona narrative:
- "A relationship manager sees fragmented account records and needs confidence-backed consolidation guidance."

Layer transition flow:
1. Salesforce -> show fragmented account before-state.
2. Databricks -> show duplicate confidence evidence.
3. Data Cloud -> show unified profile context.
4. Agentforce -> run Account Health Scan action.

Views and evidence to open:
1. Databricks main dashboard (`01f11b56ed40102ea9232dfb2404fb1b`):
   - DS-01 confidence/fragmentation panel.
2. Runtime command evidence:
   - `scripts/validate-duplicate-detection-runtime.sh`
   - `scripts/validate-agentforce-health-scan-runtime.sh`

Expected evidence callouts:
- Duplicate confidence band includes `90-94`.
- Agentforce response card includes:
  - duplicate evidence
  - cross-sell estimate
  - health score
  - AI impact summary

Fallback wording:
- "The same DS-01 evidence is available via validated runtime output for `run_20260309_042146`."

---

## DS-02 Governance Case Resolution (5 minutes)
Persona narrative:
- "A governance analyst must decide merge approval with conflicting records and explicit audit traceability."

Layer transition flow:
1. Databricks -> show enrichment validity and governance metrics.
2. Salesforce governance case -> side-by-side candidate context.
3. Data Cloud confidence -> validate merge confidence.
4. Human decision -> explicit audit fields.

Views and evidence to open:
1. Databricks main dashboard (`01f11b56ed40102ea9232dfb2404fb1b`):
   - DS-02 governance metrics panel (`cases_resolved`, `avg_resolution_minutes`, `backlog_open`, `quality_score`).
2. Runtime command evidence:
   - `scripts/validate-firmographic-enrichment-runtime.sh`
   - `scripts/validate-governance-ops-metrics-runtime.sh`
   - `scripts/validate-governance-case-runtime.sh`

Expected evidence callouts:
- Pair confidence + left/right validity visible in side-by-side payload proof.
- Audit fields shown:
  - `decision_status`
  - `decision_actor`
  - `decision_timestamp`
  - `audit_event_id`

Fallback wording:
- "If the case UI is unavailable, the same side-by-side payload contract and runtime join evidence are shown in the validator output."

---

## DS-03 Account 360 Cross-Sell Moment (4 minutes)
Persona narrative:
- "An account executive wants unified hierarchy context and quick cross-sell action in one account workspace."

Layer transition flow:
1. Data Cloud -> load hierarchy, rollup, and propensity fields.
2. Salesforce Account 360 -> show context card + banner.
3. Quick-create opportunity in account context.
4. Trigger recompute path for refreshed insights.

Views and evidence to open:
1. Databricks demo dashboard (`01f11b5709051df5a21ba10e55942421`) for stable run context.
2. Runtime command evidence:
   - `scripts/validate-account360-lwc-runtime.sh`
   - `scripts/validate-cross-sell-quick-create-runtime.sh`

Expected evidence callouts:
- Account 360 payload includes:
  - `hierarchy_payload`
  - `group_revenue_rollup`
  - `cross_sell_propensity`
  - `coverage_gap_flag`
  - `last_synced_timestamp`
- Quick-create payload includes:
  - account-context create
  - `datacloud_group_profile_link`
  - `opportunity_created` trigger
  - `expected_recompute_window_minutes=5`

Fallback wording:
- "If real-time update is delayed, we show degraded-mode message and continue with latest validated snapshot without blocking the flow."

---

## Closing (2 minutes)
1. Summarize DS-01/02/03 outcomes in one line each.
2. Confirm all evidence references tie back to one run ID.
3. Capture open questions and map to post-demo remediation list.
