#!/usr/bin/env bash
set -euo pipefail

: "${LINEAGE_UPSTREAM_TABLE:?Set LINEAGE_UPSTREAM_TABLE}"
: "${LINEAGE_DOWNSTREAM_TABLE:?Set LINEAGE_DOWNSTREAM_TABLE}"

DATABRICKS_BIN="${DATABRICKS_BIN:-$HOME/.local/bin/databricks}"

if [[ ! -x "$DATABRICKS_BIN" ]]; then
  echo "[FAIL] Databricks CLI not found at $DATABRICKS_BIN" >&2
  exit 1
fi

echo "[INFO] Checking metastore visibility"
"$DATABRICKS_BIN" unity-catalog metastores list >/dev/null

echo "[INFO] Checking upstream/downstream table existence"
"$DATABRICKS_BIN" unity-catalog tables get --full-name "$LINEAGE_UPSTREAM_TABLE" >/dev/null
"$DATABRICKS_BIN" unity-catalog tables get --full-name "$LINEAGE_DOWNSTREAM_TABLE" >/dev/null

echo "[INFO] Fetching lineage"
"$DATABRICKS_BIN" unity-catalog lineage table --table-name "$LINEAGE_DOWNSTREAM_TABLE"

echo "[PASS] Runtime lineage check completed"
