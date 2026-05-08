-- Cross-platform governance evidence packet.
-- One row represents the defensibility envelope for a served attribute, model score, LLM narrative, or steward decision.
CREATE TABLE IF NOT EXISTS pulse360_s4.gold.governance_evidence_packet (
  evidence_packet_id STRING NOT NULL,
  subject_type STRING NOT NULL,
  subject_id STRING NOT NULL,
  source_account_id STRING NOT NULL COMMENT 'Salesforce Account ID used as the CRM activation key.',
  served_attribute_name STRING NOT NULL,
  served_attribute_value_hash STRING NOT NULL,
  source_contributions_json STRING NOT NULL,
  lineage_refs_json STRING NOT NULL,
  model_refs_json STRING,
  llm_audit_refs_json STRING,
  salesforce_audit_refs_json STRING,
  confidence DOUBLE NOT NULL,
  freshness_status STRING NOT NULL,
  run_id STRING NOT NULL,
  generated_at TIMESTAMP NOT NULL,
  validation_status STRING NOT NULL,
  known_limitations_json STRING,
  ready_for_demo BOOLEAN NOT NULL,
  ready_for_external_audit BOOLEAN NOT NULL,
  regulator_readiness_reason STRING NOT NULL
)
USING DELTA
COMMENT 'Pulse360 governance evidence packets for source, lineage, model, LLM, Data Cloud, and Salesforce audit defensibility.';
