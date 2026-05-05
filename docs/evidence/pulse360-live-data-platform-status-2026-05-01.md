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
