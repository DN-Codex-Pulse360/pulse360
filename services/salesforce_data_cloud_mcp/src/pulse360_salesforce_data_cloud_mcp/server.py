from __future__ import annotations

from pathlib import Path
from typing import Any

from mcp.server.fastmcp import FastMCP

from .comparison import (
    compare_required_fields_to_mapping,
    compare_required_fields_to_source_object,
    load_contract_required_fields,
    load_mapping,
)
from .config import ServiceConfig
from .salesforce_cli import SalesforceCliClient


def _field_names(describe_payload: dict[str, Any]) -> list[str]:
    return sorted(field["name"] for field in describe_payload.get("fields", []))


def _field_summary(describe_payload: dict[str, Any]) -> list[dict[str, Any]]:
    return [
        {
            "name": field["name"],
            "type": field.get("type"),
            "createable": field.get("createable"),
            "updateable": field.get("updateable"),
        }
        for field in describe_payload.get("fields", [])
    ]


def _picklist_values_by_name(describe_payload: dict[str, Any], field_name: str) -> list[str]:
    for field in describe_payload.get("fields", []):
        if field.get("name") != field_name:
            continue
        values = []
        for picklist_value in field.get("picklistValues", []):
            if isinstance(picklist_value, dict):
                value = picklist_value.get("value")
            else:
                value = picklist_value
            if value is not None:
                values.append(str(value))
        return values
    return []


def _load_live_field_path_status(
    *,
    sf: SalesforceCliClient,
    config: ServiceConfig,
    org_alias: str | None = None,
    source_object_name: str | None = None,
    dmo_name: str | None = None,
    data_stream_name: str | None = None,
) -> dict[str, Any]:
    resolved_org = org_alias or config.default_org_alias
    resolved_source_object = source_object_name or config.default_source_object
    resolved_dmo_name = dmo_name or config.default_dmo_name
    resolved_stream_name = data_stream_name or config.default_data_stream_name

    source_contract_fields = load_contract_required_fields(config.source_contract_path)
    account_contract_fields = load_contract_required_fields(config.account_contract_path)
    account_sync_contract_fields = load_contract_required_fields(config.account_sync_contract_path)

    escaped_stream_name = resolved_stream_name.replace("'", "\\'")
    stream_result = sf.query(
        "SELECT Name, ImportRunStatus, LastRefreshDate, TotalRowsProcessed, IsNewFieldsAvailable "
        f"FROM DataStream WHERE Name = '{escaped_stream_name}'",
        org_alias=org_alias,
    )
    dlo_result = sf.query(
        "SELECT Id, Name, DataLakeObjectStatus, SyncStatus, TotalRecords, TotalNumberOfFields "
        f"FROM DataLakeObjectInstance WHERE Name = '{escaped_stream_name}'",
        org_alias=org_alias,
    )
    source_payload = sf.describe_sobject(resolved_source_object, org_alias=org_alias)
    dmo_payload = sf.describe_sobject(resolved_dmo_name, org_alias=org_alias)
    account_payload = sf.describe_sobject("Account", org_alias=org_alias)
    mapping_payload = sf.describe_sobject("MktDataLakeMapping", org_alias=org_alias)
    mapping_rows = sf.query("SELECT Id FROM MktDataLakeMapping LIMIT 1", org_alias=org_alias)
    activation_data_sources = sf.query(
        "SELECT Id FROM MktSgmtActvDataSource LIMIT 1",
        org_alias=org_alias,
    )
    data_source_bundles = sf.query("SELECT Id FROM DataSourceBundle LIMIT 1", org_alias=org_alias)
    market_segment_activations = sf.query(
        "SELECT Id FROM MarketSegmentActivation LIMIT 1",
        org_alias=org_alias,
    )

    source_object_refs = _picklist_values_by_name(mapping_payload, "SourceObjectRef")
    source_field_refs = _picklist_values_by_name(mapping_payload, "SourceFieldRef")
    source_object_available_in_mapping_surface = (
        resolved_source_object in source_object_refs
        or source_payload["name"] in source_object_refs
        or any(value.startswith(f"{source_payload['name']}.") for value in source_field_refs)
    )

    source_gap = compare_required_fields_to_source_object(
        source_contract_fields,
        _field_names(source_payload),
    )
    dmo_gap = compare_required_fields_to_mapping(
        account_contract_fields,
        load_mapping(config.dmo_mapping_path, target_object=resolved_dmo_name),
        set(_field_names(dmo_payload)),
    )
    account_gap = compare_required_fields_to_mapping(
        account_sync_contract_fields,
        load_mapping(config.activation_mapping_path, target_object="Account"),
        set(_field_names(account_payload)),
    )

    return {
        "org_alias": resolved_org,
        "data_stream_name": resolved_stream_name,
        "data_stream_records": stream_result.get("records", []),
        "data_lake_object_records": dlo_result.get("records", []),
        "source_contract_path": str(config.source_contract_path),
        "account_contract_path": str(config.account_contract_path),
        "account_sync_contract_path": str(config.account_sync_contract_path),
        "mapping_surface": {
            "source_object_ref_count": len(source_object_refs),
            "source_field_ref_count": len(source_field_refs),
            "source_object_available": source_object_available_in_mapping_surface,
            "source_object_name": source_payload["name"],
        },
        "registration_surface": {
            "data_source_bundle_count": data_source_bundles.get("totalSize", 0),
            "market_segment_activation_count": market_segment_activations.get("totalSize", 0),
            "activation_data_source_count": activation_data_sources.get("totalSize", 0),
            "data_lake_mapping_count": mapping_rows.get("totalSize", 0),
        },
        "source_object_gap": {
            "source_object_name": source_payload["name"],
            **source_gap,
        },
        "dmo_gap": {
            "dmo_name": dmo_payload["name"],
            **dmo_gap,
        },
        "account_gap": {
            "account_object_name": account_payload["name"],
            **account_gap,
        },
    }


