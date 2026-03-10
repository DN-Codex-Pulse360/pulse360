# DAN-66 Salesforce Deployment Evidence (2026-03-09)

## Scope
Delivered DAN-66 deployment slice in `pulse360-dev`:
- `LightningComponentBundle`: `pulse360CrossSellBanner`

Org alias: `pulse360-dev`  
Instance: `https://orgfarm-2587d03c12-dev-ed.develop.my.salesforce.com`

## Deployment Result
- Command:
  - `sf project deploy start -o pulse360-dev -d force-app/main/default/lwc/pulse360CrossSellBanner --json`
- Successful deployment ID: `0AfdM00000WSMrBSAX`
- Result: `pulse360CrossSellBanner` created.

## Deployed Metadata ID
- Query:
  - `SELECT Id, DeveloperName, MasterLabel, LastModifiedDate FROM LightningComponentBundle WHERE DeveloperName='pulse360CrossSellBanner'`
- Result:
  - `Id`: `0RbdM000005Uh33SAC`
  - `DeveloperName`: `pulse360CrossSellBanner`
  - `MasterLabel`: `Pulse360 CrossSell Banner`
  - `LastModifiedDate`: `2026-03-09T14:09:24.000+0000`

## Runtime Validation
- `./scripts/validate-cross-sell-quick-create-runtime.sh` -> `PASS`
- `./scripts/validate-salesforce-deployment-runtime.sh` -> `PASS`

This confirms the Salesforce deployment runtime gate is now cleared for required Pulse360 bundle/action names.

## UI Validation Links
- LWC bundle list:
  - https://orgfarm-2587d03c12-dev-ed.develop.my.salesforce.com/lightning/setup/LightningComponentBundles/home
- Direct bundle detail:
  - https://orgfarm-2587d03c12-dev-ed.develop.my.salesforce.com/lightning/setup/LightningComponentBundles/page?address=%2F0RbdM000005Uh33SAC
- Account Buttons/Links/Actions:
  - https://orgfarm-2587d03c12-dev-ed.develop.my.salesforce.com/lightning/setup/ObjectManager/Account/ButtonsLinksActions/view
