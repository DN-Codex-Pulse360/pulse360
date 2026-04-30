public with sharing class Pulse360SellerWorkspaceService {
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

    public class HierarchyEntity {
        @AuraEnabled public String entityId;
        @AuraEnabled public String crmRecordId;
        @AuraEnabled public String entityName;
        @AuraEnabled public String entityRole;
        @AuraEnabled public String coverageStatus;
        @AuraEnabled public String coverageLabel;
        @AuraEnabled public Boolean inCrm;
        @AuraEnabled public String signal;
        @AuraEnabled public String suggestedPlay;
        @AuraEnabled public Boolean isCurrentAccount;
    }

    public class ActionPack {
        @AuraEnabled public Integer rank;
        @AuraEnabled public String actionType;
        @AuraEnabled public String target;
        @AuraEnabled public String targetRecordId;
        @AuraEnabled public String targetEntity;
        @AuraEnabled public String reasoning;
        @AuraEnabled public String estimatedRevenueImpact;
        @AuraEnabled public Decimal confidence;
        @AuraEnabled public String confidenceLabel;
        @AuraEnabled public String solutionFamily;
        @AuraEnabled public String recommendedPlay;
        @AuraEnabled public String specialistRoute;
        @AuraEnabled public String buyingGroupGap;
        @AuraEnabled public String outreachObjective;
        @AuraEnabled public String buttonLabel;
        @AuraEnabled public List<String> sourceIds = new List<String>();
        @AuraEnabled public List<SourceRef> supportingSources = new List<SourceRef>();
    }

    public class WorkspaceResult {
        @AuraEnabled public Id accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public String primaryBrandName;
        @AuraEnabled public String externalLegalName;
        @AuraEnabled public String currencyCode;
        @AuraEnabled public Decimal groupRevenueRollup;
        @AuraEnabled public Decimal groupRevenueVisible;
        @AuraEnabled public Decimal hiddenRevenue;
        @AuraEnabled public Integer groupKnownSubsidiaryCount;
        @AuraEnabled public Integer crmCoveredSubsidiaryCount;
        @AuraEnabled public Integer uncoveredEntityCount;
        @AuraEnabled public Integer externalSubsidiariesFound;
        @AuraEnabled public Integer activeProductCount;
        @AuraEnabled public Integer openOpportunityCount;
        @AuraEnabled public Decimal engagementIntensityScore;
        @AuraEnabled public String engagementLabel;
        @AuraEnabled public Decimal crossSellPropensity;
        @AuraEnabled public Decimal competitorRiskSignal;
        @AuraEnabled public Decimal healthScore;
        @AuraEnabled public Boolean coverageGapFlag;
        @AuraEnabled public Boolean externallyValidated;
        @AuraEnabled public String aiNarrative;
        @AuraEnabled public String modelId;
        @AuraEnabled public String promptVersion;
        @AuraEnabled public Integer citationCount;
        @AuraEnabled public String enrichmentRunId;
        @AuraEnabled public String lastSyncedTimestamp;
        @AuraEnabled public String aiNarrativeGeneratedAt;
        @AuraEnabled public String lastEngagementTimestamp;
        @AuraEnabled public String freshnessLabel;
        @AuraEnabled public String freshnessTone;
        @AuraEnabled public String hierarchyNote;
        @AuraEnabled public Boolean hierarchyReady;
        @AuraEnabled public List<HierarchyEntity> hierarchyEntities = new List<HierarchyEntity>();
        @AuraEnabled public ActionPack primaryAction;
        @AuraEnabled public List<ActionPack> secondaryActions = new List<ActionPack>();
    }

    private class SellerPlayDefinition {
        String matchKeyword;
        String targetEntityHint;
        String solutionFamily;
        String recommendedPlay;
        String specialistRoute;
        String buyingGroupGap;
        String outreachObjective;
        Integer matchPriority;
    }

    @TestVisible
    private static List<SellerPlayDefinition> cachedDefinitions;

    @AuraEnabled(cacheable=true)
    public static WorkspaceResult getSellerWorkspace(Id accountId) {
        if (accountId == null) {
            throw new AuraHandledException('Account Id is required.');
        }

        Account accountRecord = [
            SELECT
                Id,
                Name,
                BillingCountry,
                Primary_Brand_Name__c,
                External_Legal_Name__c,
                Group_Revenue_Rollup__c,
                Group_Revenue_Visible__c,
                Group_Known_Subsidiary_Count__c,
                CRM_Covered_Subsidiary_Count__c,
                External_Subsidiaries_Found__c,
                Active_Product_Count__c,
                Open_Opportunity_Count__c,
                Engagement_Intensity_Score__c,
                Cross_Sell_Propensity__c,
                Competitor_Risk_Signal__c,
                Health_Score__c,
                Coverage_Gap_Flag__c,
                Externally_Validated__c,
                Last_Engagement_Timestamp__c,
                DataCloud_Last_Synced__c,
                AI_Narrative__c,
                AI_Model_Id__c,
                AI_Prompt_Version__c,
                AI_Citation_Count__c,
                AI_Narrative_Generated__c,
                Enrichment_Run_Id__c,
                AI_Recommended_Actions__c,
                AI_Source_Refs__c,
                Hierarchy_Payload__c
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];

        Map<String, SourceRef> sourceRefIndex = parseSourceRefIndex(accountRecord.AI_Source_Refs__c);
        List<ActionPack> actionPacks = parseActionPacks(accountRecord.AI_Recommended_Actions__c, sourceRefIndex);
        List<HierarchyEntity> hierarchyEntities = parseHierarchy(accountRecord.Hierarchy_Payload__c, accountRecord.Name);

        WorkspaceResult result = new WorkspaceResult();
        result.accountId = accountRecord.Id;
        result.accountName = accountRecord.Name;
        result.primaryBrandName = accountRecord.Primary_Brand_Name__c;
        result.externalLegalName = accountRecord.External_Legal_Name__c;
        result.currencyCode = currencyCodeForCountry(accountRecord.BillingCountry);
        result.groupRevenueRollup = accountRecord.Group_Revenue_Rollup__c;
        result.groupRevenueVisible = accountRecord.Group_Revenue_Visible__c;
        result.hiddenRevenue = hiddenRevenue(accountRecord.Group_Revenue_Rollup__c, accountRecord.Group_Revenue_Visible__c);
        result.groupKnownSubsidiaryCount = integerValue(accountRecord.Group_Known_Subsidiary_Count__c);
        result.crmCoveredSubsidiaryCount = integerValue(accountRecord.CRM_Covered_Subsidiary_Count__c);
        Integer uncoveredCount = result.groupKnownSubsidiaryCount - result.crmCoveredSubsidiaryCount;
        result.uncoveredEntityCount = uncoveredCount > 0 ? uncoveredCount : 0;
        result.externalSubsidiariesFound = integerValue(accountRecord.External_Subsidiaries_Found__c);
        result.activeProductCount = integerValue(accountRecord.Active_Product_Count__c);
        result.openOpportunityCount = integerValue(accountRecord.Open_Opportunity_Count__c);
        result.engagementIntensityScore = accountRecord.Engagement_Intensity_Score__c;
        result.engagementLabel = engagementLabel(accountRecord.Engagement_Intensity_Score__c, accountRecord.Last_Engagement_Timestamp__c);
        result.crossSellPropensity = accountRecord.Cross_Sell_Propensity__c;
        result.competitorRiskSignal = accountRecord.Competitor_Risk_Signal__c;
        result.healthScore = accountRecord.Health_Score__c;
        result.coverageGapFlag = accountRecord.Coverage_Gap_Flag__c;
        result.externallyValidated = accountRecord.Externally_Validated__c;
        result.aiNarrative = accountRecord.AI_Narrative__c;
        result.modelId = accountRecord.AI_Model_Id__c;
        result.promptVersion = accountRecord.AI_Prompt_Version__c;
        result.citationCount = integerValue(accountRecord.AI_Citation_Count__c);
        result.enrichmentRunId = accountRecord.Enrichment_Run_Id__c;
        result.lastSyncedTimestamp = datetimeValue(accountRecord.DataCloud_Last_Synced__c);
        result.aiNarrativeGeneratedAt = datetimeValue(accountRecord.AI_Narrative_Generated__c);
        result.lastEngagementTimestamp = datetimeValue(accountRecord.Last_Engagement_Timestamp__c);
        result.freshnessLabel = freshnessLabel(accountRecord.DataCloud_Last_Synced__c, accountRecord.AI_Narrative_Generated__c);
        result.freshnessTone = freshnessTone(accountRecord.DataCloud_Last_Synced__c, accountRecord.AI_Narrative_Generated__c);
        result.hierarchyEntities = hierarchyEntities;
        result.hierarchyReady = !String.isBlank(accountRecord.Hierarchy_Payload__c) && hierarchyEntities.size() > 1;
        result.hierarchyNote = hierarchyNote(result.hierarchyReady, hierarchyEntities.size(), result.groupKnownSubsidiaryCount);

        if (!actionPacks.isEmpty()) {
            result.primaryAction = actionPacks[0];
            if (actionPacks.size() > 1) {
                for (Integer index = 1; index < actionPacks.size(); index++) {
                    result.secondaryActions.add(actionPacks[index]);
                }
            }
        }

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

    private static String engagementLabel(Decimal engagementScore, Datetime lastEngagementTimestamp) {
        Decimal score = engagementScore == null ? 0 : engagementScore;
        Integer daysSinceEngagement = daysSince(lastEngagementTimestamp);

        if (score >= 75 && daysSinceEngagement != null && daysSinceEngagement <= 30) {
            return 'Active momentum';
        }
        if (score >= 50 || (daysSinceEngagement != null && daysSinceEngagement <= 90)) {
            return 'Watch this account';
        }
        return 'Low momentum';
    }

    private static String freshnessLabel(Datetime lastSyncedTimestamp, Datetime aiNarrativeGeneratedAt) {
        Integer syncDays = daysSince(lastSyncedTimestamp);
        Integer narrativeDays = daysSince(aiNarrativeGeneratedAt);
        Integer comparisonDays = minPositive(syncDays, narrativeDays);

        if (comparisonDays == null) {
            return 'Freshness unknown';
        }
        if (comparisonDays <= 7) {
            return 'Fresh';
        }
        if (comparisonDays <= 30) {
            return 'Monitor freshness';
        }
        return 'Refresh recommended';
    }

    private static String freshnessTone(Datetime lastSyncedTimestamp, Datetime aiNarrativeGeneratedAt) {
        Integer syncDays = daysSince(lastSyncedTimestamp);
        Integer narrativeDays = daysSince(aiNarrativeGeneratedAt);
        Integer comparisonDays = minPositive(syncDays, narrativeDays);

        if (comparisonDays == null || comparisonDays <= 7) {
            return 'fresh';
        }
        if (comparisonDays <= 30) {
            return 'warning';
        }
        return 'stale';
    }

    private static Integer minPositive(Integer left, Integer right) {
        if (left == null) {
            return right;
        }
        if (right == null) {
            return left;
        }
        return Math.min(left, right);
    }

    private static Integer daysSince(Datetime timestamp) {
        if (timestamp == null) {
            return null;
        }
        Long millisBetween = Datetime.now().getTime() - timestamp.getTime();
        if (millisBetween < 0) {
            return 0;
        }
        return Integer.valueOf(String.valueOf(millisBetween / (1000L * 60L * 60L * 24L)));
    }

    private static String hierarchyNote(Boolean hierarchyReady, Integer parsedEntityCount, Integer knownEntityCount) {
        if (!hierarchyReady) {
            return 'Group coverage is visible, but the full hierarchy payload has not been synchronized into CRM yet.';
        }
        if (knownEntityCount > parsedEntityCount) {
            return 'The hierarchy payload is partially available. Additional group entities are still implied by the coverage metrics.';
        }
        return 'Pulse360 has enough hierarchy context to guide group whitespace and coverage review on this account.';
    }

    private static Map<String, SourceRef> parseSourceRefIndex(String payload) {
        Map<String, SourceRef> refsById = new Map<String, SourceRef>();
        if (String.isBlank(payload)) {
            return refsById;
        }

        Object rawPayload;
        try {
            rawPayload = JSON.deserializeUntyped(payload);
        } catch (Exception ex) {
            return refsById;
        }

        if (!(rawPayload instanceof List<Object>)) {
            return refsById;
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
            if (!String.isBlank(ref.sourceId)) {
                refsById.put(ref.sourceId, ref);
            }
        }

        return refsById;
    }

    private static List<ActionPack> parseActionPacks(String payload, Map<String, SourceRef> sourceRefIndex) {
        List<ActionPack> actions = new List<ActionPack>();
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

        List<SellerPlayDefinition> playDefinitions = playDefinitions();

        for (Object item : (List<Object>)rawPayload) {
            if (!(item instanceof Map<String, Object>)) {
                continue;
            }

            Map<String, Object> actionMap = (Map<String, Object>)item;
            ActionPack action = new ActionPack();
            action.rank = integerFromObject(actionMap.get('rank'));
            action.actionType = stringFromObject(actionMap.get('action_type'));
            action.target = stringFromObject(actionMap.get('target'));
            action.targetRecordId = stringFromObject(actionMap.get('target_record_id'));
            action.reasoning = stringFromObject(actionMap.get('reasoning'));
            action.estimatedRevenueImpact = stringFromObject(actionMap.get('estimated_revenue_impact'));
            action.confidence = decimalFromObject(actionMap.get('confidence'));
            action.confidenceLabel = confidenceLabel(action.confidence);
            action.buttonLabel = buttonLabel(action.actionType);

            Object rawSourceIds = actionMap.get('source_ids');
            if (rawSourceIds instanceof List<Object>) {
                for (Object sourceId : (List<Object>)rawSourceIds) {
                    String normalizedSourceId = sourceId == null ? null : String.valueOf(sourceId);
                    if (String.isBlank(normalizedSourceId)) {
                        continue;
                    }
                    action.sourceIds.add(normalizedSourceId);
                    if (sourceRefIndex.containsKey(normalizedSourceId)) {
                        action.supportingSources.add(sourceRefIndex.get(normalizedSourceId));
                    }
                }
            }

            SellerPlayDefinition matchedPlay = matchedPlayDefinition(action, playDefinitions);
            action.targetEntity = matchedPlay != null && !String.isBlank(matchedPlay.targetEntityHint)
                ? matchedPlay.targetEntityHint
                : action.target;
            action.solutionFamily = matchedPlay != null && !String.isBlank(matchedPlay.solutionFamily)
                ? matchedPlay.solutionFamily
                : fallbackSolutionFamily(action.actionType);
            action.recommendedPlay = matchedPlay != null && !String.isBlank(matchedPlay.recommendedPlay)
                ? matchedPlay.recommendedPlay
                : action.target;
            action.specialistRoute = matchedPlay != null && !String.isBlank(matchedPlay.specialistRoute)
                ? matchedPlay.specialistRoute
                : 'Account Team';
            action.buyingGroupGap = matchedPlay != null && !String.isBlank(matchedPlay.buyingGroupGap)
                ? matchedPlay.buyingGroupGap
                : 'Confirm sponsor, economic buyer, and technical owner coverage.';
            action.outreachObjective = matchedPlay != null && !String.isBlank(matchedPlay.outreachObjective)
                ? matchedPlay.outreachObjective
                : fallbackOutreachObjective(action.reasoning);

            actions.add(action);
        }

        return actions;
    }

    private static List<HierarchyEntity> parseHierarchy(String payload, String currentAccountName) {
        List<HierarchyEntity> entities = new List<HierarchyEntity>();
        Set<String> seenNames = new Set<String>();

        if (!String.isBlank(currentAccountName)) {
            HierarchyEntity current = new HierarchyEntity();
            current.entityId = null;
            current.crmRecordId = null;
            current.entityName = currentAccountName;
            current.entityRole = 'Current account';
            current.coverageStatus = 'covered';
            current.coverageLabel = 'CRM anchor';
            current.inCrm = true;
            current.isCurrentAccount = true;
            entities.add(current);
            seenNames.add(currentAccountName.toLowerCase());
        }

        if (String.isBlank(payload)) {
            return entities;
        }

        Object rawPayload;
        try {
            rawPayload = JSON.deserializeUntyped(payload);
        } catch (Exception ex) {
            return entities;
        }

        if (!(rawPayload instanceof Map<String, Object>)) {
            return entities;
        }

        Map<String, Object> hierarchyMap = (Map<String, Object>)rawPayload;
        Object children = hierarchyMap.get('children');
        if (!(children instanceof List<Object>)) {
            return entities;
        }

        for (Object child : (List<Object>)children) {
            if (!(child instanceof Map<String, Object>)) {
                continue;
            }

            Map<String, Object> childMap = (Map<String, Object>)child;
            String entityName = stringFromObject(childMap.get('name'));
            if (String.isBlank(entityName)) {
                continue;
            }

            String normalizedName = entityName.toLowerCase();
            Boolean inCrm = booleanFromObject(childMap.get('in_crm'));
            String coverageStatus = normalizeCoverageStatus(stringFromObject(childMap.get('coverage_status')), inCrm);
            String entityRole = stringFromObject(childMap.get('role'));
            String signal = stringFromObject(childMap.get('signal'));
            String suggestedPlay = stringFromObject(childMap.get('suggested_play'));

            if (seenNames.contains(normalizedName)) {
                if (!entities.isEmpty() && entities[0].entityName != null && entities[0].entityName.toLowerCase() == normalizedName) {
                    HierarchyEntity currentEntity = entities[0];
                    currentEntity.entityId = stringFromObject(childMap.get('entity_id'));
                    currentEntity.crmRecordId = hierarchyCrmRecordId(childMap);
                    currentEntity.entityRole = String.isBlank(entityRole) ? currentEntity.entityRole : entityRole;
                    currentEntity.coverageStatus = coverageStatus;
                    currentEntity.coverageLabel = coverageLabel(coverageStatus, true);
                    currentEntity.inCrm = inCrm == null ? true : inCrm;
                    currentEntity.signal = signal;
                    currentEntity.suggestedPlay = suggestedPlay;
                }
                continue;
            }

            HierarchyEntity entity = new HierarchyEntity();
            entity.entityId = stringFromObject(childMap.get('entity_id'));
            entity.crmRecordId = hierarchyCrmRecordId(childMap);
            entity.entityName = entityName;
            entity.entityRole = String.isBlank(entityRole) ? 'Known group entity' : entityRole;
            entity.coverageStatus = coverageStatus;
            entity.coverageLabel = coverageLabel(coverageStatus, false);
            entity.inCrm = inCrm;
            entity.signal = signal;
            entity.suggestedPlay = suggestedPlay;
            entity.isCurrentAccount = false;
            entities.add(entity);
            seenNames.add(normalizedName);
        }

        return entities;
    }

    private static String hierarchyCrmRecordId(Map<String, Object> childMap) {
        String crmRecordId = stringFromObject(childMap.get('crm_record_id'));
        if (!String.isBlank(crmRecordId)) {
            return crmRecordId;
        }
        return stringFromObject(childMap.get('target_record_id'));
    }

    private static String normalizeCoverageStatus(String rawStatus, Boolean inCrm) {
        if (String.isBlank(rawStatus)) {
            if (inCrm == true) {
                return 'covered';
            }
            if (inCrm == false) {
                return 'uncovered';
            }
            return 'known';
        }

        String normalized = rawStatus.trim().toLowerCase();
        if (normalized.contains('duplicate')) {
            return 'duplicate';
        }
        if (normalized.contains('uncovered') || normalized.contains('white')) {
            return 'uncovered';
        }
        if (normalized.contains('cover')) {
            return 'covered';
        }
        return normalized;
    }

    private static String coverageLabel(String coverageStatus, Boolean isCurrentAccount) {
        if (coverageStatus == 'duplicate') {
            return 'Duplicate in CRM';
        }
        if (coverageStatus == 'uncovered') {
            return 'Whitespace target';
        }
        if (coverageStatus == 'covered' && isCurrentAccount) {
            return 'CRM anchor';
        }
        if (coverageStatus == 'covered') {
            return 'CRM-covered';
        }
        return 'Known entity';
    }

    private static List<SellerPlayDefinition> playDefinitions() {
        if (cachedDefinitions != null) {
            return cachedDefinitions;
        }

        cachedDefinitions = new List<SellerPlayDefinition>();
        for (Pulse360_Seller_Play__mdt record : [
            SELECT
                DeveloperName,
                MasterLabel,
                Match_Keyword__c,
                Target_Entity_Hint__c,
                Solution_Family__c,
                Recommended_Play__c,
                Specialist_Route__c,
                Buying_Group_Gap__c,
                Outreach_Objective__c,
                Match_Priority__c
            FROM Pulse360_Seller_Play__mdt
            ORDER BY Match_Priority__c DESC NULLS LAST, DeveloperName ASC
        ]) {
            SellerPlayDefinition definition = new SellerPlayDefinition();
            definition.matchKeyword = record.Match_Keyword__c == null ? null : record.Match_Keyword__c.toLowerCase();
            definition.targetEntityHint = record.Target_Entity_Hint__c;
            definition.solutionFamily = record.Solution_Family__c;
            definition.recommendedPlay = record.Recommended_Play__c;
            definition.specialistRoute = record.Specialist_Route__c;
            definition.buyingGroupGap = record.Buying_Group_Gap__c;
            definition.outreachObjective = record.Outreach_Objective__c;
            definition.matchPriority = record.Match_Priority__c == null ? 0 : record.Match_Priority__c.intValue();
            cachedDefinitions.add(definition);
        }

        return cachedDefinitions;
    }

    private static SellerPlayDefinition matchedPlayDefinition(ActionPack action, List<SellerPlayDefinition> playDefinitions) {
        String matchText = ((action.target == null ? '' : action.target) + ' ' + (action.reasoning == null ? '' : action.reasoning)).toLowerCase();
        for (SellerPlayDefinition definition : playDefinitions) {
            if (!String.isBlank(definition.matchKeyword) && matchText.contains(definition.matchKeyword)) {
                return definition;
            }
        }
        return null;
    }

    private static String fallbackSolutionFamily(String actionType) {
        if (actionType == 'create_opportunity') {
            return 'Growth Whitespace';
        }
        if (actionType == 'escalate_governance') {
            return 'Governance Resolution';
        }
        return 'Account Coverage';
    }

    private static String fallbackOutreachObjective(String reasoning) {
        if (String.isBlank(reasoning)) {
            return 'Confirm the opportunity, sponsor, and next review needed to move this account forward.';
        }
        return reasoning.length() > 180 ? reasoning.substring(0, 180) + '…' : reasoning;
    }

    private static String buttonLabel(String actionType) {
        switch on actionType {
            when 'create_opportunity' {
                return 'Create Opportunity';
            }
            when 'create_task' {
                return 'Create Task';
            }
            when 'investigate_subsidiary' {
                return 'Create Task';
            }
            when 'escalate_governance' {
                return 'Open Governance';
            }
            when else {
                return 'Open Follow-up';
            }
        }
    }

    private static String confidenceLabel(Decimal confidence) {
        if (confidence == null) {
            return 'Confidence unknown';
        }
        if (confidence >= 0.8) {
            return 'High confidence';
        }
        if (confidence >= 0.65) {
            return 'Moderate confidence';
        }
        return 'Use caution';
    }

    private static String stringFromObject(Object value) {
        return value == null ? null : String.valueOf(value);
    }

    private static Boolean booleanFromObject(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof Boolean) {
            return (Boolean)value;
        }

        String normalized = String.valueOf(value).trim().toLowerCase();
        if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
            return true;
        }
        if (normalized == 'false' || normalized == '0' || normalized == 'no') {
            return false;
        }
        return null;
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
