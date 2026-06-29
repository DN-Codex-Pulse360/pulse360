# Pulse360 Proactive Signal Demo Harness

## Purpose

Define the controlled harness for the next Pulse360 demo slice:

> Pulse360 detects a source-system change before the seller does, proves why it
> matters, activates the signal into Salesforce, and guides the seller to a
> governed next action.

This harness converts the manufacturing demo target into GitHub/Linear-ready
work packets and keeps the Databricks, Data Cloud, Salesforce, and Agentforce
boundaries explicit.

## Demo Target

### Fictional Customer

`Meridian Industrial Systems`

An anonymized ASEAN industrial equipment and manufacturing group that sells:

- industrial equipment,
- maintenance contracts,
- spare parts,
- digital monitoring services,
- aftermarket services.

### Hero Account Group

`Northstar Foods Group`

The demo account group includes:

- one ASEAN parent company,
- six operating subsidiaries,
- fourteen factories and service sites,
- installed equipment in Malaysia, Thailand, and Indonesia,
- a distributor-mediated spare-parts relationship in Thailand,
- a missing maintenance contract in Indonesia,
- duplicate Salesforce records for two subsidiaries,
- a warranty expiry event that creates a timely sales motion.

## Target Story

Current-state seller experience:

- the seller opens a local Salesforce Account,
- the account appears smaller than the real group,
- service, warranty, product, distributor, and subsidiary evidence is scattered,
- the seller must manually infer whether a sales play exists.

Target-state Pulse360 experience:

1. A source-system change appears in ERP, service, warranty, distributor, or CRM
   data.
2. Databricks refreshes account intelligence and identifies a material signal.
3. Data Cloud activates the signal into Salesforce account context.
4. Salesforce surfaces the signal proactively.
5. Agentforce or the fallback action panel explains the signal and offers
   governed next actions.
6. The seller accepts, rejects, escalates, or routes the recommendation.
7. The outcome is captured as feedback for the next intelligence run.

## Primary Demo Signal

`maintenance_coverage_gap`

Signal statement:

> Northstar Foods Indonesia has installed Meridian equipment, warranty expiry in
> 45 days, and no active maintenance contract. Pulse360 recommends routing an
> aftermarket services specialist and creating a follow-up task. Opportunity
> creation requires approval.

Why this works for sales:

- it is proactive rather than seller-requested,
- it is grounded in source-system changes,
- it exposes group-level relationship context,
- it creates a clear revenue-relevant next action,
- it keeps high-risk commercial mutations gated.

## Source-System Change Events

The simulation should include these source events:

| Event | Source family | Signal contribution |
| --- | --- | --- |
| New Indonesia plant service asset appears | ERP / service asset | Proves installed equipment exists outside the seller's visible account view. |
| Warranty expiry within 45 days | Warranty / service contract | Creates urgency. |
| No active maintenance contract | Contract / entitlement | Creates a coverage gap. |
| Thailand distributor spare-parts spend spikes | ERP / distributor sales | Indicates aftermarket demand hidden from direct account view. |
| Duplicate subsidiary accounts detected | CRM / identity matching | Shows account truth problem and relationship fragmentation. |
| Service cases increase at a factory | Service Cloud / case data | Adds service-to-sales context and risk. |

## Databricks Demo Slice

The first executable slice is intentionally isolated from the existing live
`pulse360_s4.intelligence.datacloud_export_accounts` table. It creates a
bronze-to-gold evidence path that can be reviewed before any live export
repointing:

| Layer | View | Purpose |
| --- | --- | --- |
| Bronze | `pulse360_s4.bronze_proactive_signal.northstar_source_change_fixture` | Synthetic source-change events for the Northstar demo. |
| Silver | `pulse360_s4.silver_proactive_signal.northstar_proactive_account_signal` | One grouped `maintenance_coverage_gap` signal with confidence, source refs, and action policy. |
| Gold | `pulse360_s4.gold_proactive_signal.datacloud_proactive_signal_projection` | Data Cloud-shaped account intelligence projection for demo activation review. |

The gold projection preserves the current activation field family:
`intent_signal_payload`, `coverage_gap_flag`, `ai_narrative`,
`ai_recommended_actions`, `source_refs`, `last_synced_timestamp`, `run_id`, and
`model_version`.

## Harness Skills

Two project-specific skill lanes govern the work:

- [Pulse360 Databricks Skill](/Users/danielnortje/Documents/Pulse360/docs/harness/skills/pulse360-databricks-skill.md)
- [Pulse360 Salesforce Skill](/Users/danielnortje/Documents/Pulse360/docs/harness/skills/pulse360-salesforce-skill.md)

Decision rule:

- Databricks owns source-backed intelligence, signals, confidence, lineage, and
  export payloads.
- Salesforce owns Data Cloud activation, CRM-facing UX, governed action, and
  user feedback.
- Agentforce interprets and packages source-backed context only when capability
  gates pass; otherwise use the custom LWC/Apex action-panel fallback.

## GitHub Work Pack

Recommended branch:

```text
feature/proactive-signal-demo
```

Recommended PR title:

```text
Add Pulse360 proactive manufacturing signal demo harness
```

PR scope:

- add manufacturing demo fixture,
- add proactive signal data contract,
- extend Databricks export or sample payload,
- add Salesforce signal-card surface or contract,
- add validation/evidence docs,
- add demo readout script.

PR description must include:

- what is simulated,
- what is source-backed,
- what is live-validated,
- what remains capability-gated,
- which validators were run.

## Linear Work Pack

Recommended project:

```text
Pulse360 Proactive Signal Demo
```

Recommended issues:

