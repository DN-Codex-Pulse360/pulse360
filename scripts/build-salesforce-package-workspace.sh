#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_root="${1:-$repo_root/build/package-workspaces/salesforce}"
members_root="$repo_root/config/packages/salesforce"

package_slugs=(
  "account-intelligence"
  "governance"
)

package_names=(
  "pulse360-account-intelligence"
  "pulse360-governance"
)

member_files=(
  "account-intelligence.members.txt"
  "governance.members.txt"
)

copy_member() {
  local source_rel="$1"
  local package_dir="$2"
  local source_abs="$repo_root/$source_rel"
  local target_rel="${source_rel#force-app/}"
  local target_abs="$package_dir/$target_rel"

  [[ -e "$source_abs" ]] || fail "Missing package member: $source_rel"

  if [[ -d "$source_abs" ]]; then
    mkdir -p "$target_abs"
    cp -R "$source_abs"/. "$target_abs"/
  else
    mkdir -p "$(dirname "$target_abs")"
    cp "$source_abs" "$target_abs"
  fi
}

emit_sfdx_project() {
  local target="$1"

  cat >"$target/sfdx-project.json" <<'EOF'
{
  "packageDirectories": [
    {
      "path": "packages/account-intelligence",
      "default": true,
      "package": "pulse360-account-intelligence",
      "versionName": "Version 0.1",
      "versionNumber": "0.1.0.NEXT"
    },
    {
      "path": "packages/governance",
      "package": "pulse360-governance",
      "versionName": "Version 0.1",
      "versionNumber": "0.1.0.NEXT",
      "dependencies": [
        {
          "package": "pulse360-account-intelligence"
        }
      ]
    }
  ],
  "namespace": "",
  "sourceApiVersion": "66.0",
  "packageAliases": {}
}
EOF
}

emit_readme() {
  local target="$1"

  cat >"$target/README.md" <<'EOF'
# Pulse360 Salesforce Package Workspace

This workspace is generated from the repo source so you can create unlocked packages
without restructuring the primary `force-app` tree.

## Packages
- `pulse360-account-intelligence`
- `pulse360-governance` (depends on `pulse360-account-intelligence`)

## Current Split
1. `pulse360-account-intelligence`
   - Account intelligence fields and seller-play metadata
   - seller workspace runtime and seller execution orchestration
   - planner, renewal-risk, seller-v2, and signal-routing surfaces
2. `pulse360-governance`
   - Governance Case metadata and decision stamping
   - governance review orchestration and direct-evidence actions
   - governance review record-page surfaces

## Typical Flow
1. Authorize a Dev Hub org.
2. Create each package once:
   - `sf package create --name pulse360-account-intelligence --package-type Unlocked --path packages/account-intelligence --no-namespace --target-dev-hub <devhub>`
   - `sf package create --name pulse360-governance --package-type Unlocked --path packages/governance --no-namespace --target-dev-hub <devhub>`
3. Write the created package IDs into `packageAliases`.
4. Create package versions from this workspace.

## Install Order
1. `pulse360-account-intelligence`
2. `pulse360-governance`
EOF
}

rm -rf "$output_root"
mkdir -p "$output_root/packages"

if [[ -f "$repo_root/.forceignore" ]]; then
  cp "$repo_root/.forceignore" "$output_root/.forceignore"
fi

for i in "${!package_slugs[@]}"; do
  slug="${package_slugs[$i]}"
  member_file="$members_root/${member_files[$i]}"
  package_dir="$output_root/packages/$slug"

  [[ -f "$member_file" ]] || fail "Missing package member list: $member_file"
  mkdir -p "$package_dir"

  while IFS= read -r member || [[ -n "$member" ]]; do
    [[ -z "$member" ]] && continue
    [[ "$member" =~ ^# ]] && continue
    copy_member "$member" "$package_dir"
  done <"$member_file"

  pass "Built Salesforce package workspace for ${package_names[$i]}"
done

emit_sfdx_project "$output_root"
emit_readme "$output_root"

pass "Salesforce package workspace created at $output_root"
