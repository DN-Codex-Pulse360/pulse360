# Pulse360 Live Data Platform Status

Date: 2026-05-01

## Scope

Read-only validation of the live Salesforce/Data Cloud and Databricks surfaces
for the sovereign identifier and firmographic Data layer work.

## Salesforce/Data Cloud Target

Org alias: `pulse360-agent-target`

Observed Data Cloud streams:

| Stream | Import status | Last refresh | Rows |
| --- | --- | --- | ---: |
| `Pulse360_Activation_Review_Queue` | `SUCCESS` | `2026-05-01T03:45:03Z` | 11 |
| `DC Export Accounts P360 V2` | `SUCCESS` | `2026-04-29T14:23:19Z` | 18 |

Observed DLOs:

| DLO | Status | Sync status | Records | Fields |
| --- | --- | --- | ---: | ---: |
| `Pulse360 Activation Review Queue` | `ACTIVE` | `ACTIVE` | 11 | 38 |
| `Pulse360 Account Intelligence Export V2` | `ACTIVE` | `ACTIVE` | 18 | 49 |

No live Data Cloud streams were found with names containing `Sovereign`,
`Firmographic`, or `Identifier`.

## Salesforce Account Activation Sample

Recent Account rows are populated through the existing Account summary
activation fields:

| Account | External registration | Externally validated | Identity confidence | External validity | Enrichment run |
| --- | --- | --- | ---: | ---: | --- |
| `Edge Communications` | null | false | 93 | 88 | `run_default_20260427_115330` |
| `Burlington Textiles Corp of America` | null | false | 93 | 88 | `run_default_20260427_115330` |
| `Pyramid Construction Inc.` | null | false | 93 | 88 | `run_default_20260427_115330` |
| `United Oil & Gas Corp.` | null | false | 93 | 88 | `run_default_20260427_115330` |

This confirms the live CRM surface is still on the older Account-summary path.
The new sovereign identifier and rich firmographic extension tables are not
activated into Salesforce/Data Cloud yet.

## Databricks Unity Catalog

Catalog/schema: `pulse360_s4.intelligence`

Observed tables:

| Table | Rows |
| --- | ---: |
| `crm_accounts_raw` | 3 |
| `datacloud_activation_review_queue` | 11 |
| `datacloud_export_accounts` | 18 |
| `duplicate_candidate_pairs` | 3 |
| `firmographic_enrichment` | 3 |
| `governance_ops_metrics` | 1 |
| `hierarchy_entity_graph` | 3 |

Not found live yet:

- `sovereign_identifier_export`
- `firmographic_profile_export`
- `company_classification_export`
- `corporate_linkage_export`
- `firmographic_source_evidence_export`

The source branch now adds SQL definitions for those five outputs under
`sql/databricks/gold`.

## Databricks Jobs

Latest successful data-layer validation:

| Job | Run | Status | Output |
| --- | --- | --- | --- |
| `pulse360-data-layer-closeout-validation` | `618622060099342` | `SUCCESS` | `check_count=19`, `failure_count=0` |

Latest successful firmographic GenAI enrichment:

| Job | Run | Status |
| --- | --- | --- |
| `pulse360-firmographic-genai-enrichment` | `767020160543876` | `SUCCESS` |

Resolved ingestion blocker:

| Job | Failed run | Recovery run | Recovery status | Notes |
| --- | --- | --- | --- | --- |
| `pulse360-salesforce-extract` | `227640205260468` | `645797079073348` | `SUCCESS` | New pipeline update `8cebc0ad-4ed4-42b9-bc62-c9ca8f608da5` completed |
| `pulse360-salesforce-governance-feedback` | `144025314928475` | `82684971078881` | `SUCCESS` | New pipeline update `4ff336e3-1b05-45c6-b961-a36c431ed248` completed |

The failed managed-ingestion event log reported:

```text
SAAS_CONNECTOR_UC_CONNECTION_OAUTH_EXCHANGE_FAILED
The OAuth token exchange failed for UC connection: pulse360.
Edit the UC connection, re-authenticate, and run the pipeline again.
```

## Required Platform Action

The Databricks UC connection `pulse360` was re-authenticated by an operator with
access to the Salesforce credential flow. The UI still displayed an HTTP 408
toast, but the backend connection metadata showed a refreshed active credential
and both managed-ingestion jobs subsequently completed successfully.

Completed after re-authentication:

1. Run `pulse360-salesforce-extract`.
2. Run `pulse360-salesforce-governance-feedback`.
3. Confirm both latest runs complete successfully.
4. Run the gold SQL package so the new sovereign/firmographic outputs are
   materialized.

Remaining platform action:

1. Create the corresponding Data Cloud streams/DLO mappings from
   `config/data-cloud/sovereign-firmographic-dlo-dmo-setup.csv`.

