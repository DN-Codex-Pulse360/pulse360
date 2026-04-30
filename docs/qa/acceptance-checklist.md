# Acceptance Checklist

This checklist is the technical and operational gate.

Use it together with:
- [persona-business-acceptance-criteria.md](/Users/danielnortje/Documents/Pulse360/docs/qa/persona-business-acceptance-criteria.md)
- [seller-planner-journey-sense-check.md](/Users/danielnortje/Documents/Pulse360/docs/qa/seller-planner-journey-sense-check.md)
- [seller-external-benchmark-and-design-gap-analysis-2026-04-14.md](/Users/danielnortje/Documents/Pulse360/docs/qa/seller-external-benchmark-and-design-gap-analysis-2026-04-14.md)
- [seller-experience-build-roadmap-2026-04-14.md](/Users/danielnortje/Documents/Pulse360/docs/planning/seller-experience-build-roadmap-2026-04-14.md)
- [pulse360-research-led-ux-realignment-program-2026-04-19.md](/Users/danielnortje/Documents/Pulse360/docs/improvements/pulse360-research-led-ux-realignment-program-2026-04-19.md)
- [pulse360-html-proposition-to-ux-research-2026-04-19.md](/Users/danielnortje/Documents/Pulse360/docs/qa/pulse360-html-proposition-to-ux-research-2026-04-19.md)
- [pulse360-ux-surface-specification-2026-04-19.md](/Users/danielnortje/Documents/Pulse360/docs/improvements/pulse360-ux-surface-specification-2026-04-19.md)
- [pulse360-ux-validation-kit-2026-04-19.md](/Users/danielnortje/Documents/Pulse360/docs/qa/pulse360-ux-validation-kit-2026-04-19.md)

The checklist alone is not sufficient for business acceptance.

## Current Interpretation

This checklist remains the runtime and operational gate.

The UX-led package now acts as the design and experience gate.

A slice should not be treated as accepted unless both are true:

- the environment, metadata, contracts, and runtime behaviors are healthy
- the user-facing workflow is decision-ready under the UX validation kit

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
- [ ] Signal-routing workspace validates in source and target org, including tab exposure, permissioning, and preview-mode behavior when `Intent_Signal_Payload__c` is not yet populated.

## Persona Acceptance Gates
- [ ] Steward acceptance passes against the business criteria in [persona-business-acceptance-criteria.md](/Users/danielnortje/Documents/Pulse360/docs/qa/persona-business-acceptance-criteria.md).
- [ ] Seller acceptance passes against the business criteria in [persona-business-acceptance-criteria.md](/Users/danielnortje/Documents/Pulse360/docs/qa/persona-business-acceptance-criteria.md).
- [ ] Planner acceptance passes against the business criteria in [persona-business-acceptance-criteria.md](/Users/danielnortje/Documents/Pulse360/docs/qa/persona-business-acceptance-criteria.md).
- [ ] UX review evidence states the decision improved for each accepted persona, not only that the UI rendered.
- [ ] Acceptance notes explicitly distinguish technical proof from business-value proof.
- [ ] UX review uses the current target surfaces defined in [pulse360-ux-surface-specification-2026-04-19.md](/Users/danielnortje/Documents/Pulse360/docs/improvements/pulse360-ux-surface-specification-2026-04-19.md).
- [ ] Journey review covers planner, seller, signal-routing, and renewal/risk flows where those capabilities are claimed.
- [ ] Any gap between the designed UX and the implemented technical slice is recorded explicitly rather than treated as implied scope reduction.

## Non-Functional Tests
- [ ] Full demo runtime <= 15 minutes.
- [ ] Cold-run rehearsal passes with non-builder presenter.
- [ ] Fallback path documented and tested for each external dependency.
