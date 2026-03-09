# HITL Validation Checklist (2026-03-09)

Purpose: provide explicit human-in-the-loop validation controls and ready-to-paste milestone comments for Pulse360 milestones A-E.

## HITL Comment Drafts for Milestones A-E
Use this exact pattern in Linear milestone comments:
- `HITL-Validated: Milestone A, 2026-03-09, Reviewer Name`
- `HITL-Validated: Milestone B, 2026-03-09, Reviewer Name`
- `HITL-Validated: Milestone C, 2026-03-09, Reviewer Name`
- `HITL-Validated: Milestone D, 2026-03-09, Reviewer Name`
- `HITL-Validated: Milestone E, 2026-03-09, Reviewer Name`

## Milestone-Level HITL Controls
1. Confirm all linked artifacts open and map to milestone DoD claims.
2. Confirm latest validator runs are green and references are current-dated.
3. Confirm one reviewer name is explicitly recorded in the milestone comment.
4. Confirm no unresolved blocker issues remain in the milestone scope.

## Milestone A Validation Steps (Environment and Data Foundations)
1. Verify EPF stage artifacts are present and readable:
- `docs/epf/stage-1.1-business-context-framing.md`
- `docs/epf/stage-1.2-enterprise-constraint-mapping.md`
- `docs/epf/stage-1.3-1.4-platform-landscape-and-option-assessment.md`
- `docs/epf/stage-1.5-decision-capture-and-scope-commitment.md`
2. Verify baseline setup/security docs are current:
- `docs/setup/salesforce-databricks-mcp-setup.md`
- `docs/security/mcp-security-assessment.md`
- `docs/epf/control-center.md`
3. Confirm Milestone A issues are `Done` in Linear (`DAN-48`, `DAN-49`, `DAN-50`, `DAN-51`, `DAN-52`, `DAN-53`, `DAN-74`, `DAN-75`, `DAN-76`, `DAN-77`).
4. Post Linear milestone comment:
- `HITL-Validated: Milestone A, 2026-03-09, Reviewer Name`

## Milestone B Validation Steps (Databricks Intelligence Layer)
1. Run and confirm DS-01/DS-02 validator pass:
- `./scripts/validate-duplicate-detection-runtime.sh`
- `./scripts/validate-firmographic-enrichment-runtime.sh`
- `./scripts/validate-governance-ops-metrics-runtime.sh`
- `./scripts/validate-dan-58-governance-dashboard-pack.sh`
2. Verify governance dashboard evidence is current:
- `docs/evidence/dan-58-governance-dashboard-latest.md`
3. Confirm Milestone B issues are `Done` in Linear (`DAN-54`, `DAN-55`, `DAN-56`, `DAN-57`, `DAN-58`).
4. Post Linear milestone comment:
- `HITL-Validated: Milestone B, 2026-03-09, Reviewer Name`

## Milestone C Validation Steps (Data Cloud Identity and Activation)
1. Run and confirm stream/runtime validators:
- `./scripts/run-datacloud-prerun-import.sh`
- `./scripts/validate-data-cloud-stream-runtime.sh`
- `./scripts/validate-dan-59-stream-pack.sh`
2. Verify stream evidence and mapping artifacts:
- `docs/evidence/dan-59-data-cloud-stream-health-latest.md`
- `docs/evidence/datacloud-prerun-import-latest.md`
- `config/data-cloud/stream-manifest.yaml`
- `config/data-cloud/activation-field-mapping.csv`
3. Confirm Milestone C issues are `Done` in Linear (`DAN-59`, `DAN-60`, `DAN-61`, `DAN-62`).
4. Post Linear milestone comment:
- `HITL-Validated: Milestone C, 2026-03-09, Reviewer Name`

## Milestone D Salesforce UI Proof Checklist
Required because payload/runtime proofs alone are insufficient for UI placement confirmation.

1. Account 360 LWC placement proof
- Capture Salesforce Lightning page screenshot showing Account 360 component placement on Account record page.
- Capture org/page assignment view screenshot (Lightning App Builder activation panel).
- Record timestamp and org alias used during capture.

2. Governance side-by-side UI proof
- Capture screenshot of governance comparison UI showing duplicate confidence and validity columns.
- Confirm displayed values correspond to latest runtime sample (`run_id`, `run_timestamp`).

3. Cross-sell quick-create UI proof
- Capture screenshot of quick-create action visible on account context.
- Capture screenshot or audit log entry confirming opportunity creation action trigger path.

4. Linkage and storage requirements
- Attach Salesforce UI screenshots to the relevant Linear issue(s) and Milestone D comment thread.
- Mirror the same proof links in Notion milestone validation section.
- Add a repo evidence pointer referencing where UI proof links are recorded (do not store credential-sensitive screenshots in repo).

## Execution Notes
- If any Milestone D UI proof item is missing, keep milestone status as HITL pending.
- If proof reveals placement/configuration mismatch, re-open affected D issues before milestone sign-off.

## HITL Validation Log (Recorded)
- `HITL-Validated: Milestone A, 2026-03-09, Daniel Nortje` -> PASS
- `HITL-Validated: Milestone B, 2026-03-09, Daniel Nortje` -> FAIL (open visual-completeness gap)
- `HITL-Validated: Milestone C, 2026-03-09, Daniel Nortje` -> PASS
- `HITL-Validated: Milestone D, 2026-03-09, Daniel Nortje` -> FAIL (Salesforce deployment gap)
- `HITL-Validated: Milestone E, 2026-03-09, Daniel Nortje` -> PASS