## Source-Side Progress

The source branch now includes contract and SQL definitions for:

- `pulse360_s4.intelligence.sovereign_identifier_export`
- `pulse360_s4.intelligence.firmographic_profile_export`
- `pulse360_s4.intelligence.company_classification_export`
- `pulse360_s4.intelligence.corporate_linkage_export`
- `pulse360_s4.intelligence.firmographic_source_evidence_export`

The sovereign identifier export is intentionally typed but empty until official
registry, tax, or filing identifiers are available. CRM IDs and provider IDs
must not be emitted as sovereign identifiers.

## Materialized Gold Output Counts

After running the gold SQL package on `2026-05-01`, the following live table
counts were observed:

| Table | Row count |
| --- | ---: |
| `pulse360_s4.intelligence.sovereign_identifier_export` | 0 |
| `pulse360_s4.intelligence.firmographic_profile_export` | 18 |
| `pulse360_s4.intelligence.company_classification_export` | 11 |
| `pulse360_s4.intelligence.corporate_linkage_export` | 2 |
| `pulse360_s4.intelligence.firmographic_source_evidence_export` | 37 |
| `pulse360_s4.intelligence.datacloud_export_accounts` | 18 |

Observed `location_type` distribution:

| location_type | Count |
| --- | ---: |
| `parent_company` | 1 |
| `single_location` | 16 |
| `subsidiary` | 1 |

## Data Cloud DMO Mapping Validation

On `2026-05-05`, the saved Data Cloud mappings were validated directly against
the live org alias `pulse360-agent-target`.

| DMO | API name | Queryable | Row count | Status |
| --- | --- | --- | ---: | --- |
| Firmographic Profile | `Pulse360_Firmographic_Profile__dlm` | yes | 18 | pass |
| Company Classification | `Pulse_360_Company_Classification__dlm` | yes | 11 | pass |
| Corporate Linkage | `Pulse360_Corporate_Linkage__dlm` | yes | 2 | pass |
| Firmographic Source Evidence | `Pulse360_Firmographic_Source_Evidenc__dlm` | yes | 37 | pass |
| Sovereign Identifier | `Pulse360_Sovereign_Identifier__dlm` | yes | 0 | pass, expected empty |

Key integrity checks:

- `Pulse360_Firmographic_Profile__dlm` has 18 rows, 18 distinct
  `source_account_id__c` values, and 18 distinct `party_id__c` values.
- All 18 referenced `source_account_id__c` values exist in Salesforce `Account`.
- `ssot__Account__dlm` has 18 rows and uses `ssot__Id__c` as the CRM Account
  key matching the Pulse360 `source_account_id__c` values.
- Classification, corporate-linkage, and evidence rows all reference known
  firmographic-profile `party_id__c` and `source_account_id__c` values.
- All 37 firmographic evidence rows have `source_url__c` populated.
- The first validation pass showed no relationship edges from the Pulse360
  extension DMOs to `ssot__Account__dlm`. The relationships were then created
  through the Data Cloud UI and revalidated.

Required relationship target:

| Child DMO | Child field | Parent DMO | Parent field | Cardinality | Generated relationship field | Status |
| --- | --- | --- | --- | --- | --- | --- |
| `Pulse360_Firmographic_Profile__dlm` | `source_account_id__c` | `ssot__Account__dlm` | `ssot__Id__c` | `OneToOne` | `rel_1777989007569_end__c` | pass |
| `Pulse_360_Company_Classification__dlm` | `source_account_id__c` | `ssot__Account__dlm` | `ssot__Id__c` | `ManyToOne` | `rel_1777990282217_end__c` | pass |
| `Pulse360_Corporate_Linkage__dlm` | `source_account_id__c` | `ssot__Account__dlm` | `ssot__Id__c` | `ManyToOne` | `rel_1777990382517_end__c` | pass |
| `Pulse360_Firmographic_Source_Evidenc__dlm` | `source_account_id__c` | `ssot__Account__dlm` | `ssot__Id__c` | `ManyToOne` | `rel_1777990482469_end__c` | pass |
| `Pulse360_Sovereign_Identifier__dlm` | `source_account_id__c` | `ssot__Account__dlm` | `ssot__Id__c` | `ManyToOne` | `rel_1777990642329_end__c` | pass |

Post-relationship validation:

- `ssot__Account__dlm` exposes all five Pulse360 DMOs as child relationships.
- Each Pulse360 child DMO exposes a generated reference field to
  `ssot__Account__dlm`.
- Row counts remained aligned after relationship creation:
  `18`, `11`, `2`, `37`, and `0`.
- `source_account_id__c` remained populated on every populated Pulse360 DMO row.

## Salesforce Report Validation After GPT Refresh

