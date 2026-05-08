#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
target_org="${TARGET_ORG:-pulse360-agent-target}"

run() {
  echo "[INFO] $*"
  if [[ "$#" -eq 1 && "$1" == *.sh && ! -x "$1" ]]; then
    bash "$1"
  else
    "$@"
  fi
}

run_with_target_org() {
  echo "[INFO] TARGET_ORG=$target_org $*"
  if [[ "$#" -eq 1 && "$1" == *.sh && ! -x "$1" ]]; then
    TARGET_ORG="$target_org" bash "$1"
  else
    TARGET_ORG="$target_org" "$@"
  fi
}

run_with_default_org() {
  echo "[INFO] PULSE360_DEFAULT_ORG_ALIAS=$target_org $*"
  if [[ "$#" -eq 1 && "$1" == *.sh && ! -x "$1" ]]; then
    PULSE360_DEFAULT_ORG_ALIAS="$target_org" bash "$1"
  else
    PULSE360_DEFAULT_ORG_ALIAS="$target_org" "$@"
  fi
}

echo "[INFO] Pulse360 build/deploy/verify/close gate validation"
echo "[INFO] Repository: $repo_root"
echo "[INFO] Target org: $target_org"

run "$repo_root/scripts/validate-contracts.sh"
run "$repo_root/scripts/validate-canonical-exports.sh"
run "$repo_root/scripts/validate-hierarchy-and-identity.sh"
run "$repo_root/scripts/validate-databricks-salesforce-sql-pack.sh"
run "$repo_root/scripts/validate-databricks-package-layout.sh"
run "$repo_root/scripts/validate-databricks-dashboard-pack.sh"
run "$repo_root/scripts/validate-databricks-dashboard-visuals.sh"
run "$repo_root/scripts/validate-governance-ops-metrics-runtime.sh"
run "$repo_root/scripts/validate-databricks-firmographic-genai-pack.sh"
run "$repo_root/scripts/validate-sovereign-firmographic-design.sh"
run "$repo_root/scripts/validate-firmographic-genai-design.sh"
run "$repo_root/scripts/validate-unity-catalog-config.sh"
run "$repo_root/scripts/validate-salesforce-package-layout.sh"
run "$repo_root/scripts/validate-salesforce-firmographic-ux-pack.sh"
run "$repo_root/scripts/validate-governance-case-metadata.sh"
run "$repo_root/scripts/validate-data-cloud-insights-config.sh"
run "$repo_root/scripts/validate-data-cloud-copy-field-exceptions.sh"

run_with_target_org "$repo_root/scripts/validate-salesforce-account-activation-fields.sh"
run_with_target_org "$repo_root/scripts/validate-data-cloud-activation-key-alignment.sh"
run_with_target_org "$repo_root/scripts/validate-data-cloud-field-path.sh"
run_with_default_org "$repo_root/scripts/validate-account-payload-exception-activation.sh"

if [[ "${PULSE360_RUN_DEPLOY_DRY_RUN:-0}" == "1" ]]; then
  echo "[INFO] Running optional Salesforce dry-run deploy validation"
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' EXIT
  run "$repo_root/scripts/build-salesforce-package-workspace.sh" "$tmp_dir"
  run sf project deploy start \
    --dry-run \
    --target-org "$target_org" \
    --source-dir "$tmp_dir/packages/account-intelligence" \
    --source-dir "$tmp_dir/packages/governance"
else
  echo "[INFO] Salesforce deploy dry-run skipped. Set PULSE360_RUN_DEPLOY_DRY_RUN=1 after explicit deployment approval."
fi

echo "[INFO] git diff --check"
(cd "$repo_root" && git diff --check)

echo "[PASS] Build/deploy/verify/close gate validation completed"
