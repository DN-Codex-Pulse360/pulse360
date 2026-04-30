#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_root="${1:-$repo_root/build/package-workspaces/databricks}"
members_root="$repo_root/config/packages/databricks"

bundle_slugs=(
  "salesforce-ingestion"
  "account-intelligence-export"
)

bundle_names=(
  "pulse360-salesforce-ingestion"
  "pulse360-account-intelligence-export"
)

member_files=(
  "salesforce-ingestion.members.txt"
  "account-intelligence-export.members.txt"
)

validate_scripts=(
  "scripts/validate-databricks-salesforce-sql-pack.sh"
  "scripts/validate-contracts.sh && bash scripts/validate-canonical-exports.sh"
)

run_orders=(
  "sql/databricks/silver_salesforce/00_create_schema.sql sql/databricks/silver_salesforce/10_crm_account.sql sql/databricks/silver_salesforce/20_crm_contact.sql sql/databricks/silver_salesforce/30_crm_opportunity.sql sql/databricks/silver_salesforce/40_crm_opportunity_contact_role.sql sql/databricks/silver_salesforce/50_crm_product.sql sql/databricks/silver_salesforce/60_crm_opportunity_line_item.sql sql/databricks/silver_salesforce/70_crm_account_contact_bridge.sql sql/databricks/silver_salesforce/80_crm_account_hierarchy_edge.sql"
  "sql/databricks/gold/00_create_schemas.sql sql/databricks/gold/10_account_export_base.sql sql/databricks/gold/20_account_core_export.sql sql/databricks/gold/30_datacloud_export_accounts.sql"
)

copy_member() {
  local source_rel="$1"
  local bundle_dir="$2"
  local source_abs="$repo_root/$source_rel"
  local target_abs="$bundle_dir/$source_rel"

  [[ -e "$source_abs" ]] || fail "Missing package member: $source_rel"

  if [[ -d "$source_abs" ]]; then
    mkdir -p "$target_abs"
    cp -R "$source_abs"/. "$target_abs"/
  else
    mkdir -p "$(dirname "$target_abs")"
    cp "$source_abs" "$target_abs"
  fi
}

emit_bundle_config() {
  local target="$1"
  local bundle_name="$2"
  local validate_script="$3"
  local run_order="$4"

  {
    echo "bundle:"
    echo "  name: $bundle_name"
    echo
    echo "workspace:"
    echo '  root_path: /Workspace/Shared/pulse360/${bundle.name}/${bundle.target}'
    echo
    echo "sync:"
    echo "  include:"
    echo "    - sql/**"
    echo "    - config/**"
    echo "    - contracts/**"
    echo "    - docs/**"
    echo "    - scripts/**"
    echo "    - dashboards/**"
    echo
    echo "scripts:"
    echo "  validate:"
    echo "    content: bash $validate_script"
    echo "  print-run-order:"
    echo "    content: |"
    echo "      printf '%s\\n' \\"
    for step in $run_order; do
      echo "        '$step' \\"
    done
    echo "        ''"
    echo
    echo "targets:"
    echo "  dev:"
    echo "    default: true"
    echo "  qa: {}"
    echo "  prod: {}"
  } >"$target/databricks.yml"
}

emit_readme() {
  local target="$1"
  local bundle_name="$2"
  local run_order="$3"

  {
    echo "# $bundle_name"
    echo
    echo "This bundle workspace is generated from the repo so the Databricks assets can"
    echo "be promoted together into a new workspace."
    echo
    echo "## Bundle Commands"
    echo "- \`databricks bundle validate\`"
    echo "- \`databricks bundle sync\`"
    echo
    echo "## SQL Run Order"
    for step in $run_order; do
      echo "- \`$step\`"
    done
  } >"$target/README.md"
}

rm -rf "$output_root"
mkdir -p "$output_root"

for i in "${!bundle_slugs[@]}"; do
  slug="${bundle_slugs[$i]}"
  bundle_dir="$output_root/$slug"
  member_file="$members_root/${member_files[$i]}"

  [[ -f "$member_file" ]] || fail "Missing bundle member list: $member_file"
  mkdir -p "$bundle_dir"

  while IFS= read -r member || [[ -n "$member" ]]; do
    [[ -z "$member" ]] && continue
    [[ "$member" =~ ^# ]] && continue
    copy_member "$member" "$bundle_dir"
  done <"$member_file"

  emit_bundle_config "$bundle_dir" "${bundle_names[$i]}" "${validate_scripts[$i]}" "${run_orders[$i]}"
  emit_readme "$bundle_dir" "${bundle_names[$i]}" "${run_orders[$i]}"

  pass "Built Databricks package workspace for ${bundle_names[$i]}"
done

pass "Databricks package workspace created at $output_root"
