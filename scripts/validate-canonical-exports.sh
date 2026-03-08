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

# 1) Referential integrity: product/engagement account IDs must exist in account export.
account_ids_file="$(mktemp)"
awk -F',' 'NR>1 {print $1}' "$account_csv" | sort -u > "$account_ids_file"

if ! awk -F',' 'NR>1 {print $1}' "$product_csv" | sort -u | comm -23 - "$account_ids_file" | awk 'NF{exit 1}'; then
  rm -f "$account_ids_file"
  fail "Product export references canonical_account_id values that do not exist in account core export"
fi

if ! awk -F',' 'NR>1 {print $1}' "$engagement_csv" | sort -u | comm -23 - "$account_ids_file" | awk 'NF{exit 1}'; then
  rm -f "$account_ids_file"
  fail "Engagement export references canonical_account_id values that do not exist in account core export"
fi
pass "Cross-file canonical_account_id references are valid"

# 2) Batch metadata consistency: run_id/run_timestamp/model_version must match across all files.
collect_batch_values() {
  local file="$1"
  local run_id_col="$2"
  local run_ts_col="$3"
  local model_col="$4"
  awk -F',' -v r="$run_id_col" -v t="$run_ts_col" -v m="$model_col" 'NR>1 {print $r"|"$t"|"$m}' "$file" | sort -u
}

account_batch="$(collect_batch_values "$account_csv" 11 12 13)"
product_batch="$(collect_batch_values "$product_csv" 9 10 11)"
engagement_batch="$(collect_batch_values "$engagement_csv" 10 11 12)"

[[ -n "$account_batch" ]] || fail "Account core export has no data rows"
[[ -n "$product_batch" ]] || fail "Product brand export has no data rows"
[[ -n "$engagement_batch" ]] || fail "Engagement export has no data rows"

if [[ "$(echo "$account_batch" | wc -l | tr -d ' ')" -ne 1 ]]; then
  rm -f "$account_ids_file"
  fail "Account core export contains multiple run_id/run_timestamp/model_version combinations"
fi
if [[ "$(echo "$product_batch" | wc -l | tr -d ' ')" -ne 1 ]]; then
  rm -f "$account_ids_file"
  fail "Product brand export contains multiple run_id/run_timestamp/model_version combinations"
fi
if [[ "$(echo "$engagement_batch" | wc -l | tr -d ' ')" -ne 1 ]]; then
  rm -f "$account_ids_file"
  fail "Engagement export contains multiple run_id/run_timestamp/model_version combinations"
fi

[[ "$account_batch" == "$product_batch" ]] || { rm -f "$account_ids_file"; fail "Product brand export batch metadata does not match account core export"; }
[[ "$account_batch" == "$engagement_batch" ]] || { rm -f "$account_ids_file"; fail "Engagement export batch metadata does not match account core export"; }
pass "Batch metadata is consistent across canonical exports"

# 3) Product/brand linkage from engagement must resolve when populated.
product_ids_file="$(mktemp)"
brand_ids_file="$(mktemp)"
awk -F',' 'NR>1 {print $2}' "$product_csv" | sort -u > "$product_ids_file"
awk -F',' 'NR>1 {print $5}' "$product_csv" | sort -u > "$brand_ids_file"

if ! awk -F',' 'NR>1 && $6 != "" {print $6}' "$engagement_csv" | sort -u | comm -23 - "$product_ids_file" | awk 'NF{exit 1}'; then
  rm -f "$account_ids_file" "$product_ids_file" "$brand_ids_file"
  fail "Engagement export contains related_product_id values not found in product brand export"
fi

if ! awk -F',' 'NR>1 && $7 != "" {print $7}' "$engagement_csv" | sort -u | comm -23 - "$brand_ids_file" | awk 'NF{exit 1}'; then
  rm -f "$account_ids_file" "$product_ids_file" "$brand_ids_file"
  fail "Engagement export contains related_brand_id values not found in product brand export"
fi
pass "Engagement product/brand references are valid"

# 4) No duplicate business keys.
dup_product_keys="$(awk -F',' 'NR>1 {print $1"|"$2}' "$product_csv" | sort | uniq -d)"
[[ -z "$dup_product_keys" ]] || {
  rm -f "$account_ids_file" "$product_ids_file" "$brand_ids_file"
  fail "Duplicate keys found in product brand export for canonical_account_id+product_id"
}

dup_engagement_keys="$(awk -F',' 'NR>1 {print $1"|"$2}' "$engagement_csv" | sort | uniq -d)"
[[ -z "$dup_engagement_keys" ]] || {
  rm -f "$account_ids_file" "$product_ids_file" "$brand_ids_file"
  fail "Duplicate keys found in engagement export for canonical_account_id+engagement_id"
}
pass "No duplicate business keys in canonical exports"

rm -f "$account_ids_file" "$product_ids_file" "$brand_ids_file"
pass "Canonical export integrity validation completed"
