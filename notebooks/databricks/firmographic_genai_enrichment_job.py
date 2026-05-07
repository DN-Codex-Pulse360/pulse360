# Databricks notebook source
"""Pulse360 firmographic GPT enrichment runtime.

This notebook/script is intentionally dual-mode:

- fixture mode: deterministic output for demos and local validation
- live mode: OpenAI Responses API call when OPENAI_API_KEY is available

The runtime writes both the historical narrative/action staging row and the
Data Cloud promotion contract row used by the five firmographic DMO exports.
"""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
import re
import sys
import tempfile
import uuid
from pathlib import Path
from typing import Any

import jsonschema
import requests


def repo_root() -> Path:
    env_root = os.environ.get("PULSE360_REPO_ROOT")
    if env_root:
        return Path(env_root).expanduser().resolve()
    try:
        return Path(__file__).resolve().parents[2]
    except NameError:
        return Path.cwd()


REPO_ROOT = repo_root()
DEFAULT_CONFIG_PATH = REPO_ROOT / "config/openai/pulse360-gpt-enrichment-spec.json"
DEFAULT_OUTPUT_SCHEMA_PATH = REPO_ROOT / "contracts/genai_firmographic_enrichment_output.schema.json"
DEFAULT_DATA_CLOUD_SCHEMA_PATH = REPO_ROOT / "contracts/pulse360_firmographic_enrichment_output.schema.json"
DEFAULT_SAMPLE_PACKET_PATH = REPO_ROOT / "data/samples/firmographic_evidence_packet_sample.json"
DEFAULT_LOCAL_OUTPUT_PATH = REPO_ROOT / "data/exports/firmographic_genai_runtime_sample.json"

SOURCE_TABLE = "pulse360_s4.bronze_firmographic.account_research_discovery"
TARGET_TABLE = "pulse360_s4.gold.account_genai_enrichment_output_runtime"
LATEST_TABLE = "pulse360_s4.gold.account_gpt_firmographic_latest"
MODEL_VERSION = "genai-firmographic-enrichment-runtime-v1"
MLFLOW_EXPERIMENT_PATH = "/Shared/pulse360/pulse360-firmographic-enrichment/dev/mlflow/firmographic-genai-runtime"

DEFAULT_CONFIG = {
    "api": "openai_responses",
    "provider": "openai",
    "models": {
        "narrative_reasoning": "gpt-5.5",
        "action_ranking": "gpt-5.5",
        "high_volume_extraction": "gpt-5.5",
    },
    "prompt_version": "pulse360-public-regional-openai-v2",
    "structured_outputs_required": True,
    "reasoning": {"default_effort": "low", "retry_effort": "medium"},
    "prompt_caching": {"prompt_cache_key": "pulse360-firmographic-openai-v2"},
    "request_timeout_seconds": 300,
    "tools": {"web_search": {"enabled": False, "type": "web_search"}},
}

DEFAULT_OUTPUT_SCHEMA = {
    "type": "object",
    "additionalProperties": False,
    "required": [
        "genai_enrichment_id",
        "evidence_packet_id",
        "resolved_entity_id",
        "ai_narrative",
        "ai_recommended_actions",
        "llm_result_confidence",
        "business_action_confidence",
        "confidence_components",
        "unsupported_claim_count",
        "insufficient_evidence_flag",
        "source_refs",
        "model_id",
        "prompt_version",
        "llm_run_id",
        "llm_input_hash",
        "llm_output_hash",
        "generation_mode",
        "activation_eligible_flag",
        "run_id",
        "run_timestamp",
        "model_version",
    ],
    "properties": {
        "genai_enrichment_id": {"type": "string", "minLength": 1},
        "evidence_packet_id": {"type": "string", "minLength": 1},
        "resolved_entity_id": {"type": "string", "pattern": "^ent_[A-Za-z0-9_]+$"},
        "crm_account_id": {"type": ["string", "null"], "minLength": 15, "maxLength": 18},
        "ai_narrative": {"type": "string", "minLength": 1},
        "ai_recommended_actions": {
            "type": "array",
            "items": {
                "type": "object",
                "additionalProperties": False,
                "required": ["rank", "action_type", "target", "reasoning", "confidence", "source_ids"],
                "properties": {
                    "rank": {"type": "integer", "minimum": 1},
                    "action_type": {"type": "string", "minLength": 1},
                    "target": {"type": "string", "minLength": 1},
                    "target_record_id": {"type": ["string", "null"]},
                    "reasoning": {"type": "string", "minLength": 1},
                    "estimated_revenue_impact": {"type": ["string", "null"]},
                    "confidence": {"type": "number", "minimum": 0, "maximum": 1},
                    "source_ids": {"type": "array", "minItems": 1, "items": {"type": "string", "minLength": 1}},
                },
            },
        },
        "llm_result_confidence": {"type": "number", "minimum": 0, "maximum": 1},
        "business_action_confidence": {"type": "number", "minimum": 0, "maximum": 1},
        "confidence_components": {
            "type": "object",
            "additionalProperties": False,
            "required": [
                "source_reliability_score",
                "evidence_coverage_score",
                "corroboration_score",
                "freshness_score",
                "extraction_certainty_score",
                "conflict_penalty",
                "schema_validation_score",
                "citation_binding_score",
                "actionability_score",
                "crm_anchor_score",
                "policy_safety_score",
            ],
            "properties": {
                "source_reliability_score": {"type": "number", "minimum": 0, "maximum": 1},
                "evidence_coverage_score": {"type": "number", "minimum": 0, "maximum": 1},
                "corroboration_score": {"type": "number", "minimum": 0, "maximum": 1},
                "freshness_score": {"type": "number", "minimum": 0, "maximum": 1},
                "extraction_certainty_score": {"type": "number", "minimum": 0, "maximum": 1},
                "conflict_penalty": {"type": "number", "minimum": 0, "maximum": 1},
                "schema_validation_score": {"type": "number", "minimum": 0, "maximum": 1},
                "citation_binding_score": {"type": "number", "minimum": 0, "maximum": 1},
                "actionability_score": {"type": "number", "minimum": 0, "maximum": 1},
                "crm_anchor_score": {"type": "number", "minimum": 0, "maximum": 1},
                "policy_safety_score": {"type": "number", "minimum": 0, "maximum": 1},
            },
        },
        "unsupported_claim_count": {"type": "integer", "minimum": 0},
        "insufficient_evidence_flag": {"type": "boolean"},
        "source_refs": {"type": "array", "minItems": 1, "items": {"type": "string", "minLength": 1}},
        "model_id": {"type": "string", "minLength": 1},
        "prompt_version": {"type": "string", "minLength": 1},
        "llm_run_id": {"type": "string", "minLength": 1},
        "llm_input_hash": {"type": "string", "minLength": 1},
        "llm_output_hash": {"type": "string", "minLength": 1},
        "llm_cost_estimate": {"type": ["number", "null"], "minimum": 0},
        "generation_mode": {"type": "string", "enum": ["source_bound_fixture", "batch_llm", "human_reviewed_llm"]},
        "activation_eligible_flag": {"type": "boolean"},
        "run_id": {"type": "string", "minLength": 1},
        "run_timestamp": {"type": "string", "format": "date-time"},
        "model_version": {"type": "string", "minLength": 1},
    },
}

DEFAULT_DATA_CLOUD_SCHEMA = {
    "type": "object",
    "additionalProperties": False,
    "required": [
        "source_account_id",
        "party_id",
        "legal_name",
        "jurisdiction_country_code",
        "identifiers",
        "firmographic_profile",
        "classifications",
        "corporate_linkages",
        "executive_roles",
        "digital_footprint",
        "field_evidence",
        "conflicts",
        "overall_confidence",
        "last_verified_at",
        "run_id",
        "model_version",
    ],
    "properties": {
        "source_account_id": {"type": "string", "minLength": 1},
        "party_id": {"type": "string", "minLength": 1},
        "legal_name": {"type": "string", "minLength": 1},
        "trade_name": {"type": "string"},
        "jurisdiction_country_code": {"type": "string", "minLength": 2, "maxLength": 2},
        "identifiers": {"type": "array", "items": {"type": "object"}},
        "firmographic_profile": {
            "type": "object",
            "additionalProperties": True,
            "required": ["registration_status", "legal_form", "primary_industry_label", "confidence"],
            "properties": {
                "registration_status": {"type": "string"},
                "legal_form": {"type": "string"},
                "primary_industry_label": {"type": "string"},
                "latest_financial_results_summary": {"type": "string"},
                "latest_financial_results_source_url": {"type": "string"},
                "investor_updates_summary": {"type": "string"},
                "investor_updates_source_urls": {"type": "array", "items": {"type": "string"}},
                "location_type": {
                    "type": "string",
                    "enum": [
                        "single_location",
                        "headquarters",
                        "branch",
                        "regional_office",
                        "subsidiary",
                        "parent_company",
                        "ultimate_parent",
                        "registered_office",
                        "operating_site",
                        "unknown",
                    ],
                },
                "confidence": {"type": "number", "minimum": 0, "maximum": 1},
            },
        },
        "classifications": {"type": "array", "items": {"type": "object"}},
        "corporate_linkages": {"type": "array", "items": {"type": "object"}},
        "executive_roles": {"type": "array", "items": {"type": "object"}},
        "digital_footprint": {"type": "array", "items": {"type": "object"}},
        "field_evidence": {
            "type": "array",
            "minItems": 1,
            "items": {
                "type": "object",
                "additionalProperties": False,
                "required": ["field_path", "source_name", "source_type", "source_url", "confidence"],
                "properties": {
                    "field_path": {"type": "string", "minLength": 1},
                    "source_name": {"type": "string", "minLength": 1},
                    "source_type": {
                        "type": "string",
                        "enum": [
                            "official_registry",
                            "tax_authority",
                            "filing",
                            "provider",
                            "crm",
                            "customer_internal",
                            "web_research",
                            "other",
                        ],
                    },
                    "source_url": {"type": "string", "minLength": 1},
                    "evidence_excerpt": {"type": "string"},
                    "retrieved_at": {"type": "string", "format": "date-time"},
                    "confidence": {"type": "number", "minimum": 0, "maximum": 1},
                },
            },
        },
        "conflicts": {"type": "array", "items": {"type": "object"}},
        "overall_confidence": {"type": "number", "minimum": 0, "maximum": 1},
        "last_verified_at": {"type": "string", "format": "date-time"},
        "run_id": {"type": "string", "minLength": 1},
        "model_version": {"type": "string", "minLength": 1},
    },
}

