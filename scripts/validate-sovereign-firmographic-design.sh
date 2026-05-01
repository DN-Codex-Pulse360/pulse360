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
  "config/data-cloud/sovereign-firmographic-dlo-dmo-setup.csv"
  "config/openai/pulse360-sovereign-firmographic-enrichment-prompt.json"
  "docs/runbook/pulse360-sovereign-firmographic-data-cloud-setup-runbook.md"
  "data/samples/databricks_gold_sovereign_identifier_export.csv"
  "data/samples/databricks_gold_firmographic_profile_export.csv"
  "data/samples/databricks_gold_company_classification_export.csv"
  "data/samples/databricks_gold_corporate_linkage_export.csv"
  "data/samples/databricks_gold_firmographic_source_evidence_export.csv"
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
]:
    if required_identifier_type not in identifier_types:
        raise SystemExit(f"Missing identifier type: {required_identifier_type}")

for removed_identifier_type in [
    "PROVIDER_BOLDDATA_ID",
    "PROVIDER_INFOBEL_ID",
    "CRM_ACCOUNT_ID",
]:
    if removed_identifier_type in identifier_types:
        raise SystemExit(f"Removed identifier type still present: {removed_identifier_type}")

prompt = json.loads(Path("config/openai/pulse360-sovereign-firmographic-enrichment-prompt.json").read_text())
catalog_types = {row["identifier_type"] for row in prompt["identifier_type_catalog"]}
missing_prompt_types = sorted((identifier_types - {"OTHER"}) - catalog_types)
if missing_prompt_types:
    raise SystemExit(f"Prompt catalog missing identifier types: {missing_prompt_types}")

for item in prompt["identifier_type_catalog"]:
    if item["identifier_type"].startswith("PROVIDER_") or item["identifier_type"] == "CRM_ACCOUNT_ID":
        raise SystemExit(f"Provider/internal ID still present in prompt catalog: {item['identifier_type']}")

text = Path("docs/design/pulse360-sovereign-identifier-and-firmographic-data-cloud-design.md").read_text()
required_terms = [
    "ssot__PartyIdentification__dlm",
    "Pulse360_Firmographic_Profile__dlm",
    "Pulse360_Identifier_Evidence__dlm",
    "GPT Enrichment Rules",
    "Provider IDs, CRM IDs, website IDs, social profile IDs, and search-result IDs",
    "latest_financial_results_summary",
    "investor_updates_summary",
    "`location_type` is a controlled description",
]
for term in required_terms:
    if term not in text:
        raise SystemExit(f"Design document missing term: {term}")

setup_path = Path("config/data-cloud/sovereign-firmographic-dlo-dmo-setup.csv")
with setup_path.open(newline="") as f:
    setup_rows = list(csv.DictReader(f))
setup_exports = {row["export_file"] for row in setup_rows}
expected_exports = {
    "data/samples/databricks_gold_sovereign_identifier_export.csv",
    "data/samples/databricks_gold_firmographic_profile_export.csv",
    "data/samples/databricks_gold_company_classification_export.csv",
    "data/samples/databricks_gold_corporate_linkage_export.csv",
    "data/samples/databricks_gold_firmographic_source_evidence_export.csv",
}
missing_exports = sorted(expected_exports - setup_exports)
if missing_exports:
    raise SystemExit(f"DLO/DMO setup matrix missing exports: {missing_exports}")
for row in setup_rows:
    if row["setup_mode"] != "runbook":
        raise SystemExit(f"Unexpected setup_mode for Data Cloud artifact: {row}")
    if not Path(row["export_file"]).is_file():
        raise SystemExit(f"Setup matrix references missing export: {row['export_file']}")

runbook = Path("docs/runbook/pulse360-sovereign-firmographic-data-cloud-setup-runbook.md").read_text()
for term in [
    "Cloud object creation",
    "ssot__PartyIdentification__dlm",
    "Provider IDs, CRM Account IDs, web profile",
    "Do not activate the full sovereign identifier",
]:
    if term not in runbook:
        raise SystemExit(f"Runbook missing term: {term}")

def load_csv(path):
    with Path(path).open(newline="") as f:
        loaded = list(csv.DictReader(f))
    if not loaded:
        raise SystemExit(f"Sample export has no rows: {path}")
    return loaded

account_rows = load_csv("data/samples/datacloud_account_core_canonical_v2_export.csv")
known_source_accounts = {row["source_account_id"] for row in account_rows}

identifier_rows = load_csv("data/samples/databricks_gold_sovereign_identifier_export.csv")
profile_rows = load_csv("data/samples/databricks_gold_firmographic_profile_export.csv")
classification_rows = load_csv("data/samples/databricks_gold_company_classification_export.csv")
linkage_rows = load_csv("data/samples/databricks_gold_corporate_linkage_export.csv")
evidence_rows = load_csv("data/samples/databricks_gold_firmographic_source_evidence_export.csv")

known_party_ids = {row["party_id"] for row in profile_rows}
allowed_location_types = set(
    json.loads(Path("contracts/pulse360_firmographic_enrichment_output.schema.json").read_text())
    ["properties"]["firmographic_profile"]["properties"]["location_type"]["enum"]
)
allowed_identifier_types = identifier_types
removed_identifier_types = {"PROVIDER_BOLDDATA_ID", "PROVIDER_INFOBEL_ID", "CRM_ACCOUNT_ID"}

