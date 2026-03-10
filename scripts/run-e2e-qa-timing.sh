#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

EVIDENCE_FILE="${EVIDENCE_FILE:-docs/evidence/e2e-qa-latest.md}"
RUN_ID="${RUN_ID:-run_20260309_042146}"
MAX_SECONDS="${MAX_SECONDS:-900}"

mkdir -p "$(dirname "$EVIDENCE_FILE")"

start_ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
start_epoch="$(date +%s)"

tmp_ds01="$(mktemp)"
tmp_ds02="$(mktemp)"
tmp_ds03="$(mktemp)"
trap 'rm -f "$tmp_ds01" "$tmp_ds02" "$tmp_ds03"' EXIT

run_block() {
  local label="$1"
  shift
  local t0 t1 dur
  t0="$(date +%s)"
  echo "[INFO] $label" >&2
  "$@" >&2
  t1="$(date +%s)"
  dur=$((t1 - t0))
  echo "$dur"
}

ds01_seconds="$(run_block "DS-01 validations" bash -lc '
  ./scripts/validate-duplicate-detection-runtime.sh | tee "'"$tmp_ds01"'";
  ./scripts/validate-agentforce-health-scan-runtime.sh >> "'"$tmp_ds01"'"
')"

ds02_seconds="$(run_block "DS-02 validations" bash -lc '
  ./scripts/validate-firmographic-enrichment-runtime.sh | tee "'"$tmp_ds02"'";
  ./scripts/validate-governance-ops-metrics-runtime.sh >> "'"$tmp_ds02"'";
  ./scripts/validate-governance-case-runtime.sh >> "'"$tmp_ds02"'"
')"

ds03_seconds="$(run_block "DS-03 validations" bash -lc '
  ./scripts/validate-account360-lwc-runtime.sh | tee "'"$tmp_ds03"'";
  ./scripts/validate-cross-sell-quick-create-runtime.sh >> "'"$tmp_ds03"'"
')"

./scripts/validate-data-cloud-stream-runtime.sh >/dev/null
./scripts/validate-data-cloud-insights-config.sh >/dev/null
./scripts/validate-contracts.sh >/dev/null
./scripts/validate-walkthrough-pack.sh >/dev/null

end_epoch="$(date +%s)"
end_ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
total_seconds=$((end_epoch - start_epoch))

[[ "$total_seconds" -le "$MAX_SECONDS" ]] || fail "Total runtime exceeds ${MAX_SECONDS}s (actual=${total_seconds}s)"

defects="None observed in automated runtime checks"

cat >"$EVIDENCE_FILE" <<EOF
# E2E QA Timing Evidence (DAN-68)

- Run ID reference: \`$RUN_ID\`
- Start (UTC): \`$start_ts\`
- End (UTC): \`$end_ts\`
- Total runtime (seconds): \`$total_seconds\`
- Runtime target: \`<= $MAX_SECONDS\` seconds (\`<= 15 minutes\`)

## Scenario Timing
- DS-01 validation duration: \`$ds01_seconds\` seconds
- DS-02 validation duration: \`$ds02_seconds\` seconds
- DS-03 validation duration: \`$ds03_seconds\` seconds

## DS-01 Evidence Snapshot
\`\`\`
$(tail -n 8 "$tmp_ds01")
\`\`\`

## DS-02 Evidence Snapshot
\`\`\`
$(tail -n 10 "$tmp_ds02")
\`\`\`

## DS-03 Evidence Snapshot
\`\`\`
$(tail -n 10 "$tmp_ds03")
\`\`\`

## Defect Log
- $defects

## Coverage Summary
- Lineage/confidence/validity/last-synced evidence validated via runtime scripts and contract checks.
- Walkthrough timing budget pack validated.
EOF

pass "Wrote E2E QA evidence to $EVIDENCE_FILE"
pass "E2E runtime within target (${total_seconds}s <= ${MAX_SECONDS}s)"
