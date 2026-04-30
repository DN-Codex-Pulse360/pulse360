from __future__ import annotations

import argparse
from dataclasses import replace
from typing import Sequence

from .config import ServiceConfig
from .server import build_server


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run the Pulse360 Salesforce and Data Cloud MCP service.",
    )
    parser.add_argument(
        "--transport",
        choices=("stdio", "sse", "streamable-http"),
        default="stdio",
        help="MCP transport to expose.",
    )
    parser.add_argument(
        "--mount-path",
        default=None,
        help="Optional mount path for HTTP-based transports.",
    )
    parser.add_argument(
        "--org-alias",
        default=None,
        help="Override the default Salesforce org alias.",
    )
    parser.add_argument(
        "--dmo-name",
        default=None,
        help="Override the default Data Cloud DMO name.",
    )
    parser.add_argument(
        "--source-object",
        default=None,
        help="Override the default Data Cloud source-object API name.",
    )
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    config = ServiceConfig.load()

    overrides = {}
    if args.org_alias:
        overrides["default_org_alias"] = args.org_alias
    if args.dmo_name:
        overrides["default_dmo_name"] = args.dmo_name
    if args.source_object:
        overrides["default_source_object"] = args.source_object
    if overrides:
        config = replace(config, **overrides)

    server = build_server(config)
    server.run(transport=args.transport, mount_path=args.mount_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
