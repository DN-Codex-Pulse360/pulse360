#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_PATH="$ROOT_DIR/config/databricks/revops-module-delivery-sequence.json"
PLAN_PATH="$ROOT_DIR/docs/planning/pulse360-revops-module-delivery-sequence-2026-05-08.md"

echo "[validate-revops-module-sequence] Checking source artifacts"

test -f "$CONFIG_PATH"
test -f "$PLAN_PATH"

python3 - "$CONFIG_PATH" <<'PY'
import json
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
payload = json.loads(config_path.read_text())

errors = []

def require(condition, message):
    if not condition:
        errors.append(message)

require(payload.get("linear_parent") == "DAN-280", "linear_parent must be DAN-280")
require(payload.get("linear_issue") == "DAN-291", "linear_issue must be DAN-291")
require(payload.get("selected_first_slice") == "M1", "selected_first_slice must be M1")
require(
    "native runtime is proven" in payload.get("agentforce_posture", ""),
    "agentforce_posture must gate native runtime claims",
)

modules = payload.get("modules", [])
require(len(modules) == 6, "exactly six modules are required")

module_ids = [module.get("module_id") for module in modules]
require(module_ids == ["M1", "M2", "M3", "M4", "M5", "M6"], "modules must be ordered M1 through M6")

priorities = [module.get("priority") for module in modules]
require(priorities == [1, 2, 3, 4, 5, 6], "module priorities must be 1 through 6")

required_list_fields = [
    "mvp_scope",
    "source_dependencies",
    "data_products",
    "data_cloud_outputs",
    "salesforce_surfaces",
    "acceptance_gates",
]

for module in modules:
    module_id = module.get("module_id", "<missing>")
    for field in ["module_name", "delivery_slice", "business_goal", "status"]:
        require(bool(module.get(field)), f"{module_id} must define {field}")
    for field in required_list_fields:
        value = module.get(field)
        require(isinstance(value, list) and len(value) > 0, f"{module_id}.{field} must be a non-empty list")

by_id = {module["module_id"]: module for module in modules}

m1_deps = set(by_id["M1"].get("source_dependencies", []))
for issue in ["DAN-282", "DAN-284", "DAN-285", "DAN-287", "DAN-288"]:
    require(issue in m1_deps, f"M1 must depend on {issue}")
require(not by_id["M1"].get("open_blockers"), "M1 must not have open blockers")

for module_id in ["M2", "M3", "M5", "M6"]:
    deps = set(by_id[module_id].get("source_dependencies", []))
    blockers = set(by_id[module_id].get("open_blockers", []))
    require("DAN-286" in deps, f"{module_id} must depend on DAN-286")
    require("DAN-286" in blockers, f"{module_id} must list DAN-286 as an open blocker")

m3_deps = set(by_id["M3"].get("source_dependencies", []))
require("DAN-291:M1" in m3_deps, "M3 must explicitly depend on the M1 slice")

next_sequence = payload.get("next_linear_sequence", [])
require(next_sequence == ["DAN-286", "DAN-290", "DAN-292"], "next_linear_sequence must be DAN-286, DAN-290, DAN-292")

serialized = json.dumps(payload)
for forbidden in ["Provider ID as sovereign", "native Agentforce success"]:
    require(forbidden not in serialized, f"forbidden claim found: {forbidden}")

if errors:
    print("[validate-revops-module-sequence] FAILED")
    for error in errors:
        print(f" - {error}")
    sys.exit(1)

print("[validate-revops-module-sequence] JSON contract OK")
PY

grep -q "DAN-291" "$PLAN_PATH"
grep -q "M1 Account Hierarchy Intelligence" "$PLAN_PATH"
grep -q "DAN-286" "$PLAN_PATH"
grep -q "native Agentforce success" "$PLAN_PATH"

echo "[validate-revops-module-sequence] Planning doc OK"
