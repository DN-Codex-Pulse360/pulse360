#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

manifest="config/data-cloud/stream-manifest.yaml"
mapping="config/data-cloud/activation-field-mapping.csv"
evidence_doc="docs/evidence/dan-59-data-cloud-stream-health-latest.md"
prerun_evidence="docs/evidence/datacloud-prerun-import-latest.md"
runbook_doc="docs/runbook/s4-ds-runbook.md"
checklist_doc="docs/qa/acceptance-checklist.md"

[[ -f "$manifest" ]] || fail "Missing stream manifest: $manifest"
[[ -f "$mapping" ]] || fail "Missing activation mapping: $mapping"
[[ -f "$evidence_doc" ]] || fail "Missing DAN-59 evidence doc: $evidence_doc"
[[ -f "$prerun_evidence" ]] || fail "Missing pre-run evidence doc: $prerun_evidence"
[[ -f "$runbook_doc" ]] || fail "Missing runbook doc: $runbook_doc"
[[ -f "$checklist_doc" ]] || fail "Missing checklist doc: $checklist_doc"
pass "DAN-59 files are present"

for token in \
  "salesforce_account_stream:" \
  "source_object: Account" \
  "mode: near_real_time" \
  "oauth_connection_valid" \
  "stream_status_active" \
  "recent_rows_detected" \
  "databricks_enrichment_stream:" \
  "source_table: pulse360_s4.intelligence.datacloud_export_accounts" \
  "ingestion_metadata_label_field: ingestion_metadata_label" \
  "- run_id" \
  "- run_timestamp" \
  "- model_version"; do
  rg -Fq -- "$token" "$manifest" || fail "Stream manifest missing token: $token"
done
pass "Manifest contains required Salesforce and Databricks stream configuration"

for field in \
  unified_profile_id \
  identity_confidence \
  group_revenue_rollup \
  health_score \
  cross_sell_propensity \
  coverage_gap_flag \
  competitor_risk_signal \
  last_synced_timestamp; do
  rg -Fq -- "$field," "$mapping" || fail "Activation mapping missing field: $field"
done
pass "Activation field mapping includes required contract fields"

for token in \
  'Issue: `DAN-59`' \
  "Databricks Enrichment — Last ingested:" \
  "## Acceptance Mapping (DAN-59)"; do
  rg -Fq -- "$token" "$evidence_doc" || fail "DAN-59 evidence doc missing token: $token"
done
pass "DAN-59 evidence doc captures run evidence and acceptance mapping"

run_id="$(rg -o 'run_id: run_[0-9]{8}_[0-9]+' -m1 "$prerun_evidence" | awk '{print $2}')"
[[ -n "${run_id:-}" ]] || fail "Pre-run evidence is missing a parseable run_id"
rg -Fq -- "$run_id" "$evidence_doc" \
  || fail "DAN-59 evidence doc is not aligned with latest pre-run run_id: $run_id"
pass "Pre-run import evidence contains run_id and DAN-59 evidence is aligned to latest run"

rg -Fq -- "validate-dan-59-stream-pack.sh" "$runbook_doc" \
  || fail "Runbook missing DAN-59 validator reference"
rg -Fq -- "dan-59-data-cloud-stream-health-latest.md" "$checklist_doc" \
  || fail "Checklist missing DAN-59 evidence reference"
pass "Runbook and checklist reference DAN-59 artifacts"
