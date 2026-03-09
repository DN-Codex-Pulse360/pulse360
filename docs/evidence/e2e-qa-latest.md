# E2E QA Timing Evidence (DAN-68)

- Run ID reference: `run_20260309_042146`
- Start (UTC): `2026-03-09T06:07:35Z`
- End (UTC): `2026-03-09T06:09:06Z`
- Total runtime (seconds): `91`
- Runtime target: `<= 900` seconds (`<= 15 minutes`)

## Scenario Timing
- DS-01 validation duration: `49` seconds
- DS-02 validation duration: `27` seconds
- DS-03 validation duration: `11` seconds

## DS-01 Evidence Snapshot
```
response_error_code=STALE_DATA_WINDOW_EXCEEDED
response_retry_disposition=manual_retry_available
response_ai_impact_summary=Duplicate evidence supports merge review; cross-sell estimate 87.0 with health score 92.4.
response_last_synced_timestamp=2026-03-09T04:22:59.151Z
response_run_id=run_20260309_042146
response_run_timestamp=2026-03-09T04:22:59.151Z
response_model_version=dbx-dc-export-v1.0.0
[["sf_acc_1001","2","92","90-94","87.0","92.4","25.0","2026-03-09T04:22:59.151Z","degraded","STALE_DATA_WINDOW_EXCEEDED","Live insights are delayed. Showing latest available snapshot."]]
```

## DS-02 Evidence Snapshot
```
[PASS] Review-flag distribution query succeeded
[["true","1","86.8"],["false","2","94.0"]]
[PASS] Table exists: pulse360_s4.intelligence.governance_ops_metrics
[PASS] Governance quality checks passed (rows=1)
[PASS] Metadata checks passed
[PASS] Latest governance metrics query succeeded
[["run_20260309_042146","2026-03-09T04:22:50.296Z","3","1","2","34.0","91.78","33.33"]]
[PASS] Governance side-by-side runtime checks passed (pairs=3)
[PASS] Governance sample query succeeded
[["sf_acc_1001","sf_acc_2001","92","94.0","86.8","92.8","run_20260309_042146","2026-03-09T04:22:17.318Z"],["sf_acc_1002","sf_acc_2001","92","94.0","86.8","92.8","run_20260309_042146","2026-03-09T04:22:17.318Z"],["sf_acc_1001","sf_acc_1002","92","94.0","94.0","92.8","run_20260309_042146","2026-03-09T04:22:17.318Z"]]
```

## DS-03 Evidence Snapshot
```
[PASS] Account 360 live-field checks passed (rows=3)
[PASS] Degraded-mode condition evaluated (degraded_rows=3, total_rows=3)
[PASS] Account 360 sample query succeeded
[["ucp_sf_acc_1001","sf_acc_1001","Pacific Holdings Group","1500000.0","87.0","false","2026-03-09T04:22:59.151Z","degraded","Data is delayed. Showing latest available snapshot.","run_20260309_042146","2026-03-09T04:22:59.151Z","dbx-dc-export-v1.0.0"],["ucp_sf_acc_1002","sf_acc_1002","Pacific Capital Singapore","1500000.0","87.0","false","2026-03-09T04:22:59.151Z","degraded","Data is delayed. Showing latest available snapshot.","run_20260309_042146","2026-03-09T04:22:59.151Z","dbx-dc-export-v1.0.0"],["ucp_sf_acc_2001","sf_acc_2001","Pacific Capital Securities","1500000.0","83.4","true","2026-03-09T04:22:59.151Z","degraded","Data is delayed. Showing latest available snapshot.","run_20260309_042146","2026-03-09T04:22:59.151Z","dbx-dc-export-v1.0.0"]]
[PASS] Cross-sell quick-create runtime source checks passed for sf_acc_1001
[PASS] Cross-sell quick-create sample query succeeded
[["sf_acc_1001","ucp_sf_acc_1001","87.0","false","1","2","show_recommendation","datacloud_group_profile_link","opportunity_created","5","2026-03-09T04:22:59.151Z","run_20260309_042146","2026-03-09T04:22:59.151Z","dbx-dc-export-v1.0.0"]]
```

## Defect Log
- None observed in automated runtime checks

## Coverage Summary
- Lineage/confidence/validity/last-synced evidence validated via runtime scripts and contract checks.
- Walkthrough timing budget pack validated.
