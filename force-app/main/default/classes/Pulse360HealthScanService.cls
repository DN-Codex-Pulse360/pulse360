public with sharing class Pulse360HealthScanService {
    public class SourceRef {
        @AuraEnabled public String sourceId;
        @AuraEnabled public String sourceName;
        @AuraEnabled public String sourceType;
        @AuraEnabled public String sourceUrl;
        @AuraEnabled public String documentDate;
        @AuraEnabled public String accessedAt;
        @AuraEnabled public String excerpt;
        @AuraEnabled public String jurisdiction;
    }

    public class RecommendedAction {
        @AuraEnabled public Integer rank;
        @AuraEnabled public String actionType;
        @AuraEnabled public String target;
        @AuraEnabled public String targetRecordId;
        @AuraEnabled public String reasoning;
        @AuraEnabled public String estimatedRevenueImpact;
        @AuraEnabled public Decimal confidence;
        @AuraEnabled public List<String> sourceIds = new List<String>();
    }

    public class HealthScanResult {
        @AuraEnabled public Id accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public Decimal healthScore;
        @AuraEnabled public Decimal regulatoryReadinessScore;
        @AuraEnabled public Integer duplicateExposureCount;
        @AuraEnabled public Decimal groupRevenueRollup;
        @AuraEnabled public Decimal groupRevenueVisible;
        @AuraEnabled public Decimal hiddenRevenue;
        @AuraEnabled public Integer groupKnownSubsidiaryCount;
        @AuraEnabled public Integer crmCoveredSubsidiaryCount;
        @AuraEnabled public Boolean externallyValidated;
        @AuraEnabled public String externalLegalName;
        @AuraEnabled public Decimal validityScoreExternal;
        @AuraEnabled public String aiNarrative;
        @AuraEnabled public String aiNarrativeGeneratedAt;
        @AuraEnabled public String enrichmentRunId;
        @AuraEnabled public String modelId;
        @AuraEnabled public String promptVersion;
        @AuraEnabled public Integer citationCount;
        @AuraEnabled public String lastSyncedTimestamp;
        @AuraEnabled public String currencyCode;
        @AuraEnabled public List<RecommendedAction> actions = new List<RecommendedAction>();
        @AuraEnabled public List<SourceRef> sourceRefs = new List<SourceRef>();
    }

    @AuraEnabled(cacheable=true)
    public static HealthScanResult runHealthScan(Id accountId) {
        if (accountId == null) {
            throw new AuraHandledException('Account Id is required.');
        }

        Account accountRecord = [
            SELECT
                Id,
                Name,
                BillingCountry,
                Health_Score__c,
                Regulatory_Readiness_Score__c,
                Duplicate_Exposure_Count__c,
                Group_Revenue_Rollup__c,
                Group_Revenue_Visible__c,
                Group_Known_Subsidiary_Count__c,
                CRM_Covered_Subsidiary_Count__c,
                Externally_Validated__c,
                External_Legal_Name__c,
                Validity_Score_External__c,
                AI_Narrative__c,
                AI_Narrative_Generated__c,
                Enrichment_Run_Id__c,
                AI_Model_Id__c,
                AI_Prompt_Version__c,
                AI_Citation_Count__c,
                DataCloud_Last_Synced__c,
                AI_Recommended_Actions__c,
                AI_Source_Refs__c
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];

        HealthScanResult result = new HealthScanResult();
        result.accountId = accountRecord.Id;
        result.accountName = accountRecord.Name;
        result.healthScore = accountRecord.Health_Score__c;
        result.regulatoryReadinessScore = accountRecord.Regulatory_Readiness_Score__c;
        result.duplicateExposureCount = integerValue(accountRecord.Duplicate_Exposure_Count__c);
        result.groupRevenueRollup = accountRecord.Group_Revenue_Rollup__c;
        result.groupRevenueVisible = accountRecord.Group_Revenue_Visible__c;
        result.hiddenRevenue = hiddenRevenue(accountRecord.Group_Revenue_Rollup__c, accountRecord.Group_Revenue_Visible__c);
        result.groupKnownSubsidiaryCount = integerValue(accountRecord.Group_Known_Subsidiary_Count__c);
        result.crmCoveredSubsidiaryCount = integerValue(accountRecord.CRM_Covered_Subsidiary_Count__c);
        result.externallyValidated = accountRecord.Externally_Validated__c;
        result.externalLegalName = accountRecord.External_Legal_Name__c;
        result.validityScoreExternal = accountRecord.Validity_Score_External__c;
        result.aiNarrative = accountRecord.AI_Narrative__c;
        result.aiNarrativeGeneratedAt = datetimeValue(accountRecord.AI_Narrative_Generated__c);
        result.enrichmentRunId = accountRecord.Enrichment_Run_Id__c;
        result.modelId = accountRecord.AI_Model_Id__c;
        result.promptVersion = accountRecord.AI_Prompt_Version__c;
        result.citationCount = integerValue(accountRecord.AI_Citation_Count__c);
        result.lastSyncedTimestamp = datetimeValue(accountRecord.DataCloud_Last_Synced__c);
        result.currencyCode = currencyCodeForCountry(accountRecord.BillingCountry);
        result.actions = parseRecommendedActions(accountRecord.AI_Recommended_Actions__c);
        result.sourceRefs = parseSourceRefs(accountRecord.AI_Source_Refs__c);

        return result;
    }

    private static Decimal hiddenRevenue(Decimal totalRevenue, Decimal visibleRevenue) {
        Decimal safeTotal = totalRevenue == null ? 0 : totalRevenue;
        Decimal safeVisible = visibleRevenue == null ? 0 : visibleRevenue;
        Decimal hidden = safeTotal - safeVisible;
        return hidden > 0 ? hidden : 0;
    }

    private static Integer integerValue(Decimal value) {
        return value == null ? 0 : value.intValue();
    }

    private static String datetimeValue(Datetime value) {
        return value == null ? null : value.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
    }

    private static String currencyCodeForCountry(String billingCountry) {
        if (String.isBlank(billingCountry)) {
            return 'USD';
        }

        String normalized = billingCountry.toLowerCase();
        if (normalized.contains('singapore')) {
            return 'SGD';
        }
        if (normalized.contains('philippines')) {
            return 'PHP';
        }
        return 'USD';
    }

    private static List<RecommendedAction> parseRecommendedActions(String payload) {
        List<RecommendedAction> actions = new List<RecommendedAction>();
        if (String.isBlank(payload)) {
            return actions;
        }

        Object rawPayload;
        try {
            rawPayload = JSON.deserializeUntyped(payload);
        } catch (Exception ex) {
            return actions;
        }

        if (!(rawPayload instanceof List<Object>)) {
            return actions;
        }

        for (Object item : (List<Object>)rawPayload) {
            if (!(item instanceof Map<String, Object>)) {
                continue;
            }

            Map<String, Object> actionMap = (Map<String, Object>)item;
            RecommendedAction action = new RecommendedAction();
            action.rank = integerFromObject(actionMap.get('rank'));
            action.actionType = stringFromObject(actionMap.get('action_type'));
            action.target = stringFromObject(actionMap.get('target'));
            action.targetRecordId = stringFromObject(actionMap.get('target_record_id'));
            action.reasoning = stringFromObject(actionMap.get('reasoning'));
            action.estimatedRevenueImpact = stringFromObject(actionMap.get('estimated_revenue_impact'));
            action.confidence = decimalFromObject(actionMap.get('confidence'));

            Object rawSourceIds = actionMap.get('source_ids');
            if (rawSourceIds instanceof List<Object>) {
                for (Object sourceId : (List<Object>)rawSourceIds) {
                    if (sourceId != null) {
                        action.sourceIds.add(String.valueOf(sourceId));
                    }
                }
            }

            actions.add(action);
        }

        return actions;
    }

    private static List<SourceRef> parseSourceRefs(String payload) {
        List<SourceRef> refs = new List<SourceRef>();
        if (String.isBlank(payload)) {
            return refs;
        }

        Object rawPayload;
        try {
            rawPayload = JSON.deserializeUntyped(payload);
        } catch (Exception ex) {
            return refs;
        }

        if (!(rawPayload instanceof List<Object>)) {
            return refs;
        }

        for (Object item : (List<Object>)rawPayload) {
            if (!(item instanceof Map<String, Object>)) {
                continue;
            }

            Map<String, Object> refMap = (Map<String, Object>)item;
            SourceRef ref = new SourceRef();
            ref.sourceId = stringFromObject(refMap.get('source_id'));
            ref.sourceName = stringFromObject(refMap.get('source_name'));
            ref.sourceType = stringFromObject(refMap.get('source_type'));
            ref.sourceUrl = stringFromObject(refMap.get('source_url'));
            ref.documentDate = stringFromObject(refMap.get('document_date'));
            ref.accessedAt = stringFromObject(refMap.get('accessed_at'));
            ref.excerpt = stringFromObject(refMap.get('excerpt'));
            ref.jurisdiction = stringFromObject(refMap.get('jurisdiction'));
            refs.add(ref);
        }

        return refs;
    }

    private static String stringFromObject(Object value) {
        return value == null ? null : String.valueOf(value);
    }

    private static Integer integerFromObject(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof Integer) {
            return (Integer)value;
        }
        if (value instanceof Decimal) {
            return ((Decimal)value).intValue();
        }
        return Integer.valueOf(String.valueOf(value));
    }

    private static Decimal decimalFromObject(Object value) {
        if (value == null) {
            return null;
        }
        return Decimal.valueOf(String.valueOf(value));
    }
}
