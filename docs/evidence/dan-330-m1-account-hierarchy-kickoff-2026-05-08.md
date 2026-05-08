# DAN-330 M1 Account Hierarchy Kickoff Evidence

## Summary

M1 has been opened as the first implementation slice after the accepted
`DAN-280` architecture gate. The branch is:
`codex/m1-account-hierarchy-intelligence`.

## Linear Scope

| Issue | Purpose |
| --- | --- |
| `DAN-330` | M1 parent implementation lane |
| `DAN-331` | Contracts and package membership |
| `DAN-332` | Databricks hierarchy edge and rollup outputs |
| `DAN-333` | Group Revenue Reveal and coverage gap rules |
| `DAN-334` | Data Cloud and Salesforce hierarchy validation surfaces |
| `DAN-335` | Implementation evidence and demo readout |

## Source Assets Added

- `contracts/m1_account_hierarchy_output.schema.json`
- `data/samples/account_hierarchy/m1_account_hierarchy_output_sample.json`
- `config/packages/databricks/account-hierarchy-intelligence.members.txt`
- `sql/databricks/account_hierarchy/*`
- `docs/runbook/pulse360-m1-account-hierarchy-runbook.md`
- `scripts/validate-m1-account-hierarchy-pack.sh`

## Current Posture

This is a source scaffold and implementation baseline. It does not claim live
Databricks SQL execution, live Data Cloud stream refresh, or Salesforce UX
rendering for the new M1 tables yet.
