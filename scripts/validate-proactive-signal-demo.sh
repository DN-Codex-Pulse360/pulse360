#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

python3 - <<'PY'
import json
import sys
from pathlib import Path


def fail(message):
    print(f"[FAIL] {message}", file=sys.stderr)
    sys.exit(1)


def pass_check(message):
    print(f"[PASS] {message}")


root = Path.cwd()
schema_path = root / "contracts/proactive_account_signal.schema.json"
fixture_path = root / "data/samples/northstar_source_change_fixture_sample.json"
signal_path = root / "data/samples/proactive_account_signal_northstar_sample.json"
sql_paths = [
    root / "sql/databricks/proactive_signal/00_create_schemas.sql",
    root / "sql/databricks/proactive_signal/05_northstar_source_change_fixture.sql",
    root / "sql/databricks/proactive_signal/10_northstar_proactive_account_signal.sql",
    root / "sql/databricks/proactive_signal/20_datacloud_proactive_signal_projection.sql",
    root / "sql/databricks/proactive_signal/README.md",
    root / "scripts/publish-databricks-proactive-signal-demo.sh",
]

missing = [str(path.relative_to(root)) for path in (schema_path, fixture_path, signal_path, *sql_paths) if not path.exists()]
if missing:
    fail("Missing proactive signal demo artifact(s): " + ", ".join(missing))

try:
    schema = json.loads(schema_path.read_text())
    fixture = json.loads(fixture_path.read_text())
    signal = json.loads(signal_path.read_text())
except json.JSONDecodeError as exc:
    fail(f"Invalid JSON: {exc}")

required_schema_fields = {
    "signal_id",
    "hero_group",
    "source_account_id",
    "signal_type",
    "trigger_source_events",
    "evidence_summary",
    "data_cloud_projection",
    "agentforce_execution_policy",
    "run_id",
    "run_timestamp",
    "model_version",
}
schema_required = set(schema.get("required", []))
missing_schema_fields = sorted(required_schema_fields - schema_required)
if missing_schema_fields:
    fail("Proactive signal schema missing required fields: " + ", ".join(missing_schema_fields))
pass_check("Proactive signal schema declares the required contract fields")

schema_text = json.dumps(schema)
for field in (
    "intent_signal_payload",
    "coverage_gap_flag",
    "ai_narrative",
    "ai_recommended_actions",
    "source_refs",
    "last_synced_timestamp",
):
    if field not in schema_text:
        fail(f"Proactive signal schema missing Data Cloud projection field: {field}")
pass_check("Schema includes the Data Cloud export projection fields")

if fixture.get("synthetic_flag") is not True:
    fail("Fixture must be explicitly synthetic")
if fixture.get("customer", {}).get("name") != "Meridian Industrial Systems":
    fail("Fixture customer must remain the anonymized Meridian Industrial Systems demo account")
if fixture.get("hero_group", {}).get("group_entity_id") != "grp_northstar_foods":
    fail("Fixture hero group must be grp_northstar_foods")

events = fixture.get("source_events", [])
if len(events) < 5:
    fail("Fixture must contain at least five cross-source events")

event_ids = [event.get("source_event_id") for event in events]
if len(set(event_ids)) != len(event_ids):
    fail("Fixture source_event_id values must be unique")

required_event_fields = {
    "source_event_id",
    "source_family",
    "source_system",
    "source_event_type",
    "event_timestamp",
    "entity_key",
    "group_entity_id",
    "source_refs",
}
for event in events:
    missing_event_fields = sorted(required_event_fields - set(event))
    if missing_event_fields:
        fail(f"Fixture event {event.get('source_event_id', '<unknown>')} missing fields: {', '.join(missing_event_fields)}")
    if event["group_entity_id"] != "grp_northstar_foods":
        fail(f"Fixture event {event['source_event_id']} points at the wrong hero group")
    if not isinstance(event["source_refs"], list) or not event["source_refs"]:
        fail(f"Fixture event {event['source_event_id']} must include at least one source reference")

event_types = {event["source_event_type"] for event in events}
expected_event_types = {
    "installed_base_event",
    "warranty_expiring",
    "no_active_contract",
    "spare_parts_spike",
    "duplicate_subsidiary_candidate",
    "service_case_increase",
}
missing_event_types = sorted(expected_event_types - event_types)
if missing_event_types:
    fail("Fixture missing proactive trigger event types: " + ", ".join(missing_event_types))
pass_check("Source-change fixture has the expected proactive trigger evidence")

if signal.get("signal_type") != "maintenance_coverage_gap":
    fail("Signal type must be maintenance_coverage_gap")
if signal.get("hero_group", {}).get("group_entity_id") != "grp_northstar_foods":
    fail("Signal hero group must be grp_northstar_foods")

source_account_id = signal.get("source_account_id", "")
if not (source_account_id.startswith("001") and 15 <= len(source_account_id) <= 18):
    fail("Signal source_account_id must look like a CRM-safe Salesforce Account Id")

trigger_events = signal.get("trigger_source_events", [])
if len(trigger_events) < 4:
    fail("Signal must reference at least four source-change events")
unknown_trigger_events = sorted(set(trigger_events) - set(event_ids))
if unknown_trigger_events:
    fail("Signal references fixture events that do not exist: " + ", ".join(unknown_trigger_events))

