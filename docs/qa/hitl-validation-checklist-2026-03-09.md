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

