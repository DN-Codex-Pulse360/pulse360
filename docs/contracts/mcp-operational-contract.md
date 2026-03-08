# MCP Operational Contract

## Required Per-Server Definition
- Authentication mode
- OAuth/token scope
- Allowed resources and tool calls
- Read/write boundary
- Audit logging destination and retention

## Security Controls
- Official-first server selection
- Security assessment pass required for non-official servers
- Secret injection only through secure environment mechanism
- Egress restricted to approved domains/endpoints

## Operational Policy
- Failed auth or scope drift blocks execution.
- Any scope expansion requires decision log entry and security sign-off.