def build_server(config: ServiceConfig | None = None) -> FastMCP:
    config = config or ServiceConfig.load()
    sf = SalesforceCliClient(default_org_alias=config.default_org_alias)

    server = FastMCP(
        name="Pulse360 Salesforce And Data Cloud MCP",
        instructions=(
            "Read-only MCP service for Pulse360 Salesforce CRM and Data Cloud validation. "
            "Use it to inspect schema, query runtime state, and compare the export contract "
            "to live Account, source-object, and DMO field surfaces. "
            "Do not treat it as a deploy or mutation layer."
        ),
        log_level="INFO",
    )

    @server.tool(description="Describe any Salesforce or Data Cloud sObject by API name.")
    def describe_sobject(
        sobject_name: str,
        org_alias: str | None = None,
        use_tooling_api: bool = False,
    ) -> dict[str, Any]:
        payload = sf.describe_sobject(
            sobject_name,
            org_alias=org_alias,
            use_tooling_api=use_tooling_api,
        )
        return {
            "org_alias": org_alias or config.default_org_alias,
            "sobject_name": payload["name"],
            "field_count": len(payload.get("fields", [])),
            "fields": _field_summary(payload),
        }

    @server.tool(description="List live Salesforce Account fields and metadata.")
    def list_account_fields(org_alias: str | None = None) -> dict[str, Any]:
        payload = sf.describe_sobject("Account", org_alias=org_alias)
        return {
            "org_alias": org_alias or config.default_org_alias,
            "sobject_name": "Account",
            "field_count": len(payload.get("fields", [])),
            "fields": _field_summary(payload),
        }

    @server.tool(description="List live Data Cloud DMO fields for the given object.")
    def list_dmo_fields(
        dmo_name: str | None = None,
        org_alias: str | None = None,
    ) -> dict[str, Any]:
        payload = sf.describe_sobject(dmo_name or config.default_dmo_name, org_alias=org_alias)
        return {
            "org_alias": org_alias or config.default_org_alias,
            "dmo_name": payload["name"],
            "field_count": len(payload.get("fields", [])),
            "fields": _field_summary(payload),
        }

    @server.tool(description="List Data Cloud data streams and their refresh status.")
    def list_data_streams(org_alias: str | None = None) -> dict[str, Any]:
        query = (
            "SELECT Id, Name, DataStreamStatus, ImportRunStatus, LastRefreshDate, "
            "TotalRowsProcessed, IsNewFieldsAvailable "
            "FROM DataStream ORDER BY LastRefreshDate DESC NULLS LAST LIMIT 50"
        )
        result = sf.query(query, org_alias=org_alias)
        return {
            "org_alias": org_alias or config.default_org_alias,
            "total_size": result.get("totalSize", 0),
            "records": result.get("records", []),
        }

    @server.tool(description="Get one Data Cloud data stream by exact name.")
    def get_data_stream_status(
        stream_name: str,
        org_alias: str | None = None,
    ) -> dict[str, Any]:
        escaped_stream_name = stream_name.replace("'", "\\'")
        query = (
            "SELECT Id, Name, DataStreamStatus, ImportRunStatus, LastRefreshDate, "
            "TotalRowsProcessed, IsNewFieldsAvailable, RefreshFrequency, RefreshHours, RefreshMode "
            f"FROM DataStream WHERE Name = '{escaped_stream_name}'"
        )
        result = sf.query(query, org_alias=org_alias)
        return {
            "org_alias": org_alias or config.default_org_alias,
            "stream_name": stream_name,
            "total_size": result.get("totalSize", 0),
            "records": result.get("records", []),
        }

    @server.tool(description="List activation targets and their current status.")
    def list_activation_targets(
        org_alias: str | None = None,
        name_like: str | None = None,
    ) -> dict[str, Any]:
        where_clause = ""
        if name_like:
            escaped_name = name_like.replace("'", "\\'")
            where_clause = f" WHERE MasterLabel LIKE '%{escaped_name}%'"
        query = (
            "SELECT Id, MasterLabel, RunStatus, TargetStatus, LastPublishStatusDate, LastTargetStatusDateTime "
            f"FROM ActivationTarget{where_clause} ORDER BY CreatedDate DESC LIMIT 50"
        )
        result = sf.query(query, org_alias=org_alias)
        return {
            "org_alias": org_alias or config.default_org_alias,
            "total_size": result.get("totalSize", 0),
            "records": result.get("records", []),
        }

    @server.tool(description="Run a read-only SOQL query and return the raw records.")
    def query_soql(
        soql: str,
        org_alias: str | None = None,
        use_tooling_api: bool = False,
    ) -> dict[str, Any]:
        result = sf.query(soql, org_alias=org_alias, use_tooling_api=use_tooling_api)
        return {
            "org_alias": org_alias or config.default_org_alias,
            "total_size": result.get("totalSize", 0),
            "records": result.get("records", []),
        }

    @server.tool(description="Run a read-only SOQL query against a Data Cloud DMO.")
    def query_dmo(
        select_fields: list[str],
        dmo_name: str | None = None,
        org_alias: str | None = None,
        where_clause: str = "",
        order_by: str = "",
        limit: int = 20,
    ) -> dict[str, Any]:
        object_name = dmo_name or config.default_dmo_name
        query = f"SELECT {', '.join(select_fields)} FROM {object_name}"
        if where_clause:
            query += f" WHERE {where_clause}"
        if order_by:
            query += f" ORDER BY {order_by}"
        query += f" LIMIT {limit}"
        result = sf.query(query, org_alias=org_alias)
        return {
            "org_alias": org_alias or config.default_org_alias,
            "dmo_name": object_name,
            "query": query,
            "total_size": result.get("totalSize", 0),
            "records": result.get("records", []),
        }

    @server.tool(
        description=(
            "Compare the export contract fields to the imported Data Cloud source object "
            "and report which required fields are missing from the source schema."
        )
    )
    def compare_export_contract_to_source_object(
        source_object_name: str | None = None,
        contract_path: str | None = None,
        org_alias: str | None = None,
    ) -> dict[str, Any]:
        contract = Path(contract_path) if contract_path else config.source_contract_path
        describe_payload = sf.describe_sobject(
            source_object_name or config.default_source_object,
            org_alias=org_alias,
        )
        required_fields = load_contract_required_fields(contract)
        comparison = compare_required_fields_to_source_object(
            required_fields,
            _field_names(describe_payload),
        )
        return {
            "org_alias": org_alias or config.default_org_alias,
            "source_object_name": describe_payload["name"],
            "contract_path": str(contract),
            **comparison,
        }

    @server.tool(
        description=(
            "Compare the export contract fields to Salesforce Account using the activation "
            "mapping file and report missing mappings or missing Account fields."
        )
    )
    def compare_export_contract_to_account(
        contract_path: str | None = None,
        mapping_path: str | None = None,
        org_alias: str | None = None,
    ) -> dict[str, Any]:
        contract = Path(contract_path) if contract_path else config.account_sync_contract_path
        mapping = Path(mapping_path) if mapping_path else config.activation_mapping_path
        required_fields = load_contract_required_fields(contract)
        mapping_rows = load_mapping(mapping, target_object="Account")
        account_payload = sf.describe_sobject("Account", org_alias=org_alias)
        comparison = compare_required_fields_to_mapping(
            required_fields,
            mapping_rows,
            set(_field_names(account_payload)),
        )
        return {
            "org_alias": org_alias or config.default_org_alias,
            "target_object": "Account",
            "contract_path": str(contract),
            "mapping_path": str(mapping),
            **comparison,
        }

    @server.tool(
        description=(
            "Compare the export contract fields to the configured Data Cloud DMO using the "
            "planned DMO mapping file and report missing mappings or missing DMO fields."
        )
    )
    def compare_export_contract_to_dmo(
        dmo_name: str | None = None,
        contract_path: str | None = None,
        mapping_path: str | None = None,
        org_alias: str | None = None,
    ) -> dict[str, Any]:
        object_name = dmo_name or config.default_dmo_name
        contract = Path(contract_path) if contract_path else config.account_contract_path
        mapping = Path(mapping_path) if mapping_path else config.dmo_mapping_path
        required_fields = load_contract_required_fields(contract)
        mapping_rows = load_mapping(mapping, target_object=object_name)
        dmo_payload = sf.describe_sobject(object_name, org_alias=org_alias)
        comparison = compare_required_fields_to_mapping(
            required_fields,
            mapping_rows,
            set(_field_names(dmo_payload)),
        )
        return {
            "org_alias": org_alias or config.default_org_alias,
            "target_object": object_name,
            "contract_path": str(contract),
            "mapping_path": str(mapping),
            **comparison,
        }

    @server.tool(
        description=(
            "Report the contract-to-source-object, contract-to-DMO, and contract-to-Account "
            "field gaps together for a single Pulse360 validation pass."
        )
    )
    def report_unmapped_fields(
        org_alias: str | None = None,
        source_object_name: str | None = None,
        dmo_name: str | None = None,
        contract_path: str | None = None,
    ) -> dict[str, Any]:
        source_gap = compare_export_contract_to_source_object(
            source_object_name=source_object_name,
            contract_path=contract_path,
            org_alias=org_alias,
        )
        dmo_gap = compare_export_contract_to_dmo(
            dmo_name=dmo_name,
            contract_path=contract_path,
            org_alias=org_alias,
        )
        account_gap = compare_export_contract_to_account(
            contract_path=contract_path,
            org_alias=org_alias,
        )
        return {
            "org_alias": org_alias or config.default_org_alias,
            "source_contract_path": str(Path(contract_path) if contract_path else config.source_contract_path),
            "account_contract_path": str(Path(contract_path) if contract_path else config.account_contract_path),
            "account_sync_contract_path": str(
                Path(contract_path) if contract_path else config.account_sync_contract_path
            ),
            "source_object_gap": source_gap,
            "dmo_gap": dmo_gap,
            "account_gap": account_gap,
        }

    @server.tool(
        description=(
            "Report the live Data Cloud field path state in one call: data stream status, "
            "source-object contract gap, DMO mapping/field gap, and Salesforce Account gap."
        )
    )
    def report_live_field_path_status(
        org_alias: str | None = None,
        source_object_name: str | None = None,
        dmo_name: str | None = None,
        data_stream_name: str | None = None,
    ) -> dict[str, Any]:
        return _load_live_field_path_status(
            sf=sf,
            config=config,
            org_alias=org_alias,
            source_object_name=source_object_name,
            dmo_name=dmo_name,
            data_stream_name=data_stream_name,
        )

    return server
