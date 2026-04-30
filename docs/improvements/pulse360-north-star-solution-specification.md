# Pulse360 North Star — Solution Specification

## Document Purpose

This specification defines exactly what needs to be kept, added, and changed to evolve the Pulse360 prototype from a closed-loop data quality demo into an externally-enriched, Gen AI-powered account intelligence platform.

It is designed to be handed directly to Claude Code for implementation planning. Each item includes the current state, target state, platform, and build guidance.

**Date:** 2026-03-28
**Scope:** Prototype evolution — not production architecture
**Assumes:** The existing Pulse360 repo, Salesforce org, Databricks workspace, and Data Cloud configuration remain the baseline

---

## 1. What to Keep — Proven Foundation

These assets are validated, working, and form the stable base the north star builds on. Do not rebuild, replace, or refactor these unless a specific change item below requires modification.

### 1.1 Databricks Silver Layer — KEEP AS-IS

| Asset | Status | Notes |
|---|---|---|
| `10_crm_account.sql` | Source-backed | CRM-safe key preservation proven |
| `20_crm_contact.sql` | Source-backed | Contact context for enrichment |
| `30_crm_opportunity.sql` | Source-backed | Commercial signal base |
| `40_crm_opportunity_contact_role.sql` | Source-backed | Relationship context |
| `50_crm_product.sql` | Source-backed | Product ownership context |
| `60_crm_opportunity_line_item.sql` | Source-backed | Revenue detail |
| `70_crm_account_contact_bridge.sql` | Source-backed | Multi-contact relationships |
| `80_crm_account_hierarchy_edge.sql` | Source-backed | Hierarchy base from CRM |

**Rationale:** The silver normalization layer correctly preserves `crm_account_id` as the deterministic key. The broad CRM source domain ingestion (not just Account) was a deliberate design decision that now pays off — the north star needs all of these domains for Gen AI reasoning context.

### 1.2 Databricks Gold Export — KEEP WITH EXTENSIONS (see §2.2)

| Asset | Status | Notes |
|---|---|---|
| `10_account_export_base.sql` | Source-backed | Core export logic |
| `20_account_core_export.sql` | Source-backed | Account-level consolidation |
| `30_datacloud_export_accounts.sql` | Source-backed | Data Cloud handoff table |

**Rationale:** The gold export contract structure is correct. The materialized export table approach is proven. Extensions (§2.2) add new columns — they do not replace the existing structure.

### 1.3 Integration Contracts — KEEP WITH EXTENSIONS (see §3.1)

| Contract | Status | Notes |
|---|---|---|
| Salesforce CRM → Databricks ingestion contract | Source-backed | Defines CRM source domains |
| Databricks → Data Cloud export contract | Source-backed | Defines export schema |
| Data Cloud → Salesforce/Agentforce contract | Source-backed | Defines CRM sync fields |
| Governance case UX and implementation spec | Source-backed | DS-02 workflow definition |

**Rationale:** The contract-first design principle is one of the prototype's genuine strengths. Contracts will be extended (not replaced) to cover external enrichment fields and Gen AI outputs.

### 1.4 Data Cloud Configuration — KEEP AS-IS

| Element | Status | Notes |
|---|---|---|
| Stream ingest from Databricks export | Runtime-validated | Health confirmed |
| DLO and DMO mapping | Runtime-validated | Values verified for live account IDs |
| Copy Field Enrichment to Salesforce Account | Runtime-validated | **The proven CRM realization mechanism** |

**Rationale:** Copy Field Enrichment is the validated CRM sync path. The north star does not change this mechanism — it adds more fields to sync through the same proven channel.

### 1.5 Salesforce Governance Case — KEEP AS-IS

| Asset | Status | Notes |
|---|---|---|
| `Governance_Case__c` object metadata | Source-backed | Stewardship data model |
| Governance validation rules | Source-backed | Approve/reject/defer enforcement |
| Governance review LWC | Source-backed | Side-by-side comparison UI |
| Governance record page (flexipage) | Source-backed | Stewardship layout |
| Governance steward permission set | Source-backed | Access control |
| Governance tab | Source-backed | Navigation |
| Governance case fixture seeding | Source-backed | Demo data setup |

**Rationale:** DS-02 is the most complete scenario. The governance case object, workflow, and LWC are the prototype's strongest implementation asset. The north star enhances the evidence displayed (§2.5) but does not change the governance model itself.

### 1.6 Salesforce Account Fields — KEEP WITH EXTENSIONS (see §3.3)

| Field | Status | Notes |
|---|---|---|
| `Unified_Profile_Id__c` | Source-backed | Identity key |
| `Identity_Confidence__c` | Source-backed | Trust indicator |
| `Group_Revenue_Rollup__c` | Source-backed | Group commercial context |
| `Health_Score__c` | Source-backed | Account health |
| `Cross_Sell_Propensity__c` | Source-backed | Commercial signal |
| `Coverage_Gap_Flag__c` | Source-backed | Whitespace indicator |
| `Competitor_Risk_Signal__c` | Source-backed | Competitive intelligence |
| `Primary_Brand_Name__c` | Source-backed | Brand context |
| `Active_Product_Count__c` | Source-backed | Product coverage |
| `Engagement_Intensity_Score__c` | Source-backed | Activity signal |
| `Open_Opportunity_Count__c` | Source-backed | Pipeline context |
| `Last_Engagement_Timestamp__c` | Source-backed | Recency |
| `DataCloud_Last_Synced__c` | Source-backed | Provenance |