| Issue | Owner skill | Acceptance evidence |
| --- | --- | --- |
| Define anonymized manufacturing demo customer | GTM / harness | Demo customer profile and source-event list committed. |
| Create source-change fixture pack | Databricks | Fixture data includes source IDs, timestamps, and before/after events. |
| Add proactive account signal contract | Databricks | Schema or contract lists required signal fields and trust metadata. |
| Generate `proactive_account_signals` output | Databricks | SQL/sample output produces at least one Northstar signal. |
| Map signal into Data Cloud export | Databricks + Salesforce | Export payload includes signal, source refs, freshness, and CRM-safe key. |
| Add Salesforce proactive signal surface | Salesforce | Signal appears as action-ready Account context or documented fallback. |
| Add Agentforce-ready signal brief | Salesforce | Brief/action contract shows explanation, approval policy, and fallback language. |
| Extend validators and evidence pack | Validator | Local checks pass or blockers are explicitly documented. |
| Produce 10-minute demo script | Narrator | Script separates live proof, simulation, and gated capability claims. |

Closure rule:

- A Linear issue is not done until it links to a repo artifact or GitHub PR and
  its acceptance evidence is captured.

## Service Blueprint

| Stage | Frontstage | Backstage | Evidence / control |
| --- | --- | --- | --- |
| Source change | Seller has not acted yet. | ERP, warranty, service, distributor, or CRM data changes. | Source event ID and timestamp. |
| Intelligence refresh | No seller-facing change yet. | Databricks builds identity, hierarchy, product footprint, and signal outputs. | Run ID, model version, lineage, source refs. |
| Signal classification | Signal enters routing queue. | Signal is scored and classified as `maintenance_coverage_gap`. | Confidence, priority, reason code. |
| Activation | Account context updates in Salesforce. | Data Cloud maps signal payload to CRM-safe account context. | `source_account_id`, freshness, mapped fields. |
| Seller action | Seller sees proactive signal and next action. | Salesforce renders signal card and supported actions. | Read-only evidence fields, approval policy. |
| Agent/fallback explanation | Seller asks why now. | Agentforce or fallback action panel explains source-backed signal. | Citations/source refs, no deterministic-field mutation. |
| Execution | Task, specialist route, or approved opportunity action is created. | Apex/Flow/LWC action contract executes. | Audit event, approval state, created record ID. |
| Feedback | Seller accepts, rejects, or escalates. | Outcome becomes input to next refresh. | Decision reason and feedback timestamp. |

## Acceptance Gates

### Demo Gate 1: Data Product

Pass when:

- source-change events exist,
- `proactive_account_signals` or equivalent sample output exists,
- output includes source refs, confidence, run metadata, and CRM-safe account key,
- no demo claim depends on hardcoded values without a fixture/source row.

### Demo Gate 2: Activation

Pass when:

- signal payload can be exported through the existing Data Cloud handoff shape
  or a documented extension,
- freshness is visible,
- current CFE/CRM writeback limitations are explicitly stated.

### Demo Gate 3: Salesforce Action

Pass when:

- seller-facing surface shows the primary signal and recommended action,
- low-risk actions are auto-executable only where supported,
- high-risk actions such as opportunity creation require approval,
- evidence fields remain read-only.

### Demo Gate 4: Agentforce Claim

Pass only when:

- native Agentforce runtime support is verified in the target org,
- actions are registered and callable,
- approval policy is enforced,
- citations or fallback source refs are visible.

Otherwise, the demo must describe the experience as:

```text
custom Salesforce LWC/Apex action panel with Agentforce-ready contract
```

### Demo Gate 5: Narrative

Pass when the demo script cleanly separates:

- source-backed facts,
- simulated events,
- live-validated surfaces,
- capability-gated Agentforce claims,
- next implementation steps.

## Validation Commands

Run the relevant existing checks before claiming the harness is ready:

```bash
./scripts/validate-proactive-signal-demo.sh
./scripts/validate-contracts.sh
./scripts/validate-data-cloud-insights-config.sh
./scripts/validate-canonical-exports.sh
./scripts/validate-account-intelligence-experience.sh
./scripts/validate-agentforce-orchestrator.sh
./scripts/validate-signal-routing-workspace.sh
./scripts/validate-multi-surface-experience.sh
```

For live target-org readiness, keep using the M1 gate:

```bash
TARGET_ORG=pulse360-agent-target ./scripts/validate-m1-account-hierarchy-readiness-gate.sh
```

The M1 live gate is allowed to fail during simulation work if the failure is the
known CRM freshness/writeback boundary and the demo narrative states that
boundary explicitly.

To publish the isolated proactive-signal Databricks pack after the SQL warehouse
is available, run:

```bash
./scripts/publish-databricks-proactive-signal-demo.sh
```

To seed the Salesforce fallback/demo surface while Databricks Community Edition
quota is unavailable, run:

```bash
TARGET_ORG=pulse360-agent-target ./scripts/seed-salesforce-proactive-signal-demo.sh
TARGET_ORG=pulse360-agent-target ./scripts/validate-salesforce-proactive-signal-demo.sh
```

## What Not To Build Yet

Do not build these before the proactive signal story is validated:

- generalized event orchestration,
- multi-industry fixture generator,
- autonomous opportunity creation,
- native Agentforce-only demo path,
- new Account-level DLO/DMO workaround to bypass freshness issues,
- production-grade streaming pipeline.

## Next Implementation Slice

The smallest useful implementation slice is:

1. create the Northstar source-change fixture,
2. create a sample proactive signal payload,
3. map that payload to the existing seller action contract,
4. add or document the seller signal surface,
5. produce the 10-minute demo script with evidence boundaries.
