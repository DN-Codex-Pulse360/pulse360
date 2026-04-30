#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

pass() {
  echo "[PASS] $1"
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "${repo_root}" <<'PY'
import csv
import json
import pathlib
import sys

repo_root = pathlib.Path(sys.argv[1])


def fail(message: str) -> None:
    print(f"[FAIL] {message}", file=sys.stderr)
    raise SystemExit(1)


def pass_(message: str) -> None:
    print(f"[PASS] {message}")


def load_json(path: pathlib.Path):
    with path.open() as f:
        return json.load(f)


databricks_schema = load_json(repo_root / "contracts/databricks_to_datacloud.schema.json")
activation_schema = load_json(repo_root / "contracts/datacloud_to_salesforce_agentforce.schema.json")
activation_sample = load_json(repo_root / "data/samples/datacloud_activation_sample.json")

databricks_required = set(databricks_schema.get("required", []))
for key in [
    "hierarchy_payload",
    "intent_signal_payload",
    "ai_recommended_actions",
    "source_refs",
    "citation_count",
    "run_id",
    "run_timestamp",
    "model_version",
]:
    if key not in databricks_required:
        fail(f"Databricks handoff schema is missing required field: {key}")

databricks_properties = databricks_schema["properties"]
actions_property = databricks_properties["ai_recommended_actions"]
if actions_property.get("type") != "array":
    fail("Databricks handoff schema must model ai_recommended_actions as an array before CRM realization")

action_required = set(actions_property["items"].get("required", []))
for key in [
    "action_type",
    "target",
    "reasoning",
    "estimated_revenue_impact",
    "confidence",
    "source_ids",
]:
    if key not in action_required:
        fail(f"Databricks handoff schema ai_recommended_actions is missing nested required field: {key}")

source_refs_property = databricks_properties["source_refs"]
if source_refs_property.get("type") != "array":
    fail("Databricks handoff schema must model source_refs as an array before CRM realization")

source_required = set(source_refs_property["items"].get("required", []))
for key in [
    "source_id",
    "source_name",
    "source_type",
    "source_url",
    "document_date",
    "accessed_at",
    "excerpt",
    "jurisdiction",
]:
    if key not in source_required:
        fail(f"Databricks handoff schema source_refs is missing nested required field: {key}")

pass_("Databricks contract preserves structured actions and structured evidence")

activation_required = set(activation_schema.get("required", []))
for key in [
    "unified_profile_id",
    "hierarchy_payload",
    "intent_signal_payload",
    "ai_recommended_actions",
    "last_synced_timestamp",
    "model_id",
    "prompt_version",
    "source_refs",
    "citation_count",
]:
    if key not in activation_required:
        fail(f"CRM activation schema is missing required field: {key}")

activation_properties = activation_schema["properties"]
for key in ["hierarchy_payload", "intent_signal_payload", "ai_recommended_actions", "source_refs"]:
    if activation_properties[key].get("type") != "string":
        fail(
            f"CRM activation schema field {key} must be string-backed because it is realized into Salesforce fields"
        )

pass_("CRM activation contract preserves serialized payload, provenance, and freshness fields")

hierarchy = json.loads(activation_sample["hierarchy_payload"])
children = hierarchy.get("children", [])
if not isinstance(children, list) or not children:
    fail("Activation sample hierarchy_payload must include at least one child entity")

if not any(child.get("crm_record_id") for child in children):
    fail("Activation sample hierarchy_payload must preserve at least one crm_record_id deep link")

for key in ["entity_id", "name", "coverage_status"]:
    if key not in children[0]:
        fail(f"Activation sample hierarchy_payload child is missing field: {key}")

intent_payload = json.loads(activation_sample["intent_signal_payload"])
for key in ["routing_confidence", "why_now", "generated_at", "top_drivers"]:
    if key not in intent_payload:
        fail(f"Activation sample intent_signal_payload is missing field: {key}")

if not isinstance(intent_payload["top_drivers"], list) or not intent_payload["top_drivers"]:
    fail("Activation sample intent_signal_payload must include at least one top driver")

recommended_actions = json.loads(activation_sample["ai_recommended_actions"])
if not isinstance(recommended_actions, list) or not recommended_actions:
    fail("Activation sample ai_recommended_actions must include at least one action")

for key in ["action_type", "target", "reasoning", "confidence", "source_ids"]:
    if key not in recommended_actions[0]:
        fail(f"Activation sample ai_recommended_actions entry is missing field: {key}")

if not any(action.get("target_record_id") for action in recommended_actions):
    fail("Activation sample ai_recommended_actions must preserve at least one target_record_id deep link")

source_refs = json.loads(activation_sample["source_refs"])
if not isinstance(source_refs, list) or not source_refs:
    fail("Activation sample source_refs must include at least one evidence reference")

for key in ["source_id", "source_url", "accessed_at", "excerpt"]:
    if key not in source_refs[0]:
        fail(f"Activation sample source_refs entry is missing field: {key}")

pass_("Activation sample preserves hierarchy, routing, action, and provenance detail")

with (repo_root / "data/samples/databricks_enrichment_sample.csv").open(newline="") as f:
    row = next(csv.DictReader(f))

csv_actions = json.loads(row["ai_recommended_actions"])
if not any(action.get("target_record_id") for action in csv_actions):
    fail("Databricks enrichment sample must preserve target_record_id in the structured action payload")

csv_sources = json.loads(row["source_refs"])
if not all(source.get("source_id") for source in csv_sources):
    fail("Databricks enrichment sample source_refs entries must preserve source_id")

csv_hierarchy = json.loads(row["hierarchy_payload"])
if not any(child.get("crm_record_id") for child in csv_hierarchy.get("children", [])):
    fail("Databricks enrichment sample hierarchy_payload must preserve crm_record_id bindings")

pass_("Databricks enrichment sample preserves deep-link and evidence completeness")
PY

pass "Contract completeness validation completed"
