#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[FAIL] $1" >&2; exit 1; }
pass() { echo "[PASS] $1"; }

manifest="config/data-cloud/stream-manifest.yaml"
contract_doc="docs/contracts/databricks-to-datacloud-contract.md"
security_doc="docs/security/mcp-security-assessment.md"
evidence_doc="docs/evidence/datacloud-prerun-import-latest.md"

[[ -f "$manifest" ]] || fail "Missing stream manifest: $manifest"
[[ -f "$contract_doc" ]] || fail "Missing contract doc: $contract_doc"
[[ -f "$security_doc" ]] || fail "Missing security doc: $security_doc"

for token in \
  "connector_contract:" \
  "contract_name: databricks_to_datacloud" \
  "contract_version: 1.1.0" \
  "metadata_version: 1.0.0" \
  "prototype_mode: pre_run_import" \
  "pre_run_import_script: scripts/run-datacloud-prerun-import.sh" \
  "evidence_file: docs/evidence/datacloud-prerun-import-latest.md" \
  "delta_share_migration_notes: docs/contracts/databricks-to-datacloud-contract.md#delta-share-migration-path-production" \
  "mode: batch_pre_run" \
  "- run_id" \
  "- run_timestamp" \
  "- model_version"; do
  rg -Fq -- "$token" "$manifest" || fail "Missing stream-manifest token: $token"
done
pass "Connector contract metadata and required fields are versioned in stream manifest"

for token in \
  "## Connector Contract Versioning (DAN-62)" \
  "## Prototype Pre-run Import Process (DAN-62)" \
  "## Delta Share Migration Path (Production)"; do
  rg -Fq -- "$token" "$contract_doc" || fail "Missing contract documentation section: $token"
done
pass "Contract documentation includes DAN-62 connector hardening sections"

rg -Fq -- "## Databricks -> Data Cloud Connector Compliance (DAN-62)" "$security_doc" \
  || fail "Missing DAN-62 section in security assessment"
pass "Security/compliance doc includes DAN-62 evidence linkage"

if [[ -f "$evidence_doc" ]]; then
  rg -Fq -- "Databricks -> Data Cloud Pre-run Import Evidence" "$evidence_doc" \
    || fail "Evidence file exists but content header is missing"
  pass "Pre-run import evidence artifact is present"
else
  echo "[WARN] Pre-run evidence file not found yet: $evidence_doc"
  echo "[WARN] Generate it with: ./scripts/run-datacloud-prerun-import.sh"
fi
