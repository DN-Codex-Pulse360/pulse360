# DAN-65 Salesforce Deployment Evidence (2026-03-09)

## Scope
Delivered DAN-65 deployment slice in `pulse360-dev`:
- `LightningComponentBundle`: `pulse360HealthScan`
- Account action metadata for health-scan and quick-create via `WebLink`:
  - `Pulse360_HealthScanAction`
  - `Pulse360_QuickCreateOpportunity`

Org alias: `pulse360-dev`  
Instance: `https://orgfarm-2587d03c12-dev-ed.develop.my.salesforce.com`

## Deployment Results
1. Health scan LWC deploy:
- Command: `sf project deploy start -o pulse360-dev -d force-app/main/default/lwc/pulse360HealthScan --json`
- Deployment ID: `0AfdM00000WSINlSAP`
- Result: success.

2. Account web-link actions deploy:
- Command: `sf project deploy start -o pulse360-dev -d force-app/main/default/objects/Account/webLinks --json`
- Deployment ID: `0AfdM00000WRoSDSA1`
- Result: success.

## Deployed Metadata IDs
- LWC (`pulse360HealthScan`):
  - `Id`: `0RbdM000005UgerSAC`
  - `MasterLabel`: `Pulse360 Health Scan`
  - `LastModifiedDate`: `2026-03-09T13:53:20.000+0000`

- WebLink actions:
  - `Pulse360_HealthScanAction`: `00bdM000007EDEWQA4`
  - `Pulse360_QuickCreateOpportunity`: `00bdM000007EDEXQA4`

## Runtime Validation
- Command: `./scripts/validate-agentforce-health-scan-runtime.sh`
- Result: `PASS`
- Output includes:
  - `response_status=degraded`
  - `response_error_code=STALE_DATA_WINDOW_EXCEEDED`
  - `response_run_id=run_20260309_064746`

## Milestone D Global Validator Delta
- Command: `./scripts/validate-salesforce-deployment-runtime.sh`
- Current result: `FAIL`
- Remaining missing metadata:
  - `pulse360CrossSellBanner`
- This confirms DAN-65 slice is present and the global gate is now primarily blocked by DAN-66 bundle deployment.

## UI Validation Links
- LWC bundle list:
  - https://orgfarm-2587d03c12-dev-ed.develop.my.salesforce.com/lightning/setup/LightningComponentBundles/home
- Account Buttons/Links/Actions:
  - https://orgfarm-2587d03c12-dev-ed.develop.my.salesforce.com/lightning/setup/ObjectManager/Account/ButtonsLinksActions/view