**Rationale:** These fields are the current Account 360 intelligence surface. They remain. New fields (§3.3) will be added alongside them.

### 1.7 Validation Scripts — KEEP AS-IS

| Script | Purpose |
|---|---|
| Contract validation | Enforces interface contracts between platforms |
| Databricks and SQL-pack validation | Silver/gold layer correctness |
| Salesforce account activation-field validation | CRM field presence checks |
| Hierarchy and identity validation | Key preservation checks |
| Governance case metadata validation | Stewardship model correctness |
| Data Cloud insight configuration validation | DC setup checks |

**Rationale:** Validation scripts are design enforcement. They should be extended (not replaced) as new capabilities are added.

---

## 2. What to Add — New Capabilities

These are net-new assets that do not exist in the current prototype. Each addresses a specific gap identified in the critical review.

### 2.1 External Data Ingestion Layer (Databricks Bronze)

**Gap addressed:** GIGO — the prototype has no external data sources.
**Platform:** Databricks
**Priority:** High — this breaks the closed loop

#### 2.1.1 Philippine SEC Corporate Registry Connector

**Purpose:** Pull legal entity data for Philippine target accounts.

**Data source:** Philippine SEC company registry (publicly accessible via iReports portal and EDGAR-like filings for listed companies).

**Target schema — bronze table: `bronze_external.sec_ph_entities`**

| Column | Type | Description |
|---|---|---|
| `sec_registration_number` | STRING | SEC registration number |
| `legal_name` | STRING | Registered legal name |
| `trade_names` | ARRAY<STRING> | Known trade/brand names |
| `incorporation_date` | DATE | Date of incorporation |
| `registered_address` | STRING | Registered office address |
| `directors` | ARRAY<STRUCT> | Director names and positions |
| `company_type` | STRING | Corporation, partnership, etc. |
| `sec_status` | STRING | Active, revoked, suspended |
| `annual_report_year` | INT | Most recent annual report year |
| `extraction_date` | DATE | When this data was extracted |
| `source_url` | STRING | Source URL for provenance |

**Implementation approach:**
- Python script using `requests` + `BeautifulSoup` for SEC iReports scraping
- Batch job scheduled weekly in Databricks
- Results land in bronze external table
- Silver view normalizes and joins against `crm_account` on fuzzy-matched legal name + registration number

**Build estimate:** 2-3 days

#### 2.1.2 PSE EDGE Listed Company Connector

**Purpose:** Pull financial disclosures for publicly listed Philippine companies (annual reports, quarterly filings, material disclosures).

**Data source:** PSE EDGE portal (Philippine Stock Exchange Electronic Disclosure Generation Technology).

**Target schema — bronze table: `bronze_external.pse_disclosures`**

| Column | Type | Description |
|---|---|---|
| `pse_ticker` | STRING | Stock ticker symbol |
| `company_name` | STRING | Listed company name |
| `disclosure_type` | STRING | Annual report, quarterly, material |
| `disclosure_date` | DATE | Filing date |
| `revenue_reported` | DECIMAL | Most recent reported revenue (PHP) |
| `headcount_reported` | INT | Reported employee count |
| `subsidiaries_disclosed` | ARRAY<STRING> | Named subsidiaries in filing |
| `raw_text_excerpt` | STRING | Relevant text excerpt (max 5000 chars) |
| `source_url` | STRING | Direct link to disclosure |
| `extraction_date` | DATE | When extracted |

**Implementation approach:**
- PSE EDGE has a structured disclosure search — scrape structured fields + download PDF filings
- Use Claude API (§2.3) to extract structured data from PDF filing text
- Weekly batch

**Build estimate:** 3-4 days (including PDF extraction pipeline)

#### 2.1.3 Commercial Firmographic Provider Integration

**Purpose:** Hierarchy discovery — find subsidiaries the CRM doesn't know about.

**Data source:** OpenCorporates API for prototype (free tier, 500 calls/month). Upgrade path to D&B or Bureau van Dijk for production.

**Target schema — bronze table: `bronze_external.firmographic_entities`**

| Column | Type | Description |
|---|---|---|
| `opencorp_id` | STRING | OpenCorporates company number |
| `jurisdiction` | STRING | PH, SG, MY, etc. |
| `legal_name` | STRING | Registered name |
| `company_type` | STRING | Corporation type |
| `status` | STRING | Active, dissolved, etc. |
| `registered_address` | STRING | Registered address |
| `parent_opencorp_id` | STRING | Parent company if known |
| `officers` | ARRAY<STRUCT> | Named officers |
| `source` | STRING | "opencorporates" |
| `extraction_date` | DATE | When extracted |

**Implementation approach:**
- OpenCorporates REST API — search by company name, filter by jurisdiction
- Match against CRM accounts using fuzzy name matching + jurisdiction
- Discover parent-child relationships not visible in CRM
- Weekly batch

**Build estimate:** 2 days

#### 2.1.4 Public Signals Ingestion — Job Postings

**Purpose:** Technology stack signals and hiring intent as competitive intelligence.

**Target schema — bronze table: `bronze_external.job_signals`**

| Column | Type | Description |
|---|---|---|
| `company_name` | STRING | Hiring company |
| `job_title` | STRING | Role title |
| `technology_tags` | ARRAY<STRING> | Extracted: Databricks, Snowflake, Salesforce, etc. |
| `posting_date` | DATE | When posted |
| `source_platform` | STRING | LinkedIn, JobStreet, etc. |
| `source_url` | STRING | Job posting URL |
| `extraction_date` | DATE | When extracted |

