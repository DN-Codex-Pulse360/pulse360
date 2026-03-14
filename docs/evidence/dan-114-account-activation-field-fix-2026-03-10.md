# DAN-114 Account Activation Field Fix - 2026-03-10

## Summary
- Implemented Salesforce source metadata for the Milestone C Account activation target fields.
- Deployed the new Account fields to `pulse360-dev`.
- Verified field existence via Salesforce Tooling API metadata queries.
- Confirmed Data Cloud mapping publish remains incomplete: `MktDataLakeMapping` currently returns zero rows.

## Implemented Fields
- `Unified_Profile_Id__c`
- `Identity_Confidence__c`
- `Group_Revenue_Rollup__c`
- `Health_Score__c`
- `Cross_Sell_Propensity__c`
- `Coverage_Gap_Flag__c`
- `Competitor_Risk_Signal__c`
- `Primary_Brand_Name__c`
- `Active_Product_Count__c`
- `Engagement_Intensity_Score__c`
- `Open_Opportunity_Count__c`
- `Last_Engagement_Timestamp__c`
- `DataCloud_Last_Synced__c`

## Repo Artifacts
- `sfdx-project.json`
- `force-app/main/default/objects/Account/fields/*.field-meta.xml`
- `scripts/validate-salesforce-account-activation-fields.sh`

## Deployment Evidence
- Target org: `pulse360-dev`
- Deploy job: `0AfdM00000WVnQDSA1`
- Deploy result: `Succeeded`
- Components deployed: `13`

## Validation Evidence
- Local metadata validator:
  - `./scripts/validate-salesforce-account-activation-fields.sh` -> PASS
- Live org validator:
  - `TARGET_ORG=pulse360-dev ./scripts/validate-salesforce-account-activation-fields.sh` -> PASS
- Tooling API query result:
  - `CustomField` records found on `Account`: `13`

## Remaining Blocker
- Data Cloud mapping publish is still incomplete.
- Query result:
  - `sf data query --target-org pulse360-dev --query "SELECT Id FROM MktDataLakeMapping LIMIT 5" --json`
  - Result: `totalSize = 0`
- Additional observation:
  - `MktDataLakeMapping` source and target field reference picklists do not yet include the Pulse360 activation fields, so the mapping step is not ready for scripted creation from the current org state.

## Activation Target Attempt
- Created activation target record:
  - Object: `ActivationTarget`
  - Id: `85UdM00000EC7IbUAL`
  - `MasterLabel`: `Pulse360 Salesforce Account Activation`
  - `ConnectionType`: `SalesforceDotCom`
  - `RunStatus`: `QUEUED`
  - `TargetStatus`: `PROCESSING`
- Companion setup was not auto-created:
  - `ActivationTargetPlatform` rows for this target: `0`
  - `ActvTgtPlatformFieldValue` rows in org: `0`
  - `ActivationTrgtIntOrgAccess` rows for this target: `0`
- API-based continuation hit platform limits:
  - Creating `ActivationTargetPlatform` returned `UNKNOWN_EXCEPTION`
  - ErrorId: `74872511-64352 (1343757781)`
  - Creating `ActivationTrgtIntOrgAccess` exposed inconsistent API behavior:
    - initial create response required `InternalOrganizationId`
    - follow-up create using `InternalOrganizationId` failed because the field is not exposed on the sObject API

## Current Assessment
- `DAN-114` step 1 is complete: Account target fields exist in source control and in `pulse360-dev`.
- `DAN-114` step 2 is only partially complete:
  - an activation target record now exists
  - field mappings and platform child records do not
- Remaining completion appears blocked by Salesforce/Data Cloud activation-target setup behavior that is not fully accessible via the current public sObject/API path.

## Milestone C Status Impact
- `DAN-114`: field-creation gap resolved; mapping publish still open.
- `DAN-61`: remains blocked on Data Cloud mapping publish and activation refresh.
- `DAN-103`: remains blocked until mapping rows exist and sample Account records are populated.
