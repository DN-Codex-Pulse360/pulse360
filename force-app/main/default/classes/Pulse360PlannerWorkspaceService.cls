public with sharing class Pulse360PlannerWorkspaceService {
    public class PlannerMetric {
        @AuraEnabled public String key;
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public String helperText;
        @AuraEnabled public String tone;
    }

    public class PlanningAction {
        @AuraEnabled public Id accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public String actionLabel;
        @AuraEnabled public String reason;
        @AuraEnabled public String priorityLabel;
        @AuraEnabled public String tone;
    }

    public class PlannerTimelineEvent implements Comparable {
        @AuraEnabled public String key;
        @AuraEnabled public Id accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public String title;
        @AuraEnabled public String detail;
        @AuraEnabled public String typeLabel;
        @AuraEnabled public String tone;
        @AuraEnabled public Datetime eventTimestamp;

        public Integer compareTo(Object comparisonTarget) {
            PlannerTimelineEvent otherEvent = (PlannerTimelineEvent)comparisonTarget;
            if (eventTimestamp == otherEvent.eventTimestamp) {
                return 0;
            }
            if (eventTimestamp == null) {
                return 1;
            }
            if (otherEvent.eventTimestamp == null) {
                return -1;
            }
            Long thisMillis = eventTimestamp.getTime();
            Long otherMillis = otherEvent.eventTimestamp.getTime();
            if (thisMillis == otherMillis) {
                return 0;
            }
            return thisMillis > otherMillis ? -1 : 1;
        }
    }

    public class PortfolioGroup {
        @AuraEnabled public Id accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public String primaryBrandName;
        @AuraEnabled public String currencyCode;
        @AuraEnabled public Decimal groupRevenueRollup;
        @AuraEnabled public Decimal groupRevenueVisible;
        @AuraEnabled public Decimal hiddenRevenue;
        @AuraEnabled public Integer groupKnownSubsidiaryCount;
        @AuraEnabled public Integer crmCoveredSubsidiaryCount;
        @AuraEnabled public Integer uncoveredEntityCount;
        @AuraEnabled public Decimal coveragePercent;
        @AuraEnabled public Integer openOpportunityCount;
        @AuraEnabled public Decimal crossSellPropensity;
        @AuraEnabled public Decimal competitorRiskSignal;
        @AuraEnabled public Decimal healthScore;
        @AuraEnabled public Boolean coverageGapFlag;
        @AuraEnabled public Boolean externallyValidated;
        @AuraEnabled public String freshnessLabel;
        @AuraEnabled public String freshnessTone;
        @AuraEnabled public Datetime dataCloudSyncedAt;
        @AuraEnabled public Datetime aiNarrativeGeneratedAt;
        @AuraEnabled public Datetime lastUpdatedAt;
        @AuraEnabled public String priorityBand;
        @AuraEnabled public Decimal priorityScore;
        @AuraEnabled public String priorityReason;
        @AuraEnabled public String nextPlanningAction;
        @AuraEnabled public String suggestedTier;
        @AuraEnabled public String whitespaceSummary;
        @AuraEnabled public String riskSummary;
        @AuraEnabled public String executivePrompt;
        @AuraEnabled public String topUncoveredEntity;
    }

    public class WorkspaceResult {
        @AuraEnabled public String title;
        @AuraEnabled public String summary;
        @AuraEnabled public String highlightedInsight;
        @AuraEnabled public String highlightedAction;
        @AuraEnabled public List<PlannerMetric> metrics = new List<PlannerMetric>();
        @AuraEnabled public List<PlanningAction> actionQueue = new List<PlanningAction>();
        @AuraEnabled public List<PlannerTimelineEvent> timeline = new List<PlannerTimelineEvent>();
        @AuraEnabled public List<PortfolioGroup> groups = new List<PortfolioGroup>();
    }

    private class HierarchyHint {
        String firstUncoveredName;
    }

    @AuraEnabled(cacheable=true)
    public static WorkspaceResult getPlannerWorkspace(Integer requestedLimit) {
        Integer portfolioLimit = normalizeLimit(requestedLimit);
        Integer queryLimit = Math.min(portfolioLimit * 3, 40);

        List<Account> accountRecords = [
            SELECT
                Id,
                Name,
                BillingCountry,
                Primary_Brand_Name__c,
                Group_Revenue_Rollup__c,
                Group_Revenue_Visible__c,
                Group_Known_Subsidiary_Count__c,
                CRM_Covered_Subsidiary_Count__c,
                Open_Opportunity_Count__c,
                Cross_Sell_Propensity__c,
                Competitor_Risk_Signal__c,
                Health_Score__c,
                Coverage_Gap_Flag__c,
                Externally_Validated__c,
                DataCloud_Last_Synced__c,
                AI_Narrative_Generated__c,
                Hierarchy_Payload__c,
                LastModifiedDate
            FROM Account
            WHERE
                Group_Revenue_Rollup__c != null
                OR Coverage_Gap_Flag__c = true
                OR Cross_Sell_Propensity__c != null
                OR Competitor_Risk_Signal__c != null
                OR Health_Score__c != null
            ORDER BY Group_Revenue_Rollup__c DESC NULLS LAST, LastModifiedDate DESC
            LIMIT :queryLimit
        ];

        List<PortfolioGroup> rankedGroups = new List<PortfolioGroup>();
        for (Account accountRecord : accountRecords) {
            rankedGroups.add(buildPortfolioGroup(accountRecord));
        }
        sortGroupsByPriority(rankedGroups);

        if (rankedGroups.size() > portfolioLimit) {
            List<PortfolioGroup> trimmedGroups = new List<PortfolioGroup>();
            for (Integer index = 0; index < portfolioLimit; index++) {
                trimmedGroups.add(rankedGroups[index]);
            }
            rankedGroups = trimmedGroups;
        }

        WorkspaceResult result = new WorkspaceResult();
        result.title = 'Pulse360 Planner Workspace';
        result.summary = 'Rank commercial groups by hidden value, coverage quality, whitespace readiness, and risk before territory or QBR decisions.';
        result.groups = rankedGroups;
        result.metrics = buildMetrics(rankedGroups);
        result.actionQueue = buildActionQueue(rankedGroups);
        result.timeline = buildTimeline(rankedGroups);
        result.highlightedInsight = highlightedInsight(rankedGroups);
        result.highlightedAction = highlightedAction(rankedGroups);
        return result;
    }

    private static Integer normalizeLimit(Integer requestedLimit) {
        if (requestedLimit == null || requestedLimit < 4) {
            return 12;
        }
        return Math.min(requestedLimit, 20);
    }

    private static PortfolioGroup buildPortfolioGroup(Account accountRecord) {
        PortfolioGroup portfolioGroup = new PortfolioGroup();
        portfolioGroup.accountId = accountRecord.Id;
        portfolioGroup.accountName = accountRecord.Name;
        portfolioGroup.primaryBrandName = accountRecord.Primary_Brand_Name__c;
        portfolioGroup.currencyCode = currencyCodeForCountry(accountRecord.BillingCountry);
        portfolioGroup.groupRevenueRollup = accountRecord.Group_Revenue_Rollup__c == null ? 0 : accountRecord.Group_Revenue_Rollup__c;
        portfolioGroup.groupRevenueVisible = accountRecord.Group_Revenue_Visible__c == null ? 0 : accountRecord.Group_Revenue_Visible__c;
        portfolioGroup.hiddenRevenue = hiddenRevenue(portfolioGroup.groupRevenueRollup, portfolioGroup.groupRevenueVisible);
        portfolioGroup.groupKnownSubsidiaryCount = integerValue(accountRecord.Group_Known_Subsidiary_Count__c);
        portfolioGroup.crmCoveredSubsidiaryCount = integerValue(accountRecord.CRM_Covered_Subsidiary_Count__c);
        portfolioGroup.uncoveredEntityCount = uncoveredCount(portfolioGroup.groupKnownSubsidiaryCount, portfolioGroup.crmCoveredSubsidiaryCount);
        portfolioGroup.coveragePercent = coveragePercent(portfolioGroup.groupKnownSubsidiaryCount, portfolioGroup.crmCoveredSubsidiaryCount);
        portfolioGroup.openOpportunityCount = integerValue(accountRecord.Open_Opportunity_Count__c);
        portfolioGroup.crossSellPropensity = safeDecimal(accountRecord.Cross_Sell_Propensity__c);
        portfolioGroup.competitorRiskSignal = safeDecimal(accountRecord.Competitor_Risk_Signal__c);
        portfolioGroup.healthScore = safeDecimal(accountRecord.Health_Score__c);
        portfolioGroup.coverageGapFlag = accountRecord.Coverage_Gap_Flag__c == true;
        portfolioGroup.externallyValidated = accountRecord.Externally_Validated__c == true;
        portfolioGroup.dataCloudSyncedAt = accountRecord.DataCloud_Last_Synced__c;
        portfolioGroup.aiNarrativeGeneratedAt = accountRecord.AI_Narrative_Generated__c;
        portfolioGroup.lastUpdatedAt = accountRecord.LastModifiedDate;
        portfolioGroup.freshnessLabel = freshnessLabel(accountRecord.DataCloud_Last_Synced__c, accountRecord.AI_Narrative_Generated__c);
        portfolioGroup.freshnessTone = freshnessTone(accountRecord.DataCloud_Last_Synced__c, accountRecord.AI_Narrative_Generated__c);

        HierarchyHint hierarchyDetails = hierarchyHint(accountRecord.Hierarchy_Payload__c);
        portfolioGroup.topUncoveredEntity = hierarchyDetails.firstUncoveredName;

        portfolioGroup.priorityScore = priorityScore(portfolioGroup);
        portfolioGroup.priorityBand = priorityBand(portfolioGroup.priorityScore);
        portfolioGroup.suggestedTier = suggestedTier(portfolioGroup);
        portfolioGroup.priorityReason = priorityReason(portfolioGroup);
        portfolioGroup.nextPlanningAction = nextPlanningAction(portfolioGroup);
        portfolioGroup.whitespaceSummary = whitespaceSummary(portfolioGroup);
        portfolioGroup.riskSummary = riskSummary(portfolioGroup);
        portfolioGroup.executivePrompt = executivePrompt(portfolioGroup);
        return portfolioGroup;
    }

    private static List<PlannerMetric> buildMetrics(List<PortfolioGroup> rankedGroups) {
        Integer coverageGapCount = 0;
        Integer whitespaceReadyCount = 0;
        Integer executiveFocusCount = 0;
        Integer validationGapCount = 0;

        for (PortfolioGroup portfolioGroup : rankedGroups) {
            if (portfolioGroup.coverageGapFlag || portfolioGroup.uncoveredEntityCount > 0) {
                coverageGapCount++;
            }
            if (portfolioGroup.crossSellPropensity >= 65 || portfolioGroup.hiddenRevenue >= 100000000) {
                whitespaceReadyCount++;
            }
            if (portfolioGroup.priorityScore >= 85) {
                executiveFocusCount++;
            }
            if (!portfolioGroup.externallyValidated) {
                validationGapCount++;
            }
        }

        return new List<PlannerMetric>{
            metric('portfolio', 'Groups under review', String.valueOf(rankedGroups.size()), 'Ranked groups currently surfaced in the planner workspace.', 'neutral'),
            metric('coverage', 'Coverage gaps', String.valueOf(coverageGapCount), 'Groups that still need owner or subsidiary coverage decisions.', coverageGapCount > 0 ? 'warning' : 'positive'),
            metric('whitespace', 'Whitespace-ready', String.valueOf(whitespaceReadyCount), 'Groups where hidden value or high propensity justify planning attention now.', whitespaceReadyCount > 0 ? 'accent' : 'neutral'),
            metric('validation', 'Needs validation', String.valueOf(validationGapCount), 'Groups whose current view still needs stronger external confirmation.', validationGapCount > 0 ? 'warning' : 'positive'),
            metric('executive', 'Executive focus', String.valueOf(executiveFocusCount), 'Groups that deserve leadership review in the next planning cycle.', executiveFocusCount > 0 ? 'negative' : 'neutral')
        };
    }

    private static PlannerMetric metric(String key, String label, String value, String helperText, String tone) {
        PlannerMetric item = new PlannerMetric();
        item.key = key;
        item.label = label;
        item.value = value;
        item.helperText = helperText;
        item.tone = tone;
        return item;
    }

    private static List<PlanningAction> buildActionQueue(List<PortfolioGroup> rankedGroups) {
        List<PlanningAction> queue = new List<PlanningAction>();
        Integer queueLimit = Math.min(rankedGroups.size(), 5);
        for (Integer index = 0; index < queueLimit; index++) {
            PortfolioGroup portfolioGroup = rankedGroups[index];
            PlanningAction item = new PlanningAction();
            item.accountId = portfolioGroup.accountId;
            item.accountName = portfolioGroup.accountName;
            item.actionLabel = portfolioGroup.nextPlanningAction;
            item.reason = portfolioGroup.priorityReason;
            item.priorityLabel = portfolioGroup.priorityBand;
            item.tone = toneForGroup(portfolioGroup);
            queue.add(item);
        }
        return queue;
    }

    private static List<PlannerTimelineEvent> buildTimeline(List<PortfolioGroup> rankedGroups) {
        List<PlannerTimelineEvent> events = new List<PlannerTimelineEvent>();
        for (PortfolioGroup portfolioGroup : rankedGroups) {
            if (portfolioGroup.dataCloudSyncedAt != null) {
                events.add(timelineEvent(
                    portfolioGroup,
                    'sync',
                    'Data Cloud sync refreshed',
                    'Signals for ' + portfolioGroup.accountName + ' were refreshed from Data Cloud and are ready for planning review.',
                    'Signal refresh',
                    portfolioGroup.freshnessTone == 'stale' ? 'warning' : 'positive',
                    portfolioGroup.dataCloudSyncedAt
                ));
            }
            if (portfolioGroup.aiNarrativeGeneratedAt != null) {
                events.add(timelineEvent(
                    portfolioGroup,
                    'brief',
                    'AI planning brief refreshed',
                    'Narrative guidance was regenerated for ' + portfolioGroup.accountName + '.',
                    'AI brief',
                    'accent',
                    portfolioGroup.aiNarrativeGeneratedAt
                ));
            }
            if (!portfolioGroup.externallyValidated) {
                events.add(timelineEvent(
                    portfolioGroup,
                    'validation',
                    'External validation gap remains',
                    'This account still needs stronger external confirmation before it becomes leadership-ready.',
                    'Validation',
                    'warning',
                    portfolioGroup.lastUpdatedAt
                ));
            }
            if (portfolioGroup.competitorRiskSignal >= 70 || portfolioGroup.healthScore <= 45) {
                events.add(timelineEvent(
                    portfolioGroup,
                    'risk',
                    'Risk watch elevated',
                    portfolioGroup.riskSummary,
                    'Risk watch',
                    'negative',
                    portfolioGroup.lastUpdatedAt
                ));
            }
        }

        events.sort();
        Integer timelineLimit = Math.min(events.size(), 10);
        List<PlannerTimelineEvent> trimmedEvents = new List<PlannerTimelineEvent>();
        for (Integer index = 0; index < timelineLimit; index++) {
            trimmedEvents.add(events[index]);
        }
        return trimmedEvents;
    }

    private static String highlightedInsight(List<PortfolioGroup> rankedGroups) {
        if (rankedGroups.isEmpty()) {
            return 'No ranked groups are available yet. Bring group revenue, coverage, or risk signals into CRM before using the planner workspace.';
        }

        Integer coverageGapCount = 0;
        Integer executiveFocusCount = 0;
        for (PortfolioGroup portfolioGroup : rankedGroups) {
            if (portfolioGroup.coverageGapFlag || portfolioGroup.uncoveredEntityCount > 0) {
                coverageGapCount++;
            }
            if (portfolioGroup.priorityScore >= 85) {
                executiveFocusCount++;
            }
        }

        PortfolioGroup topGroup = rankedGroups[0];
        return coverageGapCount + ' groups still show material coverage gaps, and ' + executiveFocusCount +
            ' should be part of the next leadership review. ' + topGroup.accountName +
            ' is the highest-priority group because ' + lowerFirst(topGroup.priorityReason);
    }

    private static String highlightedAction(List<PortfolioGroup> rankedGroups) {
        if (rankedGroups.isEmpty()) {
            return 'Planner actions will appear once ranked groups are available.';
        }

        PortfolioGroup topGroup = rankedGroups[0];
        return topGroup.nextPlanningAction + ' for ' + topGroup.accountName + '.';
    }

    private static Decimal safeDecimal(Decimal value) {
        return value == null ? 0 : value;
    }

    private static Decimal hiddenRevenue(Decimal totalRevenue, Decimal visibleRevenue) {
        Decimal safeTotal = safeDecimal(totalRevenue);
        Decimal safeVisible = safeDecimal(visibleRevenue);
        Decimal hidden = safeTotal - safeVisible;
        return hidden > 0 ? hidden : 0;
    }

    private static Integer integerValue(Decimal value) {
        return value == null ? 0 : value.intValue();
    }

    private static Integer uncoveredCount(Integer knownCount, Integer coveredCount) {
        Integer uncovered = knownCount - coveredCount;
        return uncovered > 0 ? uncovered : 0;
    }

    private static Decimal coveragePercent(Integer knownCount, Integer coveredCount) {
        if (knownCount == 0) {
            return 0;
        }
        return Decimal.valueOf(Math.round((Decimal.valueOf(coveredCount) / Decimal.valueOf(knownCount)) * 100));
    }

    private static Decimal priorityScore(PortfolioGroup portfolioGroup) {
        Decimal score = 0;
        score += Math.min(portfolioGroup.groupRevenueRollup / 100000000, Decimal.valueOf(35));
        score += Math.min(portfolioGroup.hiddenRevenue / 100000000, Decimal.valueOf(30));
        score += portfolioGroup.coverageGapFlag ? 16 : 0;
        score += Decimal.valueOf(Math.min(portfolioGroup.uncoveredEntityCount * 4, 12));
        score += Math.min(portfolioGroup.crossSellPropensity / 4, Decimal.valueOf(22));
        score += Math.min(portfolioGroup.competitorRiskSignal / 6, Decimal.valueOf(12));
        score += Math.min((Decimal.valueOf(100) - portfolioGroup.healthScore) / 5, Decimal.valueOf(12));
        score += portfolioGroup.externallyValidated ? 3 : 0;
        return score.setScale(1);
    }

    private static String priorityBand(Decimal priorityScore) {
        if (priorityScore >= 90) {
            return 'Executive now';
        }
        if (priorityScore >= 70) {
            return 'Plan this cycle';
        }
        if (priorityScore >= 45) {
            return 'Monitor closely';
        }
        return 'Watchlist';
    }

    private static String suggestedTier(PortfolioGroup portfolioGroup) {
        if (portfolioGroup.groupRevenueRollup >= 1000000000 || portfolioGroup.hiddenRevenue >= 250000000) {
            return 'Strategic';
        }
        if (portfolioGroup.groupRevenueRollup >= 250000000 || portfolioGroup.crossSellPropensity >= 70) {
            return 'Priority growth';
        }
        return 'Portfolio monitor';
    }

    private static String priorityReason(PortfolioGroup portfolioGroup) {
        if (portfolioGroup.coverageGapFlag && portfolioGroup.hiddenRevenue >= 100000000) {
            return 'material group value still sits outside visible CRM coverage';
        }
        if (portfolioGroup.crossSellPropensity >= 75 && portfolioGroup.hiddenRevenue > 0) {
            return 'Pulse360 sees a strong whitespace path with enough hidden group value to change planning';
        }
        if (portfolioGroup.competitorRiskSignal >= 70 || portfolioGroup.healthScore <= 45) {
            return 'risk signals are strong enough to warrant leadership attention';
        }
        if (!portfolioGroup.externallyValidated) {
            return 'the current group view still needs stronger validation before leadership commits';
        }
        return 'the group is commercially meaningful and ready for focused coverage decisions';
    }

    private static String nextPlanningAction(PortfolioGroup portfolioGroup) {
        if (portfolioGroup.coverageGapFlag || portfolioGroup.uncoveredEntityCount > 0) {
            return 'Assign owner to uncovered entities';
        }
        if (portfolioGroup.crossSellPropensity >= 75) {
            return 'Sponsor whitespace review';
        }
        if (portfolioGroup.competitorRiskSignal >= 70 || portfolioGroup.healthScore <= 45) {
            return 'Escalate leadership review';
        }
        if (!portfolioGroup.externallyValidated) {
            return 'Validate group evidence';
        }
        return 'Maintain tier and watch';
    }

    private static String whitespaceSummary(PortfolioGroup portfolioGroup) {
        if (portfolioGroup.hiddenRevenue <= 0 && portfolioGroup.crossSellPropensity < 60) {
            return 'Whitespace is not yet the primary portfolio story for this group.';
        }

        String targetLabel = String.isBlank(portfolioGroup.topUncoveredEntity) ? 'an uncovered entity' : portfolioGroup.topUncoveredEntity;
        return targetLabel + ' sits inside a group with ' + formatCompactCurrency(portfolioGroup.hiddenRevenue, portfolioGroup.currencyCode) +
            ' of hidden value and a whitespace score of ' + integerValue(portfolioGroup.crossSellPropensity) + '.';
    }

    private static String riskSummary(PortfolioGroup portfolioGroup) {
        if (portfolioGroup.competitorRiskSignal >= 70 || portfolioGroup.healthScore <= 45) {
            return 'Risk signals are elevated. Competitive pressure or declining health could affect planning confidence.';
        }
        if (portfolioGroup.healthScore <= 60) {
            return 'Health is mixed, so expansion and coverage decisions should be staged carefully.';
        }
        return 'Risk signals are manageable relative to the current whitespace and coverage story.';
    }

    private static String executivePrompt(PortfolioGroup portfolioGroup) {
        if (portfolioGroup.priorityScore >= 90) {
            return 'Bring this group into the next leadership review and decide whether to re-tier coverage.';
        }
        if (portfolioGroup.priorityScore >= 70) {
            return 'Use this group in the next planning cycle to rebalance ownership or expansion focus.';
        }
        return 'Keep this group visible, but do not let it crowd out higher-urgency planning decisions.';
    }

    private static String toneForGroup(PortfolioGroup portfolioGroup) {
        if (portfolioGroup.priorityScore >= 90 || portfolioGroup.competitorRiskSignal >= 70 || portfolioGroup.healthScore <= 45) {
            return 'negative';
        }
        if (portfolioGroup.coverageGapFlag || !portfolioGroup.externallyValidated) {
            return 'warning';
        }
        if (portfolioGroup.crossSellPropensity >= 75) {
            return 'accent';
        }
        return 'neutral';
    }

    private static HierarchyHint hierarchyHint(String hierarchyPayload) {
        HierarchyHint hierarchyDetails = new HierarchyHint();
        if (String.isBlank(hierarchyPayload)) {
            return hierarchyDetails;
        }

        Object deserialized = JSON.deserializeUntyped(hierarchyPayload);
        if (!(deserialized instanceof Map<String, Object>)) {
            return hierarchyDetails;
        }

        Map<String, Object> payload = (Map<String, Object>)deserialized;
        Object childrenObject = payload.get('children');
        if (!(childrenObject instanceof List<Object>)) {
            return hierarchyDetails;
        }

        for (Object childObject : (List<Object>)childrenObject) {
            if (!(childObject instanceof Map<String, Object>)) {
                continue;
            }
            Map<String, Object> child = (Map<String, Object>)childObject;
            String coverageStatus = stringValue(child.get('coverage_status'));
            Boolean inCrm = booleanValue(child.get('in_crm'));
            if (coverageStatus == 'uncovered' || !inCrm) {
                hierarchyDetails.firstUncoveredName = stringValue(child.get('name'));
                return hierarchyDetails;
            }
        }
        return hierarchyDetails;
    }

    private static PlannerTimelineEvent timelineEvent(
        PortfolioGroup portfolioGroup,
        String eventKeySuffix,
        String title,
        String detail,
        String typeLabel,
        String tone,
        Datetime eventTimestamp
    ) {
        PlannerTimelineEvent item = new PlannerTimelineEvent();
        item.key = portfolioGroup.accountId + '-' + eventKeySuffix;
        item.accountId = portfolioGroup.accountId;
        item.accountName = portfolioGroup.accountName;
        item.title = title;
        item.detail = detail;
        item.typeLabel = typeLabel;
        item.tone = tone;
        item.eventTimestamp = eventTimestamp;
        return item;
    }

    private static String stringValue(Object value) {
        return value == null ? null : String.valueOf(value);
    }

    private static Boolean booleanValue(Object value) {
        if (value == null) {
            return false;
        }
        if (value instanceof Boolean) {
            return (Boolean)value;
        }
        return 'true'.equalsIgnoreCase(String.valueOf(value));
    }

    private static void sortGroupsByPriority(List<PortfolioGroup> groups) {
        for (Integer leftIndex = 0; leftIndex < groups.size(); leftIndex++) {
            for (Integer rightIndex = leftIndex + 1; rightIndex < groups.size(); rightIndex++) {
                PortfolioGroup current = groups[leftIndex];
                PortfolioGroup candidate = groups[rightIndex];
                if (candidate.priorityScore > current.priorityScore) {
                    groups[leftIndex] = candidate;
                    groups[rightIndex] = current;
                }
            }
        }
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
            return 'watch';
        }
        return 'stale';
    }

    private static Integer daysSince(Datetime value) {
        if (value == null) {
            return null;
        }
        Integer dayDelta = value.dateGmt().daysBetween(Date.today());
        return dayDelta < 0 ? 0 : dayDelta;
    }

    private static Integer minPositive(Integer leftValue, Integer rightValue) {
        if (leftValue == null) {
            return rightValue;
        }
        if (rightValue == null) {
            return leftValue;
        }
        return Math.min(leftValue, rightValue);
    }

    private static String formatCompactCurrency(Decimal value, String currencyCode) {
        Decimal safeValue = safeDecimal(value);
        if (safeValue >= 1000000000) {
            return safeValue.divide(1000000000, 1) + 'B ' + currencyCode;
        }
        if (safeValue >= 1000000) {
            return safeValue.divide(1000000, 1) + 'M ' + currencyCode;
        }
        return safeValue.setScale(0) + ' ' + currencyCode;
    }

    private static String lowerFirst(String inputValue) {
        if (String.isBlank(inputValue)) {
            return inputValue;
        }
        return inputValue.substring(0, 1).toLowerCase() + inputValue.substring(1);
    }
}
