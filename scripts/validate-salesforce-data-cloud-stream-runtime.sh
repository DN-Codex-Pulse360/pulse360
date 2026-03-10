#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

TARGET_ORG="${TARGET_ORG:-pulse360-dev}"

query="SELECT Id, Name, StreamType, DataStreamStatus, ImportRunStatus, LastRefreshDate, TotalRowsProcessed, LastNumberOfRowsAddedCount, TotalNumberOfRowsAdded FROM DataStream ORDER BY LastModifiedDate DESC LIMIT 50"
resp="$(sf data query --target-org "$TARGET_ORG" --query "$query" --json)"
total="$(jq -r '.result.totalSize // 0' <<<"$resp")"

if [[ "$total" == "0" ]]; then
  fail "Salesforce Data Cloud has zero DataStream records in org '$TARGET_ORG' (All Data Streams shows 0 items)"
fi

pass "Salesforce Data Cloud stream runtime has $total stream records"
echo "$resp" | jq -c '{total:.result.totalSize,records:[.result.records[] | {id:.Id,name:.Name,stream_type:.StreamType,status:.DataStreamStatus,import_run_status:.ImportRunStatus,last_refresh:.LastRefreshDate,last_rows_added:.LastNumberOfRowsAddedCount,total_rows_added:.TotalNumberOfRowsAdded,total_rows_processed:.TotalRowsProcessed}]}'
