# Acceptance Checklist

## Environment Tests
- [ ] OAuth flows verified for Salesforce, Databricks, GitHub, Linear, and Notion.
- [ ] Token rotation and revocation behavior validated.
- [ ] MCP connectivity checks pass for each configured server.

## Functional Tests
- [ ] DS-01 runs end-to-end without hardcoded metrics.
- [ ] DS-02 runs end-to-end with governance audit trail.
- [ ] Salesforce governance case UI exists for `Data Operations` and renders Pulse360 stewardship evidence.
- [ ] Governance case supports `Approve`, `Reject`, and `Defer` with structured reason capture.
- [ ] Governance case validation rules enforce reason, surviving account, merged account, and distinct merge pair requirements outside the LWC path.
- [ ] Governance case shows evidence freshness timestamp and hierarchy impact summary.
- [ ] DS-03 runs end-to-end with live hierarchy and cross-sell flow.
- [ ] Lineage is visible from source to enriched outputs.
- [ ] Data Cloud insights recompute within session where required.
- [ ] Salesforce Account activation target fields exist and Data Cloud mapping is published.

## Non-Functional Tests
- [ ] Full demo runtime <= 15 minutes.
- [ ] Cold-run rehearsal passes with non-builder presenter.
- [ ] Fallback path documented and tested for each external dependency.
