CREATE OR REPLACE VIEW pulse360_s4.gold.account_intelligence_governance_evidence AS
WITH m1 AS (
  SELECT
    concat('gov_m1_account_hierarchy_', group_entity_id) AS governance_evidence_id,
    'm1_account_hierarchy' AS source_product,
    operational_profile_id AS source_record_id,
    group_entity_id AS resolved_entity_id,
    primary_anchor_account_id AS crm_activation_key,
    source_refs,
    freshness_status,
    CAST(validity_score_external / 100 AS DOUBLE) AS confidence_score,
    to_json(
      named_struct(
        'identity_confidence', identity_confidence,
        'hierarchy_confidence', hierarchy_confidence,
        'validity_score_external', validity_score_external,
        'crm_anchor_account_count', size(crm_anchor_account_ids),
        'coverage_gap_flag', coverage_gap_flag
      )
    ) AS confidence_components,
    model_id,
    CAST(NULL AS STRING) AS prompt_version,
    enrichment_run_id,
    run_id AS source_run_id,
    run_timestamp AS source_run_timestamp,
    (
      primary_anchor_account_id IS NOT NULL
      AND freshness_status IN ('fresh', 'unknown')
      AND validity_score_external >= 80
    ) AS activation_eligible_flag,
    filter(
      array(
        CASE WHEN primary_anchor_account_id IS NULL THEN 'missing_crm_activation_key' END,
        CASE WHEN freshness_status IN ('stale', 'expired') THEN concat('freshness_', freshness_status) END,
        CASE WHEN validity_score_external < 80 THEN 'confidence_below_threshold' END
      ),
      reason -> reason IS NOT NULL
    ) AS activation_block_reasons,
    (
      primary_anchor_account_id IS NULL
      OR freshness_status IN ('stale', 'expired')
      OR validity_score_external < 80
    ) AS review_required_flag,
    CASE
      WHEN source_refs IS NULL OR source_refs = '[]' THEN 'blocked'
      ELSE 'source_bound'
    END AS lineage_status
  FROM pulse360_s4.identity_resolution.m1_account_hierarchy_operational_profile
),
genai_stable AS (
  SELECT
    'firmographic_genai' AS source_product,
    genai_enrichment_id,
    resolved_entity_id,
    crm_account_id,
    source_refs,
    business_action_confidence,
    confidence_components,
    model_id,
    prompt_version,
    run_id,
    run_timestamp,
    activation_eligible_flag,
    llm_result_confidence,
    unsupported_claim_count,
    insufficient_evidence_flag
  FROM pulse360_s4.gold.account_genai_enrichment_output
),
genai_runtime_latest AS (
  SELECT
    'firmographic_genai_runtime' AS source_product,
    genai_enrichment_id,
    resolved_entity_id,
    crm_account_id,
    source_refs,
    business_action_confidence,
    confidence_components,
    model_id,
    prompt_version,
    run_id,
    run_timestamp,
    activation_eligible_flag,
    llm_result_confidence,
    unsupported_claim_count,
    insufficient_evidence_flag
  FROM (
    SELECT
      runtime.*,
      row_number() OVER (
        PARTITION BY runtime.resolved_entity_id
        ORDER BY to_timestamp(runtime.run_timestamp) DESC, runtime.run_id DESC
      ) AS runtime_rank
    FROM pulse360_s4.gold.account_genai_enrichment_output_runtime runtime
  )
  WHERE runtime_rank = 1
),
genai_runtime_steward_decisions AS (
  SELECT
    data_cloud_source_record_id,
    data_cloud_review_queue_id,
    surviving_account_id,
    decision_status,
    downstream_update_status,
    decided_at
  FROM (
    SELECT
      g.*,
      row_number() OVER (
        PARTITION BY coalesce(g.data_cloud_source_record_id, g.data_cloud_review_queue_id)
        ORDER BY coalesce(g.decided_at, g.crm_last_modified_at) DESC, g.crm_governance_case_id DESC
      ) AS decision_rank
    FROM pulse360_s4.silver_salesforce.crm_governance_case g
    WHERE g.source_product = 'firmographic_genai_runtime'
      AND g.decision_status = 'Approved'
      AND g.surviving_account_id IS NOT NULL
      AND coalesce(g.data_cloud_source_record_id, g.data_cloud_review_queue_id) IS NOT NULL
      AND coalesce(g.downstream_update_status, 'Queued') IN ('Queued', 'Ready', 'Completed')
  )
  WHERE decision_rank = 1
),
genai_source AS (
  SELECT
    source_product,
    genai_enrichment_id,
    resolved_entity_id,
    crm_account_id,
    source_refs,
    business_action_confidence,
    confidence_components,
    model_id,
    prompt_version,
    run_id,
    run_timestamp,
    activation_eligible_flag,
    llm_result_confidence,
    unsupported_claim_count,
    insufficient_evidence_flag
  FROM genai_stable
  UNION ALL
  SELECT
    r.source_product,
    r.genai_enrichment_id,
    r.resolved_entity_id,
    COALESCE(r.crm_account_id, d.surviving_account_id) AS crm_account_id,
    r.source_refs,
    r.business_action_confidence,
    r.confidence_components,
    r.model_id,
    r.prompt_version,
    r.run_id,
    r.run_timestamp,
    (r.activation_eligible_flag OR d.surviving_account_id IS NOT NULL) AS activation_eligible_flag,
    r.llm_result_confidence,
    r.unsupported_claim_count,
    r.insufficient_evidence_flag
  FROM genai_runtime_latest r
  LEFT JOIN genai_runtime_steward_decisions d
    ON d.data_cloud_source_record_id = r.genai_enrichment_id
    OR d.data_cloud_review_queue_id = concat('gov_firmographic_genai_runtime_', r.resolved_entity_id)
),
genai AS (
  SELECT
    concat('gov_', source_product, '_', resolved_entity_id) AS governance_evidence_id,
    source_product,
    genai_enrichment_id AS source_record_id,
    resolved_entity_id,
    crm_account_id AS crm_activation_key,
    source_refs,
    'fresh' AS freshness_status,
    business_action_confidence AS confidence_score,
    confidence_components,
    model_id,
    prompt_version,
    run_id AS enrichment_run_id,
    run_id AS source_run_id,
    run_timestamp AS source_run_timestamp,
    (
      activation_eligible_flag
      AND crm_account_id IS NOT NULL
      AND business_action_confidence >= 0.70
      AND llm_result_confidence >= 0.80
      AND unsupported_claim_count = 0
      AND NOT insufficient_evidence_flag
    ) AS activation_eligible_flag,
    filter(
      array(
        CASE WHEN crm_account_id IS NULL THEN 'missing_crm_activation_key' END,
        CASE WHEN business_action_confidence < 0.70 THEN 'business_action_confidence_below_threshold' END,
        CASE WHEN llm_result_confidence < 0.80 THEN 'llm_result_confidence_below_threshold' END,
        CASE WHEN unsupported_claim_count > 0 THEN 'unsupported_claims_present' END,
        CASE WHEN insufficient_evidence_flag THEN 'insufficient_evidence' END,
        CASE WHEN NOT activation_eligible_flag THEN 'source_product_not_activation_eligible' END
      ),
      reason -> reason IS NOT NULL
    ) AS activation_block_reasons,
    (
      crm_account_id IS NULL
      OR business_action_confidence < 0.70
      OR llm_result_confidence < 0.80
      OR unsupported_claim_count > 0
      OR insufficient_evidence_flag
      OR NOT activation_eligible_flag
    ) AS review_required_flag,
    CASE
      WHEN source_refs IS NULL OR source_refs = '[]' THEN 'blocked'
      WHEN model_id IS NULL OR prompt_version IS NULL THEN 'lineage_pending'
      ELSE 'source_bound'
    END AS lineage_status
  FROM genai_source
),
account_ai AS (
  SELECT
    concat('gov_account_intelligence_ai_synthetic_', resolved_entity_id) AS governance_evidence_id,
    'account_intelligence_ai_synthetic' AS source_product,
    ai_enrichment_id AS source_record_id,
    resolved_entity_id,
    crm_account_id AS crm_activation_key,
    source_refs,
    'fresh' AS freshness_status,
    business_action_confidence AS confidence_score,
    confidence_components,
    model_id,
    prompt_version,
    run_id AS enrichment_run_id,
    run_id AS source_run_id,
    run_timestamp AS source_run_timestamp,
    activation_state = 'activation_safe' AS activation_eligible_flag,
    activation_block_reasons,
    activation_state <> 'activation_safe' AS review_required_flag,
    CASE
      WHEN source_refs IS NULL OR source_refs = '[]' THEN 'blocked'
      WHEN model_id IS NULL OR prompt_version IS NULL THEN 'lineage_pending'
      ELSE 'source_bound'
    END AS lineage_status
  FROM pulse360_s4.gold_account_intelligence.account_ai_enrichment_output
),
csp_smart_city AS (
  SELECT
    concat('gov_csp_smart_city_', target_entity_id, '_', offering_family) AS governance_evidence_id,
    'csp_smart_city_proposition_readiness' AS source_product,
    proposition_readiness_id AS source_record_id,
    concat('ent_', target_entity_id) AS resolved_entity_id,
    CAST(NULL AS STRING) AS crm_activation_key,
    source_refs,
    'fresh' AS freshness_status,
    proposition_readiness_score AS confidence_score,
    to_json(
      named_struct(
        'target_entity_name', target_entity_name,
        'country_code', country_code,
        'market', market,
        'target_entity_type', target_entity_type,
        'offering_family', offering_family,
        'offer_bundle', offer_bundle,
        'signal_count', signal_count,
        'average_signal_confidence', average_signal_confidence,
        'target_b2b_customer_ids', target_b2b_customer_ids,
        'source_families', source_families,
        'consent_classes', consent_classes,
        'recommended_next_actions', recommended_next_actions
      )
    ) AS confidence_components,
    model_version AS model_id,
    CAST(NULL AS STRING) AS prompt_version,
    signal_pack_id AS enrichment_run_id,
    signal_pack_id AS source_run_id,
    run_timestamp AS source_run_timestamp,
    activation_state = 'activation_safe' AS activation_eligible_flag,
    activation_block_reasons,
    activation_state = 'review_required' AS review_required_flag,
    CASE
      WHEN source_refs IS NULL OR source_refs = '[]' THEN 'blocked'
      WHEN activation_state = 'blocked' THEN 'blocked'
      ELSE 'source_bound'
    END AS lineage_status
  FROM pulse360_s4.gold_smart_city.smart_city_proposition_readiness
)
SELECT
  governance_evidence_id,
  source_product,
  source_record_id,
  resolved_entity_id,
  crm_activation_key,
  source_refs,
  freshness_status,
  confidence_score,
  confidence_components,
  model_id,
  prompt_version,
  enrichment_run_id,
  source_run_id,
  source_run_timestamp,
  activation_eligible_flag,
  activation_block_reasons,
  review_required_flag,
  lineage_status,
  concat('governance_evidence_run_', date_format(current_timestamp(), 'yyyyMMddHHmmss')) AS run_id,
  current_timestamp() AS run_timestamp,
  'account-intelligence-governance-evidence-v1' AS model_version
