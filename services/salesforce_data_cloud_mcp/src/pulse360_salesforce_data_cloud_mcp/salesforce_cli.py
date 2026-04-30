from __future__ import annotations

import json
import subprocess
from dataclasses import dataclass


class SalesforceCliError(RuntimeError):
    """Raised when an sf CLI command fails or returns invalid JSON."""


@dataclass
class SalesforceCliClient:
    default_org_alias: str
    timeout_seconds: int = 60

    def describe_sobject(
        self,
        sobject_name: str,
        *,
        org_alias: str | None = None,
        use_tooling_api: bool = False,
    ) -> dict:
        args = ["sobject", "describe", "--sobject", sobject_name]
        if use_tooling_api:
            args.append("--use-tooling-api")
        payload = self._run_sf_json(args, org_alias=org_alias)
        return payload["result"]

    def query(
        self,
        soql: str,
        *,
        org_alias: str | None = None,
        use_tooling_api: bool = False,
    ) -> dict:
        args = ["data", "query", "--query", soql]
        if use_tooling_api:
            args.append("--use-tooling-api")
        payload = self._run_sf_json(args, org_alias=org_alias)
        return payload["result"]

    def org_display(self, *, org_alias: str | None = None, verbose: bool = True) -> dict:
        args = ["org", "display"]
        if verbose:
            args.append("--verbose")
        payload = self._run_sf_json(args, org_alias=org_alias)
        return payload["result"]

    def _run_sf_json(self, args: list[str], *, org_alias: str | None = None) -> dict:
        resolved_org = org_alias or self.default_org_alias
        command = ["sf", *args, "--target-org", resolved_org, "--json"]

        completed = self._execute(command)
        if completed.returncode == 0:
            return self._parse_json_response(command, completed.stdout, completed.stderr)

        detail = self._extract_error_detail(completed.stdout, completed.stderr)
        if self._should_refresh_session(detail):
            self._refresh_org_session(resolved_org)
            completed = self._execute(command)
            if completed.returncode == 0:
                return self._parse_json_response(command, completed.stdout, completed.stderr)
            detail = self._extract_error_detail(completed.stdout, completed.stderr)

        raise SalesforceCliError(
            f"sf command failed ({completed.returncode}): {' '.join(command)}\n{detail}"
        )

    def _execute(self, command: list[str]) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=self.timeout_seconds,
            check=False,
        )

    @staticmethod
    def _parse_json_response(command: list[str], stdout: str, stderr: str) -> dict:
        try:
            return json.loads(stdout)
        except json.JSONDecodeError as exc:
            raise SalesforceCliError(
                f"sf command returned non-JSON output: {' '.join(command)}\n{stdout}\n{stderr}"
            ) from exc

    def _refresh_org_session(self, org_alias: str) -> None:
        refresh_command = ["sf", "org", "display", "--target-org", org_alias, "--verbose", "--json"]
        completed = self._execute(refresh_command)
        if completed.returncode != 0:
            detail = self._extract_error_detail(completed.stdout, completed.stderr)
            raise SalesforceCliError(
                f"sf session refresh failed ({completed.returncode}): {' '.join(refresh_command)}\n{detail}"
            )

    @staticmethod
    def _should_refresh_session(detail: str) -> bool:
        retry_markers = (
            "ERROR_HTTP_404",
            "INVALID_AUTH_HEADER",
            "Session expired or invalid",
            "expired access/refresh token",
        )
        return any(marker in detail for marker in retry_markers)

    @staticmethod
    def _extract_error_detail(stdout: str, stderr: str) -> str:
        for candidate in (stdout, stderr):
            candidate = candidate.strip()
            if not candidate:
                continue
            try:
                payload = json.loads(candidate)
            except json.JSONDecodeError:
                return candidate
            message = payload.get("message") or payload.get("name") or candidate
            return str(message)
        return "No error detail returned by sf"
