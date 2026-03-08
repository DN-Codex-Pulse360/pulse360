# MCP Security Assessment

## Policy
No non-official MCP server can be used in build/test workflows until this assessment is PASS.
Official integrations in the active baseline remain allowlisted with least-privilege scopes only.

## Control Checklist
| Control | Result | Evidence | Owner | Notes |
| --- | --- | --- | --- | --- |
| Provenance and maintainer trust | PASS | Official GitHub/Linear/Notion/Salesforce/Databricks tooling only | Platform owner | No unvetted third-party MCP server enabled |
| License compliance | PASS | Official vendor licenses; no custom server package added | Platform owner | Re-check if new MCP package/repo is introduced |
| Dependency and SAST scan | PASS | Official-hosted MCP + vendor CLIs; local scripts reviewed in repo | Platform owner | No untrusted runtime plugin loaded |
| Secret handling review | PASS | OAuth sessions (`gh`, hosted MCP), Salesforce org auth, Databricks PAT | Platform owner | No plaintext secrets committed in repo |
| OAuth scope minimization | PASS | Least-privilege baseline in setup guide | Platform owner | Scope expansion requires explicit review |
| Network egress policy | PASS | Egress limited to approved vendor endpoints for active integrations | Platform owner | Any new endpoint requires review update |
| Tool allowlist restrictions | PASS | Allowed integrations documented in setup baseline | Platform owner | Non-official MCP tools remain blocked by policy |

## Decision
- PASS: approved for controlled use
- FAIL: blocked pending remediation

Current decision: **PASS (baseline integrations only)** as of 2026-03-08.

## Remediation Log
| ID | Finding | Severity | Action | Owner | Due |
| --- | --- | --- | --- | --- | --- |
| R-001 | No executable gate check existed (policy only) | Medium | Added `scripts/mcp-security-gate.sh` validation logic and pass/fail exit status | Platform owner | 2026-03-08 |
| R-002 | Checklist entries were left pending | Medium | Completed control results with evidence and governance notes | Platform owner | 2026-03-08 |

## Current Status Snapshot (2026-03-08)
| Integration | Provenance | Scope | Gate Status | Notes |
| --- | --- | --- | --- | --- |
| GitHub (`gh` CLI/API) | Official GitHub tooling | Repo/workflow scopes | PASS (baseline) | Branch protection + PR checks validated |
| Linear MCP | Official hosted MCP | Project/issue operations | PASS (baseline) | Milestone and issue management validated |
| Notion MCP | Official hosted MCP | Page/document operations | PASS (baseline) | Hub and docs pages created/updated |
| Salesforce (`sf` CLI) | Official Salesforce CLI | Org-scoped OAuth session | PASS (baseline) | `pulse360-dev` connected and queryable |
| Databricks CLI | Official Databricks CLI package | Workspace PAT scope | PASS (baseline) | Workspace + Unity Catalog access validated |

## Non-official MCP Servers
- Default status: **BLOCKED**
- Required before use: provenance, license, dependency/SAST, secret handling, scope, egress, tool-boundary review
- Workflow: add candidate to remediation log, define owner/due date, block usage until all controls are PASS

## Evidence Links
- Setup and least-privilege baseline: `docs/setup/salesforce-databricks-mcp-setup.md`
- Gate script: `scripts/mcp-security-gate.sh`
