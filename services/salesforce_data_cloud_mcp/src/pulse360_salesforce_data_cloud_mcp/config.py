from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path


def find_repo_root(start: Path | None = None) -> Path:
    current = (start or Path(__file__).resolve()).resolve()
    for candidate in [current, *current.parents]:
        if (candidate / "AGENTS.md").exists() and (candidate / "sfdx-project.json").exists():
            return candidate
    raise RuntimeError("Could not locate Pulse360 repo root from current file path")


@dataclass(frozen=True)
class ServiceConfig:
    repo_root: Path
    default_org_alias: str
    default_dmo_name: str
    default_source_object: str
    default_data_stream_name: str
    activation_mapping_path: Path
    dmo_mapping_path: Path
    source_contract_path: Path
    account_contract_path: Path
    account_sync_contract_path: Path

    @classmethod
    def load(cls) -> "ServiceConfig":
        repo_root = find_repo_root()
        return cls(
            repo_root=repo_root,
            default_org_alias=os.environ.get("PULSE360_DEFAULT_ORG_ALIAS", "pulse360-agent-target"),
            default_dmo_name=os.environ.get("PULSE360_DEFAULT_DMO_NAME", "ssot__Account__dlm"),
            default_source_object=os.environ.get(
                "PULSE360_DEFAULT_SOURCE_OBJECT",
                "pulse360_account_intelligence_export_v2__dll",
            ),
            default_data_stream_name=os.environ.get(
                "PULSE360_DEFAULT_DATA_STREAM_NAME",
                "DC Export Accounts P360 V2",
            ),
            activation_mapping_path=repo_root / "config/data-cloud/activation-field-mapping.csv",
            dmo_mapping_path=repo_root / "config/data-cloud/dmo-account-field-mapping.csv",
            source_contract_path=repo_root / "contracts/databricks_to_datacloud.schema.json",
            account_contract_path=repo_root / "contracts/datacloud_to_salesforce_agentforce.schema.json",
            account_sync_contract_path=repo_root / "contracts/datacloud_to_salesforce_account_sync.schema.json",
        )
