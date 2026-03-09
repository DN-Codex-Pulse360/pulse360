# DAN-64 Salesforce Deployment Evidence (2026-03-09)

## Scope
Deployed second Milestone D recovery slice for `DAN-64`:
- `LightningComponentBundle`: `pulse360Account360`
- Updated `FlexiPage`: `Pulse360_Account_Record_Page` to include `pulse360Account360`

Org alias: `pulse360-dev`  
Instance: `https://orgfarm-2587d03c12-dev-ed.develop.my.salesforce.com`

## Deployment Commands and Results
1. Initial deployment attempt (failed):
- Command: `sf project deploy start -o pulse360-dev -m LightningComponentBundle:pulse360Account360 -m FlexiPage:Pulse360_Account_Record_Page --json`
- Deployment ID: `0AfdM00000WS2neSAD`
- Failure reason:
  - `LWC1503`: invalid public property name `dataHealthStatus` (LWC reserved naming rule)
  - FlexiPage design-time resolution failed for `c:pulse360Account360`

2. Corrective deployment (success):
- Command: `sf project deploy start -o pulse360-dev -m LightningComponentBundle:pulse360Account360 -m FlexiPage:Pulse360_Account_Record_Page --json`
- Deployment ID: `0AfdM00000WRksMSAT`
- Result: component created and page updated.

## Deployed Metadata IDs (Tooling API Verification)
- LWC bundle query:
  - `SELECT Id, DeveloperName, MasterLabel, LastModifiedDate FROM LightningComponentBundle WHERE DeveloperName IN ('pulse360GovernanceCase','pulse360Account360')`
  - `pulse360Account360`:
    - `Id`: `0RbdM000005UetBSAS`
    - `DeveloperName`: `pulse360Account360`
    - `MasterLabel`: `Pulse360 Account360`
    - `LastModifiedDate`: `2026-03-09T13:09:49.000+0000`

- FlexiPage query:
  - `SELECT Id, DeveloperName, MasterLabel, Type, LastModifiedDate FROM FlexiPage WHERE DeveloperName='Pulse360_Account_Record_Page'`
  - Result:
    - `Id`: `0M0dM00000EUu6LSAT`
    - `DeveloperName`: `Pulse360_Account_Record_Page`
    - `LastModifiedDate`: `2026-03-09T13:09:49.000+0000`

## Runtime Validation (DAN-64 Payload Path)
- Command: `./scripts/validate-account360-lwc-runtime.sh`
- Result: `PASS`
- Key checks:
  - live-field checks passed (`rows=3`)
  - degraded-mode condition evaluated
  - sample payload query succeeded

## Milestone D Global Validator Status
- Command: `./scripts/validate-salesforce-deployment-runtime.sh`
- Result: `FAIL` (expected until D3/D4 metadata exists)
- Remaining missing metadata:
  - `pulse360HealthScan`
  - `pulse360CrossSellBanner`
  - `Pulse360_QuickCreateOpportunity`
  - `Pulse360_HealthScanAction`

## UI Validation Links
- LWC bundle list:
  - https://orgfarm-2587d03c12-dev-ed.develop.my.salesforce.com/lightning/setup/LightningComponentBundles/home
- Account record page list:
  - https://orgfarm-2587d03c12-dev-ed.develop.my.salesforce.com/lightning/setup/FlexiPageList/home
- Account page builder:
  - https://orgfarm-2587d03c12-dev-ed.develop.lightning.force.com/visualEditor/appBuilder.app?id=0M0dM00000EUu6LSAT
