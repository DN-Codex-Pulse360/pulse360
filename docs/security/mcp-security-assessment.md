# MCP Security Assessment

## Policy
No non-official MCP server can be used in build/test workflows until this assessment is PASS.

## Control Checklist
| Control | Result | Evidence | Owner | Notes |
| --- | --- | --- | --- | --- |
| Provenance and maintainer trust | Pending |  |  |  |
| License compliance | Pending |  |  |  |
| Dependency and SAST scan | Pending |  |  |  |
| Secret handling review | Pending |  |  |  |
| OAuth scope minimization | Pending |  |  |  |
| Network egress policy | Pending |  |  |  |
| Tool allowlist restrictions | Pending |  |  |  |

## Decision
- PASS: approved for controlled use
- FAIL: blocked pending remediation

## Remediation Log
| ID | Finding | Severity | Action | Owner | Due |
| --- | --- | --- | --- | --- | --- |

## Current Status Snapshot (2026-03-08)
| Integration | Provenance | Scope | Gate Status | Notes |
| --- | --- | --- | --- | --- |
| GitHub (`gh` CLI/API) | Official GitHub tooling | Repo/workflow scopes | PASS (baseline) | Branch protection + PR checks validated |
| Linear MCP | Official hosted MCP | Project/issue operations | PASS (baseline) | Milestone and issue management validated |
| Notion MCP | Official hosted MCP | Page/document operations | PASS (baseline) | Hub and docs pages created/updated |
| Salesforce (`sf` CLI) | Official Salesforce CLI | Org-scoped OAuth session | PASS (baseline) | `pulse360-dev` connected and queryable |
| Databricks CLI | Official Databricks CLI package | Workspace PAT scope | PASS (baseline) | Workspace + Unity Catalog access validated |
