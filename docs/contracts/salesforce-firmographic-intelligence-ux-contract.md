# Salesforce Firmographic Intelligence UX Contract

## Purpose

Define the Salesforce-facing UX layer for the GPT-enriched firmographic Data
Cloud model. This layer validates and presents governed Data Cloud intelligence;
it does not make Salesforce CRM the system of record for enriched facts.

## Boundary

Owned by Databricks/Data Cloud:

- Firmographic facts and summaries.
- Source evidence, source URLs, retrieval timestamps, confidence, and conflicts.
- Sovereign identifiers and verification status.
- Company classifications and corporate linkages.

Owned by Salesforce CRM:

- Account page placement.
- Report/dashboard presentation.
- Permission set assignment.
- Stewardship decisions and execution workflow.

Salesforce must not directly edit Data Cloud evidence or GPT-derived facts.

## Live Data Cloud Inputs

| DMO | Purpose | Account join |
| --- | --- | --- |
| `Pulse360_Firmographic_Profile__dlm` | One current profile row per Account | `source_account_id__c -> Account.Id` |
| `Pulse360_Firmographic_Source_Evidenc__dlm` | Source-bound evidence rows | `source_account_id__c -> Account.Id` |
| `Pulse_360_Company_Classification__dlm` | Sparse industry/category rows | `source_account_id__c -> Account.Id` |
| `Pulse360_Corporate_Linkage__dlm` | Source-backed parent/subsidiary rows | `source_account_id__c -> Account.Id` |
| `Pulse360_Sovereign_Identifier__dlm` | Verified sovereign identifiers only | `source_account_id__c -> Account.Id` |

The generated Data Cloud relationship fields must remain present but are not
hard-coded into Apex or LWC source because Data Cloud generates those names per
org setup.

## Report Set

The minimum validation report set is defined in
`config/salesforce/firmographic-intelligence-reports.csv`.

Reports must:

- Live in a shared Pulse360 folder before being treated as release artifacts.
- Show Account fields as Salesforce record links, not copied raw labels only.
- Include confidence, source URL, and freshness fields wherever a GPT-derived
  field is shown.
- Keep the Sovereign Identifier report even when it returns zero rows; zero is a
  meaningful control result until official-source evidence passes the gate.

## Dashboard

The dashboard target is `Pulse360 Account Intelligence Validation`.

Required tiles:

- Account enrichment coverage.
- Evidence coverage.
- Classification coverage.
- Corporate linkage coverage.
- Sovereign identifier coverage, with zero treated as expected when no official
  evidence has passed the gate.
- Detail tables for the five validation reports.

## Account Page Placement

Use the existing Account record page as the CRM surfacing point, but keep the
new Data Cloud firmographic view as a focused read-only section rather than
folding it into decision controls.

The planned section contract is captured in
`config/salesforce/account-firmographic-intelligence-surface.yaml`.

Recommended layout:

1. Main column: Firmographic profile summary, latest financial/investor summary,
   and confidence/freshness badges.
2. Main column: Related lists or embedded reports for classification and
   corporate linkage.
3. Sidebar: Evidence/provenance panel showing source type, URL, excerpt,
   retrieved timestamp, and model version.
4. Stewardship or decision actions remain separate from read-only evidence.

## Permission Contract

Minimum user access:

- Read `Account`.
- Read the five Pulse360 Data Cloud DMOs.
- Run the five validation reports.
- View the Pulse360 validation dashboard.

Do not grant edit access to DMO-derived evidence or enriched fields. If a future
CRM writeback surface is added, it must use separate stewardship fields and a
documented approval path.

## Validation Gates

Before claiming the Salesforce UX layer is complete:

1. Data streams are `ACTIVE` and latest import status is `SUCCESS`.
2. DLO row counts match Databricks export counts.
3. Five reports execute through the Analytics REST API.
4. Report row counts match the expected control counts in the CSV contract.
5. DMO fields include source URL, confidence, freshness, and Account join keys.
6. Account page design keeps read-only intelligence separate from stewardship
   execution.
