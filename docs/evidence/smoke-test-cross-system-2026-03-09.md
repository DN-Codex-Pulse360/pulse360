# Cross-System Smoke Test Evidence (2026-03-09)

Purpose: validate that we can create and remove a minimal element in both Databricks and Salesforce.

## Databricks Smoke Test
- Element type: Unity Catalog view
- Temporary view: `pulse360_s4.intelligence.smoke_test_gate_20260309_091042`

Execution results:
- create statement_id: `01f11b97-da6c-125d-a315-f268cacd86aa`
- verify statement_id: `01f11b97-e8c4-12f6-a861-bb393d9c3c6c`
- verify rows: `[["codex_smoke","1"]]`
- drop statement_id: `01f11b97-ebdf-1cde-acf9-83edda752bfc`

Outcome: create/verify/drop succeeded.

## Salesforce Smoke Test
- Org alias: `pulse360-dev`
- Element type: Tooling API ApexClass
- Temporary class name: `Pulse360SmokeGate20260309091432`
- Temporary class id: `01pdM00000T43t3QAB`

Execution results:
- create: succeeded
- verify query row: `[{"Id":"01pdM00000T43t3QAB","Name":"Pulse360SmokeGate20260309091432"}]`
- delete: succeeded

Outcome: create/verify/delete succeeded.

## Interpretation
- Write-path permissions are available in both systems.
- Current delivery gaps are therefore deployment execution/completeness, not platform access.
