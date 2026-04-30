# DAN-278 Data Cloud Intent Mapping Live Validation

## Scope
Record the resolved live-system validation for the Pulse360 signal-routing `intent_signal_payload` path in `pulse360-agent-target`.

## Validated Runtime
- Data Cloud stream:
  - `DC Export Accounts P360 V2`
  - `DataStream.Id = 1dsdL000000OMyfQAG`
  - `Object API Name = pulse360_account_intelligence_export_v2__dll`
- Live stream health:
  - `ImportRunStatus = SUCCESS`
  - `TotalRowsProcessed = 43`
  - `IsNewFieldsAvailable = false`

## Mapping Outcome
Validated on 2026-04-21 through the live Data Cloud UI:
- `Account -> Is Mapped (3)`
- persisted mappings visible in the hydrated review canvas:
  - `source_account_id -> Account Id`
  - `external_legal_name -> Account Name`
  - `intent_signal_payload -> Intent Signal Payload`

The stream record page still shows `Fields mapped = 5/49`, but the hydrated Account mapping view is the authoritative confirmation for the specific Account-target mappings above.

## Contract Validation
Validated with:

```bash
PULSE360_DEFAULT_DATA_STREAM_NAME='DC Export Accounts P360 V2' \
PULSE360_DEFAULT_SOURCE_OBJECT='pulse360_account_intelligence_export_v2__dll' \
./scripts/validate-data-cloud-field-path.sh
```

Observed result:
- `source_object.missing_field_count = 0`
- `dmo.missing_target_field_count = 0`
- `dmo.missing_mapping_count = 0`
- `account.missing_target_field_count = 0`
- `account.missing_mapping_count = 0`

This confirms the V2 stream, source object, DMO surface, and Account target surface are now aligned for the validated mapping set.

## Salesforce Validation
Validated with:

```bash
sf data query --target-org pulse360-agent-target --query "
SELECT Id, Name, Intent_Signal_Payload__c, External_Legal_Name__c
FROM Account
WHERE Id IN (
  '001dL000024xl9FQAQ',
  '001dL000024xlArQAI',
  '001dL000024wgYRQAY',
  '001dL000024weudQAA',
  '001dL000024xj2cQAA'
)
" --json
```

Observed result:
- all sampled Accounts returned populated `Intent_Signal_Payload__c`
- all sampled Accounts returned populated `External_Legal_Name__c`

Validated sample records:
- `001dL000024xl9FQAQ` `Singtel Group`
- `001dL000024xlArQAI` `NCS Pte. Ltd.`
- `001dL000024wgYRQAY` `Ayala Corporation`
- `001dL000024weudQAA` `Ayala Corp.`
- `001dL000024xj2cQAA` `JG Summit Holdings, Inc.`

## Interpretation
- The previous uncertainty was not caused by bad mapping instructions.
- The intended `intent_signal_payload -> Intent Signal Payload` mapping is now proven in the live V2 stream path.
- The direct CRM activation path for the validated field set is healthy again in `pulse360-agent-target`.

## Practical Conclusion
For `DAN-278`, the Data Cloud mapping blocker is resolved for the validated field set.

The next work should shift from proving the field path to validating and refining the Signal Routing Workspace against live records.
