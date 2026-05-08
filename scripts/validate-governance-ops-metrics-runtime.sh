#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import configparser
import json
import os
import sys
import urllib.error
import urllib.request

WAREHOUSE_ID = os.environ.get("PULSE360_DATABRICKS_WAREHOUSE_ID", "7052914888c7e86c")
RUNTIME_QUERIES = {
    "governance_ops_metrics": """
        SELECT
          COUNT(*) AS row_count,
          MAX(metric_ts) AS max_runtime_ts,
          SUM(cases_resolved) AS cases_resolved,
          MAX(backlog_open) AS backlog_open,
          AVG(avg_resolution_minutes) AS avg_resolution_minutes,
          AVG(quality_score) AS quality_score,
          MAX(model_version) AS model_version
        FROM pulse360_s4.intelligence.governance_ops_metrics
    """,
    "duplicate_candidate_pairs": """
        SELECT
          COUNT(*) AS row_count,
          MAX(run_timestamp) AS max_runtime_ts,
          AVG(duplicate_confidence_score) AS avg_duplicate_confidence,
          MAX(model_version) AS model_version
        FROM pulse360_s4.intelligence.duplicate_candidate_pairs
    """,
    "firmographic_enrichment": """
        SELECT
          COUNT(*) AS row_count,
          MAX(run_timestamp) AS max_runtime_ts,
          AVG(profile_completeness_score) AS avg_profile_completeness,
          AVG(validity_score) AS avg_validity_score,
          MAX(model_version) AS model_version
        FROM pulse360_s4.intelligence.firmographic_enrichment
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


def run_statement(host, token, statement):
    payload = json.dumps(
        {
            "warehouse_id": WAREHOUSE_ID,
            "statement": " ".join(statement.split()),
            "wait_timeout": "30s",
            "on_wait_timeout": "CONTINUE",
        }
    ).encode("utf-8")
    request = urllib.request.Request(
        f"{host}/api/2.0/sql/statements",
        data=payload,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            result = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")[:300]
        raise SystemExit(f"[FAIL] Databricks SQL API call failed: HTTP {exc.code}: {body}") from exc

    if (result.get("status") or {}).get("state") != "SUCCEEDED":
        raise SystemExit(f"[FAIL] Databricks SQL statement failed: {json.dumps(result.get('status'))}")
    columns = [
        column["name"]
        for column in ((result.get("manifest") or {}).get("schema") or {}).get("columns", [])
    ]
    rows = (result.get("result") or {}).get("data_array") or []
    if not rows:
        raise SystemExit("[FAIL] Databricks SQL statement returned no rows")
    return dict(zip(columns, rows[0]))


def require_positive(table, metrics):
    row_count = int(metrics.get("row_count") or 0)
    if row_count <= 0:
        raise SystemExit(f"[FAIL] {table} returned no rows")
    if not metrics.get("max_runtime_ts"):
        raise SystemExit(f"[FAIL] {table} has no runtime timestamp")


def main():
    host, token = load_databricks_config()
    results = {}
    for table, query in RUNTIME_QUERIES.items():
        metrics = run_statement(host, token, query)
        require_positive(table, metrics)
        results[table] = metrics

    governance = results["governance_ops_metrics"]
    if float(governance.get("cases_resolved") or 0) <= 0:
        raise SystemExit("[FAIL] governance_ops_metrics has no resolved cases")
    if float(governance.get("avg_resolution_minutes") or 0) <= 0:
        raise SystemExit("[FAIL] governance_ops_metrics has no positive average resolution time")
    if float(governance.get("quality_score") or 0) <= 0:
        raise SystemExit("[FAIL] governance_ops_metrics has no positive quality score")

    print(json.dumps({"warehouse_id": WAREHOUSE_ID, "tables": results}, indent=2))
    print("[PASS] Governance ops metrics runtime validated")


if __name__ == "__main__":
    main()
PY
