#!/usr/bin/env python3
"""Generate an S4 Databricks implementation plan or checklist."""

import argparse
from datetime import date

SCENARIO_TASKS = {
    "ds01": [
        "Publish duplicate candidate pairs with confidence distribution",
        "Publish firmographic validity examples for featured entities",
        "Verify lineage view from CRM source to gold outputs",
    ],
    "ds02": [
        "Expose validity scores for both duplicate candidates",
        "Provide governance trend metrics (resolved count, average resolution minutes)",
        "Validate confidence evidence fields for side-by-side case UI",
    ],
    "ds03": [
        "Publish stitched hierarchy graph with parent-child links",
        "Validate subsidiaries and coverage-gap markers for demo entities",
        "Provide export fields needed for group rollup downstream",
    ],
}

GLOBAL_TASKS = [
    "Pin demo dataset snapshot and run IDs",
    "Confirm no hardcoded revenue values in demo artifacts",
    "Confirm Data Cloud handoff table includes run timestamp",
    "Capture Unity Catalog lineage screenshot or equivalent",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate S4 Databricks plan/checklist")
    parser.add_argument(
        "--mode",
        choices=["plan", "checklist"],
        default="plan",
        help="Output style",
    )
    parser.add_argument(
        "--scenarios",
        default="ds01,ds02,ds03",
        help="Comma-separated list: ds01,ds02,ds03",
    )
    return parser.parse_args()


def normalize_scenarios(raw: str) -> list[str]:
    allowed = {"ds01", "ds02", "ds03"}
    scenarios = [s.strip().lower() for s in raw.split(",") if s.strip()]
    invalid = [s for s in scenarios if s not in allowed]
    if invalid:
        raise ValueError(f"Unsupported scenarios: {', '.join(invalid)}")
    return scenarios


def emit(mode: str, scenarios: list[str]) -> str:
    lines = [
        f"# S4 Databricks {mode.title()} ({date.today().isoformat()})",
        "",
        "## Scope",
        f"- Scenarios: {', '.join(scenarios)}",
        "- Layer: Databricks intelligence foundation",
        "",
    ]

    for scenario in scenarios:
        lines.append(f"## {scenario.upper()}")
        for task in SCENARIO_TASKS[scenario]:
            prefix = "- [ ]" if mode == "checklist" else "-"
            lines.append(f"{prefix} {task}")
        lines.append("")

    lines.append("## Global")
    for task in GLOBAL_TASKS:
        prefix = "- [ ]" if mode == "checklist" else "-"
        lines.append(f"{prefix} {task}")

    lines.append("")
    return "\n".join(lines)


def main() -> None:
    args = parse_args()
    scenarios = normalize_scenarios(args.scenarios)
    print(emit(args.mode, scenarios))


if __name__ == "__main__":
    main()
