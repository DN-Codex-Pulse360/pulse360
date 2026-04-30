# Pulse360 Solution Goals and Implemented Design - 2026-03-28

## Purpose
This note captures the Pulse360 solution goals as planned, the design as actually implemented in the live prototype, and the remaining work before formal closeout.

It is intended as a review-ready architecture/status note rather than a troubleshooting log.

## Planned Solution Goals
- Build an account intelligence prototype that enriches Salesforce CRM `Account` records with explainable Databricks-derived intelligence.
- Preserve CRM-safe account identity from Salesforce CRM through Databricks and Data Cloud, then back into CRM-facing experiences.
- Use Data Cloud as the operational identity and intelligence layer between Databricks and Salesforce.
- Surface intelligence in Salesforce through:
  - Account-level fields and experiences
  - governance/stewardship workflows
  - seller-facing actions such as health scan and cross-sell guidance
- Prove the end-to-end flow across the DS-01/DS-02/DS-03 scenario set.

## Planned Design
### Data and computation
- Salesforce CRM `Account` source data ingests into Databricks silver tables.
- Databricks gold logic computes canonical account intelligence, hierarchy-safe rollups, and activation-ready outputs.
- The export to Data Cloud preserves native CRM `Account.Id` as the deterministic match key (`source_account_id`).

### Operational intelligence layer
- Data Cloud ingests the Databricks export stream.
- Data Cloud maps the export into Account-facing model objects and operational enrichment surfaces.
- The original working assumption was that a Salesforce activation target would be the downstream CRM realization path.

### CRM experience layer
- Salesforce custom fields hold selected intelligence values on `Account`.
- Lightning page configuration exposes the values and related seller/stewardship UX elements.
- Governance review and Account 360 experiences consume the same account-centric intelligence model.

## Implemented Design
### 1. Databricks intelligence layer
- Implemented and validated from repo SQL.
- The live export backing Data Cloud is built from:
  - [10_account_export_base.sql](/Users/danielnortje/Documents/Pulse360/sql/databricks/gold/10_account_export_base.sql)
  - [30_datacloud_export_accounts.sql](/Users/danielnortje/Documents/Pulse360/sql/databricks/gold/30_datacloud_export_accounts.sql)
- The export now contains current enriched rows for live CRM account IDs, including `Globex APAC Pte Ltd` / `001dM00003aUn53QAC`.

### 2. Data Cloud ingestion and modeling
- Implemented and validated in the live `pulse360-dev` org.
- The Databricks data stream `datacloud_export_accounts Pulse360_Datab` is ingesting successfully.
- The Data Lake Object and Account Data Model Object both show the expected intelligence values for the current CRM account IDs.
- Data Cloud is functioning as the operational intelligence layer, not merely a transport layer.

### 3. CRM realization path
- The working CRM writeback path is `Data Cloud Copy Field Enrichment`.
- This is the most important implementation correction relative to the earlier design hypothesis.
- A Salesforce `ActivationTarget` exists and shows healthy UI status, but it was not the mechanism that ultimately proved CRM field population.
- The live CRM sync proof is through Account field updates written by the platform integration user via copy-field sync.

### 4. Salesforce experience layer
- Salesforce `Account` fields exist for the Pulse360 intelligence surface.
- The Account page layout includes a dedicated `Pulse360` section.
- The live CRM record for `Globex APAC Pte Ltd` now shows populated intelligence fields, including:
  - `Unified_Profile_Id__c`
  - `Identity_Confidence__c`
  - `Health_Score__c`
  - `Cross_Sell_Propensity__c`
  - `Competitor_Risk_Signal__c`
- Milestone D UI assets remain deployed and available through the Lightning record page and action surfaces.