**Implementation approach:**
- LinkedIn public job search (no API needed for public postings) or JobStreet Philippines
- Claude API extracts technology tags from job descriptions
- Weekly batch, filtered to target account company names

**Build estimate:** 2 days

### 2.2 Databricks Gold Layer Extensions

**Gap addressed:** Gold export currently only carries CRM-derived intelligence. Must now carry external enrichment, Gen AI outputs, and provenance metadata.

**Platform:** Databricks

#### 2.2.1 External Enrichment Silver Views

New silver views that join external bronze data against CRM accounts:

| View | Purpose | Join key |
|---|---|---|
| `90_external_sec_ph_match.sql` | SEC registry match per CRM account | Fuzzy legal name + registration number |
| `91_external_firmographic_match.sql` | Firmographic hierarchy match | Fuzzy name + jurisdiction |
| `92_external_pse_disclosure_match.sql` | PSE filing match for listed companies | Ticker/name match |
| `93_external_signal_summary.sql` | Aggregated public signals per account | Company name match |

**Build estimate:** 3 days

#### 2.2.2 Gold Export Schema Extension

New columns added to the existing `30_datacloud_export_accounts.sql`:

| Column | Type | Source | Description |
|---|---|---|---|
| `external_legal_name` | STRING | SEC PH / OpenCorp | Confirmed legal name from external registry |
| `external_registration_number` | STRING | SEC PH | SEC registration number |
| `external_incorporation_date` | DATE | SEC PH | Incorporation date |
| `external_entity_status` | STRING | SEC PH | Active/suspended/revoked |
| `external_subsidiaries_discovered` | INT | OpenCorp + PSE | Count of subsidiaries found externally but not in CRM |
| `external_subsidiary_names` | STRING | OpenCorp + PSE | JSON array of discovered subsidiary names |
| `external_revenue_reported` | DECIMAL | PSE | Most recent disclosed revenue (PHP) |
| `external_headcount` | INT | PSE | Disclosed employee count |
| `external_tech_signals` | STRING | Job signals | JSON: technology stack indicators |
| `external_enrichment_source_count` | INT | All external | How many external sources confirmed this entity |
| `external_enrichment_date` | DATE | Pipeline | When external enrichment last ran |
| `is_externally_validated` | BOOLEAN | Derived | True if ≥1 external source confirms entity |
| `validity_score_external` | INT | Derived | 0-100 validity incorporating external data |
| `ai_narrative` | STRING | Gen AI (§2.3) | Account intelligence narrative text |
| `ai_recommended_actions` | STRING | Gen AI (§2.3) | JSON array of ranked next actions |
| `ai_narrative_generated_at` | TIMESTAMP | Gen AI | When narrative was last generated |
| `enrichment_run_id` | STRING | Pipeline | Links to specific enrichment run |
| `enrichment_run_timestamp` | TIMESTAMP | Pipeline | When this enrichment run completed |

**Implementation approach:**
- Extend existing `30_datacloud_export_accounts.sql` with LEFT JOINs to external silver views
- Add Gen AI output columns (populated by §2.3 pipeline)
- Preserve all existing columns unchanged

**Build estimate:** 2 days

### 2.3 Gen AI Enrichment Pipeline (Databricks)

**Gap addressed:** Intelligence is static scores. No explanation, no reasoning, no recommended actions.
**Platform:** Databricks (orchestration) + OpenAI/GPT API or approved enterprise LLM endpoint (inference)
**Priority:** High — this is the core differentiator

**Firmographic evidence design note:** The Gen AI pipeline sits after approved firmographic evidence ingestion, not before it. Commercial provider API specifications inform the shape of the evidence packet: company identity, official identifiers, location, classification, legal status, financials, hierarchy hints, contact/web presence, technographic signals, reliability, freshness, and license metadata. No paid-provider endpoint or vendor runtime is hardwired into the design. GPT then extracts, summarizes, scores confidence, and ranks actions from governed facts. It must not create legal identifiers, CRM match keys, revenue, employee count, or hierarchy facts without bound source IDs.

#### 2.3.1 Structured Extraction Agent

**Purpose:** Process unstructured external sources (PSE filings, news articles, job postings) into structured enrichment payloads.

**Input:** Raw text from PSE disclosures, SEC filings, news articles per account.

**Output schema:**

```json
{
  "account_id": "001...",
  "extracted_facts": [
    {
      "fact_type": "revenue",
      "value": "PHP 42.3B",
      "confidence": 0.95,
      "source_url": "https://edge.pse.com.ph/...",
      "source_date": "2025-12-31",
      "extraction_date": "2026-03-28"
    },
    {
      "fact_type": "subsidiary_discovered",
      "value": "Pacific Holdings Infrastructure Inc.",
      "confidence": 0.82,
      "source_url": "https://sec.gov.ph/...",
      "source_date": "2025-06-15",
      "extraction_date": "2026-03-28"
    }
  ]
}
```

**Implementation approach:**
- Databricks Python job iterates over accounts with external source/provider data
- For each account, assembles a context payload: CRM fields + provider firmographic facts + registry facts + external raw text
- Calls OpenAI/GPT with a structured output schema prompt
- Parses JSON response and writes to `gold.account_extraction_facts` table
- Records `model_id`, `prompt_version`, `llm_run_id`, input/output hashes, source IDs, token/cost metadata, confidence components, and run timestamp
- Runs after external bronze/provider ingestion and silver normalization complete

