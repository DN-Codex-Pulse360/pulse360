#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import configparser
import json
import pathlib
import sys
import time

import requests


def fail(message: str) -> None:
    print(f"[FAIL] {message}", file=sys.stderr)
    raise SystemExit(1)


cfg_path = pathlib.Path.home() / ".databrickscfg"
cfg = configparser.ConfigParser()
if not cfg.read(cfg_path):
    fail(f"Unable to read Databricks config from {cfg_path}")

host = cfg["DEFAULT"]["host"].rstrip("/")
token = cfg["DEFAULT"]["token"]
headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
warehouse_id = ""

warehouse_response = requests.get(f"{host}/api/2.0/sql/warehouses", headers=headers, timeout=60)
warehouse_response.raise_for_status()
warehouses = warehouse_response.json().get("warehouses", [])
if not warehouses:
    fail("No Databricks SQL warehouse is available.")
warehouse_id = warehouses[0]["id"]


def wait_for_statement(statement_id: str) -> dict:
    while True:
        response = requests.get(
            f"{host}/api/2.0/sql/statements/{statement_id}",
            headers=headers,
            timeout=60,
        )
        response.raise_for_status()
        payload = response.json()
        state = payload.get("status", {}).get("state")
        if state in {"SUCCEEDED", "FAILED", "CANCELED", "CLOSED"}:
            return payload
        time.sleep(2)


def execute(statement: str) -> dict:
    last_error = None
    for _ in range(3):
        try:
            response = requests.post(
                f"{host}/api/2.0/sql/statements",
                headers=headers,
                json={
                    "warehouse_id": warehouse_id,
                    "statement": statement,
                    "wait_timeout": "50s",
                    "disposition": "INLINE",
                },
                timeout=90,
            )
            response.raise_for_status()
            break
        except requests.RequestException as exc:
            last_error = exc
            time.sleep(5)
    else:
        fail(f"Databricks SQL statement submit timed out or failed after retries: {last_error}")
    payload = response.json()
    if payload.get("status", {}).get("state") not in {"SUCCEEDED", "FAILED", "CANCELED", "CLOSED"}:
        payload = wait_for_statement(payload["statement_id"])
    return payload


def scalar(statement: str) -> int:
    payload = execute(statement)
    state = payload.get("status", {}).get("state")
    if state != "SUCCEEDED":
        fail(f"Databricks SQL failed: {payload.get('status', {}).get('error', {})}")
    rows = payload.get("result", {}).get("data_array", [])
    if not rows:
        return 0
    return int(float(rows[0][0]))


assets = {
    "pulse360_s4.silver_salesforce.crm_account": 1,
    "pulse360_s4.silver_salesforce.crm_governance_case": 1,
    "pulse360_s4.identity_resolution.resolved_entity": 1,
    "pulse360_s4.identity_resolution.entity_hierarchy_rollup": 1,
    "pulse360_s4.identity_resolution.m1_account_hierarchy_operational_profile": 1,
    "pulse360_s4.gold.account_genai_enrichment_output": 1,
    "pulse360_s4.gold_smart_city.smart_city_proposition_readiness": 6,
    "pulse360_s4.intelligence.datacloud_export_accounts": 1,
    "pulse360_s4.intelligence.datacloud_activation_review_queue": 6,
    "pulse360_s4.intelligence.governance_case_metrics": 1,
}

asset_results = []
for asset, minimum in assets.items():
    row_count = scalar(f"SELECT COUNT(*) FROM {asset}")
    asset_results.append({"asset": asset, "row_count": row_count, "minimum": minimum})
    if row_count < minimum:
        fail(f"{asset} has {row_count} rows; expected at least {minimum}")

required_columns = {
    "pulse360_s4.intelligence.datacloud_export_accounts": {
        "source_account_id",
        "intent_signal_payload",
        "ai_narrative",
        "ai_recommended_actions",
        "source_refs",
        "ingestion_metadata_label",
        "run_id",
        "run_timestamp",
        "model_version",
    },
    "pulse360_s4.intelligence.datacloud_activation_review_queue": {
        "source_record_id",
        "source_product",
        "target_entity_name",
        "market",
        "offering_family",
        "target_b2b_customer_names",
        "recommended_next_actions",
        "review_priority",
        "confidence_score",
        "activation_block_reasons",
        "run_id",
        "run_timestamp",
    },
}

column_results = []
for table_name, expected in required_columns.items():
    payload = execute(f"DESCRIBE TABLE {table_name}")
    state = payload.get("status", {}).get("state")
    if state != "SUCCEEDED":
        fail(f"Could not describe {table_name}: {payload.get('status', {}).get('error', {})}")
    rows = payload.get("result", {}).get("data_array", [])
    actual = {row[0] for row in rows if row and row[0] and not row[0].startswith("#")}
    missing = sorted(expected - actual)
    column_results.append({"table": table_name, "missing_columns": missing})
    if missing:
        fail(f"{table_name} is missing required columns: {', '.join(missing)}")

manila_action_rows = scalar(
    """
    SELECT COUNT(*)
    FROM pulse360_s4.intelligence.datacloud_activation_review_queue
    WHERE source_product = 'csp_smart_city_proposition_readiness'
      AND market = 'Philippines'
      AND target_b2b_customer_names IS NOT NULL
      AND target_b2b_customer_names <> '[]'
    """
)
if manila_action_rows < 3:
    fail(f"Expected at least 3 Manila CSP action rows, found {manila_action_rows}")

summary = {
    "warehouse_id": warehouse_id,
    "asset_results": asset_results,
    "column_results": column_results,
    "manila_csp_action_rows": manila_action_rows,
}
print(json.dumps(summary, indent=2))
print("[PASS] Databricks data layer runtime check completed")
PY