## Planned vs Implemented
| Area | Planned | Implemented |
| --- | --- | --- |
| CRM-safe key preservation | Preserve CRM `Account.Id` through the pipeline | Achieved and validated on live records |
| Databricks intelligence export | Gold outputs feed Data Cloud-ready account intelligence | Achieved after rebuild of stale export table |
| Data Cloud operational layer | Ingest, map, and model intelligence for CRM use | Achieved and validated in DLO/DMO |
| CRM field realization | Expected via Data Cloud activation target | Achieved via `Copy Field Enrichment` instead |
| Account UX | Pulse360 values visible in Salesforce | Achieved with populated fields on live Account records |
| Milestone C acceptance story | Activation/mapping/runtime proof required | Functional proof achieved; formal issue/gate closeout still pending |

## Design Corrections Learned During Implementation
### Correction 1: stale export diagnosis mattered more than field metadata
The first major runtime blocker was not Salesforce field deployment. It was a stale Databricks materialized export table. Rebuilding the export from repo SQL was required before current account intelligence could appear downstream.

### Correction 2: Data Cloud DMO verification was essential
The pipeline had to be validated at the Data Cloud object level, not just from stream status. DMO inspection proved whether the current CRM account IDs had actually received the enriched values.

### Correction 3: the effective CRM sync path was Copy Field Enrichment
The original troubleshooting path focused heavily on `ActivationTarget` state. The implemented CRM writeback proof came from `Copy Field Enrichment`, which is now the correct documented downstream mechanism for this prototype.

## Current Project Status
### What is complete
- Databricks intelligence export is current and repo-backed.
- Data Cloud stream ingest is healthy.
- Data Cloud model objects contain the expected account intelligence values.
- Salesforce CRM `Account` fields are populated on live records.
- Milestone D experience-layer deployment is complete.

### What is in review
- Milestone C formal closeout in Linear and EPF gate language.
- Gate `2.4` remains `In Review` pending explicit formal acceptance reconciliation across DS-01/DS-02/DS-03, not because the core enrichment-to-CRM path is still broken.

### What remains open
- Reconcile the exact field contract for any fields that are still blank or intentionally excluded from sync, such as `DataCloud_Last_Synced__c`.
- Decide whether older activation-target troubleshooting should remain in the main runtime evidence note or move into a separate retrospective/troubleshooting artifact.
- Refresh acceptance wording so milestone/gate language matches the implemented copy-field-sync design rather than the earlier activation-target assumption.

## Recommended Review Questions
- Does the project want to standardize `Copy Field Enrichment` as the approved CRM sync pattern for Pulse360 intelligence fields?
- Should `ActivationTarget` remain part of the intended architecture, or be demoted to a rejected/unused implementation path for this slice?
- Is the current field set sufficient for the Account 360 seller experience, or should the contract be narrowed to only the fields proven useful in the live UI?
- Should the final architecture narrative explicitly separate:
  - Databricks as computation layer
  - Data Cloud as operational identity/modeling layer
  - Salesforce copy-field sync as CRM realization layer

## Evidence Anchors
- [dan-114-activation-runtime-check-2026-03-26.md](/Users/danielnortje/Documents/Pulse360/docs/evidence/dan-114-activation-runtime-check-2026-03-26.md)
- [dan-114-data-cloud-activation-recovery-runbook.md](/Users/danielnortje/Documents/Pulse360/docs/runbook/dan-114-data-cloud-activation-recovery-runbook.md)
- [databricks-to-datacloud-contract.md](/Users/danielnortje/Documents/Pulse360/docs/contracts/databricks-to-datacloud-contract.md)
- [datacloud-to-salesforce-agentforce-contract.md](/Users/danielnortje/Documents/Pulse360/docs/contracts/datacloud-to-salesforce-agentforce-contract.md)

## Bottom Line
Pulse360's core design goal is now proven in the live prototype:

Databricks-derived account intelligence can flow through Data Cloud and land back in Salesforce CRM on live `Account` records using preserved CRM-safe keys.

The implemented downstream realization mechanism is `Copy Field Enrichment`, and the remaining work is design cleanup, formal acceptance reconciliation, and review-driven next-step decisions rather than fundamental runtime debugging.