**GPT prompt pattern:**
```
You are an account intelligence extraction agent. Given the following CRM account data and external source documents, extract structured facts about this entity.

CRM context: {crm_fields}
External source text: {raw_text}

Return ONLY a JSON object matching this schema: {schema}
Every extracted fact must include a source_id, source_url, and confidence score.
Do not infer facts that are not explicitly stated in the sources.
```

**Build estimate:** 3 days

#### 2.3.2 Account Narrative Generator

**Purpose:** Generate a paragraph-length explanation of each account's current intelligence state. Replaces opaque scores with human-readable reasoning.

**Input per account:**
- All CRM intelligence fields (health_score, cross_sell_propensity, etc.)
- External enrichment summary (subsidiaries discovered, revenue confirmed, etc.)
- Duplicate detection results
- Hierarchy context
- Recent signal changes

**Output:** A single text field (`ai_narrative`) stored in the gold export, max 500 words.

**Example output:**
> Pacific Holdings Group has a health score of 34/100 because group revenue visibility is limited to 2 of 6 known subsidiaries. SEC PH filings confirm the parent entity (Registration CS201512345) with reported revenue of PHP 8.7B, but only PHP 2.1B is captured in CRM across 2 account records. Three subsidiaries were discovered through SEC filings that have no corresponding CRM accounts: Pacific Holdings Infrastructure Inc., Pacific Digital Services Corp., and PH Energy Solutions. The Infrastructure BU has confirmed IT spending of PHP 2.1B based on their 2025 annual report. No opportunity exists against this subsidiary. Competitor risk is elevated — 2 Databricks engineering roles were posted by the Infrastructure BU in Q1 2026, suggesting they may be evaluating data platform alternatives. Recommended priority: create opportunity for Infrastructure BU, then investigate the 2 other uncovered subsidiaries.

**GPT prompt pattern:**
```
You are an account intelligence analyst. Given the structured intelligence below, write a concise narrative (max 500 words) explaining:
1. Why the health score is what it is
2. What the key risks and opportunities are
3. What has changed since the last enrichment
4. What the recommended priorities are

Intelligence payload: {all_fields_json}

Write in direct, factual language. Cite specific numbers and sources. Do not hedge or use vague qualifiers.
```

**Build estimate:** 2 days

#### 2.3.3 Next Best Actions Generator

**Purpose:** Generate 2-3 ranked recommended actions per account with reasoning and estimated revenue impact.

**Output schema per account:**

```json
{
  "account_id": "001...",
  "actions": [
    {
      "rank": 1,
      "action_type": "create_opportunity",
      "target": "Pacific Holdings Infrastructure Inc.",
      "reasoning": "Subsidiary discovered via SEC PH filing. Confirmed IT spend PHP 2.1B. No existing opportunity. High cross-sell propensity (0.87).",
      "estimated_revenue_impact": "PHP 210M",
      "confidence": 0.82,
      "source_attribution": "SEC PH annual report 2025, job posting signal Q1 2026"
    },
    {
      "rank": 2,
      "action_type": "escalate_governance",
      "target": "Account records 001ABC and 001DEF",
      "reasoning": "Duplicate confidence 94%. SEC registration number matches. Merge would consolidate PHP 1.2B in fragmented revenue.",
      "estimated_revenue_impact": "PHP 1.2B visibility improvement",
      "confidence": 0.94,
      "source_attribution": "Databricks duplicate detection + SEC PH registry confirmation"
    }
  ]
}
```

**Stored as:** JSON string in `ai_recommended_actions` column of gold export.

**Build estimate:** 2 days

#### 2.3.4 Gen AI Orchestration Job

**Purpose:** Databricks job that orchestrates the full Gen AI pipeline.

**Execution order:**
1. Wait for external bronze ingestion to complete
2. Run structured extraction (§2.3.1) for accounts with new external data
3. Run narrative generator (§2.3.2) for all active accounts
4. Run next best actions (§2.3.3) for all active accounts
5. Write results to gold export columns
6. Materialize export table
7. Log run metadata (run_id, timestamp, accounts processed, API calls made, total cost)

**Schedule:** Weekly (aligned with external data ingestion cycle)

**Build estimate:** 2 days

#### 2.3.5 Agentic Field Boundary

**Purpose:** Prevent Agentforce from becoming the hidden calculator for fields
that must remain deterministic, while still using Agentforce where it creates
real value.

**Design rule:**
Databricks/Data Cloud own facts, scores, eligibility, keys, freshness, evidence
payloads, and confidence components. Agentforce owns interpretation,
recommendation, rationale, objection handling, and action packaging.

**Do not calculate with Agentforce:**

- identity keys and CRM activation keys
- duplicate, hierarchy, validity, health, or readiness scores
- activation eligibility and block reasons
- downstream update status
- audit IDs and approved governance decision fields
- raw evidence payloads and confidence components

**Do calculate or synthesize with Agentforce:**

- seller/steward recommendation
- rationale and evidence summary
- confidence explanation
- risk and objection flags
- next-best-action package
- manager-ready or steward-ready brief

**Persistence rule:**
Agentforce-generated outputs are companion interpretation fields. If persisted,
they must carry model ID, prompt version, run ID, source references, timestamp,
and output status. Regenerating the agentic output must not overwrite the
deterministic field state.