FROM m1

UNION ALL

SELECT
  governance_evidence_id,
  source_product,
  source_record_id,
  resolved_entity_id,
  crm_activation_key,
  source_refs,
  freshness_status,
  confidence_score,
  confidence_components,
  model_id,
  prompt_version,
  enrichment_run_id,
  source_run_id,
  source_run_timestamp,
  activation_eligible_flag,
  activation_block_reasons,
  review_required_flag,
  lineage_status,
  concat('governance_evidence_run_', date_format(current_timestamp(), 'yyyyMMddHHmmss')) AS run_id,
  current_timestamp() AS run_timestamp,
  'account-intelligence-governance-evidence-v1' AS model_version
FROM genai

UNION ALL

SELECT
  governance_evidence_id,
  source_product,
  source_record_id,
  resolved_entity_id,
  crm_activation_key,
  source_refs,
  freshness_status,
  confidence_score,
  confidence_components,
  model_id,
  prompt_version,
  enrichment_run_id,
  source_run_id,
  source_run_timestamp,
  activation_eligible_flag,
  activation_block_reasons,
  review_required_flag,
  lineage_status,
  concat('governance_evidence_run_', date_format(current_timestamp(), 'yyyyMMddHHmmss')) AS run_id,
  current_timestamp() AS run_timestamp,
  'account-intelligence-governance-evidence-v1' AS model_version
FROM account_ai

UNION ALL

SELECT
  governance_evidence_id,
  source_product,
  source_record_id,
  resolved_entity_id,
  crm_activation_key,
  source_refs,
  freshness_status,
  confidence_score,
  confidence_components,
  model_id,
  prompt_version,
  enrichment_run_id,
  source_run_id,
  source_run_timestamp,
  activation_eligible_flag,
  activation_block_reasons,
  review_required_flag,
  lineage_status,
  concat('governance_evidence_run_', date_format(current_timestamp(), 'yyyyMMddHHmmss')) AS run_id,
  current_timestamp() AS run_timestamp,
  'account-intelligence-governance-evidence-v1' AS model_version
FROM csp_smart_city;
