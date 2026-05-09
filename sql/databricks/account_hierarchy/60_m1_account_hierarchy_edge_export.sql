CREATE OR REPLACE TABLE pulse360_s4.intelligence.m1_account_hierarchy_edge_export AS
SELECT
  hierarchy_edge_id,
  source_account_id,
  parent_source_account_id,
  child_source_account_id,
  parent_party_id,
  child_party_id,
  parent_name,
  child_name,
  relationship_type,
  relationship_basis,
  hierarchy_level,
  confidence,
  source_url,
  evidence_id,
  evidence_summary,
  lineage_refs_json,
  run_id,
  model_version,
  generated_at
FROM pulse360_s4.intelligence.m1_account_hierarchy_edge;
