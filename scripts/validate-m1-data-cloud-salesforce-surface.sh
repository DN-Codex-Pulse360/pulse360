#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

data_cloud_setup="$repo_root/config/data-cloud/m1-account-hierarchy-dlo-dmo-setup.csv"
dmo_field_mapping="$repo_root/config/data-cloud/m1-account-hierarchy-dmo-field-mapping.csv"
activation_mapping="$repo_root/config/data-cloud/m1-account-hierarchy-activation-field-mapping.csv"
report_config="$repo_root/config/salesforce/m1-account-hierarchy-validation-reports.csv"
surface_config="$repo_root/config/salesforce/m1-account-hierarchy-surface.yaml"
runbook="$repo_root/docs/runbook/salesforce-m1-account-hierarchy-validation-runbook.md"
evidence="$repo_root/docs/evidence/dan-334-m1-data-cloud-salesforce-validation-2026-05-09.md"
runtime_evidence="$repo_root/docs/evidence/dan-332-m1-account-hierarchy-runtime-validation-2026-05-08.md"
account_hierarchy_sql_dir="$repo_root/sql/databricks/account_hierarchy"

[[ -f "$data_cloud_setup" ]] || fail "Missing M1 Data Cloud setup config"
[[ -f "$dmo_field_mapping" ]] || fail "Missing M1 DMO field mapping"
[[ -f "$activation_mapping" ]] || fail "Missing M1 activation field mapping"
[[ -f "$report_config" ]] || fail "Missing M1 Salesforce report config"
[[ -f "$surface_config" ]] || fail "Missing M1 Salesforce surface config"
[[ -f "$runbook" ]] || fail "Missing M1 Salesforce/Data Cloud runbook"
[[ -f "$evidence" ]] || fail "Missing M1 Salesforce/Data Cloud evidence"
[[ -f "$runtime_evidence" ]] || fail "Missing M1 Databricks runtime evidence"
pass "M1 Salesforce/Data Cloud source files exist"

for table in \
  "m1_account_hierarchy_activation_export" \
  "m1_account_group_rollup_export" \
  "m1_account_hierarchy_edge_export"; do
  grep -Fq "$table" "$data_cloud_setup" || fail "Data Cloud setup missing table: $table"
  grep -Fq "$table" "$evidence" || fail "Salesforce evidence missing export table: $table"
done
pass "M1 Data Cloud setup references source-controlled export tables"

for dmo in \
  "Pulse360_M1_Hierarchy_Activation__dlm" \
  "Pulse360_M1_Account_Group_Rollup__dlm" \
  "Pulse360_M1_Hierarchy_Edge__dlm"; do
  grep -Fq "$dmo" "$data_cloud_setup" || fail "Data Cloud setup missing DMO: $dmo"
  grep -Fq "$dmo" "$surface_config" || fail "Surface config missing DMO: $dmo"
  grep -Fq "$dmo" "$report_config" || fail "Report config missing DMO: $dmo"
done
pass "M1 DMO names are consistently referenced"

for field in \
  "source_account_id__c -> Account.Id" \
  "group_anchor_source_account_id__c -> Account.Id" \
  "child_source_account_id__c -> Account.Id"; do
  grep -Fq "$field" "$runbook" || fail "Runbook missing relationship rule: $field"
done
pass "M1 Account relationship rules are documented"

for field in \
  "Group_Revenue_Rollup__c" \
  "Group_Known_Subsidiary_Count__c" \
  "Coverage_Gap_Flag__c" \
  "Group_Revenue_Visible__c" \
  "Hierarchy_Payload__c" \
  "DataCloud_Last_Synced__c"; do
  grep -Fq "$field" "$activation_mapping" || fail "Activation mapping missing Account field: $field"
  grep -Fq "$field" "$evidence" || fail "Evidence missing Account field readiness: $field"
done
pass "M1 Account activation fields are mapped and evidenced"

grep -Fq "not_created_live" "$data_cloud_setup" \
  || fail "Data Cloud setup must mark live M1 stream gap"
grep -Fq "No existing Data Cloud DMO relationship changes are required" "$evidence" \
  || fail "Evidence must document existing DMO relationship posture"
grep -Fq "Keep M1 dashboard separate" "$runbook" \
  || fail "Runbook must keep M1 dashboard separate until metadata exists"
grep -Fq "editable: false" "$surface_config" \
  || fail "M1 surface config must keep hierarchy intelligence read-only"

python3 - "$data_cloud_setup" "$dmo_field_mapping" "$activation_mapping" "$report_config" "$account_hierarchy_sql_dir" <<'PY'
import csv
import re
import sys
from pathlib import Path

setup_path, dmo_mapping_path, mapping_path, report_path, sql_dir = sys.argv[1:6]

