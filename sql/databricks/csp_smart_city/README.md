# Databricks CSP Smart City Source Pack

This SQL pack creates the first ASEAN communications-provider smart-city
proposition slice for Pulse360.

It is fixture-backed by design. The goal is to prove the product/offering pivot
before changing Salesforce UX or connecting live city, CSP, IoT, or partner
data feeds.

## Order

Run the files in this order:

1. `00_create_schemas.sql`
2. `05_smart_city_signal_sample.sql`
3. `10_smart_city_proposition_readiness.sql`

## Output Views

- `pulse360_s4.bronze_smart_city.smart_city_signal_sample`
- `pulse360_s4.bronze_smart_city.smart_city_b2b_customer_sample`
- `pulse360_s4.gold_smart_city.smart_city_proposition_readiness`

## Initial Offering Families

- `intelligent_parking`
- `urban_data_brokerage`
- `connected_city_iot_platform`

## Initial Source Families

- `municipal_open_data`
- `csp_network`
- `iot_telemetry`
- `public_sector_trigger`
- `partner_ecosystem`
- `mobility_data`
- `data_marketplace`

## Initial Target Markets

- Singapore
- Malaysia
- Thailand
- Vietnam
- Philippines, including Manila / Metro Manila propositions

## B2B Target Customer Fixture

The pack includes representative B2B target-customer records for transport
authorities, parking operators, property groups, and industrial-estate
operators. These records are synthetic account-planning fixtures, not proof
that the named organizations are already CRM accounts or contracted buyers.
Signals can carry `target_b2b_customer_ids` in `source_payload`; the readiness
view rolls those IDs into proposition-level evidence for Data Cloud governance
and Salesforce stewardship.

## Design Rules

- Every proposition signal must preserve source family, source system, evidence
  URL, confidence, consent/privacy classification, and next action.
- Data brokerage and automated-identification scenarios must route through
  governance review unless consent and aggregation controls are proven.
- CSP smart-city outputs remain Databricks intelligence products until Data
  Cloud and Salesforce CRM contracts are explicitly extended.
- This pack must not depend on paid provider endpoints, city production systems,
  or live citizen-level data.
