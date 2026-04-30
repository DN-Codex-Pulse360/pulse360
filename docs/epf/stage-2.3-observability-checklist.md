# EPF Stage 2.3 - Observability Checklist (DAN-53)

## Purpose
Define minimum observability controls for API calls, pipeline runs, and DS scenario replay evidence.

## Control Checklist
| Control Area | Control Point | Required Evidence | Owner |
| --- | --- | --- | --- |
| API tracing | Correlation ID propagated across Salesforce -> Data Cloud -> Databricks paths | Trace/sample log with shared correlation ID | Integration Engineer |
| API tracing | Request/response status and latency logged for critical endpoints | Endpoint telemetry report or log extract | Platform Engineer |
| API tracing | Failure events include error code, source, and retry disposition | Error log sample with retry metadata | Platform Engineer |
| Pipeline metadata | Every run includes `run_id`, `run_timestamp`, `model_version` | Sample output rows and contract validation pass | Data Engineer |
| Pipeline metadata | Source snapshot/version recorded for replayability | Run metadata record in pipeline logs | Data Engineer |
| Pipeline metadata | Lineage path from source table to output artifact visible | Lineage evidence (config + runtime check output) | Data Engineer |
| Scenario replay | DS-01/02/03 replay logs include start/end timestamps | Replay checklist log with timings | QA Lead |
| Scenario replay | Last-synced timestamp visible in activation payload/UI evidence | Payload sample + UI reference | Salesforce Engineer |
| Scenario replay | Gate evidence references are linked in control center and Linear | Updated control-center row + Linear comments | Project Lead |

## Minimum Log Fields
1. `correlation_id`
2. `scenario_id` (`DS-01`, `DS-02`, `DS-03`)
3. `run_id`
4. `run_timestamp`
5. `component` (CRM, Databricks, Data Cloud, Agentforce)
6. `event_type` (ingest, match, enrich, activate, action)
7. `status` (success, warning, failure)
8. `latency_ms`

## Replay Control Points
1. Confirm baseline sample payloads are versioned in repo.
2. Confirm validation scripts execute successfully before walkthrough.
3. Record scenario run timing and key evidence references per run.
4. Capture defects and remediation owner when replay mismatches expected evidence.

## Notion and Repo Parity Note
This checklist is the repo source for control points. The same control points should be mirrored in Notion Security/Runbook pages to keep cross-surface parity.

## Gate 2.3 Self-Check
Gate question: can a developer trace requests end-to-end through the observability stack?

Status: **Pass**  
Rationale: the checklist defines required telemetry fields, trace controls, and replay evidence expectations, and remains linked from the EPF control center as the repo source of truth.