On `2026-05-07`, after the OpenAI GPT enrichment runtime and gold export rebuild,
the Salesforce/Data Cloud surface was revalidated against org alias
`pulse360-agent-target`.

Operator health:

- Codex CLI authenticated.
- Salesforce CLI reached `pulse360-agent-target`.
- Databricks CLI listed the workspace root.
- GitHub CLI auth was healthy.
- Hosted MCP registrations for Linear, Notion, Data Cloud, and Databricks SQL
  were present.

Observed Data Cloud streams:

| Stream | Import status | Last refresh | Rows processed | New fields |
| --- | --- | --- | ---: | --- |
| `firmographic_profile_export_Pulse360_Dat` | `SUCCESS` | `2026-05-07T11:12:02Z` | 18 | false |
| `firmographic_source_evidence_export_Puls` | `SUCCESS` | `2026-05-07T11:12:01Z` | 140 | false |
| `company_classification_export_Pulse360_D` | `SUCCESS` | `2026-05-07T11:12:06Z` | 11 | false |
| `corporate_linkage_export_Pulse360_Databr` | `SUCCESS` | `2026-05-07T11:12:01Z` | 2 | false |
| `sovereign_identifier_export_Pulse360_Dat` | `SUCCESS` | `2026-05-07T12:12:01Z` | 0 | false |
| `Pulse360_Activation_Review_Queue` | `SUCCESS` | `2026-05-07T11:45:02Z` | 11 | false |

Observed Data Lake Object instances:

| DLO | Status | Sync status | Records | Fields | Hydration |
| --- | --- | --- | ---: | ---: | --- |
| `firmographic_profile_export Pulse360 Dat` | `ACTIVE` | `ACTIVE` | 18 | 53 | `Hydrated` |
| `firmographic_source_evidence_export Puls` | `ACTIVE` | `ACTIVE` | 140 | 17 | `Hydrated` |
| `company_classification_export Pulse360 D` | `ACTIVE` | `ACTIVE` | 11 | 16 | `Hydrated` |
| `corporate_linkage_export Pulse360 Databr` | `ACTIVE` | `ACTIVE` | 2 | 19 | `Hydrated` |
| `sovereign_identifier_export Pulse360 Dat` | `ACTIVE` | `ACTIVE` | 0 | 27 | `Hydrated` |

Report execution validation through the Salesforce Analytics REST API:

| Report | Report Id | Rows | Filters | Status |
| --- | --- | ---: | --- | --- |
| `Account and Firmographic` | `00OdL00000PHrzBUAT` | 18 | none | pass |
| `Account and Evidence` | `00OdL00000PHtxlUAD` | 140 | none | pass |
| `Account and Classification` | `00OdL00000PHuKLUA1` | 11 | none | pass |
| `Account and Corporate Linkage` | `00OdL00000PIt1FUAT` | 2 | none | pass |
| `Account and Sovereign Identifier` | `00OdL00000PIuerUAD` | 0 | none | pass, expected empty |

DMO field validation:

- `Pulse360_Firmographic_Profile__dlm` exposes 55 fields, including
  `jurisdiction_country_code__c`, investor-summary fields, financial-result
  fields, `KQ_source_account_id__c`, and generated Account relationship field
  `rel_1777989007569_end__c`.
- `Pulse360_Sovereign_Identifier__dlm` exposes 29 fields, including
  source-bound sovereign identifier fields, `source_type__c`, `source_url__c`,
  `KQ_source_account_id__c`, and generated Account relationship field
  `rel_1777990642329_end__c`.
- `Pulse_360_Company_Classification__dlm` exposes 18 fields and generated
  Account relationship field `rel_1777990282217_end__c`.
- `Pulse360_Corporate_Linkage__dlm` exposes 21 fields and generated Account
  relationship field `rel_1777990382517_end__c`.
- `Pulse360_Firmographic_Source_Evidenc__dlm` exposes 19 fields and generated
  Account relationship field `rel_1777990482469_end__c`.

Sample DMO data checks:

- `Pulse360_Firmographic_Profile__dlm` returned 18 report rows and queryable
  profile records with refreshed `last_verified_at__c` values from
  `2026-05-07T04:08:34Z` through `2026-05-07T04:19:53Z` in the sample checked.
- `Pulse360_Firmographic_Source_Evidenc__dlm` returned 140 report rows and
  source-backed evidence records with `source_url__c` populated.
- `Pulse360_Corporate_Linkage__dlm` returned the expected Singtel/NCS linkage
  rows.
- `Pulse360_Sovereign_Identifier__dlm` remained empty, which is expected until
  official registry, tax-authority, or filing evidence satisfies the verified
  sovereign identifier gate.

Salesforce-side next work:

1. Design the CRM Account page surfacing pattern for read-only Data Cloud
   intelligence, keeping evidence/provenance read-only and any stewardship
   decisions separate.
