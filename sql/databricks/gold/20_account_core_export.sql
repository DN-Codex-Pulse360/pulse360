CREATE OR REPLACE VIEW pulse360_s4.gold.account_core_export AS
SELECT
  canonical_account_id,
  ssot_id,
  source_account_id,
  deterministic_key,
  account_name,
  parent_account_id,
  industry,
  country_code,
  identity_confidence,
  validity_score,
  run_id,
  run_timestamp,
  model_version
FROM pulse360_s4.gold.account_export_base;

