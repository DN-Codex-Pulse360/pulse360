#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_root="${1:-$repo_root/build/package-workspaces}"

"$repo_root/scripts/build-salesforce-package-workspace.sh" "$output_root/salesforce"
"$repo_root/scripts/build-databricks-package-workspace.sh" "$output_root/databricks"
