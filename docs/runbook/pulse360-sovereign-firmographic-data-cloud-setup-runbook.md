# Pulse360 Sovereign Identifier and Firmographic Data Cloud Setup Runbook

Date: 2026-05-01

## Scope

This runbook converts the sovereign identifier and firmographic gold exports
into Data Cloud DLO/DMO setup. It is intentionally runbook-driven because Data
Cloud object creation, mapping, and identity-resolution setup can be org-locked
and not fully deployable through standard `sf project deploy`.

No production development is assumed. Run this only in a scratch org or sandbox
after the source artifacts have been reviewed.

## Source Artifacts

| Artifact | Purpose |
| --- | --- |
| `contracts/pulse360_sovereign_identifier.schema.json` | Contract for legal/statutory identifier rows |
| `contracts/pulse360_firmographic_enrichment_output.schema.json` | Contract for GPT/provider enrichment output |
| `config/data-cloud/sovereign-identifier-firmographic-dmo-design.csv` | Logical DMO field design |
| `config/data-cloud/sovereign-firmographic-dlo-dmo-setup.csv` | Export-to-DLO/DMO setup matrix |
| `config/openai/pulse360-sovereign-firmographic-enrichment-prompt.json` | GPT enrichment guardrails |
| `data/samples/databricks_gold_*_export.csv` | Databricks gold export samples |

## Target Objects

| Export | DLO | DMO |
| --- | --- | --- |
| `databricks_gold_sovereign_identifier_export.csv` | `Pulse360_SovereignIdentifier__dll` | `ssot__PartyIdentification__dlm` |
| `databricks_gold_firmographic_profile_export.csv` | `Pulse360_FirmographicProfile__dll` | `Pulse360_Firmographic_Profile__dlm` |
| `databricks_gold_company_classification_export.csv` | `Pulse360_CompanyClassification__dll` | `Pulse360_Company_Classification__dlm` |
| `databricks_gold_corporate_linkage_export.csv` | `Pulse360_CorporateLinkage__dll` | `Pulse360_Corporate_Linkage__dlm` |
| `databricks_gold_firmographic_source_evidence_export.csv` | `Pulse360_FirmographicSourceEvidence__dll` | `Pulse360_Firmographic_Source_Evidence__dlm` |

## Setup Steps

1. Validate source contracts locally:

   ```bash
   ./scripts/validate-sovereign-firmographic-design.sh
   ./scripts/validate-contracts.sh
   ```

2. Create or refresh the Data Cloud data streams for the five gold export CSVs.
   The preferred source is the Databricks gold export location for the active
   environment. The sample CSVs are for contract validation only.

3. Create DLOs using the names in
   `config/data-cloud/sovereign-firmographic-dlo-dmo-setup.csv`.

4. Map `Pulse360_SovereignIdentifier__dll` to
   `ssot__PartyIdentification__dlm` where the org supports standard Party
   Identification. Required mappings:

   | Source field | Target field |
   | --- | --- |
   | `identifier_id` | `ssot__Id__c` |
   | `party_id` | `ssot__PartyId__c` |
   | `identifier_type` | `ssot__PartyIdentificationTypeId__c` |
   | `identifier_name` | `ssot__Name__c` |
   | `normalized_identifier_value` | `ssot__Identificationnumber__c` |
   | `issuing_authority` | `ssot__IssuedByAuthority__c` |
   | `issued_at_location` | `ssot__IssuedAtLocation__c` |
   | `issued_date` | `ssot__IssuedDate__c` |
   | `expiry_date` | `ssot__ExpiryDate__c` |
   | `last_verified_at` | `ssot__VerifiedDate__c` |

5. Map the extension DMOs from the design CSV. Keep field-level evidence in
   `Pulse360_Firmographic_Source_Evidence__dlm`; do not flatten evidence into
   Salesforce Account fields.

6. Configure identity resolution so `ssot__PartyIdentification__dlm` contributes
   only legal/statutory identifiers. Provider IDs, CRM Account IDs, web profile
   IDs, and social IDs are not sovereign identifiers and must remain in evidence
   or source lineage only.

7. Validate a sandbox data load:

   - every sovereign identifier has a source URL and confidence
   - verified sovereign identifiers are backed by official registry, tax, or
     filing evidence
   - every investor summary has at least one source URL
   - `location_type` uses the controlled values from the contract
   - child rows reference a known `source_account_id` and `party_id`

## CRM Activation

Do not activate the full sovereign identifier and firmographic evidence model
directly into Salesforce Account. CRM should receive only curated summary fields
already governed by the Account activation contract. Full evidence, investor
summaries, source URLs, and conflict metadata should remain in Data Cloud and
Databricks unless a separate UX requirement is approved.

## Rollback

If setup is wrong in a sandbox:

1. Stop the affected Data Cloud data streams.
2. Remove the DLO-to-DMO mappings created for this slice.
3. Delete the test DLOs/DMOs only after confirming they are not reused by other
   mappings.
4. Re-run the local validators before recreating mappings.

Do not run destructive Data Cloud cleanup in production from this runbook.
