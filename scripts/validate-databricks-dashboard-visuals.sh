#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import configparser
import json
import os
import sys
import urllib.error
import urllib.request

DASHBOARDS = {
    "main": "01f11b56ed40102ea9232dfb2404fb1b",
    "demo": "01f11b5709051df5a21ba10e55942421",
}
REQUIRED_TOKENS = ["DS-01", "DS-02", "DS-03", "Freshness"]
FORBIDDEN_TOKENS = ["TODO", "PLACEHOLDER", "builder placeholder"]


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


def fetch_dashboard(host, token, dashboard_id):
    request = urllib.request.Request(
        f"{host}/api/2.0/lakeview/dashboards/{dashboard_id}",
        headers={"Authorization": f"Bearer {token}"},
    )
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")[:300]
        raise SystemExit(f"[FAIL] Dashboard {dashboard_id} API call failed: HTTP {exc.code}: {body}") from exc


def validate_dashboard(name, dashboard):
    dashboard_id = DASHBOARDS[name]
    serialized = dashboard.get("serialized_dashboard") or ""
    if dashboard.get("lifecycle_state") != "ACTIVE":
        raise SystemExit(f"[FAIL] Dashboard {dashboard_id} is not ACTIVE")
    if not serialized:
        raise SystemExit(f"[FAIL] Dashboard {dashboard_id} has no serialized dashboard payload")
    try:
        parsed = json.loads(serialized)
    except json.JSONDecodeError as exc:
        raise SystemExit(f"[FAIL] Dashboard {dashboard_id} serialized payload is not JSON: {exc}") from exc

    serialized_upper = serialized.upper()
    missing_tokens = [token for token in REQUIRED_TOKENS if token.upper() not in serialized_upper]
    forbidden_hits = [token for token in FORBIDDEN_TOKENS if token.upper() in serialized_upper]
    if missing_tokens:
        raise SystemExit(f"[FAIL] Dashboard {dashboard_id} missing visual tokens: {missing_tokens}")
    if forbidden_hits:
        raise SystemExit(f"[FAIL] Dashboard {dashboard_id} contains placeholder tokens: {forbidden_hits}")

    datasets = parsed.get("datasets") or []
    pages = parsed.get("pages") or []
    widget_count = 0
    titled_widgets = []
    for page in pages:
        for item in page.get("layout") or []:
            widget = item.get("widget") or {}
            if widget:
                widget_count += 1
            frame = ((widget.get("spec") or {}).get("frame") or {})
            title = frame.get("title")
            if title:
                titled_widgets.append(title)

    if len(datasets) < 4:
        raise SystemExit(f"[FAIL] Dashboard {dashboard_id} has fewer than four datasets")
    if widget_count < 4:
        raise SystemExit(f"[FAIL] Dashboard {dashboard_id} has fewer than four widgets")

    return {
        "dashboard": name,
        "id": dashboard_id,
        "display_name": dashboard.get("display_name"),
        "state": dashboard.get("lifecycle_state"),
        "warehouse_id": dashboard.get("warehouse_id"),
        "dataset_count": len(datasets),
        "widget_count": widget_count,
        "required_tokens": REQUIRED_TOKENS,
        "sample_widget_titles": titled_widgets[:8],
    }


def main():
    host, token = load_databricks_config()
    results = []
    for name, dashboard_id in DASHBOARDS.items():
        results.append(validate_dashboard(name, fetch_dashboard(host, token, dashboard_id)))
    print(json.dumps({"dashboards": results}, indent=2))
    print("[PASS] Databricks dashboard visuals validated")


if __name__ == "__main__":
    main()
PY