2. Add permission-set coverage for report/dashboard visibility once the target
   report folder and page placement are finalized.

## Salesforce Report Promotion

On `2026-05-07`, the five private validation reports were cloned into a
dedicated report folder and retrieved into source control.

Created folders:

| Folder | Type | Id | Developer name | Access note |
| --- | --- | --- | --- | --- |
| `Pulse360 Account Intelligence Validation` | Report | `00ldL00000NixwnQAB` | `Pulse360_Account_Intelligence_Validation` | API keeps `AccessType=Hidden`; folder sharing remains an admin/UI step |
| `Pulse360 Account Intelligence Validation` | Dashboard | `00ldL00000NixyPQAR` | `Pulse360_Account_Intelligence_Validation` | API keeps `AccessType=Hidden`; folder sharing remains an admin/UI step |

Promoted reports:

| Report | Source report Id | Promoted report Id | Promoted developer name | Rows | Status |
| --- | --- | --- | --- | ---: | --- |
| `Account and Firmographic` | `00OdL00000PHrzBUAT` | `00OdL00000PKsInUAL` | `Account_and_Firmographic_iIW1` | 18 | pass |
| `Account and Evidence` | `00OdL00000PHtxlUAD` | `00OdL00000PKsXJUA1` | `Account_and_Evidence_4W81` | 140 | pass |
| `Account and Classification` | `00OdL00000PHuKLUA1` | `00OdL00000PKsc9UAD` | `Account_and_Classification_qlX1` | 11 | pass |
| `Account and Corporate Linkage` | `00OdL00000PIt1FUAT` | `00OdL00000PKsaXUAT` | `Account_and_Corporate_Linkage_U4F1` | 2 | pass |
| `Account and Sovereign Identifier` | `00OdL00000PIuerUAD` | `00OdL00000PKsYvUAL` | `Account_and_Sovereign_Identifier_NOY1` | 0 | pass, expected empty |

Source-controlled metadata:

- `force-app/main/default/reports/Pulse360_Account_Intelligence_Validation-meta.xml`
- `force-app/main/default/reports/Pulse360_Account_Intelligence_Validation/*.report-meta.xml`
- `force-app/main/default/dashboards/Pulse360_Account_Intelligence_Validation-meta.xml`
- `force-app/main/default/dashboards/Pulse360_Account_Intelligence_Validation/zZUAzaLhrPFnOpTDCJvUEUvPEQIohz.dashboard-meta.xml`

The source folder metadata intentionally omits user-specific folder shares.
Folder access must be assigned by admin-managed folder sharing or a future
permission/set group decision.

## Salesforce Dashboard Hardening

On `2026-05-08`, the live validation dashboard was retrieved and normalized
into source control.

Dashboard validation:

| Dashboard | Id | Developer name | Folder | Components | Status |
| --- | --- | --- | --- | ---: | --- |
| `Pulse360 Account Intelligence Validation` | `01ZdL00000ABncLUAT` | `zZUAzaLhrPFnOpTDCJvUEUvPEQIohz` | `Pulse360 Account Intelligence Validation` | 10 | pass |

Component design:

- Top scorecard row: Accounts Enriched, Evidence Rows, Classifications,
  Corporate Linkages, and Sovereign IDs.
- Detail table row set: Account and Classification, Account and Corporate
  Linkage, Account and Sovereign Identifier, Account and Evidence, and Account
  and Firmographic.
- The sovereign identifier component intentionally remains visible with no data
  until official registry, tax-authority, or filing evidence satisfies the gate.

Folder visibility:

- Report folder `00ldL00000NixwnQAB` remains `AccessType=Hidden`.
- Dashboard folder `00ldL00000NixyPQAR` remains `AccessType=Hidden`.
- Metadata retrieval showed the current operator user
  `dnortje.37cf563036b7@agentforce.com` has `Manage` folder access in the live
  org.
- Source metadata excludes user-specific `folderShares`, `owner`, and
  `runningUser`; target-org folder sharing remains an admin/UI step.

## Account Activation Closure

On `2026-05-08`, the `DAN-114` Data Cloud to Salesforce Account activation
blocker was revalidated in `pulse360-agent-target`.

Latest evidence:

- Account activation field metadata and live org fields are present.
- The Account sync contract has `31` required fields, `31` mapped fields, no
  missing mappings, and no missing Account target fields.
- `DC Export Accounts P360 V2` is `ACTIVE/SUCCESS`, last refreshed
  `2026-04-29T14:23:19Z`, with `18` processed rows.
- The activation source object
  `pulse360_account_intelligence_export_v2__dll` has `18` rows, `18` distinct
  CRM-safe activation IDs, and `0` duplicate activation IDs.
- `ssot__Account__dlm` has `18` rows, `18` distinct CRM-safe activation IDs,
  and `0` duplicate activation IDs.
