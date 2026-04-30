# Databricks notebook source
"""Pulse360 firmographic GPT enrichment runtime.

This notebook/script is intentionally dual-mode:

- fixture mode: deterministic output for demos and local validation
- live mode: Claude Messages API call when ANTHROPIC_API_KEY is available

The runtime writes to a staging table so the existing demo-safe fixture view can
remain stable until the live GPT path is explicitly promoted.
"""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
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
DEFAULT_SAMPLE_PACKET_PATH = REPO_ROOT / "data/samples/firmographic_evidence_packet_sample.json"
DEFAULT_LOCAL_OUTPUT_PATH = REPO_ROOT / "data/exports/firmographic_genai_runtime_sample.json"

SOURCE_TABLE = "pulse360_s4.silver_firmographic.firmographic_fact"
TARGET_TABLE = "pulse360_s4.gold.account_genai_enrichment_output_runtime"
MODEL_VERSION = "genai-firmographic-enrichment-runtime-v1"
MLFLOW_EXPERIMENT_PATH = "/Shared/pulse360/pulse360-firmographic-enrichment/dev/mlflow/firmographic-genai-runtime"

DEFAULT_CONFIG = {
    "api": "anthropic_messages",
    "provider": "anthropic",
    "models": {
        "narrative_reasoning": "claude-sonnet-4-20250514",
        "action_ranking": "claude-sonnet-4-20250514",
        "high_volume_extraction": "claude-3-5-haiku-20241022",
    },
    "prompt_version": "pulse360-public-regional-v1",
    "structured_outputs_required": True,
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


def build_packet_from_spark(source_table: str) -> dict[str, Any]:
    spark_session = get_spark()
    if spark_session is None:
        raise RuntimeError("Spark is not available; use --fixture-only for local validation.")

    rows = [row.asDict(recursive=True) for row in spark_session.table(source_table).collect()]
    if not rows:
        raise RuntimeError(f"No rows found in {source_table}")

    resolved_entity_id = rows[0].get("resolved_entity_id") or "ent_unknown"
    source_ref_map: dict[str, dict[str, Any]] = {}
    facts = []
    for row in rows:
        source_id = row.get("source_id") or row.get("source_record_id")
        if source_id:
            source_ref_map[str(source_id)] = {
                "source_id": str(source_id),
                "source_type": row.get("source_type") or "approved_firmographic_source",
                "document_date": str(row.get("document_date")) if row.get("document_date") else None,
                "accessed_at": str(row.get("accessed_at")) if row.get("accessed_at") else str(row.get("last_refreshed_at")),
                "source_url": row.get("source_url"),
                "excerpt": row.get("source_excerpt"),
            }
        facts.append(
            {
                "source_id": source_id,
                "fact_type": row.get("fact_type"),
                "fact_name": row.get("fact_name"),
                "fact_value": row.get("fact_value"),
                "fact_unit": row.get("fact_unit"),
                "fact_period_start": str(row.get("fact_period_start")) if row.get("fact_period_start") else None,
                "fact_period_end": str(row.get("fact_period_end")) if row.get("fact_period_end") else None,
                "source_confidence": score_0_to_1(row.get("source_confidence")),
                "source_reliability_code": row.get("source_reliability_code"),
                "field_completeness_score": score_0_to_1(row.get("field_completeness_score"), 0.75),
                "freshness_status": row.get("freshness_status"),
                "last_refreshed_at": str(row.get("last_refreshed_at")) if row.get("last_refreshed_at") else None,
                "license_or_contract_reference": row.get("license_or_contract_reference"),
            }
        )

    source_refs = [source_ref_map[key] for key in sorted(source_ref_map)]
    return {
        "evidence_packet_id": f"firmographic_packet_{resolved_entity_id}",
        "account_context": {
            "crm_account_id": rows[0].get("crm_account_id"),
            "crm_account_name": rows[0].get("crm_account_name") or rows[0].get("registered_legal_name") or rows[0].get("account_candidate_name"),
            "country": rows[0].get("country_of_incorporation") or rows[0].get("account_candidate_country"),
            "website_domain": rows[0].get("website_domain"),
        },
        "resolved_identity": {
            "resolved_entity_id": resolved_entity_id,
            "sovereign_identity_key": rows[0].get("sovereign_identity_key"),
            "crm_safe_activation_key": rows[0].get("crm_account_id"),
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

    allowed_sources = set(source_ids(packet))
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
                            "items": {"type": "string", "enum": source_enum},
                        },
                    },
                },
            },
            "unsupported_claim_count": {"type": "integer"},
            "insufficient_evidence_flag": {"type": "boolean"},
            "extraction_certainty_score": {"type": "number"},
            "conflict_penalty": {"type": "number"},
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
    provider = config.get("provider", "anthropic")
    if provider == "anthropic":
        return (
            os.environ.get("ANTHROPIC_API_KEY")
            or get_databricks_secret(
                os.environ.get("PULSE360_AI_SECRET_SCOPE", "pulse360-ai"),
                os.environ.get("PULSE360_ANTHROPIC_SECRET_KEY", "anthropic-api-key"),
            ),
            provider,
        )
    return (
        os.environ.get("OPENAI_API_KEY")
        or get_databricks_secret(
            os.environ.get("PULSE360_AI_SECRET_SCOPE", "pulse360-ai"),
            os.environ.get("PULSE360_OPENAI_SECRET_KEY", "openai-api-key"),
        ),
        provider,
    )


