# DAN-63 Salesforce Deployment Evidence (2026-03-09)

## Scope
Deployed first Milestone D recovery slice for `DAN-63`:
- `LightningComponentBundle`: `pulse360GovernanceCase`
- `FlexiPage`: `Pulse360_Account_Record_Page`

Org alias: `pulse360-dev`  
Instance: `https://orgfarm-2587d03c12-dev-ed.develop.my.salesforce.com`

## Deployment Commands and Results
1. Initial deployment (partial success, flexipage design-time resolution error):
- Command: `sf project deploy start -o pulse360-dev -d force-app --json`
- Deployment ID: `0AfdM00000WS5OvSAL`
- Result: `pulse360GovernanceCase` created, `Pulse360_Account_Record_Page` failed.

2. Corrective deployment (success):
- Command: `sf project deploy start -o pulse360-dev -m LightningComponentBundle:pulse360GovernanceCase -m FlexiPage:Pulse360_Account_Record_Page --json`
- Deployment ID: `0AfdM00000WRijOSAT`
- Result: both components created.

## Deployed Metadata IDs (Tooling API Verification)
- LWC bundle query:
  - `SELECT Id, DeveloperName, MasterLabel, LastModifiedDate FROM LightningComponentBundle WHERE DeveloperName='pulse360GovernanceCase'`
  - Result:
    - `Id`: `0RbdM000005UeQ9SAK`
    - `DeveloperName`: `pulse360GovernanceCase`
    - `MasterLabel`: `Pulse360 Governance Case`
    - `LastModifiedDate`: `2026-03-09T12:55:58.000+0000`

- FlexiPage query:
  - `SELECT Id, DeveloperName, MasterLabel, Type, LastModifiedDate FROM FlexiPage WHERE DeveloperName='Pulse360_Account_Record_Page'`
  - Result:
    - `Id`: `0M0dM00000EUu6LSAT`
    - `DeveloperName`: `Pulse360_Account_Record_Page`
    - `MasterLabel`: `Pulse360 Account Record Page`
    - `Type`: `RecordPage`
    - `LastModifiedDate`: `2026-03-09T12:55:58.000+0000`

## Runtime Validation (DAN-63 Payload Path)
- Command: `./scripts/validate-governance-case-runtime.sh`
- Result: `PASS`
- Key check result:
  - `candidate_pairs=3`
  - confidence/validity/identity ranges and run metadata checks passed

## UI Validation Links
- Lightning Component Bundles:
  - https://orgfarm-2587d03c12-dev-ed.develop.my.salesforce.com/lightning/setup/LightningComponentBundles/home
- FlexiPage List:
  - https://orgfarm-2587d03c12-dev-ed.develop.my.salesforce.com/lightning/setup/FlexiPageList/home

## Remaining Gap
Milestone D global acceptance is still open/fail because remaining required metadata for `DAN-64/65/66` is not deployed yet:
- `pulse360Account360`
- `pulse360HealthScan`
- `pulse360CrossSellBanner`
- Account actions:
  - `Pulse360_QuickCreateOpportunity`
  - `Pulse360_HealthScanAction`

Full validator confirmation:
- Command: `./scripts/validate-salesforce-deployment-runtime.sh`
- Result:
  - `[MISSING] LWC bundle: pulse360Account360`
  - `[MISSING] LWC bundle: pulse360HealthScan`
  - `[MISSING] LWC bundle: pulse360CrossSellBanner`
  - `[MISSING] Account action: Pulse360_QuickCreateOpportunity`
  - `[MISSING] Account action: Pulse360_HealthScanAction`
