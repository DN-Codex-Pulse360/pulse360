# EPF Stages 1.3 and 1.4 - Platform Landscape and Option Assessment (DAN-76)

## Scope
This artifact combines Stage 1.3 (platform landscape) and Stage 1.4 (solution option assessment) for Pulse360.

## Current-State Platform Landscape (1.3)
Primary platforms in scope:
1. Salesforce CRM (Account, Opportunity, case and execution UX)
2. Databricks (intelligence processing, hierarchy/enrichment outputs, lineage)
3. Salesforce Data Cloud (identity resolution, canonical profile, activation datasets)

### Explicit Data Flow
1. CRM source account and related records are ingested into Databricks bronze/silver zones.
2. Databricks computes duplicate confidence, hierarchy graph, enrichment validity, and governance metadata.
3. Databricks publishes contract-governed exports to Data Cloud (v1 + canonical v2).
4. Data Cloud applies identity resolution and calculated insights.
5. Data Cloud activates account-centric outputs back to Salesforce for Account 360 and Agentforce actions.
6. User actions in Salesforce (for example opportunity creation) trigger downstream insight refresh logic.

### Keying Requirement for CRM Writeback
- Activation back to Salesforce CRM `Account` requires that Databricks preserve a CRM-matchable key through the enrichment flow.
- Accepted key strategies:
  - carry native Salesforce `Account.Id` from upstream CRM ingestion, or
  - carry a Salesforce External ID that is available for deterministic upsert/match in CRM.
- Databricks-origin account records without CRM key association are acceptable for analytical modeling, but not for deterministic CRM writeback acceptance.

### Integration Boundary Summary
| From | To | Contract Anchor |
| --- | --- | --- |
| Salesforce CRM | Databricks | `docs/contracts/salesforce-crm-to-databricks-account-ingestion-contract.md` |
| Databricks | Data Cloud | `docs/contracts/databricks-to-datacloud-contract.md` |
| Data Cloud | Salesforce CRM/Agentforce | `docs/contracts/datacloud-to-salesforce-agentforce-contract.md` |

## Option Assessment Matrix (1.4)
| Option | Description | Benefits | Tradeoffs | Decision |
| --- | --- | --- | --- | --- |
| A - Databricks intelligence + Data Cloud activation (current) | Databricks handles heavy identity/hierarchy/enrichment processing; Data Cloud handles unification and CRM activation | Strong lineage/governance, clear system responsibilities, scalable enrichment logic | Multi-system operational complexity, connector hardening needed | **Selected** |
| B - Data Cloud-centric identity/enrichment only | Push most transformation and matching into Data Cloud with minimal Databricks logic | Fewer platforms in active flow, simpler runtime topology | Reduced flexibility for advanced enrichment/graph workflows, less transparent custom lineage | Rejected |
| C - CRM-custom model and activation | Keep intelligence mostly in CRM custom objects/logic | Tight UX proximity, fewer external dependencies | High custom technical debt, weaker data science flexibility, harder cross-source unification | Rejected |

## Rejected Option Rationale
1. Option B rejected because DS-02/DS-03 evidence requires richer, explicit Databricks-side graph/enrichment processing than target prototype timelines support in Data Cloud-only flow.
2. Option C rejected because it increases long-term maintenance burden and weakens reuse of governed intelligence products for non-CRM consumers.

## Recommended Approach
Use Option A: Databricks for intelligence products and governance evidence, Data Cloud for canonical identity and activation, Salesforce for execution UX.  
This aligns to existing repository contracts and the canonical B2B model.

### Added Design Item
Add an explicit upstream design item to ingest Salesforce CRM Account records into Databricks before enrichment so cleaned/enriched account outputs retain a valid CRM writeback key.

## Gate Self-Checks
Stage 1.3 gate: can data flow between critical systems be explained without guessing?  
Status: **Pass**

Stage 1.4 gate: are rejected options and tradeoffs explicit?  
Status: **Pass**
