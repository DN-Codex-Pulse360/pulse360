#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

pass() {
  echo "[PASS] $1"
}

required_files=(
  "docs/design/pulse360-sovereign-identifier-and-firmographic-data-cloud-design.md"
  "contracts/pulse360_sovereign_identifier.schema.json"
  "contracts/pulse360_firmographic_enrichment_output.schema.json"
  "config/data-cloud/sovereign-identifier-firmographic-dmo-design.csv"
  "config/openai/pulse360-sovereign-firmographic-enrichment-prompt.json"
)

for f in "${required_files[@]}"; do
  [[ -f "$f" ]] || fail "Missing required file: $f"
done
pass "Required sovereign and firmographic design files are present"

python3 - <<'PY'
import csv
import json
from pathlib import Path

json_paths = [
    Path("contracts/pulse360_sovereign_identifier.schema.json"),
    Path("contracts/pulse360_firmographic_enrichment_output.schema.json"),
    Path("config/openai/pulse360-sovereign-firmographic-enrichment-prompt.json"),
]

for path in json_paths:
    with path.open() as f:
        json.load(f)

csv_path = Path("config/data-cloud/sovereign-identifier-firmographic-dmo-design.csv")
with csv_path.open(newline="") as f:
    rows = list(csv.DictReader(f))

expected_header = [
    "domain",
    "logical_entity",
    "data_cloud_target",
    "field_name",
    "field_api_name",
    "cardinality",
    "required",
    "notes",
]
if rows and list(rows[0].keys()) != expected_header:
    raise SystemExit(f"CSV header mismatch: {list(rows[0].keys())}")
if not rows:
    raise SystemExit("CSV mapping has no rows")

seen = set()
duplicates = []
for row in rows:
    key = (row["data_cloud_target"], row["field_api_name"])
    if key in seen:
        duplicates.append(key)
    seen.add(key)
if duplicates:
    raise SystemExit(f"Duplicate target field mappings: {duplicates}")

required_targets = {
    "ssot__PartyIdentification__dlm",
    "Pulse360_Identifier_Evidence__dlm",
    "Pulse360_Firmographic_Profile__dlm",
    "Pulse360_Company_Classification__dlm",
    "Pulse360_Corporate_Linkage__dlm",
    "Pulse360_Executive_Role__dlm",
    "Pulse360_Digital_Footprint__dlm",
    "Pulse360_Firmographic_Source_Evidence__dlm",
}
targets = {row["data_cloud_target"] for row in rows}
missing_targets = sorted(required_targets - targets)
if missing_targets:
    raise SystemExit(f"Missing Data Cloud targets: {missing_targets}")

identifier_schema = json.loads(Path("contracts/pulse360_sovereign_identifier.schema.json").read_text())
identifier_types = set(identifier_schema["properties"]["identifier_type"]["enum"])
for required_identifier_type in [
    "PH_SEC_REGISTRATION_NUMBER",
    "PH_TIN",
    "SG_UEN",
    "MY_SSM_REGISTRATION_NUMBER",
    "ID_NIB",
    "TH_TAX_ID",
    "VN_ENTERPRISE_CODE",
    "HK_BRN",
    "GLOBAL_LEI",
    "PROVIDER_BOLDDATA_ID",
    "PROVIDER_INFOBEL_ID",
    "CRM_ACCOUNT_ID",
]:
    if required_identifier_type not in identifier_types:
        raise SystemExit(f"Missing identifier type: {required_identifier_type}")

prompt = json.loads(Path("config/openai/pulse360-sovereign-firmographic-enrichment-prompt.json").read_text())
catalog_types = {row["identifier_type"] for row in prompt["identifier_type_catalog"]}
missing_prompt_types = sorted((identifier_types - {"OTHER"}) - catalog_types)
if missing_prompt_types:
    raise SystemExit(f"Prompt catalog missing identifier types: {missing_prompt_types}")

for item in prompt["identifier_type_catalog"]:
    if item["identifier_type"].startswith("PROVIDER_") or item["identifier_type"] == "CRM_ACCOUNT_ID":
        if item["is_sovereign_identifier"] is not False:
            raise SystemExit(f"Provider/internal ID marked sovereign: {item['identifier_type']}")

text = Path("docs/design/pulse360-sovereign-identifier-and-firmographic-data-cloud-design.md").read_text()
required_terms = [
    "ssot__PartyIdentification__dlm",
    "Pulse360_Firmographic_Profile__dlm",
    "Pulse360_Identifier_Evidence__dlm",
    "GPT Enrichment Rules",
    "Provider IDs and CRM IDs are allowed as Party Identification rows, but must not",
]
for term in required_terms:
    if term not in text:
        raise SystemExit(f"Design document missing term: {term}")
PY
pass "Sovereign identifier, firmographic DMO, and prompt artifacts are structurally valid"

grep -q "official_registry" config/openai/pulse360-sovereign-firmographic-enrichment-prompt.json || fail "Prompt missing official registry source rule"
grep -q "conflicts" config/openai/pulse360-sovereign-firmographic-enrichment-prompt.json || fail "Prompt missing conflict handling"
grep -q "source_url" contracts/pulse360_firmographic_enrichment_output.schema.json || fail "Firmographic schema missing source URL evidence"
grep -q '"confidence"' contracts/pulse360_sovereign_identifier.schema.json || fail "Identifier schema missing confidence"
pass "Sovereign and firmographic design validation completed"
