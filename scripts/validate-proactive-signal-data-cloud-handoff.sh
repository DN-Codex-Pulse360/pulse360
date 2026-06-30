#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

search_fixed() {
  local needle="$1"
  shift

  if command -v rg >/dev/null 2>&1; then
    rg -Fq "$needle" "$@"
  else
    grep -Fq -- "$needle" "$@"
  fi
}

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

mapping="config/data-cloud/proactive-signal-field-mapping.csv"
runbook="docs/runbook/proactive-signal-data-cloud-activation-runbook.md"
evidence="docs/evidence/pulse360-proactive-signal-data-cloud-handoff-2026-06-30.md"
databricks_evidence="docs/evidence/pulse360-proactive-signal-databricks-live-check-2026-06-30.json"
salesforce_evidence="docs/evidence/pulse360-proactive-signal-salesforce-seed-2026-06-29.json"

for path in "$mapping" "$runbook" "$evidence" "$databricks_evidence" "$salesforce_evidence"; do
  [[ -f "$path" ]] || fail "Missing proactive Data Cloud handoff artifact: $path"
done
pass "Proactive Data Cloud handoff artifacts are present"

expected_header="source_field,databricks_projection,data_cloud_category,data_cloud_object,target_object,target_field,required,crm_writeback_ready,notes"
actual_header="$(head -n 1 "$mapping")"
[[ "$actual_header" == "$expected_header" ]] \
  || fail "Proactive Data Cloud mapping header mismatch"

for token in \
  "source_account_id" \
  "intent_signal_payload" \
  "coverage_gap_flag" \
  "ai_narrative" \
  "ai_recommended_actions" \
  "source_refs" \
  "citation_count" \
  "last_synced_timestamp" \
  "run_id" \
  "model_version" \
  "DataCloud_Last_Synced__c"; do
  search_fixed "$token" "$mapping" || fail "Proactive Data Cloud mapping missing token: $token"
done
pass "Proactive Data Cloud mapping covers key signal, evidence, and freshness fields"

for token in \
  "pulse360_s4.gold_proactive_signal.datacloud_proactive_signal_projection" \
  "datacloud_export_accounts" \
  "Copy Field Enrichment" \
  "DataCloud_Last_Synced__c" \
  "pulse360-agent-target" \
  "custom Salesforce LWC/Apex assistant and action panels" \
  "not yet created or repointed"; do
  search_fixed "$token" "$runbook" "$evidence" \
    || fail "Proactive Data Cloud handoff docs missing token: $token"
done
pass "Proactive Data Cloud runbook and evidence state activation path and current boundary"

python3 - <<'PY'
import csv
import json
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(f"[FAIL] {message}", file=sys.stderr)
    raise SystemExit(1)


def pass_(message: str) -> None:
    print(f"[PASS] {message}")


root = Path.cwd()
mapping_rows = list(csv.DictReader((root / "config/data-cloud/proactive-signal-field-mapping.csv").open(newline="", encoding="utf-8")))
if not mapping_rows:
    fail("Proactive Data Cloud mapping is empty")

required_sources = {
    "source_account_id",
    "intent_signal_payload",
    "coverage_gap_flag",
    "ai_narrative",
    "ai_recommended_actions",
    "source_refs",
    "citation_count",
    "last_synced_timestamp",
    "run_id",
    "model_version",
}
mapped_sources = {row["source_field"] for row in mapping_rows}
missing_sources = sorted(required_sources - mapped_sources)
if missing_sources:
    fail("Mapping missing required source fields: " + ", ".join(missing_sources))

writeback_rows = [row for row in mapping_rows if row["crm_writeback_ready"].lower() == "true"]
if not writeback_rows:
    fail("Mapping must identify at least one CRM writeback-ready field")
for row in writeback_rows:
    if row["target_object"] != "Account":
        fail(f"Writeback-ready row {row['source_field']} must target Account")
    if not row["target_field"].endswith("__c"):
        fail(f"Writeback-ready row {row['source_field']} must map to a custom CRM field")

databricks = json.loads((root / "docs/evidence/pulse360-proactive-signal-databricks-live-check-2026-06-30.json").read_text(encoding="utf-8"))
if databricks.get("projection") != "pulse360_s4.gold_proactive_signal.datacloud_proactive_signal_projection":
    fail("Databricks evidence points at the wrong projection")
if databricks.get("row_count") != 1:
    fail("Databricks evidence must prove exactly one proactive projection row for the demo")
sample_row = databricks.get("sample_row") or {}
if sample_row.get("account_name") != "Northstar Foods Group":
    fail("Databricks evidence must use the Northstar Foods Group hero account")
if str(sample_row.get("coverage_gap_flag")).lower() != "true":
    fail("Databricks evidence must preserve coverage_gap_flag=true")
if str(sample_row.get("citation_count")) != "6":
    fail("Databricks evidence must preserve the six-source citation count")

salesforce = json.loads((root / "docs/evidence/pulse360-proactive-signal-salesforce-seed-2026-06-29.json").read_text(encoding="utf-8"))
if salesforce.get("seed_mode") != "fixture_backed_salesforce_preview":
    fail("Salesforce evidence must remain marked as fixture-backed until Data Cloud activates it")
if salesforce.get("native_agentforce_runtime_verified") is not False:
    fail("Salesforce evidence must not claim native Agentforce runtime verification")
if salesforce.get("fallback_surface") != "custom Salesforce LWC/Apex assistant and action panels":
    fail("Salesforce evidence must name the agreed fallback surface")

pass_("Databricks and Salesforce evidence support a Data Cloud handoff without overclaiming live activation")
PY

pass "Proactive signal Data Cloud handoff validation completed"
