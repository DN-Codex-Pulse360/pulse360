# Databricks notebook source
"""Pulse360 data-layer closeout validation job.

Runs inside Databricks so the prototype data-layer gate can be scheduled close
to the governed tables, not only from the local Codex operator machine.
"""

from __future__ import annotations

import json
import uuid
from datetime import datetime, timezone

from pyspark.sql import Row


RUN_ID = f"data_layer_closeout_{datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S')}_{uuid.uuid4().hex[:8]}"
RUN_TS = datetime.now(timezone.utc)
MINIMUM_ROWS = {
    "pulse360_s4.silver_salesforce.crm_account": 1,
    "pulse360_s4.silver_salesforce.crm_governance_case": 1,
    "pulse360_s4.identity_resolution.resolved_entity": 1,
    "pulse360_s4.identity_resolution.entity_hierarchy_rollup": 1,
    "pulse360_s4.identity_resolution.m1_account_hierarchy_operational_profile": 1,
    "pulse360_s4.gold.account_genai_enrichment_output": 1,
    "pulse360_s4.gold_smart_city.smart_city_proposition_readiness": 6,
    "pulse360_s4.intelligence.datacloud_export_accounts": 1,
    "pulse360_s4.intelligence.datacloud_activation_review_queue": 6,
    "pulse360_s4.intelligence.governance_case_metrics": 1,
}
REQUIRED_COLUMNS = {
    "pulse360_s4.intelligence.datacloud_export_accounts": {
        "source_account_id",
        "intent_signal_payload",
        "ai_narrative",
        "ai_recommended_actions",
        "source_refs",
        "ingestion_metadata_label",
        "run_id",
        "run_timestamp",
        "model_version",
    },
    "pulse360_s4.intelligence.datacloud_activation_review_queue": {
        "source_record_id",
        "source_product",
        "target_entity_name",
        "market",
        "offering_family",
        "target_b2b_customer_names",
        "recommended_next_actions",
        "review_priority",
        "confidence_score",
        "activation_block_reasons",
        "run_id",
        "run_timestamp",
    },
}


def scalar(statement: str):
    return spark.sql(statement).collect()[0][0]


results = []
failures = []

for table_name, minimum in MINIMUM_ROWS.items():
    row_count = int(scalar(f"SELECT COUNT(*) FROM {table_name}"))
    passed = row_count >= minimum
    results.append(
        Row(
            run_id=RUN_ID,
            run_timestamp=RUN_TS,
            check_name=f"minimum_rows:{table_name}",
            asset=table_name,
            passed=passed,
            observed_value=str(row_count),
            expected_value=f">={minimum}",
            details=json.dumps({"row_count": row_count, "minimum": minimum}),
        )
    )
    if not passed:
        failures.append(f"{table_name} has {row_count} rows; expected at least {minimum}")

for table_name, expected_columns in REQUIRED_COLUMNS.items():
    actual_columns = {row.col_name for row in spark.sql(f"DESCRIBE TABLE {table_name}").collect()}
    missing = sorted(expected_columns - actual_columns)
    passed = not missing
    results.append(
        Row(
            run_id=RUN_ID,
            run_timestamp=RUN_TS,
            check_name=f"required_columns:{table_name}",
            asset=table_name,
            passed=passed,
            observed_value=",".join(missing),
            expected_value="no missing columns",
            details=json.dumps({"missing_columns": missing}),
        )
    )
    if missing:
        failures.append(f"{table_name} missing required columns: {', '.join(missing)}")

current_id_checks = [
    (
        "bronze_account_current_ids",
        "pulse360_s4.bronze_salesforce.account",
        "Id LIKE '001dL%'",
        "Id LIKE '001dM%'",
    ),
    (
        "bronze_contact_current_ids",
        "pulse360_s4.bronze_salesforce.contact",
        "Id LIKE '003dL%'",
        "Id LIKE '003dM%'",
    ),
    (
        "bronze_opportunity_current_ids",
        "pulse360_s4.bronze_salesforce.opportunity",
        "Id LIKE '006dL%'",
        "Id LIKE '006dM%'",
    ),
    (
        "bronze_product_current_ids",
        "pulse360_s4.bronze_salesforce.product2",
        "Id LIKE '01tdL%'",
        "Id LIKE '01tdM%'",
    ),
    (
        "silver_account_current_ids",
        "pulse360_s4.silver_salesforce.crm_account",
        "crm_account_id LIKE '001dL%'",
        "crm_account_id LIKE '001dM%'",
    ),
    (
        "gold_export_current_ids",
        "pulse360_s4.intelligence.datacloud_export_accounts",
        "source_account_id LIKE '001dL%'",
        "source_account_id LIKE '001dM%'",
    ),
]

for check_name, table_name, current_predicate, stale_predicate in current_id_checks:
    row = spark.sql(
        f"""
        SELECT
          COUNT(*) AS total_rows,
          COUNT_IF({current_predicate}) AS current_rows,
          COUNT_IF({stale_predicate}) AS stale_rows
        FROM {table_name}
        """
    ).collect()[0]
    passed = int(row.total_rows) == int(row.current_rows) and int(row.stale_rows) == 0
    results.append(
        Row(
            run_id=RUN_ID,
            run_timestamp=RUN_TS,
            check_name=check_name,
            asset=table_name,
            passed=passed,
            observed_value=f"total={row.total_rows};current={row.current_rows};stale={row.stale_rows}",
            expected_value="all rows current; stale=0",
            details=json.dumps(
                {
                    "total_rows": int(row.total_rows),
                    "current_rows": int(row.current_rows),
                    "stale_rows": int(row.stale_rows),
                }
            ),
        )
    )
    if not passed:
        failures.append(f"{check_name} failed for {table_name}")

manila_rows = int(
    scalar(
        """
        SELECT COUNT(*)
        FROM pulse360_s4.intelligence.datacloud_activation_review_queue
        WHERE source_product = 'csp_smart_city_proposition_readiness'
          AND market = 'Philippines'
          AND target_b2b_customer_names IS NOT NULL
          AND target_b2b_customer_names <> '[]'
        """
    )
)
results.append(
    Row(
        run_id=RUN_ID,
        run_timestamp=RUN_TS,
        check_name="manila_csp_action_rows",
        asset="pulse360_s4.intelligence.datacloud_activation_review_queue",
        passed=manila_rows >= 3,
        observed_value=str(manila_rows),
        expected_value=">=3",
        details=json.dumps({"manila_csp_action_rows": manila_rows}),
    )
)
if manila_rows < 3:
    failures.append(f"Expected at least 3 Manila CSP action rows, found {manila_rows}")

spark.sql("CREATE SCHEMA IF NOT EXISTS pulse360_s4.ops")
spark.sql(
    """
    CREATE TABLE IF NOT EXISTS pulse360_s4.ops.data_layer_validation_runs (
      run_id STRING,
      run_timestamp TIMESTAMP,
      check_name STRING,
      asset STRING,
      passed BOOLEAN,
      observed_value STRING,
      expected_value STRING,
      details STRING
    )
    USING DELTA
    """
)
spark.createDataFrame(results).write.mode("append").saveAsTable("pulse360_s4.ops.data_layer_validation_runs")

summary = {
    "run_id": RUN_ID,
    "run_timestamp": RUN_TS.isoformat(),
    "check_count": len(results),
    "failure_count": len(failures),
    "failures": failures,
}
print(json.dumps(summary, indent=2))

if failures:
    raise AssertionError(json.dumps(summary, indent=2))

dbutils.notebook.exit(json.dumps(summary))