- Required supported Copy Field fields are populated in both source and DMO.
- Data Action `Pulse360_Account_Intelligence_Copy_Fields_20xo47` is `ACTIVE`.
- Latest Copy Field job `1A5dL0000001BFxSAM` completed with `18` processed,
  `18` updated, `0` failed, and `0` skipped.
- All `18` Salesforce Account records have populated
  `Unified_Profile_Id__c`, `Identity_Confidence__c`, `Health_Score__c`,
  `Cross_Sell_Propensity__c`, and `DataCloud_Last_Synced__c`.
- The populated Account records show `LastModifiedBy.Name = Platform
  Integration User`, confirming platform/runtime writeback provenance rather
  than manual user repair.

Current interpretation:

- The old duplicate/null DMO row blocker is resolved.
- The old `ActivationTarget` / `MktDataLakeMapping` objects remain empty, but
  the active implementation path is now Data Cloud Copy Field Enrichment from
  `ssot__Account__dlm` to Salesforce `Account`.
- `DAN-114` can close from a runtime evidence standpoint, and `DAN-103` /
  `DAN-61` can proceed to acceptance review.

Latest detailed evidence:

- [dan-59-data-cloud-stream-health-latest.md](/Users/danielnortje/Documents/Pulse360-ai-firmographic-enrichment-v2/docs/evidence/dan-59-data-cloud-stream-health-latest.md)

## Public Regional GPT Enrichment Closure

On `2026-05-08`, `DAN-219` was revalidated against the live
`pulse360-agent-target` org and current source-controlled Salesforce/Data Cloud
contracts.

Current closure position:

- `DAN-220`, `DAN-221`, and `DAN-222` are already closed as prerequisite
  implementation and validation slices.
- `DC Export Accounts P360 V2` remains `ACTIVE/SUCCESS`, with `18` processed
  rows.
- Copy Field Enrichment remains active through Data Action
  `3o9dL0000000IL7QAM`; latest job `1A5dL0000001BFxSAM` completed with `18`
  processed, `18` updated, `0` failed, and `0` skipped.
- Regional GPT sample Accounts for Singapore and the Philippines are present
  with GPT/provenance fields populated where source evidence supports them:
  `Singtel Group`, `NCS Pte. Ltd.`, `Ayala Corporation`, `Ayala Corp.`, and
  `JG Summit Holdings, Inc.`.
- Salesforce runtime surfaces are present: `Pulse360HealthScanService`,
  `pulse360HealthScan`, `pulse360NextBestAction`, `pulse360NarrativeCard`,
  `pulse360GroupRevenueReveal`, `governanceCaseReview`,
  `Account_Record_Page`, and `Governance_Case_Record_Page`.
- Targeted Apex tests for Health Scan and governance decision behavior passed
  `5/5`.

Acceptance caveats:

- Native Copy Field remains limited to the supported scalar/native-compatible
  field set; payload, long-text, and revenue exception fields remain governed
  by the documented exception path.
- Sovereign identifier coverage remains `0`, expected until official registry,
  tax-authority, or filing evidence satisfies the verification gate.
- This closure pass was read-only; no Salesforce deployment, permission change,
  seeded data load, or Data Cloud configuration mutation was performed.

Latest detailed evidence:

- [dan-219-public-regional-gpt-enrichment-closure-2026-05-08.md](/Users/danielnortje/Documents/Pulse360-ai-firmographic-enrichment-v2/docs/evidence/dan-219-public-regional-gpt-enrichment-closure-2026-05-08.md)

## Sovereign Identity Spine Closure

On `2026-05-08`, `DAN-282` was reconciled against the source-controlled
sovereign identifier contract, Databricks export path, Data Cloud DMO setup,
and Salesforce validation surfaces.

Current closure position:

- The sovereign identifier design follows the Salesforce KYC/KYB
  Party Identification pattern: many legal/statutory identifiers per Account
  or Party, with evidence kept separate from the Account scalar activation
  surface.
- `contracts/pulse360_sovereign_identifier.schema.json` defines the governed
  identifier contract and enforces the verified-source guardrail.
- `sql/databricks/gold/40_sovereign_identifier_export.sql` emits only
  sovereign identifier rows, excludes provider/search/CRM identifier types, and
  blocks verified rows unless confidence is at least `0.90` and the source type
  is `official_registry`, `tax_authority`, or `filing`.
- `Pulse360_Sovereign_Identifier__dlm` is live, queryable, related to
  `ssot__Account__dlm`, and represented in the promoted report/dashboard
  validation surface.
- The current row count remains `0`, which is expected and accepted until
  official registry, tax-authority, or filing evidence satisfies the gate.
- The `sovereign_identifier_export_Pulse360_Dat` stream is `ACTIVE/SUCCESS`,
  last refreshed `2026-05-08T06:12:02Z`, with `0` rows processed.