DEFAULT_SAMPLE_PACKET = {
    "evidence_packet_id": "firmographic_packet_ent_ph_sec_as096_003241",
    "account_context": {
        "crm_account_id": None,
        "crm_account_name": "Ayala Corporation",
        "country": "PH",
        "website_domain": "ayala.com",
    },
    "resolved_identity": {
        "resolved_entity_id": "ent_ph_sec_as096_003241",
        "sovereign_identity_key": "PH|SEC_AS096|003241",
        "crm_safe_activation_key": None,
        "identity_confidence": 96,
    },
    "firmographic_facts": [
        {
            "source_id": "src_neutral_firmographic_ayala_revenue_2024",
            "fact_type": "financial",
            "fact_name": "annual_revenue",
            "fact_value": 176300000000,
            "fact_unit": "PHP",
            "source_confidence": 0.91,
            "freshness_status": "fresh",
            "license_or_contract_reference": "approved-neutral-fixture",
        },
        {
            "source_id": "src_neutral_firmographic_ayala_group_hint",
            "fact_type": "hierarchy_hint",
            "fact_name": "external_subsidiaries_found",
            "fact_value": 3,
            "fact_unit": "count",
            "source_confidence": 0.84,
            "freshness_status": "fresh",
            "license_or_contract_reference": "approved-neutral-fixture",
        },
    ],
    "hierarchy_context": {
        "known_subsidiary_count": 4,
        "crm_covered_subsidiary_count": 1,
        "external_subsidiaries_found": 3,
        "coverage_gap_flag": True,
    },
    "source_refs": [
        {"source_id": "src_neutral_firmographic_ayala_revenue_2024"},
        {"source_id": "src_neutral_firmographic_ayala_group_hint"},
    ],
}


def utc_now() -> dt.datetime:
    return dt.datetime.now(dt.timezone.utc)


def utc_now_iso() -> str:
    return utc_now().isoformat(timespec="seconds").replace("+00:00", "Z")


def stable_json(value: Any) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), default=str)


def sha256_json(value: Any) -> str:
    return "sha256:" + hashlib.sha256(stable_json(value).encode("utf-8")).hexdigest()


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text())


def load_json_or_default(path: Path, default: dict[str, Any]) -> dict[str, Any]:
    return load_json(path) if path.exists() else default


def score_0_to_1(value: Any, default: float = 0.0) -> float:
    try:
        numeric = float(value)
    except (TypeError, ValueError):
        return default
    if numeric > 1:
        numeric = numeric / 100
    return max(0.0, min(1.0, numeric))


def get_spark():
    try:
        return globals()["spark"]
    except KeyError:
        return None


def build_packet_from_sample(path: Path) -> dict[str, Any]:
    packet = load_json_or_default(path, DEFAULT_SAMPLE_PACKET)
    packet.setdefault("evidence_packet_id", f"firmographic_packet_{packet['resolved_identity']['resolved_entity_id']}")
    return packet


def build_packet_from_rows(rows: list[dict[str, Any]]) -> dict[str, Any]:
    if not rows:
        raise RuntimeError("No rows supplied for firmographic evidence packet.")

    account_id = rows[0].get("crm_account_id") or rows[0].get("source_account_id")
    resolved_entity_id = rows[0].get("resolved_entity_id") or f"ent_{safe_token(account_id or rows[0].get('candidate_account_name'))}"
    source_ref_map: dict[str, dict[str, Any]] = {}
    facts = []
    for row in rows:
        source_id = row.get("source_id") or row.get("source_record_id") or row.get("research_discovery_id")
        if source_id:
            source_excerpt = row.get("source_excerpt")
            if not source_excerpt and row.get("search_query"):
                source_excerpt = f"Approved discovery query for {row.get('candidate_account_name')}: {row.get('search_query')}"
            source_ref_map[str(source_id)] = {
                "source_id": str(source_id),
                "source_type": row.get("source_type") or "approved_firmographic_source",
                "source_name": row.get("source_name"),
                "document_date": str(row.get("document_date")) if row.get("document_date") else None,
                "accessed_at": str(row.get("accessed_at")) if row.get("accessed_at") else str(row.get("retrieved_at") or row.get("last_refreshed_at")),
                "source_url": row.get("source_url"),
                "search_query": row.get("search_query"),
                "target_fields_json": row.get("target_fields_json"),
                "excerpt": source_excerpt,
            }
        fact_name = row.get("fact_name") or row.get("source_type") or "research_candidate"
        facts.append(
            {
                "source_id": source_id,
                "fact_type": row.get("fact_type") or "research_candidate",
                "fact_name": fact_name,
                "fact_value": row.get("fact_value") or row.get("search_query") or row.get("source_url"),
                "fact_unit": row.get("fact_unit"),
                "fact_period_start": str(row.get("fact_period_start")) if row.get("fact_period_start") else None,
                "fact_period_end": str(row.get("fact_period_end")) if row.get("fact_period_end") else None,
                "source_confidence": score_0_to_1(row.get("source_confidence"), 0.65),
                "source_reliability_code": row.get("source_reliability_code") or row.get("source_type"),
                "field_completeness_score": score_0_to_1(row.get("field_completeness_score"), 0.75),
                "freshness_status": row.get("freshness_status") or "fresh",
                "last_refreshed_at": str(row.get("retrieved_at") or row.get("last_refreshed_at")) if row.get("retrieved_at") or row.get("last_refreshed_at") else None,
                "license_or_contract_reference": row.get("license_or_contract_reference") or row.get("license_or_use_basis"),
            }
        )

    source_refs = [source_ref_map[key] for key in sorted(source_ref_map)]
    return {
        "evidence_packet_id": f"firmographic_packet_{resolved_entity_id}",
        "account_context": {
            "crm_account_id": account_id,
            "crm_account_name": rows[0].get("crm_account_name") or rows[0].get("registered_legal_name") or rows[0].get("candidate_account_name") or rows[0].get("account_candidate_name"),
            "country": rows[0].get("country_of_incorporation") or rows[0].get("candidate_country_code") or rows[0].get("account_candidate_country"),
            "website_domain": rows[0].get("website_domain") or rows[0].get("source_url"),
        },
        "resolved_identity": {
            "resolved_entity_id": resolved_entity_id,
            "sovereign_identity_key": rows[0].get("sovereign_identity_key"),
            "crm_safe_activation_key": account_id,
            "identity_confidence": rows[0].get("identity_confidence"),
        },
        "firmographic_facts": facts,
        "hierarchy_context": {
            "known_subsidiary_count": rows[0].get("known_subsidiary_count"),
            "crm_covered_subsidiary_count": rows[0].get("crm_covered_subsidiary_count"),
            "external_subsidiaries_found": rows[0].get("external_subsidiaries_found"),
            "coverage_gap_flag": rows[0].get("coverage_gap_flag"),
        },
        "source_refs": source_refs,
    }


def build_packets_from_spark(source_table: str) -> list[dict[str, Any]]:
    spark_session = get_spark()
    if spark_session is None:
        raise RuntimeError("Spark is not available; use --fixture-only for local validation.")

    rows = [row.asDict(recursive=True) for row in spark_session.table(source_table).collect()]
    if not rows:
        raise RuntimeError(f"No rows found in {source_table}")

    grouped_rows: dict[str, list[dict[str, Any]]] = {}
    for row in rows:
        grouping_key = (
            row.get("crm_account_id")
            or row.get("source_account_id")
            or row.get("resolved_entity_id")
            or row.get("registered_legal_name")
            or row.get("account_candidate_name")
            or "unknown"
        )
        grouped_rows.setdefault(str(grouping_key), []).append(row)
    return [build_packet_from_rows(grouped_rows[key]) for key in sorted(grouped_rows)]


