#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import anyio
import json
from pathlib import Path

from mcp.client.session import ClientSession
from mcp.client.streamable_http import streamablehttp_client


def read_databricks_config():
    cfg = Path.home() / ".databrickscfg"
    host = None
    token = None
    if cfg.exists():
        for line in cfg.read_text().splitlines():
            stripped = line.strip()
            if stripped.startswith("host"):
                host = stripped.split("=", 1)[1].strip()
            elif stripped.startswith("token"):
                token = stripped.split("=", 1)[1].strip()
    return host, token


async def tool_text(session, name, arguments):
    result = await session.call_tool(name, arguments)
    return "\n".join(getattr(item, "text", str(item)) for item in result.content)


async def main():
    import os

    config_host, config_token = read_databricks_config()
    host = os.environ.get("DATABRICKS_HOST") or config_host
    token = os.environ.get("DATABRICKS_TOKEN") or config_token

    if not host:
        raise SystemExit("Missing Databricks host. Set DATABRICKS_HOST or configure ~/.databrickscfg.")
    if not token:
        raise SystemExit("Missing Databricks token. Set DATABRICKS_TOKEN or configure ~/.databrickscfg.")

    server_url = host.rstrip("/") + "/api/2.0/mcp/sql"
    async with streamablehttp_client(
        server_url,
        headers={"Authorization": f"Bearer {token}"},
        timeout=30,
    ) as (read, write, _):
        async with ClientSession(read, write) as session:
            await session.initialize()
            tools = await session.list_tools()
            tool_names = {tool.name for tool in tools.tools}
            required_tools = {"execute_sql", "execute_sql_read_only", "poll_sql_result"}
            missing_tools = sorted(required_tools - tool_names)
            if missing_tools:
                raise SystemExit(f"Missing Databricks SQL MCP tools: {', '.join(missing_tools)}")

            text = await tool_text(session, "execute_sql_read_only", {"query": "SHOW CATALOGS"})
            payload = json.loads(text)
            for _ in range(10):
                if payload.get("status", {}).get("state") != "PENDING":
                    break
                statement_id = payload["statement_id"]
                await anyio.sleep(2)
                text = await tool_text(session, "poll_sql_result", {"statement_id": statement_id})
                payload = json.loads(text)

            state = payload.get("status", {}).get("state")
            if state != "SUCCEEDED":
                raise SystemExit(f"Databricks SQL MCP validation did not succeed; state={state}")

            result_text = json.dumps(payload)
            if "pulse360_s4" not in result_text:
                raise SystemExit("Databricks SQL MCP succeeded, but pulse360_s4 catalog was not visible.")

    print("[PASS] Databricks SQL MCP listed tools and executed SHOW CATALOGS")


anyio.run(main)
PY
