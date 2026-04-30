# Pulse360 Codex Agent Decision Framework

## Purpose

This framework defines how Codex should make implementation decisions in the
Pulse360 repo for Salesforce, Databricks, Data Cloud, and cross-system project
operations.

It exists to reduce avoidable drift when the technical path is valid but the
product shape is still wrong.

## Decision Stack

Codex should resolve decisions in this order:

1. Solution brief and proposition HTML
2. UX surface specification
3. UX-derived technical design
4. Surface-driven contract requirements
5. Repo operating rules in `AGENTS.md`
6. Validators, package-workspace builders, and runbooks

If two layers conflict, the higher layer wins unless a repo rule explicitly
blocks the change for safety.

## Done-State Vocabulary

Every meaningful change should be thought of in three states:

- `technical_valid`
  - metadata compiles
  - validators pass
  - deploy succeeds in a non-production org
- `product_aligned`
  - the change matches the intended user workflow and surface architecture
  - the UI still reflects the brief and UX specification
- `architecturally_final`
  - the implementation is not just a transition step
  - the page, service, and contract decomposition reflect the intended long-term shape

A change can be `technical_valid` without being `product_aligned`.
A change can be `product_aligned` without being `architecturally_final`.

Codex should say which state a change has reached.

## Salesforce Decision Rules

### Page Type

- Use a `lightning__AppPage` for altitude-2 portfolio or leadership workflows.
- Use a `lightning__RecordPage` for altitude-3 account-linked execution workflows.
- Do not collapse altitude-2 and altitude-3 into one page just because they share data.

### Composition

- Prefer direct FlexiPage composition of multiple focused modules.
- Treat a wrapper LWC that hosts several large business modules as transitional only.
- If a wrapper is used temporarily, document it as transitional in status notes and acceptance evidence.

### Module Size

A Salesforce module is in the right size range when it:

- has one primary job
- can be placed independently in App Builder
- can be hidden or shown by context
- consumes a clear subset of the surface contract

Modules that combine summary, evidence, actions, analytics, and navigation into
one shell should be split.

### Admin Configuration

Expose meaningful App Builder properties when:

- a section may be optional
- the same component could be used on different pages
- the page needs role- or context-based variation

Avoid boolean-only configuration when the real need is page composition.

### UX Guardrails

For Salesforce UI work, Codex should fail the design mentally if:

- the page is dominated by one large custom shell
- navigation does not preserve context between portfolio, account, and trust surfaces
- freshness, confidence, and provenance are hidden or dropped
- the UI promises actions but only provides narrative
- analytics or chronology are missing where the surface brief expects them

## Databricks Decision Rules

- Keep Databricks responsible for intelligence generation, evidence, and deep comparative logic.
- Keep Salesforce responsible for execution, stewardship, and user-triggered action.
- Do not flatten altitude-2 portfolio context into static CRM copy-down fields if drill-through depth is needed.
- Treat export and realization contracts as product interfaces, not just data-engineering outputs.

Any Databricks change that affects user-visible Salesforce behavior should ship
with:

- contract evidence
- realistic fixtures or samples
- run identifiers or version identifiers where applicable
- validation that provenance, freshness, and CRM-safe bindings remain intact

## Cross-System Decision Rules

### When MCP Is Healthy

Codex should update:

- repo artifact
- Linear or project-tracking artifact
- deploy or evidence artifact when relevant

### When MCP Is Unhealthy

Codex should:

1. capture the intended status update in repo evidence or a working note
2. report the connector failure clearly
3. avoid pretending the project tracker was updated
4. continue repo-safe work where possible

This avoids losing operational truth because one connector is unavailable.

## Required Build Sequence

### Salesforce surface change

1. confirm target surface and altitude
2. confirm record-page versus app-page placement
3. update source metadata and LWC/Apex
4. update or add validators
5. validate locally
6. validate deploy
7. deploy to approved non-production org
8. capture whether the result is transitional or final

### Databricks-to-Salesforce change

1. update SQL/contracts/samples
2. validate export and contract drift
3. confirm Salesforce realization target fields
4. validate the CRM-facing surface behavior
5. document org-locked Data Cloud steps separately when needed

## Anti-Patterns

Codex should avoid these by default:

- one large LWC pretending to be a modular Lightning page
- narrative text as the stable integration boundary
- portfolio analytics reduced to a static Account page summary
- repo updates without tracker or evidence follow-through
- tracker updates without matching repo artifacts
- org changes that are not traceable back to source

## Operator Practice

Before cross-system work, run:

- `./scripts/check-codex-operator-health.sh`

When hosted MCP auth is stale, use:

- `./scripts/repair-hosted-mcp-auth.sh linear`
- `./scripts/repair-hosted-mcp-auth.sh notion`

If CLI auth is healthy but plugin tools still fail through the Codex app bridge,
restart the Codex desktop app to refresh the hosted connector session.