evidence_summary = signal.get("evidence_summary", {})
if evidence_summary.get("source_event_count") != len(trigger_events):
    fail("Signal evidence_summary.source_event_count must match trigger_source_events")

confidence = signal.get("confidence_score")
if not isinstance(confidence, (int, float)) or not (0.65 <= confidence <= 0.95):
    fail("Signal confidence_score must be a cautious actionable score between 0.65 and 0.95")

projection = signal.get("data_cloud_projection", {})
required_projection_fields = {
    "intent_signal_payload",
    "coverage_gap_flag",
    "ai_narrative",
    "ai_recommended_actions",
    "source_refs",
    "last_synced_timestamp",
    "run_id",
    "run_timestamp",
    "model_version",
}
missing_projection_fields = sorted(required_projection_fields - set(projection))
if missing_projection_fields:
    fail("Data Cloud projection missing fields: " + ", ".join(missing_projection_fields))
if projection.get("coverage_gap_flag") is not True:
    fail("Data Cloud projection coverage_gap_flag must be true for this scenario")
pass_check("Signal projects into the current Data Cloud account intelligence export shape")

intent_payload = projection.get("intent_signal_payload", {})
required_salesforce_routing_fields = {
    "routing_version",
    "signal_score",
    "signal_label",
    "threshold_label",
    "route_to",
    "routing_confidence",
    "why_now",
    "drafted_outreach",
    "channel_readiness",
    "top_drivers",
    "generated_at",
}
missing_salesforce_routing_fields = sorted(required_salesforce_routing_fields - set(intent_payload))
if missing_salesforce_routing_fields:
    fail("Intent signal payload missing Salesforce routing fields: " + ", ".join(missing_salesforce_routing_fields))
if intent_payload.get("signal_label") != "Coverage-led review":
    fail("Intent signal payload must use the existing Salesforce signal label: Coverage-led review")
if intent_payload.get("route_to") != "account_owner_plus_coverage":
    fail("Intent signal payload must route to account_owner_plus_coverage")
if not isinstance(intent_payload.get("top_drivers"), list) or len(intent_payload["top_drivers"]) < 3:
    fail("Intent signal payload must preserve at least three top drivers for the Salesforce workspace")
pass_check("Intent signal payload is compatible with the existing Salesforce signal-routing workspace")

source_refs = projection.get("source_refs", [])
if len(source_refs) < 4:
    fail("Data Cloud projection must preserve at least four source references")
unknown_projection_refs = sorted(set(source_refs) - set(event_ids))
if unknown_projection_refs:
    fail("Data Cloud source_refs include unknown source events: " + ", ".join(unknown_projection_refs))

policy = signal.get("agentforce_execution_policy", {})
if policy.get("native_runtime_verified") is not False:
    fail("Agentforce policy must not claim native runtime verification")
if policy.get("fallback_surface") != "custom Salesforce LWC/Apex assistant and action panels":
    fail("Agentforce policy must name the agreed fallback surface")

actions = policy.get("recommended_actions", [])
if not actions:
    fail("Agentforce policy must include recommended actions")
for action in actions:
    action_type = action.get("action_type")
    if action_type in {"create_opportunity", "update_account_hierarchy", "write_crm_field"}:
        if action.get("approval_required") is not True:
            fail(f"High-impact action {action_type} must require approval")
    if action.get("target_record_id") and not str(action["target_record_id"]).startswith("001"):
        fail(f"Action {action_type} target_record_id must remain CRM-safe")
pass_check("Agentforce execution policy is approval-aware and runtime-honest")

if signal.get("unsupported_claim_count") != 0:
    fail("Signal must not contain unsupported claims")
if signal.get("synthetic_flag") is not True:
    fail("Signal sample must be explicitly synthetic")
pass_check("Proactive signal demo artifacts passed validation")

sql_text = "\n".join(path.read_text() for path in sql_paths)
for token in (
    "pulse360_s4.bronze_proactive_signal.northstar_source_change_fixture",
    "pulse360_s4.silver_proactive_signal.northstar_proactive_account_signal",
    "pulse360_s4.gold_proactive_signal.datacloud_proactive_signal_projection",
    "intent_signal_payload",
    "coverage_gap_flag",
    "ai_narrative",
    "ai_recommended_actions",
    "source_refs",
    "last_synced_timestamp",
    "run_id",
    "model_version",
    "signal_score",
    "signal_label",
    "route_to",
    "routing_confidence",
    "top_drivers",
    "maintenance_coverage_gap",
    "custom Salesforce LWC/Apex assistant and action panels",
):
    if token not in sql_text:
        fail(f"Databricks proactive signal SQL pack missing token: {token}")
pass_check("Databricks proactive signal SQL pack names the required bronze, silver, and gold views")

if "native_runtime_verified, false" not in sql_text and "'native_runtime_verified', false" not in sql_text:
    fail("Databricks proactive signal SQL must preserve native_runtime_verified = false")
if "'approval_required', true" not in sql_text:
    fail("Databricks proactive signal SQL must preserve approval_required=true for high-impact actions")
pass_check("Databricks SQL projection preserves Agentforce gating and approval policy")
PY
