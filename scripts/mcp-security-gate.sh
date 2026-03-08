#!/usr/bin/env bash
set -euo pipefail

cat <<'MSG'
MCP SECURITY GATE CHECK

Validate each MCP server against:
1) provenance and maintainer trust
2) license compliance
3) dependency and SAST scan
4) secret handling and key storage
5) OAuth scope minimization
6) network egress restrictions
7) allowed tool/resource boundaries

Record results in docs/security/mcp-security-assessment.md
Non-official MCP servers remain blocked until PASS.
MSG