def build_packet_from_spark(source_table: str) -> dict[str, Any]:
    return build_packets_from_spark(source_table)[0]


def source_ids(packet: dict[str, Any]) -> list[str]:
    refs = packet.get("source_refs") or []
    ids = []
    for ref in refs:
        if isinstance(ref, str):
            ids.append(ref)
        elif isinstance(ref, dict) and ref.get("source_id"):
            ids.append(str(ref["source_id"]))
    for fact in packet.get("firmographic_facts") or []:
        source_id = fact.get("source_id")
        if source_id:
            ids.append(str(source_id))
    return sorted(set(ids))


def model_source_ids(model_payload: dict[str, Any]) -> list[str]:
    ids: list[str] = []
    for action in model_payload.get("ai_recommended_actions") or []:
        ids.extend(str(source_id) for source_id in action.get("source_ids") or [] if source_id)
    for collection_name in ("identifiers", "classifications", "corporate_linkages", "field_evidence"):
        for item in model_payload.get(collection_name) or []:
            if item.get("source_id"):
                ids.append(str(item["source_id"]))
    return sorted(set(ids))


def confidence_components(packet: dict[str, Any], model_payload: dict[str, Any]) -> dict[str, float]:
    facts = packet.get("firmographic_facts") or []
    fact_confidences = [score_0_to_1(fact.get("source_confidence"), 0.75) for fact in facts]
    source_reliability = sum(fact_confidences) / len(fact_confidences) if fact_confidences else 0.0

    required_fact_types = {"financial", "hierarchy"}
    observed_fact_types = {str(fact.get("fact_type")) for fact in facts if fact.get("fact_type")}
    evidence_coverage = len(required_fact_types & observed_fact_types) / len(required_fact_types)
    if facts and evidence_coverage == 0:
        evidence_coverage = 0.5

    action_count = len(model_payload.get("ai_recommended_actions") or [])
    actionability = 0.8 if action_count else 0.2
    crm_anchor = 1.0 if packet.get("resolved_identity", {}).get("crm_safe_activation_key") else 0.2

    allowed_sources = set(source_ids(packet)) | set(model_source_ids(model_payload))
    cited_sources = []
    for action in model_payload.get("ai_recommended_actions") or []:
        cited_sources.extend(action.get("source_ids") or [])
    cited_sources = [str(source_id) for source_id in cited_sources]
    citation_binding = 1.0 if cited_sources and set(cited_sources).issubset(allowed_sources) else 0.0

    freshness_values = {str(fact.get("freshness_status", "unknown")) for fact in facts}
    freshness = 0.9 if "fresh" in freshness_values else 0.65 if "stale" in freshness_values else 0.45

    return {
        "source_reliability_score": round(source_reliability, 4),
        "evidence_coverage_score": round(evidence_coverage, 4),
        "corroboration_score": 0.75 if len(allowed_sources) > 1 else 0.55,
        "freshness_score": freshness,
        "extraction_certainty_score": min(score_0_to_1(model_payload.get("extraction_certainty_score"), 0.84), source_reliability or 0.84),
        "conflict_penalty": score_0_to_1(model_payload.get("conflict_penalty"), 0.1),
        "schema_validation_score": 1.0,
        "citation_binding_score": citation_binding,
        "actionability_score": actionability,
        "crm_anchor_score": crm_anchor,
        "policy_safety_score": 1.0,
    }


def llm_result_confidence(components: dict[str, float]) -> float:
    score = (
        0.20 * components["source_reliability_score"]
        + 0.20 * components["evidence_coverage_score"]
        + 0.15 * components["corroboration_score"]
        + 0.15 * components["freshness_score"]
        + 0.15 * components["extraction_certainty_score"]
        + 0.10 * components["citation_binding_score"]
        + 0.05 * components["schema_validation_score"]
        - components["conflict_penalty"]
    )
    return round(max(0.0, min(1.0, score)), 4)


def business_action_confidence(llm_score: float, components: dict[str, float]) -> float:
    score = (
        0.60 * llm_score
        + 0.20 * components["actionability_score"]
        + 0.10 * components["crm_anchor_score"]
        + 0.10 * components["policy_safety_score"]
    )
    return round(max(0.0, min(1.0, score)), 4)


def fixture_model_payload(packet: dict[str, Any]) -> dict[str, Any]:
    allowed_sources = source_ids(packet)
    entity_id = packet["resolved_identity"]["resolved_entity_id"]
    crm_anchor = packet["resolved_identity"].get("crm_safe_activation_key")
    narrative = (
        "The governed evidence packet shows a firmographic coverage gap, but "
        "the output should remain in review until a CRM-safe activation key is "
        "available and all narrative claims are tied to source IDs."
    )
    if "ayala" in stable_json(packet).lower():
        narrative = (
            "Ayala Corporation has a coverage gap because governed firmographic "
            "evidence shows external group scale while the current CRM-safe "
            "anchor is not yet available for this group profile. The revenue and "
            "group coverage statements are limited to supplied source facts and "
            "should stay in review until a Salesforce Account anchor or approved "
            "External ID is established."
        )
    return {
        "ai_narrative": narrative,
        "ai_recommended_actions": [
            {
                "rank": 1,
                "action_type": "flag_hierarchy_review",
                "target": f"{entity_id} coverage gap review",
                "target_record_id": crm_anchor,
                "reasoning": "Route to stewardship before CRM activation because the evidence packet is source-bound but activation is not fully safe.",
                "estimated_revenue_impact": "Improved group coverage accuracy before seller activation",
                "confidence": 0.74,
                "source_ids": allowed_sources[:2] or allowed_sources,
            }
        ],
        "unsupported_claim_count": 0,
        "insufficient_evidence_flag": False,
        "extraction_certainty_score": 0.84,
        "conflict_penalty": 0.10,
        "firmographic_profile": {
            "registration_status": "unknown",
            "legal_form": "",
            "primary_industry_label": "Unknown",
            "business_category": "Unknown",
            "business_description": narrative,
            "annual_revenue_local": None,
            "annual_revenue_usd": None,
            "revenue_currency": "",
            "revenue_year": None,
            "latest_financial_results_summary": "",
            "latest_financial_results_period": "",
            "latest_financial_results_source_url": "",
            "investor_updates_summary": "",
            "investor_updates_source_urls": [],
            "location_type": "unknown",
            "confidence": 0.72,
        },
        "identifiers": [],
        "classifications": [],
        "corporate_linkages": [],
        "field_evidence": [],
        "conflicts": [],
    }


