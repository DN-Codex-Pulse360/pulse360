#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export REPO_ROOT
export TARGET_WAREHOUSE_ID="${TARGET_WAREHOUSE_ID:-}"

python3 - <<'PY'
import configparser
import json
import os
import pathlib
import sys
import time

import requests

repo_root = pathlib.Path(os.environ["REPO_ROOT"])
cfg_path = pathlib.Path.home() / ".databrickscfg"
cfg = configparser.ConfigParser()
if not cfg.read(cfg_path):
    raise SystemExit(f"Unable to read Databricks config from {cfg_path}")

host = cfg["DEFAULT"]["host"].rstrip("/")
token = cfg["DEFAULT"]["token"]
headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

warehouse_id = os.environ.get("TARGET_WAREHOUSE_ID", "").strip()
if not warehouse_id:
    response = requests.get(f"{host}/api/2.0/sql/warehouses", headers=headers, timeout=30)
    response.raise_for_status()
    warehouses = response.json().get("warehouses", [])
    if not warehouses:
        raise SystemExit("No Databricks SQL warehouse is available.")
    warehouse_id = warehouses[0]["id"]

sql_files = [
    repo_root / "sql/databricks/gold/00_create_schemas.sql",
    repo_root / "sql/databricks/gold/10_account_export_base.sql",
    repo_root / "sql/databricks/gold/20_account_core_export.sql",
    repo_root / "sql/databricks/gold/30_datacloud_export_accounts.sql",
]

def wait_for_statement(statement_id: str) -> dict:
    while True:
        result = requests.get(
            f"{host}/api/2.0/sql/statements/{statement_id}",
            headers=headers,
            timeout=30,
        )
        result.raise_for_status()
        payload = result.json()
        state = payload.get("status", {}).get("state")
        if state in {"SUCCEEDED", "FAILED", "CANCELED", "CLOSED"}:
            return payload
        time.sleep(2)

def execute_statement(statement: str, label: str) -> None:
    submit = requests.post(
        f"{host}/api/2.0/sql/statements",
        headers=headers,
        data=json.dumps(
            {
                "warehouse_id": warehouse_id,
                "statement": statement,
                "wait_timeout": "50s",
                "disposition": "INLINE",
                "catalog": "pulse360_s4",
                "schema": "intelligence",
            }
        ),
        timeout=30,
    )
    submit.raise_for_status()
    submit_payload = submit.json()
    statement_id = submit_payload["statement_id"]
    final_payload = submit_payload
    if submit_payload.get("status", {}).get("state") not in {"SUCCEEDED", "FAILED", "CANCELED", "CLOSED"}:
        final_payload = wait_for_statement(statement_id)

    state = final_payload.get("status", {}).get("state")
    if state != "SUCCEEDED":
        print(json.dumps(final_payload, indent=2))
        raise SystemExit(f"Databricks statement failed for {label}: {state}")

for sql_file in sql_files:
    raw_text = sql_file.read_text()
    statements = [chunk.strip() for chunk in raw_text.split(";") if chunk.strip()]
    for index, statement in enumerate(statements, start=1):
        execute_statement(statement, f"{sql_file.name}#{index}")
    print(f"[OK] Applied {sql_file.relative_to(repo_root)} via warehouse {warehouse_id}")

verify = requests.post(
    f"{host}/api/2.0/sql/statements",
    headers=headers,
    data=json.dumps(
        {
            "warehouse_id": warehouse_id,
            "statement": "DESCRIBE TABLE pulse360_s4.intelligence.datacloud_export_accounts",
            "wait_timeout": "50s",
            "disposition": "INLINE",
        }
    ),
    timeout=30,
)
verify.raise_for_status()
verify_payload = verify.json()
statement_id = verify_payload["statement_id"]
if verify_payload.get("status", {}).get("state") not in {"SUCCEEDED", "FAILED", "CANCELED", "CLOSED"}:
    verify_payload = wait_for_statement(statement_id)

if verify_payload.get("status", {}).get("state") != "SUCCEEDED":
    print(json.dumps(verify_payload, indent=2))
    raise SystemExit("Databricks verification statement failed")

rows = verify_payload.get("result", {}).get("data_array", [])
column_names = [row[0] for row in rows if row and row[0]]
if "intent_signal_payload" not in column_names:
    raise SystemExit("intent_signal_payload not present in live datacloud_export_accounts schema")

print("[OK] Verified intent_signal_payload in pulse360_s4.intelligence.datacloud_export_accounts")
PY
