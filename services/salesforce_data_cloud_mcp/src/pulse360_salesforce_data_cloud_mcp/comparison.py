from __future__ import annotations

import csv
import json
from pathlib import Path


def load_contract_required_fields(contract_path: Path) -> list[str]:
    payload = json.loads(contract_path.read_text())
    return sorted(payload.get("required", []))


def load_mapping(mapping_path: Path, *, target_object: str | None = None) -> list[dict[str, str]]:
    with mapping_path.open(newline="") as handle:
        reader = csv.DictReader(handle)
        rows = list(reader)
    if target_object is None:
        return rows
    return [row for row in rows if row.get("target_object") == target_object]


def normalize_source_object_field_name(field_name: str) -> str:
    normalized = field_name
    if normalized.startswith("KQ_"):
        normalized = normalized[3:]
    if normalized.endswith("__c"):
        normalized = normalized[:-3]
    return normalized


def normalize_source_object_field_names(field_names: list[str]) -> set[str]:
    return {normalize_source_object_field_name(name) for name in field_names}


def compare_required_fields_to_mapping(
    required_fields: list[str],
    mapping_rows: list[dict[str, str]],
    live_target_fields: set[str],
) -> dict:
    mapping_by_source = {row["source_field"]: row for row in mapping_rows}
    mapped_results = []
    missing_mapping_fields = []
    missing_target_fields = []

    for source_field in required_fields:
        mapping = mapping_by_source.get(source_field)
        if mapping is None:
            missing_mapping_fields.append(source_field)
            continue

        target_field = mapping["target_field"]
        target_present = target_field in live_target_fields
        mapped_results.append(
            {
                "source_field": source_field,
                "target_field": target_field,
                "required": mapping.get("required", ""),
                "target_present": target_present,
            }
        )
        if not target_present:
            missing_target_fields.append(target_field)

    return {
        "required_field_count": len(required_fields),
        "mapped_field_count": len(mapped_results),
        "missing_mapping_count": len(missing_mapping_fields),
        "missing_target_field_count": len(missing_target_fields),
        "missing_mapping_fields": sorted(missing_mapping_fields),
        "missing_target_fields": sorted(missing_target_fields),
        "mapped_results": mapped_results,
    }


def compare_required_fields_to_source_object(
    required_fields: list[str],
    source_object_field_names: list[str],
) -> dict:
    live_source_fields = normalize_source_object_field_names(source_object_field_names)
    present_fields = sorted(field for field in required_fields if field in live_source_fields)
    missing_fields = sorted(field for field in required_fields if field not in live_source_fields)
    return {
        "required_field_count": len(required_fields),
        "live_source_field_count": len(live_source_fields),
        "present_field_count": len(present_fields),
        "missing_field_count": len(missing_fields),
        "present_fields": present_fields,
        "missing_fields": missing_fields,
    }
