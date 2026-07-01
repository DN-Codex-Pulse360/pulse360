#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export REPO_ROOT
export TARGET_WAREHOUSE_ID="${TARGET_WAREHOUSE_ID:-}"
export PULSE360_DATABRICKS_PUBLISH_DRY_RUN="${PULSE360_DATABRICKS_PUBLISH_DRY_RUN:-0}"

python3 - <<'PY'
import configparser
import json
import os
import pathlib
import sys
import time
from datetime import datetime, timezone

import requests

repo_root = pathlib.Path(os.environ["REPO_ROOT"])
cfg_path = pathlib.Path.home() / ".databrickscfg"
cfg = configparser.ConfigParser()
if not cfg.read(cfg_path):
    raise SystemExit(f"Unable to read Databricks config from {cfg_path}")

profile = "DEFAULT"
host = cfg[profile]["host"].rstrip("/")
token = cfg[profile]["token"]
headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

warehouse_id = os.environ.get("TARGET_WAREHOUSE_ID", "").strip()
dry_run = os.environ.get("PULSE360_DATABRICKS_PUBLISH_DRY_RUN", "0") == "1"
if not warehouse_id:
    response = requests.get(f"{host}/api/2.0/sql/warehouses", headers=headers, timeout=30)
    response.raise_for_status()
    warehouses = response.json().get("warehouses", [])
    if not warehouses:
        raise SystemExit("No Databricks SQL warehouse is available.")
    warehouse_id = warehouses[0]["id"]

sql_files = [
    repo_root / "sql/databricks/proactive_signal/00_create_schemas.sql",
    repo_root / "sql/databricks/proactive_signal/05_northstar_source_change_fixture.sql",
    repo_root / "sql/databricks/proactive_signal/10_northstar_proactive_account_signal.sql",
    repo_root / "sql/databricks/proactive_signal/20_datacloud_proactive_signal_projection.sql",
]

required_projection_columns = {
    "source_account_id",
    "account_name",
    "hierarchy_payload",
    "intent_signal_payload",
    "coverage_gap_flag",
    "ai_narrative",
    "ai_recommended_actions",
    "source_refs",
    "citation_count",
    "ingestion_metadata_label",
    "agentforce_execution_policy",
    "run_id",
    "run_timestamp",
    "model_version",
}


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


def api_error_message(response: requests.Response) -> str:
    try:
        payload = response.json()
    except ValueError:
        return response.text[:1000]
    reason = ""
    for detail in payload.get("details", []):
        metadata = detail.get("metadata", {})
        if metadata.get("denyReason"):
            reason = f" ({metadata['denyReason']})"
            break
    return f"{payload.get('message', response.text)}{reason}"


def warehouse_state() -> str:
    response = requests.get(
        f"{host}/api/2.0/sql/warehouses/{warehouse_id}",
        headers=headers,
        timeout=30,
    )
    response.raise_for_status()
    return response.json().get("state", "UNKNOWN")


def ensure_warehouse_running() -> None:
    state = warehouse_state()
    if state == "RUNNING":
        return
    if state not in {"STOPPED", "STOPPING", "STARTING"}:
        raise SystemExit(f"Warehouse {warehouse_id} is not runnable; current state is {state}")

    if state == "STOPPED":
        start = requests.post(
            f"{host}/api/2.0/sql/warehouses/{warehouse_id}/start",
            headers=headers,
            timeout=30,
        )
        if start.status_code >= 400:
            raise SystemExit(
                f"Unable to start Databricks warehouse {warehouse_id}: {api_error_message(start)}"
            )

    for _ in range(30):
        state = warehouse_state()
        if state == "RUNNING":
            return
        time.sleep(5)
    raise SystemExit(f"Warehouse {warehouse_id} did not reach RUNNING state within the wait window")


