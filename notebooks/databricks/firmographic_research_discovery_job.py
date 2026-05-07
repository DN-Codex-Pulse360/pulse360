# Databricks notebook source
"""Pulse360 governed firmographic research discovery.

This job prepares source-governed research candidates for every Salesforce
Account before GPT extraction. It does not call paid firmographic providers and
does not assert facts by itself; it creates approved metadata rows that the
GenAI runtime can use as retrieval/search instructions and provenance anchors.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
import sys
from pathlib import Path
from typing import Any


SOURCE_TABLE = "pulse360_s4.silver_salesforce.crm_account"
TARGET_TABLE = "pulse360_s4.bronze_firmographic.account_research_discovery"
MODEL_VERSION = "firmographic-research-discovery-v1"
DEFAULT_TARGET_ACCOUNT_COUNT = 18

APPROVED_SOURCE_TYPES = [
    "official_registry",
    "tax_authority",
    "filing",
    "investor_relations",
    "annual_report",
    "earnings_release",
    "stock_exchange",
    "company_website",
]

COUNTRY_CODE_ALIASES = {
    "AU": "AU",
    "AUS": "AU",
    "AUSTRALIA": "AU",
    "CA": "CA",
    "CAN": "CA",
    "CANADA": "CA",
    "GB": "GB",
    "GBR": "GB",
    "GREAT BRITAIN": "GB",
    "HK": "HK",
    "HKG": "HK",
    "HONG KONG": "HK",
    "ID": "ID",
    "IDN": "ID",
    "INDONESIA": "ID",
    "MY": "MY",
    "MYS": "MY",
    "MALAYSIA": "MY",
    "PH": "PH",
    "PHL": "PH",
    "PHILIPPINES": "PH",
    "SG": "SG",
    "SGP": "SG",
    "SINGAPORE": "SG",
    "TH": "TH",
    "THA": "TH",
    "THAILAND": "TH",
    "UK": "GB",
    "UNITED KINGDOM": "GB",
    "US": "US",
    "USA": "US",
    "UNITED STATES": "US",
    "UNITED STATES OF AMERICA": "US",
    "VN": "VN",
    "VNM": "VN",
    "VIET NAM": "VN",
    "VIETNAM": "VN",
}

COUNTRY_NAME_BY_CODE = {
    "AU": "Australia",
    "CA": "Canada",
    "GB": "United Kingdom",
    "HK": "Hong Kong",
    "ID": "Indonesia",
    "MY": "Malaysia",
    "PH": "Philippines",
    "SG": "Singapore",
    "TH": "Thailand",
    "US": "United States",
    "VN": "Vietnam",
    "ZZ": "global",
}


def utc_now_iso() -> str:
    return dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")


def get_spark():
    try:
        return globals()["spark"]
    except KeyError:
        return None


def slug(value: str) -> str:
    cleaned = re.sub(r"[^a-z0-9]+", "_", value.lower()).strip("_")
    return cleaned or "unknown"


def source_account_id(row: dict[str, Any]) -> str:
    return str(row.get("crm_account_id") or row.get("source_account_id") or "")


def account_name(row: dict[str, Any]) -> str:
    return str(row.get("crm_account_name") or row.get("account_name") or "")


def account_country(row: dict[str, Any]) -> str:
    country = row.get("crm_billing_country") or row.get("crm_shipping_country") or row.get("country") or "ZZ"
    normalized = re.sub(r"[^A-Za-z]+", " ", str(country)).strip().upper()
    return COUNTRY_CODE_ALIASES.get(normalized, str(country)[:2].upper() if country else "ZZ")


def country_search_label(country_code: str) -> str:
    return COUNTRY_NAME_BY_CODE.get(country_code, country_code)


def account_website(row: dict[str, Any]) -> str | None:
    website = row.get("crm_website") or row.get("website")
    return str(website) if website else None


def build_discovery_rows(accounts: list[dict[str, Any]], target_account_count: int) -> list[dict[str, Any]]:
    run_id = f"research_discovery_{dt.datetime.now(dt.timezone.utc).strftime('%Y%m%d%H%M%S')}"
    retrieved_at = utc_now_iso()
    rows: list[dict[str, Any]] = []

    for account in accounts[:target_account_count]:
        crm_account_id = source_account_id(account)
        name = account_name(account)
        country = account_country(account)
        country_label = country_search_label(country)
        website = account_website(account)
        account_slug = slug(name)
        base_query = f'"{name}" {country_label} {country}'.strip()
        jurisdiction_guard = (
            f"Prioritize {country_label} ({country}) registry, tax, filing, company website, and address evidence. "
            "Reject or flag similarly named entities in other countries unless the CRM account country is absent or "
            "cross-border registration is directly supported."
        )
        source_candidates = [
            {
                "source_type": "official_registry",
                "source_name": "Official registry search",
                "source_url": f"https://www.google.com/search?q={base_query}+official+company+registry",
                "search_query": f"{base_query} official company registry registration number. {jurisdiction_guard}",
                "use_basis": "public_registry_search",
                "target_fields": ["identifiers", "registration_status", "legal_form", "incorporation_date"],
            },
            {
                "source_type": "tax_authority",
                "source_name": "Tax authority search",
                "source_url": f"https://www.google.com/search?q={base_query}+tax+identifier",
                "search_query": f"{base_query} tax identifier business registration. {jurisdiction_guard}",
                "use_basis": "public_tax_reference_search",
                "target_fields": ["identifiers"],
            },
            {
                "source_type": "filing",
                "source_name": "Regulatory filing search",
                "source_url": f"https://www.google.com/search?q={base_query}+annual+report+filing",
                "search_query": f"{base_query} annual report filing latest financial results. {jurisdiction_guard}",
                "use_basis": "public_filing_search",
                "target_fields": [
                    "latest_financial_results_summary",
                    "latest_financial_results_period",
                    "latest_fin_results_presentation_date",
                    "latest_financial_results_source_url",
                ],
            },
            {
                "source_type": "investor_relations",
                "source_name": "Investor relations search",
                "source_url": f"https://www.google.com/search?q={base_query}+investor+relations+presentation",
                "search_query": f"{base_query} investor relations earnings presentation news. {jurisdiction_guard}",
                "use_basis": "public_investor_material_search",
                "target_fields": ["investor_updates_summary", "investor_updates_source_urls"],
            },
            {
                "source_type": "annual_report",
                "source_name": "Annual report search",
                "source_url": f"https://www.google.com/search?q={base_query}+annual+report+PDF",
                "search_query": f"{base_query} annual report PDF revenue employees subsidiaries. {jurisdiction_guard}",
                "use_basis": "public_company_report_search",
                "target_fields": ["annual_revenue_local", "employees_total", "corporate_linkages"],
            },
            {
                "source_type": "earnings_release",
                "source_name": "Earnings release search",
                "source_url": f"https://www.google.com/search?q={base_query}+earnings+release",
                "search_query": f"{base_query} earnings release latest results. {jurisdiction_guard}",
                "use_basis": "public_earnings_release_search",
                "target_fields": ["latest_financial_results_summary", "investor_updates_summary"],
            },
            {
                "source_type": "stock_exchange",
                "source_name": "Stock exchange search",
                "source_url": f"https://www.google.com/search?q={base_query}+stock+exchange+filing",
                "search_query": f"{base_query} stock exchange filing listed company. {jurisdiction_guard}",
                "use_basis": "public_market_disclosure_search",
                "target_fields": ["identifiers", "latest_financial_results_summary", "corporate_linkages"],
            },
            {
                "source_type": "company_website",
                "source_name": "Company website",
                "source_url": website or f"https://www.google.com/search?q={base_query}+official+website",
                "search_query": f"{base_query} official website about company. {jurisdiction_guard}",
                "use_basis": "public_company_website_search",
                "target_fields": ["business_description", "website", "company_classification"],
            },
        ]

        for index, candidate in enumerate(source_candidates, start=1):
            discovery_id = f"disc_{crm_account_id.lower()}_{index}_{slug(candidate['source_type'])}"
            rows.append(
                {
                    "research_discovery_id": discovery_id,
                    "source_account_id": crm_account_id,
                    "party_id": f"party_{crm_account_id.lower()}",
                    "candidate_account_name": name,
                    "candidate_country_code": country,
                    "source_type": candidate["source_type"],
                    "source_name": candidate["source_name"],
                    "source_url": candidate["source_url"],
                    "search_query": candidate["search_query"],
                    "target_fields_json": json.dumps(candidate["target_fields"], sort_keys=True),
                    "license_or_use_basis": candidate["use_basis"],
                    "approval_status": "approved_for_gpt",
                    "source_confidence": 0.65 if candidate["source_type"] == "company_website" else 0.75,
                    "retrieved_at": retrieved_at,
                    "run_id": run_id,
                    "model_version": MODEL_VERSION,
                    "target_account_count": target_account_count,
                    "account_slug": account_slug,
                }
            )
    return rows


def sample_accounts() -> list[dict[str, Any]]:
    return [
        {
            "crm_account_id": "001dL000024xl9FQAQ",
            "crm_account_name": "Singapore Telecommunications Limited",
            "crm_billing_country": "SG",
            "crm_website": "https://www.singtel.com",
        },
        {
            "crm_account_id": "001dL000024xlArQAI",
            "crm_account_name": "NCS Pte. Ltd.",
            "crm_billing_country": "SG",
            "crm_website": "https://www.ncs.co",
        },
    ]


def read_accounts(source_table: str, fixture_only: bool) -> list[dict[str, Any]]:
    spark_session = get_spark()
    if fixture_only or spark_session is None:
        return sample_accounts()
    return [row.asDict(recursive=True) for row in spark_session.table(source_table).collect()]


def write_rows(rows: list[dict[str, Any]], target_table: str) -> None:
    spark_session = get_spark()
    if spark_session is None:
        return
    from pyspark.sql.types import DoubleType, IntegerType, StringType, StructField, StructType

    schema = StructType(
        [
            StructField("research_discovery_id", StringType(), False),
            StructField("source_account_id", StringType(), False),
            StructField("party_id", StringType(), False),
            StructField("candidate_account_name", StringType(), False),
            StructField("candidate_country_code", StringType(), False),
            StructField("source_type", StringType(), False),
            StructField("source_name", StringType(), False),
            StructField("source_url", StringType(), False),
            StructField("search_query", StringType(), False),
            StructField("target_fields_json", StringType(), False),
            StructField("license_or_use_basis", StringType(), False),
            StructField("approval_status", StringType(), False),
            StructField("source_confidence", DoubleType(), False),
            StructField("retrieved_at", StringType(), False),
            StructField("run_id", StringType(), False),
            StructField("model_version", StringType(), False),
            StructField("target_account_count", IntegerType(), False),
            StructField("account_slug", StringType(), False),
        ]
    )
    spark_session.createDataFrame(rows, schema=schema).write.mode("overwrite").option("overwriteSchema", "true").saveAsTable(target_table)


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Create governed firmographic research discovery rows.")
    parser.add_argument("--source-table", default=SOURCE_TABLE)
    parser.add_argument("--target-table", default=TARGET_TABLE)
    parser.add_argument("--target-account-count", type=int, default=DEFAULT_TARGET_ACCOUNT_COUNT)
    parser.add_argument("--fixture-only", action="store_true")
    parser.add_argument("--local-output", default="")
    args, _ = parser.parse_known_args(argv)
    return args


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    accounts = read_accounts(args.source_table, args.fixture_only)
    rows = build_discovery_rows(accounts, args.target_account_count)
    write_rows(rows, args.target_table)

    if args.local_output:
        output_path = Path(args.local_output)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(json.dumps(rows, indent=2, sort_keys=True) + "\n")

    print(
        json.dumps(
            {
                "source_table": args.source_table,
                "target_table": args.target_table,
                "target_account_count": args.target_account_count,
                "account_count": min(len(accounts), args.target_account_count),
                "research_discovery_rows": len(rows),
                "approved_source_types": APPROVED_SOURCE_TYPES,
            },
            indent=2,
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    main(sys.argv[1:])