Acceptance caveats:

- `DAN-282` is closed for the first governed spine implementation, not for
  broad sovereign identifier coverage.
- Standard `ssot__PartyIdentification__dlm` remains the preferred semantic
  target where org support allows it; this prototype also uses Pulse360 custom
  extension DMOs for Data Cloud validation and reporting.
- The broad close gate was attempted during this closure pass, but the
  unrelated Databricks SQL governance metrics step returned warehouse
  `HTTP 400` even for `SELECT 1`; targeted sovereign, SQL-pack, GPT-pack, and
  Salesforce UX validators passed.

Latest detailed evidence:

- [dan-282-sovereign-identity-spine-closure-2026-05-08.md](/Users/danielnortje/Documents/Pulse360-ai-firmographic-enrichment-v2/docs/evidence/dan-282-sovereign-identity-spine-closure-2026-05-08.md)

## Milestone C Acceptance Closure

On `2026-05-08`, the remaining Milestone C acceptance blockers were validated
against source-controlled contracts and live MCP checks in
`pulse360-agent-target`.

Current closure position:

- `DAN-116` is satisfied: Salesforce Account, the Data Cloud source object, and
  `ssot__Account__dlm` all preserve the Salesforce `Account.Id` as the
  activation/join key across `18` records.
- `DAN-61` is satisfied for prototype acceptance: calculated insight
  configuration validates, the Data Cloud field path validates, the Copy Field
  job completed `18/18` with no failures, and all target Accounts have synced
  intelligence fields plus `DataCloud_Last_Synced__c`.
- `DAN-103` can close once the Linear blocker links are removed from
  `DAN-116` and `DAN-61`.

Acceptance caveats:

- Sovereign identifier coverage is still `0`, which is expected until official
  registry, tax-authority, or filing evidence passes the verification gate.
- The live activation mechanism is Data Cloud Copy Field Enrichment, not the
  older empty `ActivationTarget` / `MktDataLakeMapping` surface.
- Payload and long-text exceptions remain handled by the documented runbook
  rather than by native Copy Field.

Latest detailed evidence:

- [dan-103-milestone-c-acceptance-2026-05-08.md](/Users/danielnortje/Documents/Pulse360-ai-firmographic-enrichment-v2/docs/evidence/dan-103-milestone-c-acceptance-2026-05-08.md)

## Milestone E Acceptance Closure

On `2026-05-08`, the Milestone E acceptance gate was validated against
source-controlled artifacts plus live Salesforce/Data Cloud and Databricks
runtime evidence.

Current closure position:

- Both Databricks Lakeview dashboards required by `DAN-104` resolve through the
  Databricks API and are `ACTIVE`.
- The Salesforce dashboard `Pulse360 Account Intelligence Validation`
  (`01ZdL00000ABncLUAT`) exists in the hidden validation dashboard folder with
  developer name `zZUAzaLhrPFnOpTDCJvUEUvPEQIohz`.
- The five promoted validation reports exist in the hidden validation report
  folder.
- Data Cloud validation streams are `ACTIVE/SUCCESS` with current
  `2026-05-08` refresh timestamps for firmographic profile, source evidence,
  classification, corporate linkage, sovereign identifier, and activation
  review queue.
- `DC Export Accounts P360 V2` remains `ACTIVE/SUCCESS`, with `18` processed
  rows.
- Salesforce runtime surfaces are present: `Account_Record_Page`, `38`
  `pulse360%` Lightning component bundles, and `18` Account rows with
  `DataCloud_Last_Synced__c`.
- The new closeout gate
  `./scripts/validate-build-deploy-verify-close-gate.sh` passed.

Acceptance caveats:

- Sovereign identifier coverage remains `0`, expected until official registry,
  tax-authority, or filing evidence satisfies the verification gate.
- The gate does not run a Salesforce deploy dry-run by default; that remains
  opt-in after explicit deployment approval.

Latest detailed evidence:

- [dan-104-milestone-e-acceptance-2026-05-08.md](/Users/danielnortje/Documents/Pulse360-ai-firmographic-enrichment-v2/docs/evidence/dan-104-milestone-e-acceptance-2026-05-08.md)

## Milestone B Acceptance Closure

On `2026-05-08`, the older Milestone B Databricks acceptance gate was
revalidated against the live Databricks Lakeview and SQL Warehouse runtime.

Current closure position:

- The main and demo S4 Lakeview dashboards are both `ACTIVE`.
- Both dashboards contain the required DS-01, DS-02, DS-03, and freshness
  visuals, with `7` datasets and `8` widgets each.
- The required Catalog objects exist and return data:
  `governance_ops_metrics`, `duplicate_candidate_pairs`, and
  `firmographic_enrichment`.
