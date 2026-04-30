public with sharing class Pulse360SignalRoutingWorkspaceService {
    public class QueueItem implements Comparable {
        @AuraEnabled public Id accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public String ownerName;
        @AuraEnabled public Decimal signalScore;
        @AuraEnabled public String signalLabel;
        @AuraEnabled public String thresholdLabel;
        @AuraEnabled public String routeLabel;
        @AuraEnabled public String freshnessLabel;
        @AuraEnabled public String freshnessTone;
        @AuraEnabled public Boolean payloadBacked;
        @AuraEnabled public String summary;

        public Integer compareTo(Object otherValue) {
            QueueItem otherItem = (QueueItem) otherValue;
            Decimal leftScore = signalScore == null ? 0 : signalScore;
            Decimal rightScore = otherItem.signalScore == null ? 0 : otherItem.signalScore;
            if (leftScore != rightScore) {
                return leftScore > rightScore ? -1 : 1;
            }

            String leftName = accountName == null ? '' : accountName;
            String rightName = otherItem.accountName == null ? '' : otherItem.accountName;
            return leftName.toLowerCase().compareTo(rightName.toLowerCase());
        }
    }

    public class RoutingDriver {
        @AuraEnabled public String key;
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public String copy;
        @AuraEnabled public String tone;
    }

    public class TargetContact {
        @AuraEnabled public Id contactId;
        @AuraEnabled public String contactName;
        @AuraEnabled public String title;
        @AuraEnabled public String department;
        @AuraEnabled public String email;
        @AuraEnabled public String contactLabel;
        @AuraEnabled public String lastTouchedLabel;
        @AuraEnabled public Boolean hasEmail;
    }

    public class SourcePreview {
        @AuraEnabled public String sourceId;
        @AuraEnabled public String sourceName;
        @AuraEnabled public String sourceType;
        @AuraEnabled public String sourceUrl;
    }

    public class ActionPreview {
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
        @AuraEnabled public List<SourcePreview> supportingSources = new List<SourcePreview>();
    }

    public class WorkspaceResult {
        @AuraEnabled public Id accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public String ownerName;
        @AuraEnabled public String currencyCode;
        @AuraEnabled public Decimal hiddenRevenue;
        @AuraEnabled public Decimal signalScore;
        @AuraEnabled public Decimal routingConfidence;
        @AuraEnabled public String confidenceLabel;
        @AuraEnabled public String signalLabel;
        @AuraEnabled public String thresholdLabel;
        @AuraEnabled public String routeLabel;
        @AuraEnabled public String whyNow;
        @AuraEnabled public String draftedOutreach;
        @AuraEnabled public String channelReadiness;
        @AuraEnabled public String payloadModeLabel;
        @AuraEnabled public String provisionalNote;
        @AuraEnabled public String freshnessLabel;
        @AuraEnabled public String freshnessTone;
        @AuraEnabled public Boolean payloadBacked;
        @AuraEnabled public String promptVersion;
        @AuraEnabled public String modelId;
        @AuraEnabled public String contactCoverageNote;
        @AuraEnabled public List<RoutingDriver> topDrivers = new List<RoutingDriver>();
        @AuraEnabled public List<TargetContact> targetContacts = new List<TargetContact>();
        @AuraEnabled public ActionPreview primaryAction;
    }

    private class SignalProfile {
        Decimal signalScore;
        Decimal routingConfidence;
        String signalLabel;
        String thresholdLabel;
        String routeLabel;
        String whyNow;
        String draftedOutreach;
        String channelReadiness;
        String payloadModeLabel;
        String provisionalNote;
        Boolean payloadBacked;
        List<String> topDriverSummaries = new List<String>();
    }

    @AuraEnabled(cacheable=true)
    public static List<QueueItem> getRoutingQueue(Integer requestedLimit) {
        Integer queueLimit = normalizeLimit(requestedLimit);
        List<QueueItem> queueItems = new List<QueueItem>();

        for (Account accountRecord : [
            SELECT
                Id,
                Name,
                Owner.Name,
                Cross_Sell_Propensity__c,
                Engagement_Intensity_Score__c,
                Competitor_Risk_Signal__c,
                Coverage_Gap_Flag__c,
                DataCloud_Last_Synced__c,
                AI_Narrative_Generated__c,
                Intent_Signal_Payload__c
            FROM Account
            WHERE
                Cross_Sell_Propensity__c != null
                OR Engagement_Intensity_Score__c != null
                OR Coverage_Gap_Flag__c = true
                OR DataCloud_Last_Synced__c != null
                OR AI_Narrative_Generated__c != null
            ORDER BY Cross_Sell_Propensity__c DESC NULLS LAST, Engagement_Intensity_Score__c DESC NULLS LAST, LastModifiedDate DESC
            LIMIT :queueLimit
        ]) {
            SignalProfile signalProfile = buildSignalProfile(accountRecord, null);

            QueueItem queueItem = new QueueItem();
            queueItem.accountId = accountRecord.Id;
            queueItem.accountName = accountRecord.Name;
            queueItem.ownerName = accountRecord.Owner == null ? 'Unassigned owner' : accountRecord.Owner.Name;
            queueItem.signalScore = signalProfile.signalScore;
            queueItem.signalLabel = signalProfile.signalLabel;
            queueItem.thresholdLabel = signalProfile.thresholdLabel;
            queueItem.routeLabel = signalProfile.routeLabel;
            queueItem.freshnessLabel = freshnessLabel(accountRecord.DataCloud_Last_Synced__c, accountRecord.AI_Narrative_Generated__c);
            queueItem.freshnessTone = freshnessTone(accountRecord.DataCloud_Last_Synced__c, accountRecord.AI_Narrative_Generated__c);
            queueItem.payloadBacked = signalProfile.payloadBacked;
            queueItem.summary = truncate(signalProfile.whyNow, 150);
            queueItems.add(queueItem);
        }

        queueItems.sort();
        return queueItems;
    }

    @AuraEnabled(cacheable=true)
    public static WorkspaceResult getRoutingWorkspace(Id accountId) {
        if (accountId == null) {
            throw new AuraHandledException('Account Id is required.');
        }

        Account accountRecord = [
            SELECT
                Id,
                Name,
                BillingCountry,
                Owner.Name,
                Cross_Sell_Propensity__c,
                Engagement_Intensity_Score__c,
                Competitor_Risk_Signal__c,
                Coverage_Gap_Flag__c,
                DataCloud_Last_Synced__c,
                AI_Narrative_Generated__c,
                Intent_Signal_Payload__c
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];

        Pulse360SellerWorkspaceService.WorkspaceResult sellerWorkspace =
            Pulse360SellerWorkspaceService.getSellerWorkspace(accountId);
        SignalProfile signalProfile = buildSignalProfile(accountRecord, sellerWorkspace);

        WorkspaceResult result = new WorkspaceResult();
        result.accountId = accountRecord.Id;
        result.accountName = accountRecord.Name;
        result.ownerName = accountRecord.Owner == null ? 'Unassigned owner' : accountRecord.Owner.Name;
        result.currencyCode = sellerWorkspace.currencyCode;
        result.hiddenRevenue = sellerWorkspace.hiddenRevenue;
        result.signalScore = signalProfile.signalScore;
        result.routingConfidence = signalProfile.routingConfidence;
        result.confidenceLabel = confidenceLabel(signalProfile.routingConfidence, signalProfile.payloadBacked);
        result.signalLabel = signalProfile.signalLabel;
        result.thresholdLabel = signalProfile.thresholdLabel;
        result.routeLabel = signalProfile.routeLabel;
        result.whyNow = signalProfile.whyNow;
        result.draftedOutreach = signalProfile.draftedOutreach;
        result.channelReadiness = signalProfile.channelReadiness;
        result.payloadModeLabel = signalProfile.payloadModeLabel;
        result.provisionalNote = signalProfile.provisionalNote;
        result.freshnessLabel = sellerWorkspace.freshnessLabel;
        result.freshnessTone = sellerWorkspace.freshnessTone;
        result.payloadBacked = signalProfile.payloadBacked;
        result.promptVersion = sellerWorkspace.promptVersion;
        result.modelId = sellerWorkspace.modelId;
        result.primaryAction = buildActionPreview(sellerWorkspace);
        result.topDrivers = buildRoutingDrivers(accountRecord, sellerWorkspace, signalProfile);
        result.targetContacts = buildTargetContacts(accountId);
        result.contactCoverageNote = buildContactCoverageNote(result.targetContacts, signalProfile.payloadBacked);
        return result;
    }

    private static Integer normalizeLimit(Integer requestedLimit) {
        if (requestedLimit == null || requestedLimit < 5) {
            return 12;
        }
        return Math.min(requestedLimit, 20);
    }

    private static SignalProfile buildSignalProfile(
        Account accountRecord,
        Pulse360SellerWorkspaceService.WorkspaceResult sellerWorkspace
    ) {
        Map<String, Object> payload = parsePayload(accountRecord.Intent_Signal_Payload__c);
        SignalProfile signalProfile = new SignalProfile();

        if (!payload.isEmpty()) {
            signalProfile.signalScore = decimalValue(payload.get('signal_score'));
            signalProfile.routingConfidence = decimalValue(payload.get('routing_confidence'));
            signalProfile.signalLabel = stringValue(payload.get('signal_label'));
            signalProfile.thresholdLabel = stringValue(payload.get('threshold_label'));
            signalProfile.routeLabel = routeLabelFromPayload(payload, accountRecord.Owner == null ? null : accountRecord.Owner.Name);
            signalProfile.whyNow = coalesce(
                stringValue(payload.get('why_now')),
                sellerWorkspace == null ? null : sellerWorkspace.aiNarrative,
                'Pulse360 did not receive a route explanation for this alert.'
            );
            signalProfile.draftedOutreach = coalesce(
                stringValue(payload.get('drafted_outreach')),
                buildFallbackOutreach(accountRecord.Name, sellerWorkspace, null),
                'Prepare a short outreach draft once the target contact is confirmed.'
            );
            signalProfile.channelReadiness = coalesce(
                stringValue(payload.get('channel_readiness')),
                'salesforce_preview'
            );
            signalProfile.payloadModeLabel = 'Activated intent payload';
            signalProfile.provisionalNote =
                'This view is backed by an activated intent payload, but Slack and cross-channel delivery still need to be completed.';
            signalProfile.payloadBacked = true;
            signalProfile.topDriverSummaries = stringListValue(payload.get('top_drivers'));
            if (signalProfile.topDriverSummaries.isEmpty()) {
                signalProfile.topDriverSummaries = derivedDriverSummaries(accountRecord, sellerWorkspace);
            }
            return normalizeProfile(signalProfile, accountRecord, sellerWorkspace);
        }

        signalProfile.signalScore = derivedSignalScore(accountRecord, sellerWorkspace);
        signalProfile.routingConfidence = derivedRoutingConfidence(accountRecord, sellerWorkspace);
        signalProfile.signalLabel = derivedSignalLabel(signalProfile.signalScore);
        signalProfile.thresholdLabel = derivedThresholdLabel(accountRecord, signalProfile.signalScore);
        signalProfile.routeLabel = derivedRouteLabel(accountRecord.Owner == null ? null : accountRecord.Owner.Name, accountRecord.Coverage_Gap_Flag__c);
        signalProfile.whyNow = coalesce(
            sellerWorkspace == null ? null : sellerWorkspace.primaryAction == null ? null : sellerWorkspace.primaryAction.reasoning,
            sellerWorkspace == null ? null : sellerWorkspace.aiNarrative,
            accountRecord.Name + ' has enough commercial context to justify a routed follow-up.'
        );
        signalProfile.topDriverSummaries = derivedDriverSummaries(accountRecord, sellerWorkspace);
        signalProfile.draftedOutreach = buildFallbackOutreach(accountRecord.Name, sellerWorkspace, signalProfile.topDriverSummaries);
        signalProfile.channelReadiness = 'salesforce_preview';
        signalProfile.payloadModeLabel = 'Salesforce-first preview';
        signalProfile.provisionalNote =
            'This queue is being derived from current Salesforce account, contact, and action context until the activated intent payload is fully live.';
        signalProfile.payloadBacked = false;
        return normalizeProfile(signalProfile, accountRecord, sellerWorkspace);
    }

    private static SignalProfile normalizeProfile(
        SignalProfile signalProfile,
        Account accountRecord,
        Pulse360SellerWorkspaceService.WorkspaceResult sellerWorkspace
    ) {
        if (signalProfile.signalScore == null) {
            signalProfile.signalScore = derivedSignalScore(accountRecord, sellerWorkspace);
        }
        if (signalProfile.routingConfidence == null) {
            signalProfile.routingConfidence = derivedRoutingConfidence(accountRecord, sellerWorkspace);
        }
        if (String.isBlank(signalProfile.signalLabel)) {
            signalProfile.signalLabel = derivedSignalLabel(signalProfile.signalScore);
        }
        if (String.isBlank(signalProfile.thresholdLabel)) {
            signalProfile.thresholdLabel = derivedThresholdLabel(accountRecord, signalProfile.signalScore);
        }
        if (String.isBlank(signalProfile.routeLabel)) {
            signalProfile.routeLabel = derivedRouteLabel(accountRecord.Owner == null ? null : accountRecord.Owner.Name, accountRecord.Coverage_Gap_Flag__c);
        }
        if (String.isBlank(signalProfile.channelReadiness)) {
            signalProfile.channelReadiness = 'salesforce_preview';
        }
        if (signalProfile.topDriverSummaries.isEmpty()) {
            signalProfile.topDriverSummaries = derivedDriverSummaries(accountRecord, sellerWorkspace);
        }
        return signalProfile;
    }

    private static List<RoutingDriver> buildRoutingDrivers(
        Account accountRecord,
        Pulse360SellerWorkspaceService.WorkspaceResult sellerWorkspace,
        SignalProfile signalProfile
    ) {
        List<RoutingDriver> drivers = new List<RoutingDriver>();

        RoutingDriver whitespaceDriver = new RoutingDriver();
        whitespaceDriver.key = 'whitespace';
        whitespaceDriver.label = 'Whitespace signal';
        whitespaceDriver.value = decimalLabel(accountRecord.Cross_Sell_Propensity__c);
        whitespaceDriver.copy = coalesce(
            signalProfile.topDriverSummaries.size() > 0 ? signalProfile.topDriverSummaries[0] : null,
            'Pulse360 has not attached a whitespace rationale yet.'
        );
        whitespaceDriver.tone = accountRecord.Cross_Sell_Propensity__c != null && accountRecord.Cross_Sell_Propensity__c >= 80 ? 'positive' : 'warning';
        drivers.add(whitespaceDriver);

        RoutingDriver engagementDriver = new RoutingDriver();
        engagementDriver.key = 'engagement';
        engagementDriver.label = 'Engagement timing';
        engagementDriver.value = decimalLabel(accountRecord.Engagement_Intensity_Score__c);
        engagementDriver.copy = coalesce(
            signalProfile.topDriverSummaries.size() > 1 ? signalProfile.topDriverSummaries[1] : null,
            sellerWorkspace == null ? null : sellerWorkspace.engagementLabel,
            'Engagement momentum still needs interpretation.'
        );
        engagementDriver.tone = accountRecord.Engagement_Intensity_Score__c != null && accountRecord.Engagement_Intensity_Score__c >= 60 ? 'positive' : 'soft';
        drivers.add(engagementDriver);

        RoutingDriver routeDriver = new RoutingDriver();
        routeDriver.key = 'coverage';
        routeDriver.label = 'Route clarity';
        routeDriver.value = accountRecord.Coverage_Gap_Flag__c == true ? 'Coverage gap' : 'Stable route';
        routeDriver.copy = coalesce(
            signalProfile.topDriverSummaries.size() > 2 ? signalProfile.topDriverSummaries[2] : null,
            accountRecord.Coverage_Gap_Flag__c == true
                ? 'Coverage is incomplete across the commercial group, so the routed alert should confirm owner and sponsor coverage.'
                : 'Coverage is stable enough for a directed routed follow-up.'
        );
        routeDriver.tone = accountRecord.Coverage_Gap_Flag__c == true ? 'warning' : 'soft';
        drivers.add(routeDriver);

        return drivers;
    }

    private static List<TargetContact> buildTargetContacts(Id accountId) {
        List<TargetContact> targetContacts = new List<TargetContact>();
        for (Contact contactRecord : [
            SELECT Id, Name, Title, Department, Email, LastModifiedDate
            FROM Contact
            WHERE AccountId = :accountId
            ORDER BY LastModifiedDate DESC
            LIMIT 4
        ]) {
            TargetContact targetContact = new TargetContact();
            targetContact.contactId = contactRecord.Id;
            targetContact.contactName = contactRecord.Name;
            targetContact.title = contactRecord.Title;
            targetContact.department = contactRecord.Department;
            targetContact.email = contactRecord.Email;
            targetContact.contactLabel = buildContactLabel(contactRecord.Title, contactRecord.Department);
            targetContact.lastTouchedLabel = daysAgoLabel(contactRecord.LastModifiedDate);
            targetContact.hasEmail = !String.isBlank(contactRecord.Email);
            targetContacts.add(targetContact);
        }
        return targetContacts;
    }

    private static String buildContactCoverageNote(List<TargetContact> targetContacts, Boolean payloadBacked) {
        if (targetContacts.isEmpty()) {
            return payloadBacked
                ? 'The routed signal is live, but there are no CRM contacts on the account yet. The next operator should confirm who should receive the first touch.'
                : 'No CRM contacts are attached to this account yet, so this remains a queue preview rather than a channel-ready outbound motion.';
        }

        return payloadBacked
            ? 'Pulse360 can ground the routed alert on live CRM contacts while broader channel delivery is completed.'
            : 'These CRM contacts provide the first routed audience while the full intent payload and Slack delivery path are still being completed.';
    }

    private static ActionPreview buildActionPreview(Pulse360SellerWorkspaceService.WorkspaceResult sellerWorkspace) {
        ActionPreview actionPreview = new ActionPreview();
        Pulse360SellerWorkspaceService.ActionPack sellerAction = sellerWorkspace.primaryAction;

        if (sellerAction == null) {
            actionPreview.actionType = 'create_task';
            actionPreview.target = sellerWorkspace.accountName;
            actionPreview.targetEntity = sellerWorkspace.accountName;
            actionPreview.reasoning = sellerWorkspace.aiNarrative;
            actionPreview.recommendedPlay = 'Confirm routed follow-up';
            actionPreview.solutionFamily = 'Account Intelligence';
            actionPreview.specialistRoute = 'Account Team';
            actionPreview.buyingGroupGap = 'Validate sponsor and owner coverage before routing.';
            actionPreview.outreachObjective = 'Confirm the next outbound or seller-owned motion.';
            actionPreview.buttonLabel = 'Create follow-up task';
            actionPreview.confidenceLabel = 'Preview only';
            return actionPreview;
        }

        actionPreview.rank = sellerAction.rank;
        actionPreview.actionType = sellerAction.actionType;
        actionPreview.target = sellerAction.target;
        actionPreview.targetRecordId = sellerAction.targetRecordId;
        actionPreview.targetEntity = sellerAction.targetEntity;
        actionPreview.reasoning = sellerAction.reasoning;
        actionPreview.estimatedRevenueImpact = sellerAction.estimatedRevenueImpact;
        actionPreview.confidence = sellerAction.confidence;
        actionPreview.confidenceLabel = sellerAction.confidenceLabel;
        actionPreview.solutionFamily = sellerAction.solutionFamily;
        actionPreview.recommendedPlay = sellerAction.recommendedPlay;
        actionPreview.specialistRoute = sellerAction.specialistRoute;
        actionPreview.buyingGroupGap = sellerAction.buyingGroupGap;
        actionPreview.outreachObjective = sellerAction.outreachObjective;
        actionPreview.buttonLabel = sellerAction.buttonLabel;

        if (sellerAction.supportingSources != null) {
            for (Pulse360SellerWorkspaceService.SourceRef sourceRef : sellerAction.supportingSources) {
                SourcePreview sourcePreview = new SourcePreview();
                sourcePreview.sourceId = sourceRef.sourceId;
                sourcePreview.sourceName = sourceRef.sourceName;
                sourcePreview.sourceType = sourceRef.sourceType;
                sourcePreview.sourceUrl = sourceRef.sourceUrl;
                actionPreview.supportingSources.add(sourcePreview);
            }
        }

        return actionPreview;
    }

    private static Decimal derivedSignalScore(
        Account accountRecord,
        Pulse360SellerWorkspaceService.WorkspaceResult sellerWorkspace
    ) {
        Decimal crossSell = zeroDecimal(accountRecord.Cross_Sell_Propensity__c);
        Decimal engagement = zeroDecimal(accountRecord.Engagement_Intensity_Score__c);
        Decimal competitor = zeroDecimal(accountRecord.Competitor_Risk_Signal__c);
        Decimal hiddenRevenueBoost = sellerWorkspace == null || sellerWorkspace.hiddenRevenue == null || sellerWorkspace.hiddenRevenue <= 0 ? 0 : 5;
        Decimal totalScore =
            (crossSell * Decimal.valueOf('0.55'))
            + (engagement * Decimal.valueOf('0.30'))
            + (accountRecord.Coverage_Gap_Flag__c == true ? 12 : 0)
            + (competitor >= 55 ? 6 : 0)
            + hiddenRevenueBoost;

        return clampDecimal(totalScore, 0, 100).setScale(0);
    }

    private static Decimal derivedRoutingConfidence(
        Account accountRecord,
        Pulse360SellerWorkspaceService.WorkspaceResult sellerWorkspace
    ) {
        Decimal confidence =
            Decimal.valueOf('0.45')
            + (zeroDecimal(accountRecord.Cross_Sell_Propensity__c) / 200)
            + (zeroDecimal(accountRecord.Engagement_Intensity_Score__c) / 300)
            + (accountRecord.Coverage_Gap_Flag__c == true ? Decimal.valueOf('0.08') : 0)
            + (sellerWorkspace != null && sellerWorkspace.externallyValidated ? Decimal.valueOf('0.05') : 0);

        return clampDecimal(confidence, Decimal.valueOf('0.35'), Decimal.valueOf('0.95')).setScale(2);
    }

    private static String derivedSignalLabel(Decimal signalScore) {
        Decimal safeScore = zeroDecimal(signalScore);
        if (safeScore >= 80) {
            return 'Route now';
        }
        if (safeScore >= 65) {
            return 'Queue for review';
        }
        return 'Monitor';
    }

    private static String derivedThresholdLabel(Account accountRecord, Decimal signalScore) {
        Decimal safeCrossSell = zeroDecimal(accountRecord.Cross_Sell_Propensity__c);
        Decimal safeEngagement = zeroDecimal(accountRecord.Engagement_Intensity_Score__c);
        if (safeCrossSell >= 80 && safeEngagement >= 70) {
            return 'Whitespace and engagement crossed the route-now threshold.';
        }
        if (accountRecord.Coverage_Gap_Flag__c == true && safeCrossSell >= 65) {
            return 'Coverage gaps and commercial potential crossed the routed-review threshold.';
        }
        if (zeroDecimal(signalScore) >= 65) {
            return 'The account has enough context to justify a routed review instead of another manual pass.';
        }
        return 'The account should stay visible while the signal matures.';
    }

    private static String derivedRouteLabel(String ownerName, Boolean coverageGapFlag) {
        String safeOwnerName = String.isBlank(ownerName) ? 'the account owner' : ownerName;
        if (coverageGapFlag == true) {
            return 'Route to ' + safeOwnerName + ' with a coverage check';
        }
        return 'Route to ' + safeOwnerName;
    }

    private static List<String> derivedDriverSummaries(
        Account accountRecord,
        Pulse360SellerWorkspaceService.WorkspaceResult sellerWorkspace
    ) {
        List<String> driverSummaries = new List<String>();
        driverSummaries.add(
            zeroDecimal(accountRecord.Cross_Sell_Propensity__c) >= 80
                ? 'Whitespace readiness is elevated enough to justify immediate seller attention.'
                : 'Commercial room exists, but the routed motion still needs qualification.'
        );
        driverSummaries.add(
            zeroDecimal(accountRecord.Engagement_Intensity_Score__c) >= 60
                ? 'Engagement context suggests the account can absorb a routed follow-up now.'
                : 'Engagement is thin enough that the first touch should validate timing and interest.'
        );
        driverSummaries.add(
            accountRecord.Coverage_Gap_Flag__c == true
                ? 'Coverage is incomplete across the group, so the route must confirm the real sponsor and owner path.'
                : 'Coverage is stable enough for a directed follow-up rather than a broad account review.'
        );
        return driverSummaries;
    }

    private static String buildFallbackOutreach(
        String accountName,
        Pulse360SellerWorkspaceService.WorkspaceResult sellerWorkspace,
        List<String> driverSummaries
    ) {
        String recommendedPlay = sellerWorkspace == null || sellerWorkspace.primaryAction == null
            ? 'the next Pulse360 follow-up'
            : coalesce(sellerWorkspace.primaryAction.recommendedPlay, sellerWorkspace.primaryAction.target, 'the next Pulse360 follow-up');
        String firstDriver = driverSummaries != null && !driverSummaries.isEmpty()
            ? driverSummaries[0]
            : 'Pulse360 has flagged a credible commercial reason to re-engage';

        return 'Pulse360 flagged ' + accountName + ' because ' + firstDriver
            + ' Lead with ' + recommendedPlay + ' and confirm who owns the next sponsor conversation.';
    }

    private static String routeLabelFromPayload(Map<String, Object> payload, String ownerName) {
        String explicitRoute = stringValue(payload.get('route_label'));
        if (!String.isBlank(explicitRoute)) {
            return explicitRoute;
        }

        String routeTo = stringValue(payload.get('route_to'));
        if (routeTo == 'account_owner_plus_coverage') {
            return derivedRouteLabel(ownerName, true);
        }
        return derivedRouteLabel(ownerName, false);
    }

    private static String confidenceLabel(Decimal routingConfidence, Boolean payloadBacked) {
        Decimal confidence = zeroDecimal(routingConfidence);
        if (confidence >= Decimal.valueOf('0.80')) {
            return payloadBacked ? 'High confidence' : 'High-confidence preview';
        }
        if (confidence >= Decimal.valueOf('0.65')) {
            return payloadBacked ? 'Operator-ready' : 'Operator-ready preview';
        }
        return payloadBacked ? 'Needs review' : 'Preview only';
    }

    private static Map<String, Object> parsePayload(String rawPayload) {
        if (String.isBlank(rawPayload)) {
            return new Map<String, Object>();
        }

        try {
            return (Map<String, Object>) JSON.deserializeUntyped(rawPayload);
        } catch (Exception exceptionValue) {
            return new Map<String, Object>();
        }
    }

    private static List<String> stringListValue(Object rawValue) {
        List<String> values = new List<String>();
        if (!(rawValue instanceof List<Object>)) {
            return values;
        }

        for (Object entry : (List<Object>) rawValue) {
            String value = stringValue(entry);
            if (!String.isBlank(value)) {
                values.add(value);
            }
        }
        return values;
    }

    private static String stringValue(Object rawValue) {
        return rawValue == null ? null : String.valueOf(rawValue);
    }

    private static Decimal decimalValue(Object rawValue) {
        if (rawValue == null) {
            return null;
        }

        try {
            return Decimal.valueOf(String.valueOf(rawValue));
        } catch (Exception exceptionValue) {
            return null;
        }
    }

    private static Decimal zeroDecimal(Decimal value) {
        return value == null ? 0 : value;
    }

    private static Decimal clampDecimal(Decimal value, Decimal minimumValue, Decimal maximumValue) {
        Decimal safeValue = value == null ? minimumValue : value;
        if (safeValue < minimumValue) {
            return minimumValue;
        }
        if (safeValue > maximumValue) {
            return maximumValue;
        }
        return safeValue;
    }

    private static String decimalLabel(Decimal value) {
        return value == null ? 'N/A' : String.valueOf(value.setScale(0));
    }

    private static String buildContactLabel(String title, String department) {
        List<String> labelParts = new List<String>();
        if (!String.isBlank(title)) {
            labelParts.add(title);
        }
        if (!String.isBlank(department)) {
            labelParts.add(department);
        }
        return labelParts.isEmpty() ? 'Role not specified' : String.join(labelParts, ' | ');
    }

    private static String daysAgoLabel(Datetime value) {
        Integer dayDelta = daysSince(value);
        if (dayDelta == null) {
            return 'Touchpoint unknown';
        }
        if (dayDelta == 0) {
            return 'Touched today';
        }
        if (dayDelta == 1) {
            return 'Touched 1 day ago';
        }
        return 'Touched ' + String.valueOf(dayDelta) + ' days ago';
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

    private static String truncate(String value, Integer maxLength) {
        if (String.isBlank(value) || value.length() <= maxLength) {
            return value;
        }
        return value.substring(0, maxLength - 3) + '...';
    }

    private static String coalesce(String firstValue, String secondValue) {
        return coalesce(firstValue, secondValue, null);
    }

    private static String coalesce(String firstValue, String secondValue, String thirdValue) {
        if (!String.isBlank(firstValue)) {
            return firstValue;
        }
        if (!String.isBlank(secondValue)) {
            return secondValue;
        }
        return thirdValue;
    }
}
