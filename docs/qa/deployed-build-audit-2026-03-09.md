# Deployed Build Audit (2026-03-09)

Scope: compare perceived-built artifacts vs actual deployed state in Databricks and Salesforce.

## Environment Endpoints
- Databricks workspace: `https://dbc-7f0ce7bb-56ca.cloud.databricks.com`
- Salesforce org alias: `pulse360-dev`
- Salesforce instance: `https://orgfarm-2587d03c12-dev-ed.develop.my.salesforce.com`

## Perceived vs Actual
| Surface | Perceived built elements | Actual deployed state | Result |
| --- | --- | --- | --- |
| Databricks dashboards | Two canonical Pulse360 dashboards should be active (main + demo) and visually finalized for walkthrough | Both dashboards are present and `ACTIVE`: `01f11b56ed40102ea9232dfb2404fb1b`, `01f11b5709051df5a21ba10e55942421`, but UI review shows builder/skeleton state without finalized visual widgets | Partial |
| Databricks intelligence tables | Core DS-01/02/03 + activation tables should exist and be populated | `crm_accounts_raw`, `duplicate_candidate_pairs`, `firmographic_enrichment`, `governance_ops_metrics`, `hierarchy_entity_graph`, `datacloud_export_accounts`, `firmographic_candidate_comparisons` all exist | Match |
| Salesforce UI deployment (Milestone D) | Account 360/governance/cross-sell/health UI components should be deployed and placeable | No Pulse360-specific `LightningComponentBundle`, `FlexiPage` record pages, or `AuraDefinitionBundle` found; Account actions list shows default actions only | Gap |

## Databricks Runtime Snapshot
Statement ID (table inventory): `01f11b92-bbff-1db1-8c14-8f9f86af752b`

Statement ID (row counts/freshness): `01f11b92-df80-15d3-adda-49ef99a64d1b`

| Table | Rows | Latest timestamp (UTC) |
| --- | ---: | --- |
| `crm_accounts_raw` | 3 | `2026-03-08 13:46:00.355445` |
| `duplicate_candidate_pairs` | 3 | `2026-03-09 06:48:15.171485` |
| `firmographic_enrichment` | 3 | `2026-03-09 06:48:37.842910` |
| `governance_ops_metrics` | 1 | `2026-03-09 08:06:47.165711` |
| `hierarchy_entity_graph` | 3 | `2026-03-08 13:46:08.173353` |
| `datacloud_export_accounts` | 3 | `2026-03-09 06:49:02.874379` |

## Validation Links
### Databricks (UI)
- Main dashboard: [Pulse360 S4 - Use Case & Transition Dashboard](https://dbc-7f0ce7bb-56ca.cloud.databricks.com/sql/dashboardsv3/01f11b56ed40102ea9232dfb2404fb1b)
- Demo dashboard: [Pulse360 S4 - Use Case & Transition Dashboard (Demo)](https://dbc-7f0ce7bb-56ca.cloud.databricks.com/sql/dashboardsv3/01f11b5709051df5a21ba10e55942421)
- Lakeview dashboard list: [Databricks SQL Dashboards](https://dbc-7f0ce7bb-56ca.cloud.databricks.com/sql/dashboards)

### Salesforce (UI)
- Org home: [Salesforce Lightning Home](https://orgfarm-2587d03c12-dev-ed.develop.my.salesforce.com/lightning/page/home)
- LWC bundles setup: [Lightning Component Bundles](https://orgfarm-2587d03c12-dev-ed.develop.my.salesforce.com/lightning/setup/LightningComponentBundles/home)
- Lightning App Builder pages: [FlexiPage List](https://orgfarm-2587d03c12-dev-ed.develop.my.salesforce.com/lightning/setup/FlexiPageList/home)
- Account record actions setup: [Account Buttons, Links, and Actions](https://orgfarm-2587d03c12-dev-ed.develop.my.salesforce.com/lightning/setup/ObjectManager/Account/ButtonsLinksActions/view)

## Commands Used (Audit)
```bash
sf org display --json | jq -c '{alias:.result.alias,username:.result.username,instanceUrl:.result.instanceUrl,apiVersion:.result.apiVersion,connectedStatus:.result.connectedStatus}'

sf data query --use-tooling-api -o pulse360-dev --query "SELECT DeveloperName, MasterLabel, NamespacePrefix, LastModifiedDate FROM LightningComponentBundle WHERE DeveloperName LIKE '%Account360%' OR DeveloperName LIKE '%Governance%' OR DeveloperName LIKE '%CrossSell%' OR DeveloperName LIKE '%Health%' ORDER BY LastModifiedDate DESC" --json

sf data query --use-tooling-api -o pulse360-dev --query "SELECT Id, DeveloperName, MasterLabel, Type, EntityDefinition.QualifiedApiName, LastModifiedDate FROM FlexiPage WHERE Type = 'RecordPage' ORDER BY LastModifiedDate DESC LIMIT 50" --json

sf data query -o pulse360-dev --query "SELECT ActionListContext, ApiName, Label, SourceEntity, Type FROM PlatformAction WHERE ActionListContext IN ('Record','RecordDetail') AND SourceEntity='Account' ORDER BY ApiName LIMIT 100" --json
```

## Conclusion
- Databricks deployment state is partially consistent: assets exist and runtime data is present, but dashboard visual completeness is not yet finished.
- Salesforce deployment state does not yet show Pulse360-specific Milestone D UI metadata in this org, so UI-level HITL proof remains unresolved.