def extract_openai_response_json(response: dict[str, Any]) -> dict[str, Any]:
    if response.get("output_text"):
        return json.loads(response["output_text"])
    for item in response.get("output", []):
        for content in item.get("content", []):
            if content.get("type") in {"output_text", "text"} and content.get("text"):
                return json.loads(content["text"])
    raise ValueError("OpenAI response did not contain output_text JSON.")


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
            "Use only supplied facts. Do not invent CRM keys, legal identifiers, "
            "revenue, employee counts, or hierarchy edges. Every action must cite "
            "source_ids from the evidence packet. Emit only the requested tool input."
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


def call_openai(packet: dict[str, Any], config: dict[str, Any], api_key: str) -> dict[str, Any]:
    model = config["models"]["narrative_reasoning"]
    allowed_sources = source_ids(packet)
    payload = {
        "model": model,
        "input": [
            {
                "role": "system",
                "content": (
                    "You create source-bound firmographic enrichment JSON for Pulse360. "
                    "Use only supplied facts. Do not invent CRM keys, legal identifiers, "
                    "revenue, employee counts, or hierarchy edges. Every action must cite "
                    "source_ids from the evidence packet."
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
    response = requests.post(
        "https://api.openai.com/v1/responses",
        headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
        json=payload,
        timeout=90,
    )
    response.raise_for_status()
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


def output_for_packet(packet: dict[str, Any], config: dict[str, Any], schema: dict[str, Any], fixture_only: bool) -> dict[str, Any]:
    api_key, provider = provider_api_key(config)
    if api_key and not fixture_only:
        if provider == "anthropic":
            model_payload = call_anthropic(packet, config, api_key)
        else:
            model_payload = call_openai(packet, config, api_key)
        mode = "batch_llm"
    else:
        model_payload = fixture_model_payload(packet)
        mode = "source_bound_fixture"
    return assemble_output(packet, model_payload, config, schema, mode)


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
    parser.add_argument("--sample-packet", default=str(DEFAULT_SAMPLE_PACKET_PATH))
    parser.add_argument("--source-table", default=SOURCE_TABLE)
    parser.add_argument("--target-table", default=TARGET_TABLE)
    args, _ = parser.parse_known_args(argv)
    return args


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    config = load_json_or_default(Path(args.config), DEFAULT_CONFIG)
    schema = load_json_or_default(Path(args.schema), DEFAULT_OUTPUT_SCHEMA)
    spark_session = get_spark()

    if spark_session is None or args.fixture_only:
        packet = build_packet_from_sample(Path(args.sample_packet))
    else:
        packet = build_packet_from_spark(args.source_table)

    output = output_for_packet(packet, config, schema, args.fixture_only)
    write_to_spark(output, args.target_table)
    mlflow_trace = log_mlflow_trace(output, packet, config, args.target_table)
    if spark_session is not None and mlflow_trace.get("mlflow_status") != "logged":
        raise RuntimeError(f"MLflow trace logging failed: {mlflow_trace}")

    output_path = None
    if spark_session is None or os.environ.get("PULSE360_WRITE_LOCAL_OUTPUT") == "1":
        output_path = Path(args.local_output)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(json.dumps(output, indent=2, sort_keys=True) + "\n")

    print(
        json.dumps(
            {
                "generation_mode": output["generation_mode"],
                "output_path": str(output_path) if output_path else None,
                "activation_eligible_flag": output["activation_eligible_flag"],
                "target_table": args.target_table if spark_session is not None else None,
                **mlflow_trace,
            },
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    main(sys.argv[1:])
