# DAN-283 Plural Enrichment Ingestion Closure - 2026-05-08

## Scope

This note records the closure evidence for `DAN-283`: build the plural
enrichment ingestion plan across registries, Marketplace/commercial sources,
customer-internal systems, internet research, and clean-room collaboration
outputs.

The closure is for the first governed implementation slice:

- source-controlled source adapter contract
- five-family adapter sample registry
- Databricks adapter configuration controls
- research document contract extension for source family and adapter IDs
- source reliability scoring support for the new approved source types
- validator coverage that rejects paid-provider hardwiring and unsafe identity
  semantics

No Salesforce metadata deployment, permission change, folder sharing change,
seeded data load, paid provider connector, Data Cloud configuration mutation, or
Databricks external connector setup was performed as part of this closure pass.

## Design Boundary

Pulse360 enrichment is plural, but governed. Each source family contributes
evidence under explicit identity, license, retention, and lineage rules:

| Source family | Primary ingestion mode | Identity rule | Current status |
| --- | --- | --- | --- |
| National registries and regulator filings | Registry snapshot or filing extract | May produce sovereign identifier candidates only when official-source evidence passes gates. | Demo adapter approved. |
| Commercial providers through Marketplace or Delta Sharing | Marketplace Delta Share or Delta Sharing | Provider IDs are xrefs only and never replace CRM or sovereign keys. | Contract-gated. |
| Customer-internal systems | Lakeflow Connect or approved connector | Joins through CRM-safe keys or approved internal xrefs only. | Contract-gated. |
| Internet research and document extraction | Governed public URL/PDF extraction | Evidence-only unless official source confidence gates are met. | Demo adapter approved. |
| Clean-room collaboration | Clean-room output tables | Aggregate signal by default; row-level identity is disabled unless separately approved. | Contract-gated. |

This keeps the current OpenAI enrichment path source-bound without introducing a
paid provider dependency or treating provider/search IDs as sovereign identity.

## Source-Controlled Artifacts

| Layer | Artifact | Closure relevance |
| --- | --- | --- |
| Contract | `contracts/firmographic_source_adapter.schema.json` | Defines the governed source adapter fields, five source-family enum, identity-key policy, license/use basis, retention, lineage, and run metadata requirements. |
| Sample registry | `data/samples/firmographic_source_adapters.json` | Provides one governed adapter example for each of the five source families. |
| Databricks config | `config/databricks/firmographic-source-adapters.json` | Captures default controls for raw-payload references, run metadata, license refs, lineage, commercial xref-only IDs, clean-room aggregate defaults, and official-source sovereign identifiers. |
| Research contract | `contracts/firmographic_research_document.schema.json` | Extends approved research documents with `source_family`, `source_adapter_id`, and source types for registry, filing, Marketplace, internal, and clean-room outputs. |
| Research fixture | `data/samples/firmographic_research_document_sample.json` | Anchors the existing Ayala public-report fixture to the internet research adapter. |
| Bronze SQL | `sql/databricks/firmographic_enrichment/05_raw_research_document_sample.sql` | Emits the research fixture with source family and adapter ID. |
| Silver SQL | `sql/databricks/firmographic_enrichment/15_extracted_firmographic_fact.sql` | Adds source reliability scoring for approved registry, filing, Marketplace, internal, and clean-room source types. |
| Validator | `scripts/validate-firmographic-source-adapters.sh` | Validates five-family coverage, source IDs, run metadata, lineage, commercial xref-only controls, registry sovereign-only controls, clean-room aggregate defaults, and no hardwired paid providers. |
| Pack validator | `scripts/validate-databricks-firmographic-genai-pack.sh` | Wires the adapter contract into the broader firmographic GPT validation gate. |

## Acceptance Evidence

`DAN-283` is satisfied for the governed ingestion planning and contract layer:

- all five enrichment source families are represented in source control
- source adapters define license/use basis, retention, lineage, run metadata,
  and approved fact types
- commercial provider identifiers are constrained to xref-only semantics
- clean-room outputs are aggregate-only by default
- official registry and filing sources are the only source family allowed to
  become sovereign identifier candidates
- internet research remains the active demo path and is anchored to source
  family plus adapter metadata
- no paid provider endpoint, vendor-specific runtime, or connector dependency is
  hardwired into the repo

## Validation Commands

The following validators cover this closure:

```bash
./scripts/validate-firmographic-source-adapters.sh
./scripts/validate-databricks-firmographic-genai-pack.sh
./scripts/validate-sovereign-firmographic-design.sh
./scripts/validate-databricks-salesforce-sql-pack.sh
git diff --check
```

Accepted caveats:

- The Marketplace, customer-internal, and clean-room adapters are governed
  contracts only until commercial terms, customer approval, or collaboration
  agreements exist.
- The first live enrichment runtime still uses CRM plus governed public research
  inputs.
- Weighted attribute resolution and source contribution scoring remain owned by
  `DAN-285`.
- Data Cloud DMO relationship changes are not required for this closure.

Recommended Linear outcome: move `DAN-283` to Done.