batch_values = set()
for path, rows_for_batch in {
    "identifier": identifier_rows,
    "profile": profile_rows,
    "classification": classification_rows,
    "linkage": linkage_rows,
    "evidence": evidence_rows,
}.items():
    for row in rows_for_batch:
        if row["source_account_id"] not in known_source_accounts:
            raise SystemExit(f"{path} export references unknown source_account_id: {row['source_account_id']}")
        if row["party_id"] not in known_party_ids:
            raise SystemExit(f"{path} export references unknown party_id: {row['party_id']}")
        batch_values.add((row["run_id"], row["model_version"]))
if len(batch_values) != 1:
    raise SystemExit(f"Gold exports contain inconsistent run_id/model_version values: {sorted(batch_values)}")

for row in identifier_rows:
    if row["identifier_type"] not in allowed_identifier_types:
        raise SystemExit(f"Unknown identifier type in sample: {row['identifier_type']}")
    if row["identifier_type"] in removed_identifier_types:
        raise SystemExit(f"Provider/internal ID present in sovereign sample: {row['identifier_type']}")
    if row["is_sovereign_identifier"].lower() != "true":
        raise SystemExit(f"Sovereign sample row is not sovereign: {row['identifier_id']}")
    if row["verification_status"] == "verified":
        if row["source_type"] not in {"official_registry", "tax_authority", "filing"}:
            raise SystemExit(f"Verified sovereign ID has weak source type: {row['identifier_id']}")
        if float(row["confidence"]) < 0.9:
            raise SystemExit(f"Verified sovereign ID below confidence threshold: {row['identifier_id']}")
    if not row["source_url"]:
        raise SystemExit(f"Sovereign identifier missing source URL: {row['identifier_id']}")

for row in profile_rows:
    if row["location_type"] not in allowed_location_types:
        raise SystemExit(f"Invalid location_type in profile export: {row['location_type']}")
    if row["latest_financial_results_summary"] and not row["latest_financial_results_source_url"]:
        raise SystemExit(f"Investor financial summary missing source URL: {row['firmographic_profile_id']}")
    if row["investor_updates_summary"] and not row["investor_updates_source_urls"]:
        raise SystemExit(f"Investor updates summary missing source URLs: {row['firmographic_profile_id']}")

allowed_classification_schemes = {"SIC", "NAICS", "NACE", "LOCAL", "OTHER"}
for row in classification_rows:
    if row["scheme"] not in allowed_classification_schemes:
        raise SystemExit(f"Invalid classification scheme: {row['scheme']}")
    if not row["source_url"]:
        raise SystemExit(f"Classification missing source URL: {row['classification_id']}")

allowed_relationships = {"parent", "subsidiary", "branch", "ultimate_parent", "local_headquarter", "national_headquarter", "shared_director", "beneficial_owner", "other"}
for row in linkage_rows:
    if row["relationship_type"] not in allowed_relationships:
        raise SystemExit(f"Invalid corporate linkage relationship: {row['relationship_type']}")
    if row["related_party_id"] and row["related_party_id"] not in known_party_ids:
        raise SystemExit(f"Corporate linkage references unknown related_party_id: {row['related_party_id']}")
    if not row["source_url"]:
        raise SystemExit(f"Corporate linkage missing source URL: {row['linkage_id']}")

evidence_by_account_and_field = {
    (row["source_account_id"], row["field_path"]): row
    for row in evidence_rows
}
for row in identifier_rows:
    evidence_key = (row["source_account_id"], "identifiers[0].identifier_value")
    if evidence_key not in evidence_by_account_and_field:
        raise SystemExit(f"Identifier lacks field evidence: {row['identifier_id']}")
for row in profile_rows:
    for field in [
        "firmographic_profile.latest_financial_results_summary",
        "firmographic_profile.investor_updates_summary",
    ]:
        if row[field.split(".")[-1]] and (row["source_account_id"], field) not in evidence_by_account_and_field:
            raise SystemExit(f"Profile field lacks evidence: {row['firmographic_profile_id']} {field}")
for row in evidence_rows:
    if not row["source_url"]:
        raise SystemExit(f"Evidence row missing source URL: {row['evidence_id']}")
    if not row["evidence_excerpt"]:
        raise SystemExit(f"Evidence row missing excerpt: {row['evidence_id']}")
    if float(row["confidence"]) <= 0:
        raise SystemExit(f"Evidence row has non-positive confidence: {row['evidence_id']}")
PY
pass "Sovereign identifier, firmographic DMO, sample, and prompt artifacts are structurally valid"

grep -q "official_registry" config/openai/pulse360-sovereign-firmographic-enrichment-prompt.json || fail "Prompt missing official registry source rule"
grep -q "conflicts" config/openai/pulse360-sovereign-firmographic-enrichment-prompt.json || fail "Prompt missing conflict handling"
grep -q "source_url" contracts/pulse360_firmographic_enrichment_output.schema.json || fail "Firmographic schema missing source URL evidence"
grep -q '"confidence"' contracts/pulse360_sovereign_identifier.schema.json || fail "Identifier schema missing confidence"
pass "Sovereign and firmographic design validation completed"
