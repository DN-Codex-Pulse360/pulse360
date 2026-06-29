#!/usr/bin/env bash
set -euo pipefail

TARGET_ORG="${TARGET_ORG:-pulse360-agent-target}"
SF_BIN="${SF_BIN:-sf}"
API_VERSION="${API_VERSION:-66.0}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export TARGET_ORG
export SF_BIN
export API_VERSION
export REPO_ROOT

python3 - <<'PY'
import json
import os
import pathlib
import subprocess
import sys
from datetime import datetime, timezone
from urllib.parse import quote

import requests

target_org = os.environ["TARGET_ORG"]
sf_bin = os.environ["SF_BIN"]
api_version = os.environ["API_VERSION"]
repo_root = pathlib.Path(os.environ["REPO_ROOT"])
sample_path = repo_root / "data/samples/proactive_account_signal_northstar_sample.json"


def fail(message):
    raise SystemExit(message)


def sf_json(*args):
    completed = subprocess.run(
        [sf_bin, *args, "--json"],
        check=False,
        capture_output=True,
        text=True,
    )
    if completed.returncode != 0:
        print(completed.stdout)
        print(completed.stderr, file=sys.stderr)
        fail(f"sf command failed: {' '.join(args)}")
    return json.loads(completed.stdout)


org_display = sf_json("org", "display", "--target-org", target_org, "--verbose")
instance_url = org_display["result"]["instanceUrl"].rstrip("/")
access_token = org_display["result"]["accessToken"]
headers = {"Authorization": f"Bearer {access_token}", "Content-Type": "application/json"}

sample = json.loads(sample_path.read_text())
projection = sample["data_cloud_projection"]
intent_payload = projection["intent_signal_payload"]
source_refs = projection["source_refs"]
run_timestamp = sample["run_timestamp"]


def request(method, path, **kwargs):
    response = requests.request(
        method,
        f"{instance_url}/services/data/v{api_version}{path}",
        headers=headers,
        timeout=30,
        **kwargs,
    )
    if response.status_code >= 400:
        try:
            detail = response.json()
        except ValueError:
            detail = response.text
        fail(f"Salesforce REST {method} {path} failed with {response.status_code}: {detail}")
    if response.status_code == 204:
        return {}
    return response.json()


def soql(query):
    return request("GET", f"/query?q={quote(query)}")


def query_first(query):
    records = soql(query).get("records", [])
    return records[0] if records else None


def create_sobject(sobject, payload):
    return request("POST", f"/sobjects/{sobject}", data=json.dumps(payload))


def patch_sobject(sobject, record_id, payload):
    request("PATCH", f"/sobjects/{sobject}/{record_id}", data=json.dumps(payload))


def source_ref_objects(ref_ids):
    return [
        {
            "source_id": ref_id,
            "source_name": ref_id.replace("_", " ").title(),
            "source_type": "synthetic_proactive_signal_fixture",
            "source_url": f"fixture://northstar/proactive-signal/{ref_id}",
            "document_date": "2026-06-29",
            "accessed_at": run_timestamp,
            "excerpt": "Synthetic source-change evidence used by the Pulse360 proactive signal demo.",
            "jurisdiction": "ASEAN",
        }
        for ref_id in ref_ids
    ]


account_name = sample["account_name"]
account = query_first(f"SELECT Id, Name FROM Account WHERE Name = '{account_name}' LIMIT 1")
if account:
    account_id = account["Id"]
    account_created = False
else:
    created = create_sobject(
        "Account",
        {
            "Name": account_name,
            "BillingCountry": "Singapore",
            "Industry": "Food & Beverage Manufacturing",
        },
    )
    account_id = created["id"]
    account_created = True

actions = []
for action in projection["ai_recommended_actions"]:
    next_action = dict(action)
    next_action["target_record_id"] = account_id
    actions.append(next_action)

agentforce_policy = dict(sample["agentforce_execution_policy"])
agentforce_policy["fallback_surface"] = "custom Salesforce LWC/Apex assistant and action panels"
agentforce_policy["native_runtime_verified"] = False
for action in agentforce_policy.get("recommended_actions", []):
    action["target_record_id"] = account_id

intent_payload = dict(intent_payload)
intent_payload["generated_at"] = run_timestamp
intent_payload["target_record_id"] = account_id