**Implementation reference:**
`docs/planning/pulse360-agentic-field-design-2026-04-29.md`

**Build estimate:** 0.5 day for contract alignment; implementation tracked as a
separate Agentforce slice.

### 2.4 Data Cloud Schema Extension

**Gap addressed:** Data Cloud currently models CRM-derived intelligence only. Must now carry external enrichment and Gen AI outputs.
**Platform:** Data Cloud
**Priority:** Medium — depends on §2.2 completion

#### 2.4.1 Extended DLO/DMO Mapping

Add new fields to the existing Data Cloud data stream and object mappings:

| Field | DLO Source | DMO Target | Purpose |
|---|---|---|---|
| `external_legal_name` | Databricks export | Account DMO | Registry-confirmed name |
| `external_registration_number` | Databricks export | Account DMO | SEC registration for audit |
| `external_subsidiaries_discovered` | Databricks export | Account DMO | Subsidiary count |
| `is_externally_validated` | Databricks export | Account DMO | External confirmation flag |
| `validity_score_external` | Databricks export | Account DMO | External validity score |
| `ai_narrative` | Databricks export | Account DMO | Gen AI narrative text |
| `ai_recommended_actions` | Databricks export | Account DMO | Gen AI actions JSON |
| `ai_narrative_generated_at` | Databricks export | Account DMO | Narrative freshness |
| `enrichment_run_id` | Databricks export | Account DMO | Run provenance |
| `enrichment_run_timestamp` | Databricks export | Account DMO | Run timing |

**Implementation approach:**
- Extend existing data stream mapping (runbook-driven, as Data Cloud setup is not source-deployable)
- No new streams needed — same Databricks export table, additional columns
- Update DMO field mapping in Data Cloud setup

**Build estimate:** 1 day (runbook update + manual DC configuration)

#### 2.4.2 Extended Copy Field Enrichment

Add new fields to the existing Copy Field Enrichment configuration:

| Data Cloud Field | Salesforce Target Field | Purpose |
|---|---|---|
| `external_legal_name` | `External_Legal_Name__c` | Registry-confirmed name |
| `is_externally_validated` | `Externally_Validated__c` | Confirmation flag |
| `validity_score_external` | `Validity_Score_External__c` | External trust score |
| `ai_narrative` | `AI_Narrative__c` | Gen AI explanation |
| `ai_recommended_actions` | `AI_Recommended_Actions__c` | Gen AI actions |
| `ai_narrative_generated_at` | `AI_Narrative_Generated__c` | Freshness timestamp |
| `external_subsidiaries_discovered` | `External_Subsidiaries_Found__c` | Subsidiary count |
| `enrichment_run_id` | `Enrichment_Run_Id__c` | Run provenance |

**Build estimate:** 0.5 days

#### 2.4.3 Regulatory Readiness Calculated Insight

New Calculated Insight in Data Cloud:

**Name:** `Regulatory_Readiness_Score`

**Formula logic:**
- Start at 100
- Deduct 20 if `identity_confidence` < 80
- Deduct 20 if `is_externally_validated` = false
- Deduct 15 if duplicate count for this account > 0
- Deduct 15 if `coverage_gap_flag` = true
- Deduct 15 if group revenue visibility < 50% of known subsidiaries
- Deduct 15 if `ai_narrative` contains "no audit trail" or similar flags

**Output:** Integer 0-100, synced to `Regulatory_Readiness_Score__c` on Account via Copy Field Enrichment.

**Purpose:** BSP Circular 1213 compliance indicator. Answers the question: "If a BSP examiner audited this account's identity resolution today, would we pass?"

**Build estimate:** 1 day

### 2.5 Agentforce Actions (Salesforce)

**Gap addressed:** No interactive intelligence surfaces. The brief describes Agentforce actions that don't exist in the implementation.
**Platform:** Salesforce (Apex + Agentforce configuration)
**Priority:** Highest — this is where demo value lives

#### 2.5.1 Account Health Scan Action

**Purpose:** DS-01 payoff moment. User triggers from Account page, receives structured intelligence card.

**Trigger:** Custom button or Agentforce action on Account record page.

**Behaviour:**
1. Read all Pulse360 intelligence fields from the Account record
2. Read `ai_narrative` and `ai_recommended_actions` from the Account record
3. Format into a structured response card

**Response card structure:**
```
╔══════════════════════════════════════════╗
║ ACCOUNT HEALTH SCAN — Pacific Holdings   ║
╠══════════════════════════════════════════╣
║ Health Score:        34 / 100            ║
║ Regulatory Readiness: 45 / 100           ║
║ Duplicate Exposure:  4,247 pairs         ║
║ Group Revenue:       PHP 8.7B confirmed  ║
║ CRM Revenue Visible: PHP 2.1B (24%)     ║
║ Hidden Revenue:      PHP 6.6B            ║
║ Subsidiaries Known:  6                   ║
║ Subsidiaries in CRM: 2                   ║
║ External Validation: SEC PH confirmed    ║
║ Last Enriched:       3 days ago          ║
╠══════════════════════════════════════════╣
║ AI ASSESSMENT                            ║
║ [ai_narrative text displayed here]       ║
╠══════════════════════════════════════════╣
║ RECOMMENDED ACTIONS                      ║
║ 1. Create opp: Infrastructure BU         ║
║ 2. Escalate: Governance case #GC-0042    ║
║ 3. Investigate: 2 uncovered subsidiaries ║
╚══════════════════════════════════════════╝
```

