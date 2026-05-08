# DAN-285 Weighted Attribute Resolution Closure - 2026-05-08

## Scope

This note records the closure evidence for `DAN-285`: define weighted attribute
resolution and source contribution metadata contracts.

The closure is for the first governed implementation slice:

- source-controlled weighted attribute resolution contract
- source contribution sample payload
- Databricks weighting and survivorship rule configuration
- deterministic SQL views for contribution scoring and attribute survivorship
- validator coverage for source weights, contribution scores, freshness,
  conflict counts, license references, and run metadata

No Salesforce metadata deployment, permission change, folder sharing change,
seeded data load, Data Cloud configuration mutation, paid provider connector, or
Databricks external connector setup was performed as part of this closure pass.

## Design Boundary

Weighted attribute resolution runs before downstream GPT narrative and before
Data Cloud/Salesforce promotion. The layer decides which candidate source fact
can become a served value and preserves why that decision was made.

Each resolved attribute carries:

- deterministic `attribute_resolution_id`
- entity/account anchor
- attribute path and winning value
- winning source ID and source family
- survivorship rule
- confidence and freshness status
- source contribution count
- conflict count
- full source contribution metadata
- source refs and license/contract refs
- run ID and model version

This keeps deterministic survivorship in Databricks while GPT remains a
source-bound extraction and explanation layer.

## Source-Controlled Artifacts

| Layer | Artifact | Closure relevance |
| --- | --- | --- |
| Contract | `contracts/weighted_attribute_resolution.schema.json` | Defines resolved attribute fields and required source contribution metadata. |
| Sample | `data/samples/weighted_attribute_resolution_sample.json` | Shows a corroborated annual revenue attribute with one selected source and one lower-scoring contribution. |
| Databricks config | `config/databricks/weighted-attribute-resolution-rules.json` | Defines source type weights, source family identity rules, survivorship defaults, and required controls. |
| Silver SQL | `sql/databricks/firmographic_enrichment/25_weighted_attribute_resolution.sql` | Creates `source_contribution` and `weighted_attribute_resolution` views. |
| Validator | `scripts/validate-weighted-attribute-resolution.sh` | Validates contribution metadata, source weights, selected contribution semantics, SQL tokens, and no hardwired paid providers. |
| Pack validator | `scripts/validate-databricks-firmographic-genai-pack.sh` | Wires weighted attribute validation into the broader firmographic GPT package gate. |
| Package manifest | `config/packages/databricks/firmographic-enrichment.members.txt` | Includes the new contracts, config, sample, SQL, and validators in the Databricks package workspace. |

## Acceptance Evidence

`DAN-285` is satisfied for the first weighted attribute implementation slice:

- every served attribute candidate has source contribution metadata
- source type weights are explicitly configured
- source contribution scores combine source confidence, source weight,
  freshness, and field completeness
- survivorship uses `highest_weighted_confidence` by default, with official
  source and aggregate-only rules available for registry and clean-room cases
- conflict counts are calculated from distinct candidate values
- source refs and license/contract refs are preserved as JSON arrays
- paid-provider endpoints or vendor-specific runtime dependencies are not
  hardwired into the repo

## Validation Commands

The following validators cover this closure:

```bash
./scripts/validate-weighted-attribute-resolution.sh
./scripts/validate-databricks-firmographic-genai-pack.sh
./scripts/validate-databricks-salesforce-sql-pack.sh
./scripts/validate-databricks-package-layout.sh
git diff --check
```

Accepted caveats:

- The current SQL slice is fixture-backed and contract-oriented; it is ready for
  Databricks execution once the SQL Warehouse availability issue is resolved.
- Data Cloud export tables are unchanged in this slice; downstream promotion of
  weighted attributes remains an explicit follow-on.
- Model serving and BYOM feature tables remain tracked under `DAN-286`.
- Cross-platform lineage and audit hardening remain tracked under `DAN-290`.

Recommended Linear outcome: move `DAN-285` to Done.
