# DAN-282 Sovereign Identity Spine Closure - 2026-05-08

## Scope

This note records the closure evidence for `DAN-282`: design and build the
sovereign identity spine for account resolution.

The closure is for the first governed implementation slice:

- source-controlled sovereign identifier contract
- official-source identifier taxonomy and validation rules
- Databricks gold export path
- Data Cloud DLO/DMO setup and relationship rules
- Salesforce validation report/dashboard visibility
- runtime evidence that the zero-count sovereign identifier state is expected
  and safely handled

No Salesforce metadata deployment, permission change, folder sharing change,
seeded data load, or Data Cloud configuration mutation was performed as part of
this closure pass.

## Design Boundary

The adopted design anchors external account identity on regulator-issued or
legally recognized identifiers, not commercial provider IDs.

Sovereign identifier rows must satisfy these rules:

- `source_account_id` remains the CRM-safe Salesforce `Account.Id` join key.
- Each identifier row has a deterministic `identifier_id`, `party_id`, and
  jurisdiction-specific `identifier_type`.
- Provider IDs, CRM IDs, website IDs, social IDs, and search-result IDs are not
  sovereign identifiers.
- Verified identifiers require source type `official_registry`,
  `tax_authority`, or `filing`.
- Verified identifiers require `confidence >= 0.90`.
- Every non-empty identifier value requires a source URL, source name,
  source type, last verified timestamp, run id, and model version.

## Source-Controlled Artifacts

| Layer | Artifact | Closure relevance |
| --- | --- | --- |
| Design | `docs/design/pulse360-sovereign-identifier-and-firmographic-data-cloud-design.md` | Defines the Salesforce KYC/KYB-aligned Party Identification pattern, identifier taxonomy, and strict GPT extraction rules. |
| Contract | `contracts/pulse360_sovereign_identifier.schema.json` | Enforces identifier fields, official source types, confidence range, and verified identifier guardrail. |
| Data Cloud setup | `config/data-cloud/sovereign-identifier-firmographic-dmo-design.csv` | Maps Account, Party, Party Identification, identifier evidence, and firmographic extension concepts. |
| Data Cloud setup | `config/data-cloud/sovereign-firmographic-dlo-dmo-setup.csv` | Documents DLO/DMO setup for the sovereign identifier export and related firmographic exports. |
| GPT prompt | `config/openai/pulse360-sovereign-firmographic-enrichment-prompt.json` | Rejects provider/search/CRM IDs as sovereign identifiers and requires official evidence for verified identifiers. |
| Gold SQL | `sql/databricks/gold/40_sovereign_identifier_export.sql` | Filters GPT identifiers to sovereign-only rows and blocks verified rows without official source evidence. |
| Runbook | `docs/runbook/pulse360-sovereign-firmographic-data-cloud-setup-runbook.md` | Captures org-locked Data Cloud setup and validation steps. |
| Salesforce UX | `config/salesforce/firmographic-intelligence-reports.csv` | Keeps the Account and Sovereign Identifier validation report visible with expected zero rows. |
| Dashboard | `force-app/main/default/dashboards/Pulse360_Account_Intelligence_Validation/zZUAzaLhrPFnOpTDCJvUEUvPEQIohz.dashboard-meta.xml` | Keeps the sovereign identifier coverage component visible as a control. |

## Runtime Evidence

The live `pulse360-agent-target` runtime supports the spine:

| Runtime check | Result |
| --- | --- |
| Sovereign identifier DMO | `Pulse360_Sovereign_Identifier__dlm` exists and is queryable. |
| Data stream | `sovereign_identifier_export_Pulse360_Dat` is `ACTIVE/SUCCESS`, last refreshed `2026-05-08T06:12:02.000+0000`. |
| Row count | `0`, expected until official registry, tax-authority, or filing evidence satisfies the gate. |
| DMO relationship | `Pulse360_Sovereign_Identifier__dlm.source_account_id__c -> ssot__Account__dlm.ssot__Id__c` exists as `ManyToOne`. |
| Salesforce report | `Account and Sovereign Identifier` exists and returns `0` rows without join errors. |
| Dashboard component | Sovereign identifier component renders as an expected no-data control. |

The current zero-count state is not a failure. It proves that the system does
not promote unsupported CRM IDs, provider IDs, search IDs, or weak web evidence
into sovereign Party Identification-style rows.

## Validation Commands

The following validators cover the sovereign identity spine:

```bash
./scripts/validate-sovereign-firmographic-design.sh
./scripts/validate-databricks-salesforce-sql-pack.sh
./scripts/validate-databricks-firmographic-genai-pack.sh
./scripts/validate-salesforce-firmographic-ux-pack.sh
git diff --check
```

Validation result on `2026-05-08`:

- sovereign and firmographic design validator passed
- Databricks Salesforce SQL pack validator passed
- firmographic GPT package validator passed
- Salesforce firmographic UX pack validator passed
- `git diff --check` passed

The broader close gate was attempted after this doc update, but the Databricks
SQL warehouse API returned `HTTP 400` for the unrelated governance runtime
metrics check. A direct `SELECT 1` against warehouse `7052914888c7e86c`
returned the same error while Databricks workspace API access still worked.
This is treated as an external SQL warehouse availability issue, not a
sovereign identifier contract failure.

## Acceptance Decision

`DAN-282` is satisfied for the first implementation slice.

Completed:

- sovereign identifier schema and taxonomy
- strict official-source verified gate
- no-provider-ID and no-CRM-ID guardrails
- Databricks export path
- Data Cloud DMO and Account relationship path
- Salesforce report/dashboard validation surface
- runtime handling of expected zero sovereign identifier coverage

Accepted caveats:

- Actual sovereign identifier population remains dependent on official
  registry, tax-authority, or filing evidence.
- The design currently uses Pulse360 custom extension DMOs where standard
  `ssot__PartyIdentification__dlm` support is org-dependent.
- Verified identifier extraction should remain sparse by design until the
  research/evidence job retrieves authoritative sources.

Recommended Linear outcome: move `DAN-282` to Done.
