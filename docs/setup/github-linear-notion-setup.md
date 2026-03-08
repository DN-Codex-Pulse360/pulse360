# GitHub, Linear, and Notion Setup Guide

## GitHub
1. Confirm repository access:
   - `gh repo view DN-Codex-Pulse360/pulse360 --json name,url,defaultBranchRef`
2. Ensure default branch is `main`.
3. Configure branch protection and required checks (manual/UI or `gh api`).
4. Ensure CODEOWNERS and CI workflow are active.

## Linear
1. Project: Pulse360.
2. Milestones A-E created.
3. Issue labels required: `EPF`, `Gate-Criteria`, `Assumption`, `Security-Gate`, `S4-DS`.
4. Issue descriptions must include:
   - EPF stage
   - Gate mapping
   - Acceptance criteria

## Notion
1. Parent page: Pulse360.
2. Hub page: Pulse360 S4 Prototype - EPF Control Center.
3. Mandatory subpages:
   - 01 Business Context and Constraints
   - 02 Architecture and Integration Contracts
   - 03 Setup Guides
   - 04 Runbook
   - 05 User Guide
   - 06 Decision Log and ADRs
   - 07 Security and Compliance
4. Closure rule: each closed issue updates at least one Notion page.