**Implementation:**
- Apex class: `Pulse360HealthScanAction.cls`
- Reads from Account custom fields (already synced via Copy Field Enrichment)
- Parses `AI_Recommended_Actions__c` JSON for action list
- Returns structured response for Agentforce to display
- Agentforce action configuration: topic = "Account Intelligence", action = "Run Health Scan"

**Build estimate:** 3 days (Apex + Agentforce config + LWC card if needed)

#### 2.5.2 Governance Case Enrichment Action

**Purpose:** When a steward opens a governance case, auto-populate external evidence for both candidate accounts.

**Trigger:** `Governance_Case__c` record view — fires on page load or via button.

**Behaviour:**
1. Read both candidate Account IDs from the governance case
2. For each account, retrieve: `external_legal_name`, `external_registration_number`, `validity_score_external`, `is_externally_validated`
3. Format into the existing side-by-side LWC as additional evidence fields

**New evidence fields on Governance_Case__c:**

| Field | Type | Description |
|---|---|---|
| `Account_A_External_Name__c` | Text(255) | Registry-confirmed name for Account A |
| `Account_A_Registration__c` | Text(50) | SEC registration number for Account A |
| `Account_A_External_Validity__c` | Number | External validity score for Account A |
| `Account_B_External_Name__c` | Text(255) | Registry-confirmed name for Account B |
| `Account_B_Registration__c` | Text(50) | SEC registration number for Account B |
| `Account_B_External_Validity__c` | Number | External validity score for Account B |
| `Registry_Match_Confirmed__c` | Checkbox | True if both accounts match the same registry entity |

**Implementation:**
- Apex class: `Pulse360GovernanceEnrichment.cls`
- Reads from related Account records' Pulse360 fields
- Populates governance case evidence fields
- Extend existing governance review LWC to display external evidence section

**Build estimate:** 2 days

#### 2.5.3 Next Best Action Surface

**Purpose:** DS-03 seller action moment. Show ranked Gen AI recommendations on Account 360.

**Trigger:** Account record page — always visible in Pulse360 section.

**Behaviour:**
1. Read `AI_Recommended_Actions__c` from Account record
2. Parse JSON array of actions
3. Render as interactive cards with "Execute" buttons
4. Execute button triggers: create opportunity, create task, or navigate to governance case

**Implementation:**
- LWC: `pulse360NextBestAction`
- Reads from Account field, parses JSON
- Each action card shows: action type, target, reasoning, estimated revenue impact
- Execute buttons call standard Salesforce actions (create Opportunity, create Task)
- Log the intelligence source that triggered the action on the created record

**Build estimate:** 3 days

#### 2.5.4 Group Revenue Reveal Component

**Purpose:** The ASEAN "wow moment." Visual before/after showing CRM-visible revenue vs. true group revenue.

**Trigger:** Account record page — always visible in Pulse360 section.

**Behaviour:**
1. Read `Group_Revenue_Rollup__c` (total group) and current Account revenue
2. Read `External_Subsidiaries_Found__c` (count of discovered subsidiaries)
3. Display visual comparison: "Your sellers see PHP 2.1B. The real group is PHP 8.7B."
4. Show subsidiary breakdown with coverage status (covered / not in CRM)

**Implementation:**
- LWC: `pulse360GroupRevenueReveal`
- Horizontal bar chart: CRM-visible vs. full group
- Subsidiary list with coverage indicators
- Delta callout: "PHP 6.6B in uncovered subsidiaries"

**Build estimate:** 2 days

### 2.6 Continuous Intelligence Pipeline

**Gap addressed:** Value is one-time. No ongoing enrichment, no signal detection, no compounding.
**Platform:** Databricks (scheduling) + Salesforce (notifications)
**Priority:** Low for prototype — but design it now for production story

#### 2.6.1 Scheduled Enrichment Cycle

**Purpose:** Weekly automated re-enrichment of all tracked accounts.

**Implementation:**
- Databricks Workflow with scheduled trigger (weekly)
- Job chain: external bronze ingest → silver matching → gold export → Gen AI pipeline → materialized export table → validation
- Delta flag in export: `enrichment_changed_since_last_run` (BOOLEAN)
- Run log table: `ops.enrichment_run_log`

**Build estimate:** 2 days

#### 2.6.2 Signal Detection and Notification

**Purpose:** When a material change is detected for a tracked account, generate a Salesforce notification.

**Material change triggers:**
- New SEC filing detected
- New subsidiary discovered
- Revenue change > 10% from last enrichment
- New competitor technology signal (e.g., Snowflake job posting at a Databricks prospect)
- Duplicate confidence change > 10 points

**Implementation:**
- Databricks compares current enrichment with previous run
- For material changes, writes to `ops.signal_alerts` table
- Salesforce scheduled job reads alerts and creates Chatter posts or Tasks on affected Accounts
- Alert text generated by Claude API: one-sentence summary of what changed and why it matters

**Build estimate:** 3 days

### 2.7 Demo Data Enhancement

**Gap addressed:** Current demo data is generic. Philippines market story needs specific, contextualised demo data.
**Platform:** All layers

#### 2.7.1 Philippine Demo Account Set

Replace or extend generic demo accounts with Philippine-contextualised data:

| Demo Account | Industry | Scenario Role |
|---|---|---|
| Pacific Holdings Group (parent) | Conglomerate | DS-01: Fragmentation discovery |
| Pacific Telecom Inc. | Telco BU | DS-01: Subsidiary with duplicates |
| Pacific Infrastructure Corp. | Construction BU | DS-03: Discovered subsidiary, no coverage |
| Pacific Digital Services | Tech BU | DS-03: Competitor signal target |
| Pacific Financial Holdings | Banking BU | DS-02: BSP Circular 1213 urgency |
| Pacific Energy Solutions | Utilities BU | DS-03: Whitespace opportunity |

**Requirements:**
- All accounts must have realistic Philippine business context (PHP currency, BSP regulatory references, SEC PH registration numbers)
- Demo duplicate records must look like real CRM fragmentation (name variants, missing fields, no hierarchy)
- External enrichment data must include SEC PH mock filings and PSE mock disclosures
- Gen AI narratives must reference Philippine-specific context

**Build estimate:** 3 days (data prep across all layers)

---

## 3. What to Change — Modifications to Existing Assets

These are targeted modifications to existing assets. They do not replace the asset — they extend or adjust it.

### 3.1 Contract Extensions

#### 3.1.1 Databricks → Data Cloud Export Contract

**Change:** Add external enrichment and Gen AI output fields to the existing export contract.

**New fields to add to contract:**
- All columns listed in §2.2.2
- Explicit provenance rules: every external field must carry `source`, `extraction_date`, and `confidence`
- Explicit Gen AI rules: `ai_narrative` and `ai_recommended_actions` must carry `generated_at` timestamp and `enrichment_run_id`

**Build estimate:** 0.5 days

#### 3.1.2 Data Cloud → Salesforce/Agentforce Contract

**Change:** Add new CRM target fields and Agentforce action definitions.

**New fields to add to contract:**
- All Salesforce target fields listed in §2.4.2
- Agentforce action definitions for §2.5.1, §2.5.2, §2.5.3
- Regulatory Readiness Calculated Insight definition
- Agentic field ownership rules from §2.3.5: deterministic intelligence fields
  remain Databricks/Data Cloud owned; Agentforce companion fields carry
  recommendation, rationale, evidence summary, risk flags, confidence
  explanation, and audit metadata

**Build estimate:** 0.5 days

### 3.2 Governance Case LWC Enhancement

**Change:** Extend the existing governance review LWC to display external evidence alongside existing Databricks evidence.

**Current state:** Side-by-side comparison shows CRM fields and Databricks duplicate confidence + validity scores.

**Target state:** Same layout, with an additional "External Evidence" section per candidate account showing:
- Registry-confirmed legal name
- SEC registration number
- External validity score
- Registry match status (confirmed same entity / different entity / no match)

**Implementation:** Modify existing `governanceReviewLWC` — add a new `<template if:true={hasExternalEvidence}>` section below existing evidence fields. Read from new `Governance_Case__c` fields (§2.5.2).

**Build estimate:** 1 day

### 3.3 Salesforce Account Custom Fields Extension

**Change:** Add new custom fields to the Account object for external enrichment and Gen AI output display.

**New fields:**

| API Name | Type | Length | Description |
|---|---|---|---|
| `External_Legal_Name__c` | Text | 255 | Registry-confirmed legal name |
| `Externally_Validated__c` | Checkbox | — | External source confirmed entity |
| `Validity_Score_External__c` | Number | 3,0 | External validity 0-100 |
| `AI_Narrative__c` | Long Text Area | 10000 | Gen AI account intelligence narrative |
| `AI_Recommended_Actions__c` | Long Text Area | 10000 | Gen AI recommended actions JSON |
| `AI_Narrative_Generated__c` | DateTime | — | When narrative was last generated |
| `External_Subsidiaries_Found__c` | Number | 5,0 | Subsidiaries discovered externally |
| `Enrichment_Run_Id__c` | Text | 50 | Links to Databricks run |
| `Regulatory_Readiness_Score__c` | Number | 3,0 | BSP compliance readiness 0-100 |

**Implementation:** Source-backed metadata in repo. Deploy via `sfdx` or metadata API.

**Build estimate:** 0.5 days

### 3.4 Account Record Page Enhancement

**Change:** Extend the Account flexipage to include new Pulse360 components.

**Current state:** Pulse360 section shows intelligence fields in a standard field layout.

**Target state:** Pulse360 section includes:
1. **Group Revenue Reveal** component (§2.5.4) — visual before/after
2. **AI Narrative** — displayed as a rich text card reading from `AI_Narrative__c`
3. **Next Best Actions** component (§2.5.3) — interactive action cards
4. **Existing intelligence fields** — retained in a collapsible detail section
5. **Enrichment provenance footer** — shows `Enrichment_Run_Id__c`, `AI_Narrative_Generated__c`, `DataCloud_Last_Synced__c`

**Build estimate:** 1 day (flexipage layout + component placement)

### 3.5 Validation Script Extensions

**Change:** Add validation checks for external enrichment and Gen AI pipeline.

**New validation checks:**

| Script | Validates |
|---|---|
| External enrichment freshness | Bronze external tables have data within last 7 days |
| Gen AI output completeness | All active accounts have non-null `ai_narrative` and `ai_recommended_actions` |
| External-to-CRM match rate | At least 50% of CRM accounts have ≥1 external source match |
| Gold export schema validation | New columns present and non-null where expected |
| Agentforce action validation | Health Scan, Governance Enrichment, and NBA actions configured and callable |
| Regulatory Readiness validation | Calculated Insight computes correctly for test accounts |