def response_schema(allowed_source_ids: list[str]) -> dict[str, Any]:
    source_enum = allowed_source_ids or ["no_source_available"]
    return {
        "type": "object",
        "additionalProperties": False,
        "required": [
            "ai_narrative",
            "ai_recommended_actions",
            "unsupported_claim_count",
            "insufficient_evidence_flag",
            "extraction_certainty_score",
            "conflict_penalty",
            "firmographic_profile",
            "identifiers",
            "classifications",
            "corporate_linkages",
            "field_evidence",
            "conflicts",
        ],
        "properties": {
            "ai_narrative": {"type": "string"},
            "ai_recommended_actions": {
                "type": "array",
                "items": {
                    "type": "object",
                    "additionalProperties": False,
                    "required": ["rank", "action_type", "target", "target_record_id", "reasoning", "estimated_revenue_impact", "confidence", "source_ids"],
                    "properties": {
                        "rank": {"type": "integer"},
                        "action_type": {"type": "string"},
                        "target": {"type": "string"},
                        "target_record_id": {"type": ["string", "null"]},
                        "reasoning": {"type": "string"},
                        "estimated_revenue_impact": {"type": ["string", "null"]},
                        "confidence": {"type": "number"},
                        "source_ids": {
                            "type": "array",
                            "items": {"type": "string"},
                        },
                    },
                },
            },
            "unsupported_claim_count": {"type": "integer"},
            "insufficient_evidence_flag": {"type": "boolean"},
            "extraction_certainty_score": {"type": "number"},
            "conflict_penalty": {"type": "number"},
            "firmographic_profile": {
                "type": "object",
                "additionalProperties": False,
                "required": [
                    "registration_status",
                    "legal_form",
                    "primary_industry_label",
                    "business_category",
                    "business_description",
                    "annual_revenue_local",
                    "annual_revenue_usd",
                    "revenue_currency",
                    "revenue_year",
                    "latest_financial_results_summary",
                    "latest_financial_results_period",
                    "latest_financial_results_source_url",
                    "investor_updates_summary",
                    "investor_updates_source_urls",
                    "location_type",
                    "confidence",
                ],
                "properties": {
                    "registration_status": {"type": "string"},
                    "legal_form": {"type": "string"},
                    "primary_industry_label": {"type": "string"},
                    "business_category": {"type": "string"},
                    "business_description": {"type": "string"},
                    "annual_revenue_local": {"type": ["number", "null"]},
                    "annual_revenue_usd": {"type": ["number", "null"]},
                    "revenue_currency": {"type": "string"},
                    "revenue_year": {"type": ["integer", "null"]},
                    "latest_financial_results_summary": {"type": "string"},
                    "latest_financial_results_period": {"type": "string"},
                    "latest_financial_results_source_url": {"type": "string"},
                    "investor_updates_summary": {"type": "string"},
                    "investor_updates_source_urls": {"type": "array", "items": {"type": "string"}},
                    "location_type": {
                        "type": "string",
                        "enum": [
                            "single_location",
                            "headquarters",
                            "branch",
                            "regional_office",
                            "subsidiary",
                            "parent_company",
                            "ultimate_parent",
                            "registered_office",
                            "operating_site",
                            "unknown",
                        ],
                    },
                    "confidence": {"type": "number"},
                },
            },
            "identifiers": {
                "type": "array",
                "items": {
                    "type": "object",
                    "additionalProperties": False,
                    "required": [
                        "identifier_type",
                        "identifier_name",
                        "identifier_value",
                        "normalized_identifier_value",
                        "jurisdiction_country_code",
                        "issuing_authority",
                        "issued_at_location",
                        "issued_date",
                        "expiry_date",
                        "is_sovereign_identifier",
                        "verification_status",
                        "confidence",
                        "source_id",
                        "source_name",
                        "source_type",
                        "source_url",
                        "evidence_excerpt",
                    ],
                    "properties": {
                        "identifier_type": {"type": "string"},
                        "identifier_name": {"type": "string"},
                        "identifier_value": {"type": "string"},
                        "normalized_identifier_value": {"type": "string"},
                        "jurisdiction_country_code": {"type": "string"},
                        "issuing_authority": {"type": "string"},
                        "issued_at_location": {"type": "string"},
                        "issued_date": {"type": ["string", "null"]},
                        "expiry_date": {"type": ["string", "null"]},
                        "is_sovereign_identifier": {"type": "boolean"},
                        "verification_status": {"type": "string"},
                        "confidence": {"type": "number"},
                        "source_id": {"type": "string"},
                        "source_name": {"type": "string"},
                        "source_type": {"type": "string"},
                        "source_url": {"type": "string"},
                        "evidence_excerpt": {"type": "string"},
                    },
                },
            },
            "classifications": {
                "type": "array",
                "items": {
                    "type": "object",
                    "additionalProperties": False,
                    "required": ["scheme", "code", "description", "is_primary", "confidence", "source_id", "source_name", "source_type", "source_url"],
                    "properties": {
                        "scheme": {"type": "string", "enum": ["SIC", "NAICS", "NACE", "LOCAL", "OTHER"]},
                        "code": {"type": "string"},
                        "description": {"type": "string"},
                        "is_primary": {"type": "boolean"},
                        "confidence": {"type": "number"},
                        "source_id": {"type": "string"},
                        "source_name": {"type": "string"},
                        "source_type": {"type": "string"},
                        "source_url": {"type": "string"},
                    },
                },
            },
            "corporate_linkages": {
                "type": "array",
                "items": {
                    "type": "object",
                    "additionalProperties": False,
                    "required": [
                        "relationship_type",
                        "related_entity_name",
                        "related_party_id",
                        "related_identifier_type",
                        "related_identifier_value",
                        "ownership_percentage",
                        "jurisdiction_country_code",
                        "confidence",
                        "source_id",
                        "source_name",
                        "source_type",
                        "source_url",
                    ],
                    "properties": {
                        "relationship_type": {"type": "string"},
                        "related_entity_name": {"type": "string"},
                        "related_party_id": {"type": "string"},
                        "related_identifier_type": {"type": "string"},
                        "related_identifier_value": {"type": "string"},
                        "ownership_percentage": {"type": ["number", "null"]},
                        "jurisdiction_country_code": {"type": "string"},
                        "confidence": {"type": "number"},
                        "source_id": {"type": "string"},
                        "source_name": {"type": "string"},
                        "source_type": {"type": "string"},
                        "source_url": {"type": "string"},
                    },
                },
            },
            "field_evidence": {
                "type": "array",
                "items": {
                    "type": "object",
                    "additionalProperties": False,
                    "required": ["field_path", "source_id", "source_name", "source_type", "source_url", "evidence_excerpt", "confidence"],
                    "properties": {
                        "field_path": {"type": "string"},
                        "source_id": {"type": "string"},
                        "source_name": {"type": "string"},
                        "source_type": {"type": "string"},
                        "source_url": {"type": "string"},
                        "evidence_excerpt": {"type": "string"},
                        "confidence": {"type": "number"},
                    },
                },
            },
            "conflicts": {
                "type": "array",
                "items": {
                    "type": "object",
                    "additionalProperties": False,
                    "required": ["field_path", "candidate_values", "recommended_resolution"],
                    "properties": {
                        "field_path": {"type": "string"},
                        "candidate_values": {"type": "array", "items": {"type": "string"}},
                        "recommended_resolution": {"type": "string"},
                    },
                },
            },
        },
    }


def get_databricks_secret(scope: str, key: str) -> str | None:
    try:
        dbutils = globals()["dbutils"]
    except KeyError:
        return None
    try:
        return dbutils.secrets.get(scope=scope, key=key)
    except Exception:
        return None


def provider_api_key(config: dict[str, Any]) -> tuple[str | None, str]:
    provider = config.get("provider", "openai")
    if provider == "anthropic":
        return (
            os.environ.get("ANTHROPIC_API_KEY")
            or get_databricks_secret(
                os.environ.get("PULSE360_AI_SECRET_SCOPE", "pulse360-ai"),
                os.environ.get("PULSE360_ANTHROPIC_SECRET_KEY", "anthropic-api-key"),
            ),
            provider,
        )
    secret_scope = os.environ.get("PULSE360_AI_SECRET_SCOPE") or config.get("secret_scope", "pulse360-ai")
    secret_key = os.environ.get("PULSE360_OPENAI_SECRET_KEY") or config.get("secret_key", "openai-api-key")
    return (
        os.environ.get("OPENAI_API_KEY")
        or get_databricks_secret(secret_scope, secret_key),
        provider,
    )


def default_reasoning_effort(config: dict[str, Any]) -> str:
    return str(config.get("reasoning", {}).get("default_effort") or "low")


def retry_reasoning_effort(config: dict[str, Any]) -> str:
    return str(config.get("reasoning", {}).get("retry_effort") or "medium")


def extract_openai_response_json(response: dict[str, Any]) -> dict[str, Any]:
    if response.get("output_text"):
        return json.loads(response["output_text"])
    for item in response.get("output", []):
        for content in item.get("content", []):
            if content.get("type") in {"output_text", "text"} and content.get("text"):
                return json.loads(content["text"])
    raise ValueError("OpenAI response did not contain output_text JSON.")


def raise_for_openai_status(response: requests.Response) -> None:
    """Raise a Databricks-safe OpenAI error with request ID and response body."""
    if response.ok:
        return
    request_id = response.headers.get("x-request-id") or response.headers.get("openai-request-id")
    try:
        body = response.json()
    except ValueError:
        body = {"raw": response.text[:1200]}
    message = f"OpenAI Responses API returned HTTP {response.status_code}"
    if request_id:
        message = f"{message} (request_id={request_id})"
    raise RuntimeError(f"{message}: {json.dumps(body, sort_keys=True)[:2400]}")


def anthropic_tool_schema(allowed_source_ids: list[str]) -> dict[str, Any]:
    return {
        "name": "emit_firmographic_enrichment",
        "description": "Emit source-bound Pulse360 firmographic enrichment JSON.",
        "input_schema": response_schema(allowed_source_ids),
    }


def extract_anthropic_tool_json(response: dict[str, Any]) -> dict[str, Any]:
    for block in response.get("content", []):
        if block.get("type") == "tool_use" and block.get("name") == "emit_firmographic_enrichment":
            return block["input"]
    text_blocks = [block.get("text", "") for block in response.get("content", []) if block.get("type") == "text"]
    if text_blocks:
        return json.loads("\n".join(text_blocks))
    raise ValueError("Anthropic response did not contain firmographic enrichment tool output.")


def call_anthropic(packet: dict[str, Any], config: dict[str, Any], api_key: str) -> dict[str, Any]:
    model = config["models"]["narrative_reasoning"]
    allowed_sources = source_ids(packet)
    payload = {
        "model": model,
        "max_tokens": 1800,
        "system": (
            "You create source-bound firmographic enrichment JSON for Pulse360. "
            "Use only supplied facts. Treat account_context.country and candidate_country_code "
            "as jurisdiction anchors when disambiguating similarly named entities. Prefer evidence "
            "whose registry jurisdiction, address, legal suffix, domain, and identifiers match the "
            "CRM/source country. Do not let search-result spelling correction override the supplied "
            "country; emit a conflict instead when another-country evidence is plausible but not "
            "anchored to the CRM account. Do not invent CRM keys, legal identifiers, revenue, "
            "employee counts, or hierarchy edges. Every action must cite source_ids from the evidence "
            "packet. Emit only the requested tool input."
        ),
        "tools": [anthropic_tool_schema(allowed_sources)],
        "tool_choice": {"type": "tool", "name": "emit_firmographic_enrichment"},
        "messages": [
            {
                "role": "user",
                "content": "Return the firmographic enrichment tool input for this evidence packet:\n"
                + json.dumps(packet, indent=2, default=str),
            }
        ],
    }
    response = requests.post(
        "https://api.anthropic.com/v1/messages",
        headers={
            "x-api-key": api_key,
            "anthropic-version": "2023-06-01",
            "content-type": "application/json",
        },
        json=payload,
        timeout=90,
    )
    response.raise_for_status()
    return extract_anthropic_tool_json(response.json())