with open(setup_path, newline="", encoding="utf-8") as handle:
    setup_rows = list(csv.DictReader(handle))
if len(setup_rows) != 3:
    raise SystemExit(f"Expected 3 M1 Data Cloud setup rows, found {len(setup_rows)}")

expected_setup = {
    "m1_account_hierarchy_activation_export": ("source_account_id__c", "18"),
    "m1_account_group_rollup_export": ("group_anchor_source_account_id__c", "17"),
    "m1_account_hierarchy_edge_export": ("child_source_account_id__c", "2"),
}
for row in setup_rows:
    table = row["source_object_name"]
    if table not in expected_setup:
        raise SystemExit(f"Unexpected M1 setup table: {table}")
    expected_join, expected_rows = expected_setup[table]
    if row["account_join_key"] != expected_join:
        raise SystemExit(f"{table} has wrong join key: {row['account_join_key']}")
    if row["account_related_field"] != "Account.Id":
        raise SystemExit(f"{table} must relate to Account.Id")
    if row["expected_rows"] != expected_rows:
        raise SystemExit(f"{table} expected rows must be {expected_rows}")
    if row["setup_status"] != "not_created_live":
        raise SystemExit(f"{table} must remain marked not_created_live until MCP proves it exists")

with open(dmo_mapping_path, newline="", encoding="utf-8") as handle:
    dmo_mapping_rows = list(csv.DictReader(handle))
if not dmo_mapping_rows:
    raise SystemExit("M1 DMO field mapping must contain rows")
expected_mapping_header = [
    "source_object_name",
    "dmo_api_name",
    "source_field",
    "dmo_field_api_name",
    "data_type",
    "required",
    "key_qualifier",
    "relationship_key",
    "notes",
]
if list(dmo_mapping_rows[0].keys()) != expected_mapping_header:
    raise SystemExit(f"M1 DMO field mapping header mismatch: {list(dmo_mapping_rows[0].keys())}")

with open(mapping_path, newline="", encoding="utf-8") as handle:
    mapping_rows = list(csv.DictReader(handle))
if not any(row["source_field"] == "source_account_id" and row["target_field"] == "Id" for row in mapping_rows):
    raise SystemExit("Activation mapping must include source_account_id -> Account.Id")
if not all(row["target_object"] == "Account" for row in mapping_rows):
    raise SystemExit("M1 activation mapping must target Account only")

with open(report_path, newline="", encoding="utf-8") as handle:
    report_rows = list(csv.DictReader(handle))
reports = [row for row in report_rows if row["artifact_type"] == "report"]
dashboards = [row for row in report_rows if row["artifact_type"] == "dashboard"]
if len(reports) != 3:
    raise SystemExit(f"Expected 3 M1 report rows, found {len(reports)}")
if len(dashboards) != 1:
    raise SystemExit(f"Expected 1 M1 dashboard row, found {len(dashboards)}")

expected_reports = {
    "M1_Account_Hierarchy_Activation": ("18", "source_account_id__c"),
    "M1_Account_Group_Rollup": ("17", "group_anchor_source_account_id__c"),
    "M1_Hierarchy_Edges": ("2", "child_source_account_id__c"),
}
for row in reports:
    name = row["developer_name"]
    if name not in expected_reports:
        raise SystemExit(f"Unexpected M1 report: {name}")
    expected_count, expected_key = expected_reports[name]
    if row["row_count_expectation"] != expected_count:
        raise SystemExit(f"{name} expected count must be {expected_count}")
    if row["relationship_key"] != expected_key:
        raise SystemExit(f"{name} relationship key must be {expected_key}")
    if row["promoted_report_id"] or row["promoted_developer_name"]:
        raise SystemExit(f"{name} must not claim live report metadata before creation")
    if "confidence__c" not in row["required_columns"]:
        raise SystemExit(f"{name} must expose confidence__c")

dashboard = dashboards[0]
if dashboard["developer_name"] != "M1_Account_Hierarchy_Validation":
    raise SystemExit("Unexpected M1 dashboard developer name")
if dashboard["promoted_report_id"] or dashboard["promoted_developer_name"]:
    raise SystemExit("M1 dashboard must not claim live metadata before creation")

