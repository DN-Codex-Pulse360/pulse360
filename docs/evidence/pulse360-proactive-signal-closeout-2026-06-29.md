# Pulse360 Proactive Signal Closeout - 2026-06-29

## Status

Today's closeout state is **partial pass with one external blocker**.

The proactive signal slice is ready locally and the Salesforce preview path is
live in `pulse360-agent-target`. The Databricks live publish remains blocked by
Databricks Community Edition daily quota.

## Live Salesforce Evidence

- Account: `Northstar Foods Group`
- Account ID: `001dL00002HTb4cQAD`
- Target contact ID: `003dL00002BsNDBQA3`
- Account URL: `https://orgfarm-d50863b207-dev-ed.develop.my.salesforce.com/lightning/r/Account/001dL00002HTb4cQAD/view`
- Signal routing URL: `https://orgfarm-d50863b207-dev-ed.develop.my.salesforce.com/lightning/n/Pulse360_Signal_Routing?c__previewRecordId=001dL00002HTb4cQAD`

The seeded surface is explicitly fixture-backed Salesforce preview:

- native Agentforce runtime verified: `false`
- fallback surface: `custom Salesforce LWC/Apex assistant and action panels`
- approval-gated actions: `create_opportunity`, `update_account_hierarchy`

## Verification Run

```bash
./scripts/validate-proactive-signal-demo.sh
```

Result:

```text
[PASS] Proactive signal schema declares the required contract fields
[PASS] Schema includes the Data Cloud export projection fields
[PASS] Source-change fixture has the expected proactive trigger evidence
[PASS] Signal projects into the current Data Cloud account intelligence export shape
[PASS] Intent signal payload is compatible with the existing Salesforce signal-routing workspace
[PASS] Agentforce execution policy is approval-aware and runtime-honest
[PASS] Proactive signal demo artifacts passed validation
[PASS] Databricks proactive signal SQL pack names the required bronze, silver, and gold views
[PASS] Databricks SQL projection preserves Agentforce gating and approval policy
```

```bash
TARGET_ORG=pulse360-agent-target ./scripts/validate-salesforce-proactive-signal-demo.sh
```

Result:

```text
[PASS] Salesforce proactive signal artifacts exist
[PASS] Salesforce routing payload is Account workspace compatible
[PASS] Salesforce seed script preserves proactive signal evidence fields
[PASS] Proactive signal sample preserves scenario identity and fallback policy
[PASS] Required Account signal fields exist
[PASS] Evidence fields remain read-only in the Account Intelligence permission set
[PASS] Existing Salesforce signal-routing surface is available for the seeded account
[PASS] Live org Northstar Account has the proactive Salesforce fields populated
[PASS] Salesforce proactive signal demo validation completed
```

```bash
PULSE360_DATABRICKS_PUBLISH_DRY_RUN=1 ./scripts/publish-databricks-proactive-signal-demo.sh
```

Result:

```text
[DRY-RUN] Would apply SQL files in order:
  - sql/databricks/proactive_signal/00_create_schemas.sql
  - sql/databricks/proactive_signal/05_northstar_source_change_fixture.sql
  - sql/databricks/proactive_signal/10_northstar_proactive_account_signal.sql
  - sql/databricks/proactive_signal/20_datacloud_proactive_signal_projection.sql
[DRY-RUN] Would use warehouse 7052914888c7e86c in state STOPPED
```

```bash
./scripts/publish-databricks-proactive-signal-demo.sh
```

Result:

```text
Unable to start Databricks warehouse 7052914888c7e86c: Sorry, cannot run the resource because you have hit your free daily limit. Please come back again tomorrow. (COMMUNITY_EDITION_CREDIT_EXHAUSTED)
```

## Ready For Tomorrow

1. Re-run the Databricks publisher after quota reset:

   ```bash
   ./scripts/publish-databricks-proactive-signal-demo.sh
   ```

2. If the gold projection publishes, capture the generated evidence JSON and
   decide whether to connect the proactive signal to Data Cloud or keep it as an
   isolated demo proof.
3. Decide whether to add an Agentforce-specific action for proactive signal
   context. Until native runtime is proven, keep the demo language as fallback
   LWC/Apex action panel.