def execute_statement(statement: str, label: str, disposition: str = "INLINE") -> dict:
    submit = requests.post(
        f"{host}/api/2.0/sql/statements",
        headers=headers,
        data=json.dumps(
            {
                "warehouse_id": warehouse_id,
                "statement": statement,
                "wait_timeout": "50s",
                "disposition": disposition,
                "catalog": "pulse360_s4",
            }
        ),
        timeout=30,
    )
    if submit.status_code >= 400:
        raise SystemExit(f"Databricks statement submit failed for {label}: {api_error_message(submit)}")
    payload = submit.json()
    statement_id = payload["statement_id"]
    if payload.get("status", {}).get("state") not in {"SUCCEEDED", "FAILED", "CANCELED", "CLOSED"}:
        payload = wait_for_statement(statement_id)

    state = payload.get("status", {}).get("state")
    if state != "SUCCEEDED":
        print(json.dumps(payload, indent=2))
        raise SystemExit(f"Databricks statement failed for {label}: {state}")
    return payload


def run_query(statement: str, label: str) -> dict:
    return execute_statement(statement, label)


def data_array(payload: dict) -> list:
    return payload.get("result", {}).get("data_array", [])


if dry_run:
    print("[DRY-RUN] Would apply SQL files in order:")
    for sql_file in sql_files:
        print(f"  - {sql_file.relative_to(repo_root)}")
    print(f"[DRY-RUN] Would use warehouse {warehouse_id} in state {warehouse_state()}")
    raise SystemExit(0)

ensure_warehouse_running()

for sql_file in sql_files:
    raw_text = sql_file.read_text()
    statements = [chunk.strip() for chunk in raw_text.split(";") if chunk.strip()]
    for index, statement in enumerate(statements, start=1):
        execute_statement(statement, f"{sql_file.name}#{index}")
    print(f"[OK] Applied {sql_file.relative_to(repo_root)} via warehouse {warehouse_id}")

describe_payload = run_query(
    "DESCRIBE TABLE pulse360_s4.gold_proactive_signal.datacloud_proactive_signal_projection",
    "describe proactive projection",
)
columns = {
    row[0]
    for row in data_array(describe_payload)
    if row and row[0] and not str(row[0]).startswith("#")
}
missing_columns = sorted(required_projection_columns - columns)
if missing_columns:
    raise SystemExit("Projection missing required columns: " + ", ".join(missing_columns))

count_payload = run_query(
    "SELECT COUNT(*) AS row_count FROM pulse360_s4.gold_proactive_signal.datacloud_proactive_signal_projection",
    "count proactive projection",
)
row_count = int(data_array(count_payload)[0][0])
if row_count != 1:
    raise SystemExit(f"Expected exactly one proactive demo projection row, found {row_count}")

sample_payload = run_query(
    """
    SELECT
      account_name,
      source_account_id,
      coverage_gap_flag,
      citation_count,
      ingestion_metadata_label,
      run_id,
      model_version,
      intent_signal_payload,
      ai_recommended_actions,
      agentforce_execution_policy
    FROM pulse360_s4.gold_proactive_signal.datacloud_proactive_signal_projection
    LIMIT 1
    """,
    "sample proactive projection",
)
sample_rows = data_array(sample_payload)
if not sample_rows:
    raise SystemExit("No sample row returned from proactive projection")

checked_at = datetime.now(timezone.utc)
evidence = {
    "checked_at": checked_at.isoformat(),
    "workspace_host": host,
    "warehouse_id": warehouse_id,
    "projection": "pulse360_s4.gold_proactive_signal.datacloud_proactive_signal_projection",
    "row_count": row_count,
    "required_columns_present": sorted(required_projection_columns),
    "sample_row": {
        "account_name": sample_rows[0][0],
        "source_account_id": sample_rows[0][1],
        "coverage_gap_flag": sample_rows[0][2],
        "citation_count": sample_rows[0][3],
        "ingestion_metadata_label": sample_rows[0][4],
        "run_id": sample_rows[0][5],
        "model_version": sample_rows[0][6],
        "intent_signal_payload": sample_rows[0][7],
        "ai_recommended_actions": sample_rows[0][8],
        "agentforce_execution_policy": sample_rows[0][9],
    },
}

evidence_dir = repo_root / "docs/evidence"
evidence_dir.mkdir(parents=True, exist_ok=True)
evidence_path = evidence_dir / f"pulse360-proactive-signal-databricks-live-check-{checked_at.date().isoformat()}.json"
evidence_path.write_text(json.dumps(evidence, indent=2) + "\n")

print("[OK] Verified proactive projection columns and row count")
print(f"[OK] Wrote evidence to {evidence_path.relative_to(repo_root)}")
PY