expected_export_columns = {
    "40_m1_account_hierarchy_activation_export.sql": {
        "activation_id",
        "source_account_id",
        "account_name",
        "account_group_id",
        "group_anchor_source_account_id",
        "group_anchor_name",
        "ultimate_parent_name",
        "member_account_count",
        "known_child_account_count",
        "group_revenue_local",
        "group_revenue_usd",
        "revenue_coverage_ratio",
        "hierarchy_completeness_score",
        "coverage_gap_count",
        "coverage_gap_flag",
        "coverage_gap_summary",
        "confidence",
        "evidence_refs_json",
        "hierarchy_payload",
        "run_id",
        "model_version",
        "generated_at",
    },
    "50_m1_account_group_rollup_export.sql": {
        "account_group_id",
        "group_anchor_source_account_id",
        "group_anchor_name",
        "ultimate_parent_name",
        "member_account_count",
        "known_child_account_count",
        "group_revenue_local",
        "group_revenue_usd",
        "revenue_coverage_ratio",
        "hierarchy_completeness_score",
        "coverage_gap_count",
        "coverage_gap_flag",
        "coverage_gap_summary",
        "confidence",
        "source_account_ids_json",
        "evidence_refs_json",
        "run_id",
        "model_version",
        "generated_at",
    },
    "60_m1_account_hierarchy_edge_export.sql": {
        "hierarchy_edge_id",
        "source_account_id",
        "parent_source_account_id",
        "child_source_account_id",
        "parent_party_id",
        "child_party_id",
        "parent_name",
        "child_name",
        "relationship_type",
        "relationship_basis",
        "hierarchy_level",
        "confidence",
        "source_url",
        "evidence_id",
        "evidence_summary",
        "lineage_refs_json",
        "run_id",
        "model_version",
        "generated_at",
    },
}

setup_by_source = {row["source_object_name"]: row for row in setup_rows}
mapping_by_source = {}
seen_mapping_targets = set()
for row in dmo_mapping_rows:
    source = row["source_object_name"]
    if source not in setup_by_source:
        raise SystemExit(f"M1 DMO mapping references unknown source object: {source}")
    if row["dmo_api_name"] != setup_by_source[source]["dmo_api_name"]:
        raise SystemExit(f"{source} maps to wrong DMO: {row['dmo_api_name']}")
    if len(row["source_field"]) > 40:
        raise SystemExit(f"{source} source field exceeds 40 chars: {row['source_field']}")
    if len(row["dmo_field_api_name"]) > 40:
        raise SystemExit(f"{source} DMO field exceeds 40 chars: {row['dmo_field_api_name']}")
    if row["required"].lower() not in {"true", "false"}:
        raise SystemExit(f"{source}.{row['source_field']} required must be true or false")
    if row["relationship_key"].lower() not in {"true", "false"}:
        raise SystemExit(f"{source}.{row['source_field']} relationship_key must be true or false")
    target_key = (row["dmo_api_name"], row["dmo_field_api_name"])
    if target_key in seen_mapping_targets:
        raise SystemExit(f"Duplicate M1 DMO target field mapping: {target_key}")
    seen_mapping_targets.add(target_key)
    mapping_by_source.setdefault(source, {})[row["source_field"]] = row

for filename, columns in expected_export_columns.items():
    sql_path = Path(sql_dir) / filename
    if not sql_path.exists():
        raise SystemExit(f"Missing M1 export SQL file: {filename}")
    sql_text = sql_path.read_text(encoding="utf-8")
    for column in sorted(columns):
        if len(column) > 40:
            raise SystemExit(f"{filename} has Data Cloud field over 40 chars: {column}")
        if not re.search(rf"\b{re.escape(column)}\b", sql_text):
            raise SystemExit(f"{filename} missing expected export column: {column}")

sql_to_source = {
    "40_m1_account_hierarchy_activation_export.sql": "m1_account_hierarchy_activation_export",
    "50_m1_account_group_rollup_export.sql": "m1_account_group_rollup_export",
    "60_m1_account_hierarchy_edge_export.sql": "m1_account_hierarchy_edge_export",
}
for filename, source in sql_to_source.items():
    expected_columns = expected_export_columns[filename]
    mapped_columns = set(mapping_by_source.get(source, {}))
    if mapped_columns != expected_columns:
        missing = sorted(expected_columns - mapped_columns)
        extra = sorted(mapped_columns - expected_columns)
        raise SystemExit(f"{source} DMO mapping mismatch. Missing={missing}; Extra={extra}")
    setup_row = setup_by_source[source]
    primary_source_field = setup_row["primary_key"].removesuffix("__c")
    relationship_source_field = setup_row["account_join_key"].removesuffix("__c")
    if mapping_by_source[source][primary_source_field]["key_qualifier"] != "Primary Key":
        raise SystemExit(f"{source} primary key mapping must be marked Primary Key")
    relationship_row = mapping_by_source[source][relationship_source_field]
    if relationship_row["relationship_key"].lower() != "true":
        raise SystemExit(f"{source} relationship key mapping must be marked true")
    if not relationship_row["key_qualifier"].startswith("KQ_"):
        raise SystemExit(f"{source} relationship key mapping must define a KQ_ qualifier")

print("[PASS] M1 Salesforce/Data Cloud CSV contracts are valid")
PY

pass "M1 Salesforce/Data Cloud validation surface completed"
