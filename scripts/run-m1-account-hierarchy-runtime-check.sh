#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import configparser
import json
import os
import time
import urllib.error
import urllib.request
from pathlib import Path

WAREHOUSE_ID = os.environ.get("PULSE360_DATABRICKS_WAREHOUSE_ID", "7052914888c7e86c")
SQL_FILES = [
    "sql/databricks/account_hierarchy/00_create_schema.sql",
    "sql/databricks/account_hierarchy/10_m1_account_hierarchy_edge.sql",
    "sql/databricks/account_hierarchy/20_m1_account_group_rollup.sql",
    "sql/databricks/account_hierarchy/30_m1_account_hierarchy_activation.sql",
]
METRIC_QUERIES = {
    "m1_account_hierarchy_edge": """
        SELECT
          COUNT(*) AS row_count,
          COUNT(DISTINCT parent_source_account_id) AS parent_count,
          COUNT(DISTINCT child_source_account_id) AS child_count,
          AVG(confidence) AS avg_confidence,
          MAX(generated_at) AS max_generated_at,
          MAX(model_version) AS model_version
        FROM pulse360_s4.intelligence.m1_account_hierarchy_edge
    """,
    "m1_account_group_rollup": """
        SELECT
          COUNT(*) AS row_count,
          SUM(member_account_count) AS total_member_count,
          SUM(known_child_account_count) AS known_child_account_count,
          SUM(coverage_gap_count) AS coverage_gap_count,
          AVG(hierarchy_completeness_score) AS avg_hierarchy_completeness_score,
          MAX(generated_at) AS max_generated_at,
          MAX(model_version) AS model_version
        FROM pulse360_s4.intelligence.m1_account_group_rollup
    """,
    "m1_account_hierarchy_activation": """
        SELECT
          COUNT(*) AS row_count,
          COUNT(DISTINCT source_account_id) AS distinct_source_account_count,
          COUNT(DISTINCT account_group_id) AS account_group_count,
          SUM(CASE WHEN coverage_gap_flag THEN 1 ELSE 0 END) AS coverage_gap_account_count,
          AVG(confidence) AS avg_confidence,
          MAX(generated_at) AS max_generated_at,
          MAX(model_version) AS model_version
        FROM pulse360_s4.intelligence.m1_account_hierarchy_activation
    """,
}


def load_databricks_config():
    profile = os.environ.get("DATABRICKS_CONFIG_PROFILE", "DEFAULT")
    cfg_path = os.path.expanduser(os.environ.get("DATABRICKS_CONFIG_FILE", "~/.databrickscfg"))
    cfg = configparser.ConfigParser()
    if not cfg.read(cfg_path):
        raise SystemExit(f"[FAIL] Databricks config not found at {cfg_path}")
    if profile not in cfg:
        raise SystemExit(f"[FAIL] Databricks profile '{profile}' not found in {cfg_path}")
    host = cfg[profile].get("host", "").rstrip("/")
    token = cfg[profile].get("token", "")
    if not host or not token:
        raise SystemExit(f"[FAIL] Databricks profile '{profile}' is missing host or token")
    return host, token


def api_request(host, token, method, path, payload=None):
    data = None
    if payload is not None:
        data = json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(
        f"{host}{path}",
        data=data,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        method=method,
    )
    try:
        with urllib.request.urlopen(request, timeout=90) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")[:500]
        raise SystemExit(f"[FAIL] Databricks API call failed: HTTP {exc.code}: {body}") from exc


def run_statement(host, token, statement):
    result = api_request(
        host,
        token,
        "POST",
        "/api/2.0/sql/statements",
        {
            "warehouse_id": WAREHOUSE_ID,
            "statement": " ".join(statement.split()),
            "wait_timeout": "30s",
            "on_wait_timeout": "CONTINUE",
        },
    )
    statement_id = result.get("statement_id")
    state = (result.get("status") or {}).get("state")

    deadline = time.time() + 300
    while state in {"PENDING", "RUNNING"} and statement_id and time.time() < deadline:
        time.sleep(5)
        result = api_request(host, token, "GET", f"/api/2.0/sql/statements/{statement_id}")
        state = (result.get("status") or {}).get("state")

    if state != "SUCCEEDED":
        raise SystemExit(f"[FAIL] Databricks SQL statement failed: {json.dumps(result.get('status'))}")
    return result


def first_row(result):
    columns = [
        column["name"]
        for column in ((result.get("manifest") or {}).get("schema") or {}).get("columns", [])
    ]
    rows = (result.get("result") or {}).get("data_array") or []
    if not rows:
        raise SystemExit("[FAIL] Databricks SQL statement returned no rows")
    return dict(zip(columns, rows[0]))


def as_int(value):
    return int(float(value or 0))


def main():
    host, token = load_databricks_config()
    repo_root = Path.cwd()

    executed = []
    for sql_file in SQL_FILES:
        path = repo_root / sql_file
        if not path.exists():
            raise SystemExit(f"[FAIL] Missing M1 SQL file: {sql_file}")
        run_statement(host, token, path.read_text(encoding="utf-8"))
        executed.append(sql_file)

    metrics = {}
    for table, query in METRIC_QUERIES.items():
        row = first_row(run_statement(host, token, query))
        if as_int(row.get("row_count")) <= 0:
            raise SystemExit(f"[FAIL] {table} returned no rows")
        metrics[table] = row

    activation = metrics["m1_account_hierarchy_activation"]
    if as_int(activation.get("distinct_source_account_count")) <= 0:
        raise SystemExit("[FAIL] M1 activation output has no Account join keys")

    print(json.dumps({
        "warehouse_id": WAREHOUSE_ID,
        "executed_sql_files": executed,
        "tables": metrics,
    }, indent=2))
    print("[PASS] M1 Account Hierarchy runtime validated")


if __name__ == "__main__":
    main()
PY
