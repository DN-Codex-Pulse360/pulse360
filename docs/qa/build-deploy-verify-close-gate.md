# Build -> Deploy -> Verify -> Evidence -> Close Gate

Rule: **No evidence = no Done**.

This gate prevents status drift and hallucinated completion claims by requiring deployment proof (not just runtime/sample proof) before issue closure.

## Gate Phases
1. Build
- Repo artifacts exist (SQL/contracts/scripts/docs).
- Config validators pass.

2. Deploy
- Databricks assets are deployed and visually complete.
- Salesforce metadata is deployed in target org.

3. Verify
- Runtime validators pass.
- Deployment validators pass.

4. Evidence
- Machine evidence captured (IDs, timestamps, query outputs).
- UI evidence captured (screenshots/links).
- Evidence mirrored in repo + Linear + Notion + PR.

5. Close
- Issue state can be moved to `Done` only after phases 1-4 are all green.

## Required Validators
- Databricks visual deployment:
  - `scripts/validate-databricks-dashboard-visuals.sh`
- Salesforce metadata deployment:
  - `scripts/validate-salesforce-deployment-runtime.sh`
- End-to-end gate:
  - `scripts/validate-build-deploy-verify-close-gate.sh`

## Default Deployment Expectations
Salesforce runtime validator uses explicit expected metadata names and fails if missing.

Defaults (override with env vars when names differ):
- `REQUIRED_LWC_BUNDLES=pulse360GovernanceCase,pulse360Account360,pulse360HealthScan,pulse360CrossSellBanner`
- `REQUIRED_RECORD_PAGES=Pulse360_Account_Record_Page`
- `REQUIRED_ACCOUNT_ACTIONS=Pulse360_QuickCreateOpportunity,Pulse360_HealthScanAction`

Databricks visual validator defaults:
- Two canonical dashboard IDs (`main`, `demo`).
- Minimum datasets/widgets and at least one non-table widget (`MIN_NON_TABLE_WIDGETS>=1`).
- Required panel title tokens: `DS-01`, `DS-02`, `DS-03`, `Freshness`, `KPI`.

## Suggested Run Order
```bash
./scripts/validate-deployment-gate-assets.sh
./scripts/validate-databricks-dashboard-pack.sh
./scripts/validate-dan-58-governance-dashboard-pack.sh
./scripts/validate-databricks-dashboard-visuals.sh
./scripts/validate-salesforce-deployment-runtime.sh
./scripts/validate-build-deploy-verify-close-gate.sh
```

## Close Criteria
- Databricks dashboard visuals are finalized and proof-linked.
- Salesforce UI metadata exists in org and proof-linked.
- Runtime and deployment validators are all green.
- HITL checklist comment is posted with reviewer name.
