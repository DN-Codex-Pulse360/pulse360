#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

pass() {
  echo "[PASS] $1"
}

RUN_ID="${RUN_ID:-run_$(date -u +%Y%m%d_%H%M%S)}"
EVIDENCE_FILE="${EVIDENCE_FILE:-docs/evidence/datacloud-prerun-import-latest.md}"
EVIDENCE_DIR="$(dirname "$EVIDENCE_FILE")"
ts_utc="$(date -u +"%Y-%m-%d %H:%M:%S UTC")"

mkdir -p "$EVIDENCE_DIR"
tmp_stream="$(mktemp)"
trap 'rm -f "$tmp_stream"' EXIT

run_step() {
  local label="$1"
  shift
  echo "[INFO] $label"
  "$@"
}

run_step "Build duplicate candidate pairs" env RUN_ID="$RUN_ID" ./scripts/build-duplicate-candidate-pairs.sh
run_step "Build firmographic enrichment" env RUN_ID="$RUN_ID" ./scripts/build-firmographic-enrichment.sh
run_step "Build governance ops metrics" env RUN_ID="$RUN_ID" ./scripts/build-governance-ops-metrics.sh
run_step "Build Data Cloud account export" env RUN_ID="$RUN_ID" ./scripts/build-datacloud-export-accounts.sh
run_step "Validate Data Cloud stream runtime" ./scripts/validate-data-cloud-stream-runtime.sh | tee "$tmp_stream"
run_step "Validate Data Cloud insights config" ./scripts/validate-data-cloud-insights-config.sh
run_step "Validate core contracts" ./scripts/validate-contracts.sh
run_step "Validate canonical exports" ./scripts/validate-canonical-exports.sh
run_step "Validate connector contract hardening" ./scripts/validate-datacloud-connector-contract.sh

stream_row_json="$(tail -n 1 "$tmp_stream" | tr -d '\r' || true)"
stream_row="$(jq -r '.[0] | @tsv' <<<"$stream_row_json" 2>/dev/null || true)"
dup_rows="$(awk -F'\t' '{print $1}' <<<"$stream_row")"
enr_rows="$(awk -F'\t' '{print $2}' <<<"$stream_row")"
gov_rows="$(awk -F'\t' '{print $3}' <<<"$stream_row")"
exp_rows="$(awk -F'\t' '{print $4}' <<<"$stream_row")"
last_synced="$(awk -F'\t' '{print $5}' <<<"$stream_row")"
label="$(awk -F'\t' '{print $6}' <<<"$stream_row")"

cat >"$EVIDENCE_FILE" <<EOF
# Databricks -> Data Cloud Pre-run Import Evidence

- Run timestamp (UTC): $ts_utc
- run_id: $RUN_ID
- Workflow: prototype pre-run import connector contract (DAN-62)

## Commands Executed
- \`RUN_ID=$RUN_ID ./scripts/build-duplicate-candidate-pairs.sh\`
- \`RUN_ID=$RUN_ID ./scripts/build-firmographic-enrichment.sh\`
- \`RUN_ID=$RUN_ID ./scripts/build-governance-ops-metrics.sh\`
- \`RUN_ID=$RUN_ID ./scripts/build-datacloud-export-accounts.sh\`
- \`./scripts/validate-data-cloud-stream-runtime.sh\`
- \`./scripts/validate-data-cloud-insights-config.sh\`
- \`./scripts/validate-contracts.sh\`
- \`./scripts/validate-canonical-exports.sh\`
- \`./scripts/validate-datacloud-connector-contract.sh\`

## Stream Runtime Snapshot
- duplicate_candidate_pairs rows: ${dup_rows:-n/a}
- firmographic_enrichment rows: ${enr_rows:-n/a}
- governance_ops_metrics rows: ${gov_rows:-n/a}
- datacloud_export_accounts rows: ${exp_rows:-n/a}
- export last_synced_timestamp: ${last_synced:-n/a}
- ingestion_metadata_label: ${label:-n/a}
EOF

pass "Wrote pre-run import evidence file: $EVIDENCE_FILE"
