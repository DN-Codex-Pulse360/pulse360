"""Pulse360 Salesforce and Data Cloud helper package."""

from __future__ import annotations

from typing import Any

__all__ = ["build_server"]


def __getattr__(name: str) -> Any:
    if name != "build_server":
        raise AttributeError(name)

    from .server import build_server

    return build_server
