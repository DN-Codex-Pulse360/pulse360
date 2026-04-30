# Pulse360 CSP Smart City Pivot

Date: 2026-04-27

## Decision

Pulse360 should pivot from a generic IT-services RevOps lens toward a
communications-provider growth lens for ASEAN smart-city propositions.

The product target is now:

> Pulse360 helps communications providers identify, prioritize, and activate the
> right smart-city propositions for the right cities, agencies, infrastructure
> owners, and ecosystem partners by combining city signals, CSP network context,
> IoT readiness, public-sector triggers, partner coverage, and weighted
> evidence-backed account intelligence.

This does not discard the existing Databricks -> Data Cloud -> Salesforce CRM
-> Databricks cycle. It changes the business objects, source families, product
taxonomy, and demonstration scenarios that flow through that cycle.

## ASEAN Research Pattern

ASEAN communications-provider smart-city propositions cluster around seven
families:

| Offering family | Common ASEAN positioning |
| --- | --- |
| Connectivity foundation | 5G, NB-IoT, LTE-M, fiber, private wireless, edge |
| Connected asset / IoT platform | Sensors, gateways, SIM/eSIM lifecycle, device management, telemetry |
| Urban mobility | Intelligent parking, curbside management, traffic monitoring, EV charging |
| City operations center | Integrated command center, dashboards, incident and SLA monitoring |
| Urban data and analytics | Mobility intelligence, anonymized telco insights, data products, forecasting |
| Environment and utilities | Waste, water, energy, air quality, lighting, metering |
| Safety and security | Surveillance, anomaly detection, emergency response, cyber/physical resilience |

The first Pulse360 smart-city demo should focus on three propositions:

1. `intelligent_parking`
2. `urban_data_brokerage`
3. `connected_city_iot_platform`

These are broad enough to show differentiated communications-provider value,
but narrow enough to build credible scenario data quickly.

## Account Model Shift

| Previous account lens | CSP smart-city lens |
| --- | --- |
| Enterprise company account | City, municipality, agency, utility, transport authority, campus, property group |
| Subsidiaries | Departments, jurisdictions, asset operators, municipal corporations |
| Products | Smart-city propositions and solution bundles |
| Firmographics | Urbanographics, infrastructure footprint, IoT maturity, public-sector triggers |
| Buying committee | Mayor/city manager, transport agency, parking operator, data office, sustainability office, CSP account team, SI/vendor partners |
| Whitespace | Missing smart-city domains across mobility, IoT, data brokerage, lighting, waste, safety |
| Renewal risk | SLA breaches, device uptime, adoption gaps, citizen outcome risk, partner delivery risk |

## Source Families

The synthetic and live-source strategy should include:

- `municipal_open_data`: parking zones, traffic counts, EV chargers, air quality,
  permits, public datasets.
- `csp_network`: coverage, latency, NB-IoT/5G readiness, private wireless
  footprint, enterprise contracts.
- `iot_telemetry`: sensor uptime, parking occupancy, gateway health, device
  alerts.
- `public_sector_trigger`: smart-city grants, RFPs, mobility plans, emissions
  targets, budget announcements.
- `partner_ecosystem`: parking vendors, SI partners, device vendors, platform
  partners, city operators.
- `mobility_data`: footfall, origin-destination patterns, corridor congestion,
  curbside demand.
- `environmental_data`: air quality, waste, energy, water, flood and resilience
  indicators.
- `data_marketplace`: cataloged datasets, access constraints, demand signals,
  monetization readiness.

## Priority Stack Adaptation

Priority 1 remains the data foundation:

```text
Databricks -> Salesforce Data Cloud -> Salesforce CRM -> Databricks
```

But the Priority 1 scenario matrix now needs CSP smart-city coverage:

| Scenario | Expected proof |
| --- | --- |
| ASEAN-SC-01 Intelligent Parking Fit | City or district has parking congestion, enforcement, sensor, or curbside indicators that justify a parking proposition |
| ASEAN-SC-02 Urban Data Brokerage Fit | City has mobility or telco-derived data value with consent/governance constraints visible |
| ASEAN-SC-03 Connected City IoT Platform Fit | City or industrial zone has multiple vertical IoT use cases but fragmented device/platform operations |
| ASEAN-SC-04 Blocked / Governance Required | Data monetization or public safety proposition is blocked by privacy, consent, sovereignty, or insufficient lineage |
| ASEAN-SC-05 Partner-Led Motion | Best route is through a parking, SI, device, or city-operations partner rather than direct CSP sale |

## Contract Requirements

Every smart-city proposition signal must preserve:

- target entity and entity type
- country and market context
- proposition family and offer bundle
- source family, source system, source reference, and evidence URL or document ID
- confidence score and weighting rationale
- consent/privacy classification
- expected activation state
- recommended next action
- run ID, timestamp, and model/prompt metadata where AI is used

For account-planning usefulness, the signal pack also carries associated
sample B2B target customers:

- transport authorities and municipal agencies for public-sector sponsorship
- parking operators for intelligent-parking pilots
- property groups and industrial-estate operators for venue-led adoption
- data consumers or ecosystem partners for brokerage and marketplace motions

These are synthetic target-customer fixtures unless explicitly tied to a CRM
Account ID. They are used to test the Databricks -> Data Cloud -> Salesforce CRM
flow and should not be presented as confirmed buyers.

## Build Implication

The next Databricks build slice should add a CSP smart-city source pack beside
the existing enterprise source pack. It should not overwrite the RevOps assets
until the new scenario has proven:

1. Databricks can compute proposition readiness from plural smart-city sources.
2. Data Cloud can see the review/activation rows with source product and
   confidence metadata.
3. Salesforce CRM can capture stewardship or pursuit decisions.
4. Databricks can ingest those decisions back for closed-loop learning.

## Live Databricks Validation

2026-04-27:

- Created/refreshed `pulse360_s4.bronze_smart_city.smart_city_signal_sample`.
- Created/refreshed
  `pulse360_s4.gold_smart_city.smart_city_proposition_readiness`.
- Verified the first proposition scoring mix:
  - `activation_safe`: Ho Chi Minh City Intelligent Parking
  - `review_required`: Singapore Urban Data Brokerage
  - `blocked`: single-source propositions without enough cross-source evidence
- Extended the Data Cloud handoff and refreshed
  `Pulse360_Activation_Review_Queue`.
- Verified `3` CSP smart-city rows in
  `Pulse360_Activation_Review_Queue__dlm`; total stream rows are now `8`.
- Evidence:
  `docs/evidence/dan-317-csp-smart-city-databricks-live-validation-2026-04-27.md`.

## Manila and Target-Customer Extension

2026-04-27:

- Added Manila / Metro Manila propositions for:
  - `intelligent_parking`
  - `urban_data_brokerage`
  - `connected_city_iot_platform`
- Added representative B2B target-customer fixtures, including:
  - Metro Manila Development Authority Mobility Office
  - Manila Central Parking Operator
  - Ayala Urban Property Group
- Added `target_b2b_customer_ids` to proposition evidence so the readiness
  output can explain which target customer route should be qualified next.
- Refreshed Databricks handoff output:
  - `6` CSP smart-city rows in
    `pulse360_s4.intelligence.datacloud_activation_review_queue`
  - `3` Manila / Metro Manila rows covering IoT platform, intelligent parking,
    and urban data brokerage
- Salesforce Data Cloud still requires a `Pulse360_Activation_Review_Queue`
  refresh before the Manila rows appear in the DMO.