account_payload = {
    "BillingCountry": "Singapore",
    "Industry": "Food & Beverage Manufacturing",
    "Cross_Sell_Propensity__c": 78,
    "Health_Score__c": 64,
    "Coverage_Gap_Flag__c": True,
    "Competitor_Risk_Signal__c": 12,
    "Primary_Brand_Name__c": "Industrial Service Maintenance",
    "Active_Product_Count__c": 6,
    "Engagement_Intensity_Score__c": 73,
    "Open_Opportunity_Count__c": 0,
    "DataCloud_Last_Synced__c": projection["last_synced_timestamp"],
    "External_Legal_Name__c": account_name,
    "Externally_Validated__c": False,
    "External_Subsidiaries_Found__c": 4,
    "AI_Narrative__c": projection["ai_narrative"],
    "AI_Recommended_Actions__c": json.dumps(actions, separators=(",", ":")),
    "AI_Narrative_Generated__c": run_timestamp,
    "Enrichment_Run_Id__c": sample["run_id"],
    "Regulatory_Readiness_Score__c": 86,
    "Duplicate_Exposure_Count__c": 1,
    "Group_Known_Subsidiary_Count__c": 4,
    "CRM_Covered_Subsidiary_Count__c": 2,
    "External_Revenue_Confirmed__c": 0,
    "AI_Model_Id__c": "proactive-signal-fixture",
    "AI_Prompt_Version__c": "pulse360-proactive-signal-demo-v1",
    "AI_Source_Refs__c": json.dumps(source_ref_objects(source_refs), separators=(",", ":")),
    "AI_Citation_Count__c": len(source_refs),
    "Intent_Signal_Payload__c": json.dumps(intent_payload, separators=(",", ":")),
}

patch_sobject("Account", account_id, account_payload)

contact = query_first(
    "SELECT Id, Email FROM Contact "
    f"WHERE AccountId = '{account_id}' AND Email = 'maya.tan@northstar.example' LIMIT 1"
)
if contact:
    contact_id = contact["Id"]
    contact_created = False
else:
    contact_result = create_sobject(
        "Contact",
        {
            "AccountId": account_id,
            "FirstName": "Maya",
            "LastName": "Tan",
            "Title": "Regional Operations Director",
            "Department": "Operations",
            "Email": "maya.tan@northstar.example",
        },
    )
    contact_id = contact_result["id"]
    contact_created = True

verified = query_first(
    "SELECT Id, Name, Coverage_Gap_Flag__c, Intent_Signal_Payload__c, "
    "AI_Recommended_Actions__c, AI_Source_Refs__c, DataCloud_Last_Synced__c "
    f"FROM Account WHERE Id = '{account_id}' LIMIT 1"
)
if not verified:
    fail("Unable to verify seeded Northstar Account")
for field in [
    "Intent_Signal_Payload__c",
    "AI_Recommended_Actions__c",
    "AI_Source_Refs__c",
    "DataCloud_Last_Synced__c",
]:
    if not verified.get(field):
        fail(f"Seeded Northstar Account is missing {field}")
if verified.get("Coverage_Gap_Flag__c") is not True:
    fail("Seeded Northstar Account Coverage_Gap_Flag__c is not true")

account_url = f"{instance_url}/lightning/r/Account/{account_id}/view"
signal_routing_url = f"{instance_url}/lightning/n/Pulse360_Signal_Routing?c__previewRecordId={account_id}"
evidence = {
    "checked_at": datetime.now(timezone.utc).isoformat(),
    "target_org": target_org,
    "instance_url": instance_url,
    "account_id": account_id,
    "account_created": account_created,
    "contact_id": contact_id,
    "contact_created": contact_created,
    "account_url": account_url,
    "signal_routing_url": signal_routing_url,
    "seed_mode": "fixture_backed_salesforce_preview",
    "native_agentforce_runtime_verified": False,
    "fallback_surface": "custom Salesforce LWC/Apex assistant and action panels",
    "approval_gated_actions": [
        action["action_type"]
        for action in agentforce_policy["recommended_actions"]
        if action.get("approval_required")
    ],
    "populated_fields": sorted(account_payload),
}

evidence_dir = repo_root / "docs/evidence"
evidence_dir.mkdir(parents=True, exist_ok=True)
evidence_path = evidence_dir / "pulse360-proactive-signal-salesforce-seed-2026-06-29.json"
evidence_path.write_text(json.dumps(evidence, indent=2) + "\n")

print(f"[OK] Seeded proactive signal account: {account_name} ({account_id})")
print(f"[OK] Seeded target contact: {contact_id}")
print(f"[OK] Account link: {account_url}")
print(f"[OK] Signal routing link: {signal_routing_url}")
print(f"[OK] Wrote evidence to {evidence_path.relative_to(repo_root)}")
PY
