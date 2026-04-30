#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

pass() {
  echo "[PASS] $1"
}

account_csv="data/samples/datacloud_account_core_canonical_v2_export.csv"
product_csv="data/samples/datacloud_product_brand_canonical_v2_export.csv"
engagement_csv="data/samples/datacloud_engagement_canonical_v2_export.csv"

for f in "$account_csv" "$product_csv" "$engagement_csv"; do
  [[ -f "$f" ]] || fail "Missing canonical export file: $f"
done
pass "Canonical export files exist"

python3 - "$account_csv" "$product_csv" "$engagement_csv" <<'PY'
import csv
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(f"[FAIL] {message}", file=sys.stderr)
    raise SystemExit(1)


def pass_(message: str) -> None:
    print(f"[PASS] {message}")


def read_rows(path: str) -> list[dict[str, str]]:
    with Path(path).open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


account_csv, product_csv, engagement_csv = sys.argv[1:4]
account_rows = read_rows(account_csv)
product_rows = read_rows(product_csv)
engagement_rows = read_rows(engagement_csv)

if not account_rows:
    fail("Account core export has no data rows")
if not product_rows:
    fail("Product brand export has no data rows")
if not engagement_rows:
    fail("Engagement export has no data rows")

account_ids = {row["canonical_account_id"] for row in account_rows}
product_account_ids = {row["canonical_account_id"] for row in product_rows}
engagement_account_ids = {row["canonical_account_id"] for row in engagement_rows}

missing_product_accounts = sorted(product_account_ids - account_ids)
if missing_product_accounts:
    fail("Product export references canonical_account_id values that do not exist in account core export")

missing_engagement_accounts = sorted(engagement_account_ids - account_ids)
if missing_engagement_accounts:
    fail("Engagement export references canonical_account_id values that do not exist in account core export")

pass_("Cross-file canonical_account_id references are valid")


def collect_batch_values(rows: list[dict[str, str]]) -> set[tuple[str, str, str]]:
    return {
        (row["run_id"], row["run_timestamp"], row["model_version"])
        for row in rows
    }


account_batch = collect_batch_values(account_rows)
product_batch = collect_batch_values(product_rows)
engagement_batch = collect_batch_values(engagement_rows)

if len(account_batch) != 1:
    fail("Account core export contains multiple run_id/run_timestamp/model_version combinations")
if len(product_batch) != 1:
    fail("Product brand export contains multiple run_id/run_timestamp/model_version combinations")
if len(engagement_batch) != 1:
    fail("Engagement export contains multiple run_id/run_timestamp/model_version combinations")

if account_batch != product_batch:
    fail("Product brand export batch metadata does not match account core export")
if account_batch != engagement_batch:
    fail("Engagement export batch metadata does not match account core export")

pass_("Batch metadata is consistent across canonical exports")

product_ids = {row["product_id"] for row in product_rows}
brand_ids = {row["brand_id"] for row in product_rows}

missing_product_refs = sorted(
    {
        row["related_product_id"]
        for row in engagement_rows
        if row["related_product_id"] and row["related_product_id"] not in product_ids
    }
)
if missing_product_refs:
    fail("Engagement export contains related_product_id values not found in product brand export")

missing_brand_refs = sorted(
    {
        row["related_brand_id"]
        for row in engagement_rows
        if row["related_brand_id"] and row["related_brand_id"] not in brand_ids
    }
)
if missing_brand_refs:
    fail("Engagement export contains related_brand_id values not found in product brand export")

pass_("Engagement product/brand references are valid")

product_keys = [(row["canonical_account_id"], row["product_id"]) for row in product_rows]
if len(product_keys) != len(set(product_keys)):
    fail("Duplicate keys found in product brand export for canonical_account_id+product_id")

engagement_keys = [(row["canonical_account_id"], row["engagement_id"]) for row in engagement_rows]
if len(engagement_keys) != len(set(engagement_keys)):
    fail("Duplicate keys found in engagement export for canonical_account_id+engagement_id")

pass_("No duplicate business keys in canonical exports")
pass_("Canonical export integrity validation completed")
PY