def call_openai(
    packet: dict[str, Any],
    config: dict[str, Any],
    api_key: str,
    reasoning_effort: str | None = None,
) -> dict[str, Any]:
    model = config.get("models", {}).get("narrative_reasoning") or "gpt-5.5"
    allowed_sources = source_ids(packet)
    payload = {
        "model": model,
        "reasoning": {"effort": reasoning_effort or default_reasoning_effort(config)},
        "input": [
            {
                "role": "system",
                "content": (
                    "You create source-bound firmographic enrichment JSON for Pulse360. "
                    "Use the supplied CRM account context and approved source candidates. "
                    "Treat account_context.country and candidate_country_code as jurisdiction "
                    "anchors when disambiguating similarly named entities. Prefer evidence whose "
                    "registry jurisdiction, address, legal suffix, domain, and identifiers match "
                    "the CRM/source country. Do not let search-result spelling correction override "
                    "the supplied country; emit a conflict instead when another-country evidence "
                    "is plausible but not anchored to the CRM account. "
                    "When web search is available, verify facts against official registries, "
                    "filings, investor relations, annual reports, earnings releases, stock "
                    "exchange disclosures, or company websites. Do not invent CRM keys, legal "
                    "identifiers, revenue, employee counts, or hierarchy edges. Every non-empty "
                    "fact must include a source_id, source_name, source_type, source_url, "
                    "and evidence_excerpt."
                ),
            },
            {
                "role": "user",
                "content": "Return JSON for this evidence packet:\n" + json.dumps(packet, indent=2, default=str),
            },
        ],
        "text": {
            "format": {
                "type": "json_schema",
                "name": "pulse360_firmographic_genai_response",
                "strict": True,
                "schema": response_schema(allowed_sources),
            }
        },
    }
    prompt_cache_key = config.get("prompt_caching", {}).get("prompt_cache_key")
    if prompt_cache_key:
        payload["prompt_cache_key"] = prompt_cache_key
    web_search = config.get("tools", {}).get("web_search", {})
    if web_search.get("enabled"):
        payload["tools"] = [{"type": web_search.get("type") or "web_search"}]
    request_timeout_seconds = int(config.get("request_timeout_seconds") or 300)
    response = requests.post(
        "https://api.openai.com/v1/responses",
        headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
        json=payload,
        timeout=request_timeout_seconds,
    )
    raise_for_openai_status(response)
    return extract_openai_response_json(response.json())


def assemble_output(
    packet: dict[str, Any],
    model_payload: dict[str, Any],
    config: dict[str, Any],
    schema: dict[str, Any],
    generation_mode: str,
) -> dict[str, Any]:
    components = confidence_components(packet, model_payload)
    llm_score = llm_result_confidence(components)
    business_score = business_action_confidence(llm_score, components)
    now = utc_now_iso()
    input_hash = sha256_json(packet)
    output_core_hash = sha256_json(model_payload)
    resolved_entity_id = packet["resolved_identity"]["resolved_entity_id"]
    crm_account_id = packet["resolved_identity"].get("crm_safe_activation_key")
    source_ref_ids = source_ids(packet)
    insufficient_evidence = bool(model_payload.get("insufficient_evidence_flag"))
    unsupported_claims = int(model_payload.get("unsupported_claim_count") or 0)
    activation_eligible = bool(
        crm_account_id
        and llm_score >= 0.80
        and business_score >= 0.70
        and unsupported_claims == 0
        and not insufficient_evidence
    )
    output = {
        "genai_enrichment_id": f"genai_firmographic_{resolved_entity_id}",
        "evidence_packet_id": packet["evidence_packet_id"],
        "resolved_entity_id": resolved_entity_id,
        "crm_account_id": crm_account_id,
        "ai_narrative": model_payload["ai_narrative"],
        "ai_recommended_actions": model_payload["ai_recommended_actions"],
        "llm_result_confidence": llm_score,
        "business_action_confidence": business_score,
        "confidence_components": components,
        "unsupported_claim_count": unsupported_claims,
        "insufficient_evidence_flag": insufficient_evidence,
        "source_refs": source_ref_ids,
        "model_id": "genai-design-placeholder" if generation_mode == "source_bound_fixture" else config["models"]["narrative_reasoning"],
        "prompt_version": config.get("prompt_version", "pulse360-firmographic-evidence-v1"),
        "llm_run_id": f"llm_{generation_mode}_{uuid.uuid4().hex}",
        "llm_input_hash": input_hash,
        "llm_output_hash": output_core_hash,
        "llm_cost_estimate": 0,
        "generation_mode": generation_mode,
        "activation_eligible_flag": activation_eligible,
        "run_id": f"genai_firmographic_{generation_mode}_{utc_now().strftime('%Y%m%d%H%M%S')}",
        "run_timestamp": now,
        "model_version": MODEL_VERSION,
    }
    jsonschema.validate(output, schema)
    return output


def source_ref_map(packet: dict[str, Any]) -> dict[str, dict[str, Any]]:
    refs: dict[str, dict[str, Any]] = {}
    for ref in packet.get("source_refs") or []:
        if isinstance(ref, dict) and ref.get("source_id"):
            refs[str(ref["source_id"])] = ref
        elif isinstance(ref, str):
            refs[ref] = {"source_id": ref}
    return refs


def ref_for_model_item(item: dict[str, Any], refs: dict[str, dict[str, Any]]) -> dict[str, Any]:
    source_id = str(item.get("source_id") or "")
    ref = dict(refs.get(source_id) or {})
    for key in ("source_name", "source_type", "source_url"):
        if item.get(key):
            ref[key] = item[key]
    if item.get("evidence_excerpt"):
        ref["excerpt"] = item["evidence_excerpt"]
    if source_id and not ref.get("source_id"):
        ref["source_id"] = source_id
    return ref


def source_account_id_for_packet(packet: dict[str, Any]) -> str:
    resolved = packet.get("resolved_identity", {})
    context = packet.get("account_context", {})
    return str(
        resolved.get("crm_safe_activation_key")
        or context.get("crm_account_id")
        or resolved.get("resolved_entity_id")
        or packet.get("evidence_packet_id")
    )


def country_code(value: Any) -> str:
    if not value:
        return "ZZ"
    cleaned = "".join(ch for ch in str(value).upper() if ch.isalpha())
    return (cleaned[:2] or "ZZ").ljust(2, "Z")


def short_hash(value: Any) -> str:
    return hashlib.sha1(stable_json(value).encode("utf-8")).hexdigest()[:12]


def safe_token(value: Any) -> str:
    cleaned = re.sub(r"[^A-Za-z0-9_]+", "_", str(value or "unknown")).strip("_")
    return cleaned or "unknown"


def safe_date(value: Any) -> str | None:
    if value is None or value == "":
        return None
    text = str(value)[:10]
    try:
        dt.date.fromisoformat(text)
        return text
    except ValueError:
        return None


def number_or_none(value: Any) -> float | None:
    if value is None or value == "":
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def integer_or_none(value: Any) -> int | None:
    numeric = number_or_none(value)
    return int(numeric) if numeric is not None else None


def source_type_for_datacloud(value: Any) -> str:
    source_type = str(value or "other")
    if source_type in {"official_registry", "tax_authority", "filing", "provider", "crm", "customer_internal", "web_research", "other"}:
        return source_type
    if source_type in {"annual_report", "earnings_release", "stock_exchange"}:
        return "filing"
    if source_type in {"investor_relations", "company_website"}:
        return "web_research"
    return "other"


def source_url_for_ref(ref: dict[str, Any] | None, source_id: str, source_account_id: str) -> str:
    if ref and ref.get("source_url"):
        return str(ref["source_url"])
    if source_id.startswith("crm_"):
        return f"salesforce://Account/{source_account_id}"
    return f"databricks://pulse360_s4/silver_firmographic/firmographic_fact/{source_id}"


def source_name_for_ref(ref: dict[str, Any] | None) -> str:
    return str((ref or {}).get("source_name") or (ref or {}).get("source_type") or "Governed firmographic evidence")


def source_type_for_ref(ref: dict[str, Any] | None) -> str:
    return source_type_for_datacloud((ref or {}).get("source_type"))


def annual_revenue_fact(packet: dict[str, Any]) -> dict[str, Any] | None:
    candidates = [
        fact
        for fact in packet.get("firmographic_facts") or []
        if str(fact.get("fact_name") or "").lower() in {"annual_revenue", "revenue"}
    ]
    if not candidates:
        return None
    return sorted(candidates, key=lambda fact: str(fact.get("fact_period_end") or ""), reverse=True)[0]