**Build estimate:** 2 days

### 3.6 Milestone C Acceptance Language Update

**Change:** Update formal gate wording to reflect implemented reality.

**Specific changes:**
- Replace `ActivationTarget` references with `Copy Field Enrichment` as the canonical CRM realization mechanism
- Add external enrichment and Gen AI output acceptance criteria
- Add Agentforce action acceptance criteria
- Add regulatory readiness acceptance criteria

**Build estimate:** 0.5 days

---

## 4. Build Priority and Sequencing

### Phase 1: Agentforce Surfaces (highest demo impact, fastest to build)
**Duration:** 5-7 days
**Delivers:** Interactive demo moments for DS-01, DS-02, DS-03

| Item | Ref | Days | Depends On |
|---|---|---|---|
| Account Health Scan Action | §2.5.1 | 3 | Existing Account fields |
| Next Best Action Surface | §2.5.3 | 3 | Existing Account fields |
| Group Revenue Reveal | §2.5.4 | 2 | Existing Account fields |
| Account page enhancement | §3.4 | 1 | §2.5.1, §2.5.3, §2.5.4 |

**Note:** Phase 1 uses existing field values with mock Gen AI data pre-loaded via fixture scripts. This lets the demo work immediately while the real Gen AI pipeline is being built in Phase 2.

### Phase 2: External Enrichment (breaks GIGO)
**Duration:** 8-10 days
**Delivers:** External data flowing through the full pipeline

| Item | Ref | Days | Depends On |
|---|---|---|---|
| SEC PH connector | §2.1.1 | 3 | — |
| OpenCorporates connector | §2.1.3 | 2 | — |
| PSE EDGE connector | §2.1.2 | 4 | — |
| External silver views | §2.2.1 | 3 | §2.1.1, §2.1.3, §2.1.2 |
| Gold export extension | §2.2.2 | 2 | §2.2.1 |
| Contract extensions | §3.1 | 1 | §2.2.2 |
| Data Cloud schema extension | §2.4.1, §2.4.2 | 1.5 | §2.2.2, §3.1 |
| SF Account field extension | §3.3 | 0.5 | §2.4.2 |

### Phase 3: Gen AI Pipeline (intelligence, not just data)
**Duration:** 7-9 days
**Delivers:** Narratives, recommendations, and structured extraction

| Item | Ref | Days | Depends On |
|---|---|---|---|
| Structured extraction agent | §2.3.1 | 3 | §2.1 (external data available) |
| Account narrative generator | §2.3.2 | 2 | §2.2.2 (gold schema extended) |
| Next best actions generator | §2.3.3 | 2 | §2.2.2, §2.3.2 |
| Gen AI orchestration job | §2.3.4 | 2 | §2.3.1, §2.3.2, §2.3.3 |
| Regulatory readiness insight | §2.4.3 | 1 | §2.4.1 |

### Phase 4: Experience Enhancement + Continuous Loop
**Duration:** 6-8 days
**Delivers:** Full demo story with Philippine context + ongoing value

| Item | Ref | Days | Depends On |
|---|---|---|---|
| Governance LWC enhancement | §3.2 | 1 | §2.5.2 |
| Governance enrichment action | §2.5.2 | 2 | §3.3, §2.4.2 |
| Philippine demo data | §2.7.1 | 3 | §2.2.2, §2.3 (Gen AI outputs) |
| Scheduled enrichment cycle | §2.6.1 | 2 | §2.3.4 |
| Signal detection | §2.6.2 | 3 | §2.6.1 |
| Validation extensions | §3.5 | 2 | All above |
| Milestone C language update | §3.6 | 0.5 | All above |
| Job signals connector | §2.1.4 | 2 | — |

### Total Estimated Build

| Phase | Days | Cumulative |
|---|---|---|
| Phase 1: Agentforce Surfaces | 7 | 7 |
| Phase 2: External Enrichment | 10 | 17 |
| Phase 3: Gen AI Pipeline | 9 | 26 |
| Phase 4: Enhancement + Loop | 8 | 34 |

**Prototype-complete estimate: ~34 days of focused Claude Code build time.**

This is deliberately sequenced so that each phase delivers a demonstrable improvement. Phase 1 alone transforms the demo. Phases 2+3 together transform the proposition. Phase 4 transforms the commercial story from project to platform.

---

## 5. Architecture Decisions Resolved

This specification resolves the open review questions from the design document (§12.2):

| Question | Decision |
|---|---|
| Should Copy Field Enrichment be the official CRM realization pattern? | **Yes.** It is the proven mechanism. All new fields use the same path. |
| Should ActivationTarget be documented as non-primary? | **Yes.** Document as investigated, not implemented. Remove from acceptance criteria. |
| Is the current field set the right Account 360 surface? | **No.** Extend with AI narrative, recommended actions, external validation, regulatory readiness, and group revenue reveal. The current fields become the "detail" layer; the new components become the "action" layer. |
| Should the architecture separate CRM fields from richer surfaces? | **Yes.** Copy Field Enrichment handles scalar intelligence fields. Agentforce actions and LWCs handle richer context (narratives, action cards, hierarchy views). Two channels, one account model. |
| Should more org-validated surfaces be brought into repo metadata? | **Yes.** All new LWCs and Agentforce actions must be source-backed from day one. No runtime-only proof for new capabilities. |