- Governance runtime metrics include resolved cases, open backlog, average
  resolution time, and quality score.
- The required gate scripts now exist and pass:
  `./scripts/validate-databricks-dashboard-visuals.sh` and
  `./scripts/validate-governance-ops-metrics-runtime.sh`.
- The broader closeout gate includes both Milestone B validators.

## Milestone B Intelligence Planning Closure

On `2026-05-08`, the older Milestone B intelligence planning tickets `DAN-117`
through `DAN-120` were reconciled against the repo source. The closure evidence
is captured in
`docs/evidence/dan-117-120-milestone-b-intelligence-planning-closure-2026-05-08.md`.

Outcome:

- `DAN-117` is satisfied for the first execution slice by the stewardship
  intelligence blueprint and Databricks output spec.
- `DAN-118` is satisfied for steward trust by explicit duplicate, validity,
  hierarchy, and low-confidence explanation payload requirements.
- `DAN-119` is satisfied for the governance action loop by approve, reject,
  defer, reason capture, and audit requirements.
- `DAN-120` is satisfied for Milestone B by the explainable account truth
  resolution proof-of-value narrative.
- Broader seller, planner, six-module RevOps, and native Agentforce expansion
  remain tracked separately under the future architecture backlog, especially
  `DAN-280`.

Acceptance caveats:

- API validation confirms the dashboards are active, structured, and not empty
  placeholders; it does not replace a human aesthetic browser review.
- Governance metrics are deterministic demo/runtime data and remain
  presentation-safe without rerunning source jobs.

Latest detailed evidence:

- [dan-105-milestone-b-acceptance-2026-05-08.md](/Users/danielnortje/Documents/Pulse360-ai-firmographic-enrichment-v2/docs/evidence/dan-105-milestone-b-acceptance-2026-05-08.md)

## Plural Enrichment Ingestion Closure

On `2026-05-08`, `DAN-283` was closed for the first governed implementation
slice of plural firmographic enrichment ingestion.

Current closure position:

- The repo now contains a source adapter contract for the five enrichment source
  families: national registry, commercial provider Marketplace/Delta Sharing,
  customer-internal, internet research, and clean-room collaboration.
- The sample adapter registry includes one governed adapter per source family.
- Databricks adapter controls require license/use basis, lineage, run metadata,
  raw payload references, xref-only commercial provider IDs, aggregate-by-default
  clean-room outputs, and official-source gates for sovereign identifiers.
- The research document contract and fixture now carry `source_family` and
  `source_adapter_id`.
- Silver extraction scoring recognizes registry, filing, Marketplace, internal,
  and clean-room source types without adding a paid provider dependency.

Acceptance caveats:

- Marketplace, internal-system, and clean-room adapters remain contract-gated
  until the customer approves the relevant entitlement or data-sharing path.
- Internet research remains the active demo source family for GPT enrichment.
- Weighted attribute resolution remains tracked separately under `DAN-285`.

Latest detailed evidence:

- [dan-283-plural-enrichment-ingestion-closure-2026-05-08.md](/Users/danielnortje/Documents/Pulse360-ai-firmographic-enrichment-v2/docs/evidence/dan-283-plural-enrichment-ingestion-closure-2026-05-08.md)

## Weighted Attribute Resolution Closure

On `2026-05-08`, `DAN-285` was closed for the first governed implementation
slice of weighted firmographic attribute resolution.

Current closure position:

- The repo now contains a weighted attribute resolution contract and sample.
- Databricks rules define source type weights, source family identity policies,
  survivorship defaults, and required contribution controls.
- The firmographic enrichment SQL package now emits
  `pulse360_s4.silver_firmographic.source_contribution` and
  `pulse360_s4.silver_firmographic.weighted_attribute_resolution`.
- Each weighted attribute candidate carries source contribution JSON, source
  refs, license/contract refs, freshness, conflict count, confidence, run ID,
  and model version.
- The firmographic GPT package validator now includes the weighted attribute
  resolution gate.

Acceptance caveats:

- This is a deterministic contract/SQL slice and does not change Data Cloud
  export tables yet.
- Live Databricks SQL execution remains subject to SQL Warehouse availability.
- Live model serving endpoint creation and Salesforce BYOM setup remain runtime
  gates, while the source-controlled feature/model plan is tracked under
  `DAN-286`.

Latest detailed evidence:

- [dan-285-weighted-attribute-resolution-closure-2026-05-08.md](/Users/danielnortje/Documents/Pulse360-ai-firmographic-enrichment-v2/docs/evidence/dan-285-weighted-attribute-resolution-closure-2026-05-08.md)

## Six Module Delivery Sequence Closure

On `2026-05-08`, `DAN-291` was closed for the six-module RevOps Intelligence
delivery sequence.

Current closure position:

- The selected first delivery slice is `M1 Account Hierarchy Intelligence`.
- M1 is sequenced first because it uses the validated account identity,
  firmographic profile, corporate linkage, evidence, Data Cloud, and Salesforce
  report/dashboard foundation already present in the build.
- The durable sequence contract is source-controlled in
  `config/databricks/revops-module-delivery-sequence.json`.
- `M2`, `M3`, `M5`, and `M6` depend on the `DAN-286` feature engineering,
  model serving, and Salesforce BYOM plan, which is now source-controlled.
- `M4` remains gated by contact/person, role, and consent source availability.

Acceptance caveats:

- This is a source-only sequencing closure. It does not deploy Salesforce
  metadata, change Data Cloud relationships, run Databricks jobs, or mutate
  target-org configuration.
- Native Agentforce claims remain gated until target-org runtime support is
  proven.
- Live Databricks SQL execution remains subject to SQL Warehouse availability.

Latest detailed evidence:

- [dan-291-six-module-delivery-sequence-closure-2026-05-08.md](/Users/danielnortje/Documents/Pulse360-ai-firmographic-enrichment-v2/docs/evidence/dan-291-six-module-delivery-sequence-closure-2026-05-08.md)

## Feature, Model Serving, and BYOM Plan Closure

On `2026-05-08`, `DAN-286` was closed for the source-controlled feature
engineering, model serving, and Salesforce BYOM plan.

Current closure position:

- The repo now contains feature snapshot and model score output contracts.
- The first planned model family is `icp_fit`.
- The default runtime posture is batch-first Data Cloud enrichment, with
  real-time Databricks serving and Salesforce BYOM explicitly gated.
- The Databricks package workspace generator now includes a
  `pulse360-model-serving-byom` bundle.
- Model score output requires score, confidence, score band, top drivers,
  explanation text, model version, run ID, score timestamp, and activation
  eligibility.

Acceptance caveats:

- This is a source-controlled plan and SQL-contract closure, not a live endpoint
  deployment.
- Salesforce BYOM remains gated by target-org entitlement, endpoint
  connectivity, authentication, and output mapping.
- Live Databricks SQL execution remains subject to SQL Warehouse availability.

Latest detailed evidence:

- [dan-286-feature-model-byom-closure-2026-05-08.md](/Users/danielnortje/Documents/Pulse360-ai-firmographic-enrichment-v2/docs/evidence/dan-286-feature-model-byom-closure-2026-05-08.md)

## Governance Evidence Closure

On `2026-05-08`, `DAN-290` was closed for the source-controlled governance,
lineage, audit, and regulator evidence slice.

Current closure position:

- The repo now contains a governance evidence packet contract and sample.
- Governance gates require Unity Catalog lineage, source contribution,
  feature/model lineage, Data Cloud mapping, Salesforce audit, Governance Case
  decision audit, LLM audit metadata, and provider/license evidence when
  applicable.
- The Databricks package workspace generator now includes a
  `pulse360-governance-evidence` bundle.
- Unity Catalog governance config now includes feature snapshot, model score,
  and governance evidence tables.
- Evidence packets distinguish demo readiness from external audit readiness.

Acceptance caveats:

- This is a source-controlled evidence contract and runbook closure, not a live
  runtime lineage export.
- Live Unity Catalog lineage remains pending until the Databricks SQL Warehouse
  issue is resolved and CLI/API lineage output is captured.
- Salesforce and Data Cloud runtime audit evidence should be captured without
  changing relationships or folder sharing.

Latest detailed evidence:

- [dan-290-governance-evidence-closure-2026-05-08.md](/Users/danielnortje/Documents/Pulse360-ai-firmographic-enrichment-v2/docs/evidence/dan-290-governance-evidence-closure-2026-05-08.md)

## Final Acceptance Gate Closure

On `2026-05-08`, `DAN-292` was closed for the final feasible architecture
acceptance/readout gate under `DAN-280`.

Current closure position:

- The architecture stack is ready for M1 implementation scope with runtime
  gates.
- The final readout distinguishes `built`, `feasible`, `gated`, and `roadmap`
  claims.
- The selected first module remains `M1 Account Hierarchy Intelligence`.
- The next delivery branch should focus on hierarchy foundation, group context,
  corporate linkage evidence, governance evidence packet generation, and
  Salesforce dashboard/report validation.

Acceptance caveats:

- No live Salesforce BYOM success is claimed.
- No native Agentforce runtime success is claimed.
- No external audit readiness is claimed.
- No paid provider integration is claimed.
- No automatic steward merge execution is claimed.

Latest detailed evidence:

- [dan-292-final-acceptance-gate-closure-2026-05-08.md](/Users/danielnortje/Documents/Pulse360-ai-firmographic-enrichment-v2/docs/evidence/dan-292-final-acceptance-gate-closure-2026-05-08.md)