def validated_identifier_rows(
    packet: dict[str, Any],
    runtime_output: dict[str, Any],
    model_payload: dict[str, Any],
    refs: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    source_account_id = source_account_id_for_packet(packet)
    party_id = f"party_{source_account_id.lower()}"
    run_id = runtime_output["run_id"]
    model_version = runtime_output["model_version"]
    rows: list[dict[str, Any]] = []
    allowed_types = {
        "PH_SEC_REGISTRATION_NUMBER",
        "PH_TIN",
        "SG_UEN",
        "MY_SSM_REGISTRATION_NUMBER",
        "ID_NIB",
        "TH_TAX_ID",
        "VN_ENTERPRISE_CODE",
        "HK_BRN",
        "GLOBAL_LEI",
        "OTHER",
    }
    forbidden_prefixes = ("PROVIDER_", "CRM_", "SEARCH_")
    for identifier in model_payload.get("identifiers") or []:
        identifier_type = str(identifier.get("identifier_type") or "OTHER").upper()
        if identifier_type.startswith(forbidden_prefixes):
            continue
        if identifier_type not in allowed_types:
            identifier_type = "OTHER"
        identifier_value = str(identifier.get("identifier_value") or "").strip()
        normalized_value = str(identifier.get("normalized_identifier_value") or identifier_value).strip()
        if not identifier_value or normalized_value == source_account_id:
            continue
        source_id = str(identifier.get("source_id") or "")
        ref = ref_for_model_item(identifier, refs)
        source_type = source_type_for_ref(ref)
        confidence = score_0_to_1(identifier.get("confidence"), 0.0)
        status = str(identifier.get("verification_status") or "unverified")
        if status == "verified" and (confidence < 0.90 or source_type not in {"official_registry", "tax_authority", "filing"}):
            status = "probable"
        source_url = source_url_for_ref(ref, source_id or "unknown_source", source_account_id)
        rows.append(
            {
                "identifier_id": f"id_{source_account_id}_{identifier_type}_{short_hash(normalized_value)}",
                "party_id": party_id,
                "source_account_id": source_account_id,
                "identifier_type": identifier_type,
                "identifier_name": str(identifier.get("identifier_name") or identifier_type.replace("_", " ").title()),
                "identifier_value": identifier_value,
                "normalized_identifier_value": normalized_value,
                "jurisdiction_country_code": country_code(identifier.get("jurisdiction_country_code") or packet.get("account_context", {}).get("country")),
                "issuing_authority": str(identifier.get("issuing_authority") or source_name_for_ref(ref)),
                "issued_at_location": str(identifier.get("issued_at_location") or ""),
                "issued_date": safe_date(identifier.get("issued_date")),
                "expiry_date": safe_date(identifier.get("expiry_date")),
                "is_sovereign_identifier": bool(identifier.get("is_sovereign_identifier")),
                "verification_status": status,
                "confidence": confidence,
                "source_name": source_name_for_ref(ref),
                "source_type": source_type,
                "source_url": source_url,
                "evidence_excerpt": str(identifier.get("evidence_excerpt") or (ref or {}).get("excerpt") or ""),
                "last_verified_at": runtime_output["run_timestamp"],
                "run_id": run_id,
                "model_version": model_version,
            }
        )
    return rows


def evidence_rows(
    packet: dict[str, Any],
    runtime_output: dict[str, Any],
    model_payload: dict[str, Any],
    refs: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    source_account_id = source_account_id_for_packet(packet)
    party_id = f"party_{source_account_id.lower()}"
    account_name = packet.get("account_context", {}).get("crm_account_name") or source_account_id
    rows = [
        {
            "field_path": "firmographic_profile.legal_name",
            "source_name": "Salesforce Account",
            "source_type": "crm",
            "source_url": f"salesforce://Account/{source_account_id}",
            "evidence_excerpt": f"Salesforce Account Name: {account_name}",
            "retrieved_at": runtime_output["run_timestamp"],
            "confidence": 0.70,
        }
    ]
    for item in model_payload.get("field_evidence") or []:
        source_id = str(item.get("source_id") or "")
        ref = ref_for_model_item(item, refs)
        rows.append(
            {
                "field_path": str(item.get("field_path") or "firmographic_profile.business_description"),
                "source_name": source_name_for_ref(ref),
                "source_type": source_type_for_ref(ref),
                "source_url": source_url_for_ref(ref, source_id or "unknown_source", source_account_id),
                "evidence_excerpt": str(item.get("evidence_excerpt") or (ref or {}).get("excerpt") or ""),
                "retrieved_at": str((ref or {}).get("accessed_at") or runtime_output["run_timestamp"]),
                "confidence": score_0_to_1(item.get("confidence"), runtime_output["llm_result_confidence"]),
            }
        )
    return rows


def field_evidence_export_rows(contract: dict[str, Any]) -> list[dict[str, Any]]:
    rows = []
    for index, evidence in enumerate(contract.get("field_evidence") or [], start=1):
        row = dict(evidence)
        row["evidence_id"] = f"evid_{contract['source_account_id'].lower()}_gpt_{index}_{short_hash(row)}"
        row["party_id"] = contract["party_id"]
        row["source_account_id"] = contract["source_account_id"]
        row["run_id"] = contract["run_id"]
        row["model_version"] = contract["model_version"]
        rows.append(row)
    return rows


def build_data_cloud_enrichment_contract(
    packet: dict[str, Any],
    runtime_output: dict[str, Any],
    model_payload: dict[str, Any],
    data_cloud_schema: dict[str, Any],
) -> dict[str, Any]:
    refs = source_ref_map(packet)
    source_account_id = source_account_id_for_packet(packet)
    party_id = f"party_{source_account_id.lower()}"
    context = packet.get("account_context", {})
    annual_fact = annual_revenue_fact(packet)
    profile_payload = model_payload.get("firmographic_profile") or {}
    source_rows = evidence_rows(packet, runtime_output, model_payload, refs)
    primary_evidence = source_rows[0]
    latest_financial_url = str(profile_payload.get("latest_financial_results_source_url") or "")
    investor_urls = [str(url) for url in profile_payload.get("investor_updates_source_urls") or [] if str(url)]
    location_type = str(profile_payload.get("location_type") or "unknown")
    allowed_location_types = {
        "single_location",
        "headquarters",
        "branch",
        "regional_office",
        "subsidiary",
        "parent_company",
        "ultimate_parent",
        "registered_office",
        "operating_site",
        "unknown",
    }
    if location_type not in allowed_location_types:
        location_type = "unknown"
    if profile_payload.get("latest_financial_results_summary") and not latest_financial_url:
        latest_financial_summary = ""
        latest_financial_period = ""
    else:
        latest_financial_summary = str(profile_payload.get("latest_financial_results_summary") or "")
        latest_financial_period = str(profile_payload.get("latest_financial_results_period") or "")
    investor_summary = str(profile_payload.get("investor_updates_summary") or "") if investor_urls else ""

    contract = {
        "source_account_id": source_account_id,
        "party_id": party_id,
        "legal_name": str(context.get("crm_account_name") or profile_payload.get("legal_name") or source_account_id),
        "trade_name": str(profile_payload.get("trade_name") or context.get("crm_account_name") or ""),
        "jurisdiction_country_code": country_code(profile_payload.get("jurisdiction_country_code") or context.get("country")),
        "identifiers": validated_identifier_rows(packet, runtime_output, model_payload, refs),
        "firmographic_profile": {
            "registration_status": str(profile_payload.get("registration_status") or "unknown"),
            "legal_form": str(profile_payload.get("legal_form") or ""),
            "incorporation_date": safe_date(profile_payload.get("incorporation_date")),
            "dissolution_date": safe_date(profile_payload.get("dissolution_date")),
            "primary_industry_label": str(profile_payload.get("primary_industry_label") or "Unknown"),
            "business_category": str(profile_payload.get("business_category") or profile_payload.get("primary_industry_label") or "Unknown"),
            "business_description": str(profile_payload.get("business_description") or runtime_output["ai_narrative"]),
            "registered_address": {"country_code": country_code(context.get("country"))},
            "operational_address": {"country_code": country_code(context.get("country"))},
            "annual_revenue_local": number_or_none(profile_payload.get("annual_revenue_local"))
            if profile_payload.get("annual_revenue_local") is not None
            else number_or_none((annual_fact or {}).get("fact_value")),
            "annual_revenue_usd": number_or_none(profile_payload.get("annual_revenue_usd")),
            "revenue_currency": str(profile_payload.get("revenue_currency") or (annual_fact or {}).get("fact_unit") or ""),
            "revenue_year": integer_or_none(profile_payload.get("revenue_year"))
            or (int(str((annual_fact or {}).get("fact_period_end"))[:4]) if str((annual_fact or {}).get("fact_period_end") or "")[:4].isdigit() else None),
            "revenue_indicator": "gpt_source_bound" if annual_fact else "unknown",
            "share_capital": number_or_none(profile_payload.get("share_capital")),
            "financial_year_end": str(profile_payload.get("financial_year_end") or ""),
            "latest_financial_results_summary": latest_financial_summary,
            "latest_financial_results_period": latest_financial_period,
            "latest_fin_results_presentation_date": safe_date(profile_payload.get("latest_fin_results_presentation_date")),
            "latest_financial_results_source_url": latest_financial_url,
            "investor_updates_summary": investor_summary,
            "investor_updates_source_urls": investor_urls,
            "employees_total": integer_or_none(profile_payload.get("employees_total")),
            "employees_total_indicator": str(profile_payload.get("employees_total_indicator") or ""),
            "employees_on_site": integer_or_none(profile_payload.get("employees_on_site")),
            "employee_range": str(profile_payload.get("employee_range") or ""),
            "import_export_code": str(profile_payload.get("import_export_code") or ""),
            "import_export_label": str(profile_payload.get("import_export_label") or ""),
            "location_type": location_type,
            "subsidiary_flag": profile_payload.get("subsidiary_flag"),
            "local_headquarter_id": str(profile_payload.get("local_headquarter_id") or ""),
            "national_headquarter_id": str(profile_payload.get("national_headquarter_id") or ""),
            "global_headquarter_id": str(profile_payload.get("global_headquarter_id") or ""),
            "group_company_count": integer_or_none(profile_payload.get("group_company_count")),
            "ultimate_parent_name": str(profile_payload.get("ultimate_parent_name") or ""),
            "primary_source_name": primary_evidence["source_name"],
            "primary_source_url": primary_evidence["source_url"],
            "source_count": len(source_rows),
            "conflict_count": len(model_payload.get("conflicts") or []),
            "confidence": score_0_to_1(profile_payload.get("confidence"), runtime_output["llm_result_confidence"]),
        },
        "classifications": [],
        "corporate_linkages": [],
        "executive_roles": [],
        "digital_footprint": [],
        "field_evidence": source_rows,
        "conflicts": [],
        "overall_confidence": runtime_output["llm_result_confidence"],
        "last_verified_at": runtime_output["run_timestamp"],
        "run_id": runtime_output["run_id"],
        "model_version": runtime_output["model_version"],
    }
    for item in model_payload.get("classifications") or []:
        source_id = str(item.get("source_id") or "")
        ref = ref_for_model_item(item, refs)
        scheme = str(item.get("scheme") or "OTHER").upper()
        if scheme not in {"SIC", "NAICS", "NACE", "LOCAL", "OTHER"}:
            scheme = "OTHER"
        contract["classifications"].append(
            {
                "scheme": scheme,
                "code": str(item.get("code") or "UNKNOWN"),
                "description": str(item.get("description") or ""),
                "is_primary": bool(item.get("is_primary")),
                "confidence": score_0_to_1(item.get("confidence"), runtime_output["llm_result_confidence"]),
                "source_url": source_url_for_ref(ref, source_id or "unknown_source", source_account_id),
            }
        )
    for item in model_payload.get("corporate_linkages") or []:
        source_id = str(item.get("source_id") or "")
        ref = ref_for_model_item(item, refs)
        relationship_type = str(item.get("relationship_type") or "other")
        if relationship_type not in {
            "parent",
            "subsidiary",
            "branch",
            "ultimate_parent",
            "local_headquarter",
            "national_headquarter",
            "shared_director",
            "beneficial_owner",
            "other",
        }:
            relationship_type = "other"
        contract["corporate_linkages"].append(
            {
                "relationship_type": relationship_type,
                "related_entity_name": str(item.get("related_entity_name") or ""),
                "related_identifier_type": str(item.get("related_identifier_type") or ""),
                "related_identifier_value": str(item.get("related_identifier_value") or ""),
                "ownership_percentage": number_or_none(item.get("ownership_percentage")),
                "jurisdiction_country_code": country_code(item.get("jurisdiction_country_code") or context.get("country")),
                "confidence": score_0_to_1(item.get("confidence"), runtime_output["llm_result_confidence"]),
                "source_url": source_url_for_ref(ref, source_id or "unknown_source", source_account_id),
            }
        )
    for item in model_payload.get("conflicts") or []:
        values = [
            {"value": str(value), "source_name": "Governed source", "source_url": primary_evidence["source_url"], "confidence": 0.5}
            for value in item.get("candidate_values", [])
        ]
        if len(values) >= 2:
            contract["conflicts"].append(
                {
                    "field_path": str(item.get("field_path") or "unknown"),
                    "candidate_values": values,
                    "recommended_resolution": str(item.get("recommended_resolution") or "human_review"),
                }
            )
    validate_data_cloud_contract(contract, data_cloud_schema)
    return contract


def validate_data_cloud_contract(contract: dict[str, Any], schema: dict[str, Any]) -> None:
    schema = dict(schema)
    schema.pop("$id", None)
    identifier_schema_path = REPO_ROOT / "contracts/pulse360_sovereign_identifier.schema.json"
    store = {}
    if identifier_schema_path.exists():
        identifier_schema = load_json(identifier_schema_path)
        store[identifier_schema.get("$id", "pulse360_sovereign_identifier.schema.json")] = identifier_schema
        store["pulse360_sovereign_identifier.schema.json"] = identifier_schema
    resolver = jsonschema.RefResolver.from_schema(schema, store=store)
    jsonschema.Draft202012Validator(schema, resolver=resolver).validate(contract)


def should_retry_model_payload(model_payload: dict[str, Any], config: dict[str, Any]) -> bool:
    reasoning = config.get("reasoning", {})
    threshold = score_0_to_1(reasoning.get("retry_when_llm_confidence_below"), 0.80)
    retry_confidence = score_0_to_1(model_payload.get("extraction_certainty_score"), 1.0) < threshold
    retry_conflict = bool(reasoning.get("retry_when_conflicts_present", True)) and score_0_to_1(model_payload.get("conflict_penalty"), 0) > 0
    return retry_confidence or retry_conflict


def output_for_packet(
    packet: dict[str, Any],
    config: dict[str, Any],
    schema: dict[str, Any],
    fixture_only: bool,
) -> tuple[dict[str, Any], dict[str, Any]]:
    api_key, provider = provider_api_key(config)
    if api_key and not fixture_only:
        if provider == "anthropic":
            model_payload = call_anthropic(packet, config, api_key)
        else:
            model_payload = call_openai(packet, config, api_key, default_reasoning_effort(config))
            if should_retry_model_payload(model_payload, config):
                model_payload = call_openai(packet, config, api_key, retry_reasoning_effort(config))
        mode = "batch_llm"
    else:
        model_payload = fixture_model_payload(packet)
        mode = "source_bound_fixture"
    return assemble_output(packet, model_payload, config, schema, mode), model_payload


def write_to_spark(output: dict[str, Any], target_table: str) -> None:
    spark_session = get_spark()
    if spark_session is None:
        return
    from pyspark.sql.types import BooleanType, DoubleType, StringType, StructField, StructType

    row = dict(output)
    row["ai_recommended_actions"] = json.dumps(row["ai_recommended_actions"], sort_keys=True)
    row["confidence_components"] = json.dumps(row["confidence_components"], sort_keys=True)
    row["source_refs"] = json.dumps(row["source_refs"], sort_keys=True)
    schema = StructType(
        [
            StructField("genai_enrichment_id", StringType(), False),
            StructField("evidence_packet_id", StringType(), False),
            StructField("resolved_entity_id", StringType(), False),
            StructField("crm_account_id", StringType(), True),
            StructField("ai_narrative", StringType(), False),
            StructField("ai_recommended_actions", StringType(), False),
            StructField("llm_result_confidence", DoubleType(), False),
            StructField("business_action_confidence", DoubleType(), False),
            StructField("confidence_components", StringType(), False),
            StructField("unsupported_claim_count", DoubleType(), False),
            StructField("insufficient_evidence_flag", BooleanType(), False),
            StructField("source_refs", StringType(), False),
            StructField("model_id", StringType(), False),
            StructField("prompt_version", StringType(), False),
            StructField("llm_run_id", StringType(), False),
            StructField("llm_input_hash", StringType(), False),
            StructField("llm_output_hash", StringType(), False),
            StructField("llm_cost_estimate", DoubleType(), True),
            StructField("generation_mode", StringType(), False),
            StructField("activation_eligible_flag", BooleanType(), False),
            StructField("run_id", StringType(), False),
            StructField("run_timestamp", StringType(), False),
            StructField("model_version", StringType(), False),
        ]
    )
    row["unsupported_claim_count"] = float(row["unsupported_claim_count"])
    row["llm_cost_estimate"] = float(row["llm_cost_estimate"] or 0)
    dataframe = spark_session.createDataFrame([row], schema=schema)
    dataframe.write.mode("append").option("mergeSchema", "true").saveAsTable(target_table)


def write_latest_contracts(contracts: list[dict[str, Any]], latest_table: str) -> None:
    spark_session = get_spark()
    if spark_session is None:
        return
    from pyspark.sql.types import DoubleType, StringType, StructField, StructType

    rows = []
    for contract in contracts:
        rows.append(
            {
                "source_account_id": contract["source_account_id"],
                "party_id": contract["party_id"],
                "legal_name": contract["legal_name"],
                "jurisdiction_country_code": contract["jurisdiction_country_code"],
                "firmographic_profile_json": json.dumps(contract["firmographic_profile"], sort_keys=True, default=str),
                "identifiers_json": json.dumps(contract["identifiers"], sort_keys=True, default=str),
                "classifications_json": json.dumps(contract["classifications"], sort_keys=True, default=str),
                "corporate_linkages_json": json.dumps(contract["corporate_linkages"], sort_keys=True, default=str),
                "gpt_field_evidence_json": json.dumps(field_evidence_export_rows(contract), sort_keys=True, default=str),
                "conflicts_json": json.dumps(contract["conflicts"], sort_keys=True, default=str),
                "overall_confidence": float(contract["overall_confidence"]),
                "last_verified_at": contract["last_verified_at"],
                "run_id": contract["run_id"],
                "model_version": contract["model_version"],
                "gpt_status": "schema_valid",
            }
        )
    schema = StructType(
        [
            StructField("source_account_id", StringType(), False),
            StructField("party_id", StringType(), False),
            StructField("legal_name", StringType(), False),
            StructField("jurisdiction_country_code", StringType(), False),
            StructField("firmographic_profile_json", StringType(), False),
            StructField("identifiers_json", StringType(), False),
            StructField("classifications_json", StringType(), False),
            StructField("corporate_linkages_json", StringType(), False),
            StructField("gpt_field_evidence_json", StringType(), False),
            StructField("conflicts_json", StringType(), False),
            StructField("overall_confidence", DoubleType(), False),
            StructField("last_verified_at", StringType(), False),
            StructField("run_id", StringType(), False),
            StructField("model_version", StringType(), False),
            StructField("gpt_status", StringType(), False),
        ]
    )
    dataframe = spark_session.createDataFrame(rows, schema=schema)
    dataframe.write.mode("overwrite").option("overwriteSchema", "true").saveAsTable(latest_table)


def log_mlflow_trace(output: dict[str, Any], packet: dict[str, Any], config: dict[str, Any], target_table: str) -> dict[str, Any]:
    try:
        import mlflow
    except ImportError:
        return {"mlflow_status": "skipped", "reason": "mlflow_not_available"}

    experiment_path = os.environ.get("PULSE360_MLFLOW_EXPERIMENT_PATH", MLFLOW_EXPERIMENT_PATH)
    provider = config.get("provider", "anthropic")
    action_count = len(output.get("ai_recommended_actions") or [])
    source_ref_count = len(output.get("source_refs") or [])
    trace_summary = {
        "trace_schema_version": "pulse360-genai-trace-v1",
        "provider": provider,
        "model_id": output["model_id"],
        "prompt_version": output["prompt_version"],
        "generation_mode": output["generation_mode"],
        "evidence_packet_id": output["evidence_packet_id"],
        "resolved_entity_id": output["resolved_entity_id"],
        "run_id": output["run_id"],
        "run_timestamp": output["run_timestamp"],
        "llm_input_hash": output["llm_input_hash"],
        "llm_output_hash": output["llm_output_hash"],
        "source_ref_count": source_ref_count,
        "action_count": action_count,
        "validation_result": "passed",
        "activation_eligible_flag": output["activation_eligible_flag"],
        "target_table": target_table,
    }

    try:
        mlflow.set_experiment(experiment_path)
        with mlflow.start_run(run_name=output["run_id"]) as active_run:
            mlflow.set_tags(
                {
                    "pulse360.component": "firmographic_genai_runtime",
                    "pulse360.validation_result": "passed",
                    "pulse360.generation_mode": output["generation_mode"],
                    "pulse360.provider": provider,
                    "pulse360.evidence_packet_id": output["evidence_packet_id"],
                    "pulse360.resolved_entity_id": output["resolved_entity_id"],
                    "pulse360.activation_eligible_flag": str(output["activation_eligible_flag"]).lower(),
                }
            )
            mlflow.log_params(
                {
                    "provider": provider,
                    "model_id": output["model_id"],
                    "prompt_version": output["prompt_version"],
                    "generation_mode": output["generation_mode"],
                    "model_version": output["model_version"],
                    "run_id": output["run_id"],
                    "evidence_packet_id": output["evidence_packet_id"],
                    "resolved_entity_id": output["resolved_entity_id"],
                    "target_table": target_table,
                    "llm_input_hash": output["llm_input_hash"],
                    "llm_output_hash": output["llm_output_hash"],
                    "packet_shape_hash": sha256_json(
                        {
                            "fact_count": len(packet.get("firmographic_facts") or []),
                            "source_ref_count": source_ref_count,
                            "has_crm_anchor": bool(packet.get("resolved_identity", {}).get("crm_safe_activation_key")),
                        }
                    ),
                }
            )
            mlflow.log_metrics(
                {
                    "llm_result_confidence": float(output["llm_result_confidence"]),
                    "business_action_confidence": float(output["business_action_confidence"]),
                    "unsupported_claim_count": float(output["unsupported_claim_count"]),
                    "source_ref_count": float(source_ref_count),
                    "action_count": float(action_count),
                    "activation_eligible": 1.0 if output["activation_eligible_flag"] else 0.0,
                    **{f"confidence_{key}": float(value) for key, value in output["confidence_components"].items()},
                }
            )
            with tempfile.TemporaryDirectory() as tmpdir:
                artifact_path = Path(tmpdir) / "trace_summary.json"
                artifact_path.write_text(json.dumps(trace_summary, indent=2, sort_keys=True) + "\n")
                mlflow.log_artifact(str(artifact_path), artifact_path="governance")
            return {
                "mlflow_status": "logged",
                "mlflow_experiment_path": experiment_path,
                "mlflow_run_id": active_run.info.run_id,
            }
    except Exception as exc:
        return {"mlflow_status": "failed", "reason": type(exc).__name__, "message": str(exc)[:300]}


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run Pulse360 firmographic GPT enrichment.")
    parser.add_argument("--fixture-only", action="store_true", help="Do not call a live LLM even if provider credentials are present.")
    parser.add_argument("--local-output", default=str(DEFAULT_LOCAL_OUTPUT_PATH), help="Local JSON output path for validation runs.")
    parser.add_argument("--config", default=str(DEFAULT_CONFIG_PATH))
    parser.add_argument("--schema", default=str(DEFAULT_OUTPUT_SCHEMA_PATH))
    parser.add_argument("--data-cloud-schema", default=str(DEFAULT_DATA_CLOUD_SCHEMA_PATH))
    parser.add_argument("--sample-packet", default=str(DEFAULT_SAMPLE_PACKET_PATH))
    parser.add_argument("--source-table", default=SOURCE_TABLE)
    parser.add_argument("--target-table", default=TARGET_TABLE)
    parser.add_argument("--latest-table", default=LATEST_TABLE)
    args, _ = parser.parse_known_args(argv)
    return args


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    config = load_json_or_default(Path(args.config), DEFAULT_CONFIG)
    web_search_override = os.environ.get("PULSE360_OPENAI_WEB_SEARCH")
    if web_search_override in {"0", "1"}:
        config.setdefault("tools", {}).setdefault("web_search", {})["enabled"] = web_search_override == "1"
    schema = load_json_or_default(Path(args.schema), DEFAULT_OUTPUT_SCHEMA)
    data_cloud_schema = load_json_or_default(Path(args.data_cloud_schema), DEFAULT_DATA_CLOUD_SCHEMA)
    spark_session = get_spark()

    if spark_session is None or args.fixture_only:
        packets = [build_packet_from_sample(Path(args.sample_packet))]
    else:
        packets = build_packets_from_spark(args.source_table)

    outputs: list[dict[str, Any]] = []
    contracts: list[dict[str, Any]] = []
    mlflow_traces: list[dict[str, Any]] = []
    for packet in packets:
        output, model_payload = output_for_packet(packet, config, schema, args.fixture_only)
        contract = build_data_cloud_enrichment_contract(packet, output, model_payload, data_cloud_schema)
        outputs.append(output)
        contracts.append(contract)
        write_to_spark(output, args.target_table)
        mlflow_trace = log_mlflow_trace(output, packet, config, args.target_table)
        mlflow_traces.append(mlflow_trace)
        if spark_session is not None and mlflow_trace.get("mlflow_status") != "logged":
            raise RuntimeError(f"MLflow trace logging failed: {mlflow_trace}")
    write_latest_contracts(contracts, args.latest_table)

    output_path = None
    if spark_session is None or os.environ.get("PULSE360_WRITE_LOCAL_OUTPUT") == "1":
        output_path = Path(args.local_output)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(
            json.dumps({"runtime": outputs, "data_cloud_contracts": contracts}, indent=2, sort_keys=True) + "\n"
        )

    print(
        json.dumps(
            {
                "generation_mode": outputs[0]["generation_mode"],
                "processed_account_count": len(outputs),
                "output_path": str(output_path) if output_path else None,
                "activation_eligible_count": sum(1 for output in outputs if output["activation_eligible_flag"]),
                "target_table": args.target_table if spark_session is not None else None,
                "latest_table": args.latest_table if spark_session is not None else None,
                "data_cloud_contract_valid": True,
                "mlflow_statuses": [trace.get("mlflow_status") for trace in mlflow_traces],
            },
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    main(sys.argv[1:])
