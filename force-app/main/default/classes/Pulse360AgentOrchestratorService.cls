public with sharing class Pulse360AgentOrchestratorService {
    @TestVisible
    private static String reviewEvidenceObjectApiName = 'ssot__Account__dlm';

    @TestVisible
    private static String cspReviewEvidenceObjectApiName = 'Pulse360_Activation_Review_Queue__dlm';

    @TestVisible
    private static ReviewEvidence injectedReviewEvidence;

    public class AuditState {
        @AuraEnabled public String decisionStatus;
        @AuraEnabled public String auditEventId;
        @AuraEnabled public String downstreamUpdateStatus;
        @AuraEnabled public String mergeExecutionStatus;
        @AuraEnabled public String decidedById;
        @AuraEnabled public String decidedAt;
    }

    public class ReviewContext {
        @AuraEnabled public String subagentName;
        @AuraEnabled public Id governanceCaseId;
        @AuraEnabled public String governanceCaseNumber;
        @AuraEnabled public String candidatePairId;
        @AuraEnabled public Id leftAccountId;
        @AuraEnabled public Id rightAccountId;
        @AuraEnabled public Decimal confidence;
        @AuraEnabled public String reasoning;
        @AuraEnabled public String currentStatus;
        @AuraEnabled public AuditState auditState;
        @AuraEnabled public String recommendedAction;
        @AuraEnabled public String sourceProduct;
        @AuraEnabled public String reviewQueueId;
        @AuraEnabled public String sourceRecordId;
        @AuraEnabled public String targetEntityName;
        @AuraEnabled public String offeringFamily;
        @AuraEnabled public String reviewPriority;
    }

    public class ReviewEvidenceEntity {
        @AuraEnabled public String crmRecordId;
        @AuraEnabled public String dataCloudRecordId;
        @AuraEnabled public String accountName;
        @AuraEnabled public String externalLegalName;
        @AuraEnabled public String registrationNumber;
        @AuraEnabled public String unifiedProfileId;
        @AuraEnabled public Decimal identityConfidence;
        @AuraEnabled public Decimal validityScore;
        @AuraEnabled public String dataSourceId;
        @AuraEnabled public String dataSourceObjectId;
        @AuraEnabled public String hierarchyPayload;
    }

    public class ReviewEvidence {
        @AuraEnabled public Boolean available;
        @AuraEnabled public Boolean failClosed;
        @AuraEnabled public String candidatePairId;
        @AuraEnabled public List<ReviewEvidenceEntity> entityMatches = new List<ReviewEvidenceEntity>();
        @AuraEnabled public String attributeValidity;
        @AuraEnabled public String hierarchyImpact;
        @AuraEnabled public List<String> sourceRefs = new List<String>();
        @AuraEnabled public String evidenceTimestamp;
        @AuraEnabled public String dataCloudSource;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String sourceProduct;
        @AuraEnabled public String sourceRecordId;
        @AuraEnabled public String reviewQueueId;
        @AuraEnabled public String targetEntityName;
        @AuraEnabled public String countryCode;
        @AuraEnabled public String market;
        @AuraEnabled public String offeringFamily;
        @AuraEnabled public String offerBundle;
        @AuraEnabled public String targetB2bCustomerIds;
        @AuraEnabled public String targetB2bCustomerNames;
        @AuraEnabled public String recommendedNextActions;
        @AuraEnabled public String reviewPriority;
        @AuraEnabled public Decimal confidenceScore;
        @AuraEnabled public String activationBlockReasons;
    }

    public class ExecutionResult {
        @AuraEnabled public String status;
        @AuraEnabled public List<String> createdRecordIds = new List<String>();
        @AuraEnabled public String agentSummary;
        @AuraEnabled public String approvalState;
        @AuraEnabled public String auditEventId;
        @AuraEnabled public String errorCode;
        @AuraEnabled public Boolean approvalRequired;
        @AuraEnabled public String primaryRecordId;
        @AuraEnabled public String primaryObjectApiName;
        @AuraEnabled public String subagentName;
    }

    @AuraEnabled(cacheable=true)
    public static ReviewContext getPulse360ReviewContext(Id governanceCaseId) {
        if (governanceCaseId == null) {
            throw new AuraHandledException('Governance Case Id is required.');
        }

        Governance_Case__c governanceCase = [
            SELECT
                Id,
                Name,
                Candidate_Pair_Id__c,
                Left_Account__c,
                Right_Account__c,
                Duplicate_Confidence__c,
                Feature_Explanations__c,
                Recommended_Action__c,
                Status__c,
                Decision_Status__c,
                Audit_Event_Id__c,
                Downstream_Update_Status__c,
                Merge_Execution_Status__c,
                Decided_By__c,
                Decided_At__c,
                Source_Product__c,
                Data_Cloud_Review_Queue_Id__c,
                Data_Cloud_Source_Record_Id__c,
                Target_Entity_Name__c,
                Offering_Family__c,
                Review_Priority__c
            FROM Governance_Case__c
            WHERE Id = :governanceCaseId
            LIMIT 1
        ];

        ReviewContext context = new ReviewContext();
        context.subagentName = 'Governance Review Manager';
        context.governanceCaseId = governanceCase.Id;
        context.governanceCaseNumber = governanceCase.Name;
        context.candidatePairId = governanceCase.Candidate_Pair_Id__c;
        context.leftAccountId = governanceCase.Left_Account__c;
        context.rightAccountId = governanceCase.Right_Account__c;
        context.confidence = governanceCase.Duplicate_Confidence__c;
        context.reasoning = String.isBlank(governanceCase.Feature_Explanations__c)
            ? governanceCase.Recommended_Action__c
            : governanceCase.Feature_Explanations__c;
        context.currentStatus = governanceCase.Status__c;
        context.recommendedAction = governanceCase.Recommended_Action__c;
        context.sourceProduct = governanceCase.Source_Product__c;
        context.reviewQueueId = governanceCase.Data_Cloud_Review_Queue_Id__c;
        context.sourceRecordId = governanceCase.Data_Cloud_Source_Record_Id__c;
        context.targetEntityName = governanceCase.Target_Entity_Name__c;
        context.offeringFamily = governanceCase.Offering_Family__c;
        context.reviewPriority = governanceCase.Review_Priority__c;
        context.auditState = new AuditState();
        context.auditState.decisionStatus = governanceCase.Decision_Status__c;
        context.auditState.auditEventId = governanceCase.Audit_Event_Id__c;
        context.auditState.downstreamUpdateStatus = governanceCase.Downstream_Update_Status__c;
        context.auditState.mergeExecutionStatus = governanceCase.Merge_Execution_Status__c;
        context.auditState.decidedById = governanceCase.Decided_By__c;
        context.auditState.decidedAt = formatDatetime(governanceCase.Decided_At__c);
        return context;
    }

    @AuraEnabled(cacheable=true)
    public static ReviewEvidence getPulse360DataCloudReviewEvidence(String candidatePairId, Id leftAccountId, Id rightAccountId) {
        if (Test.isRunningTest() && injectedReviewEvidence != null) {
            return injectedReviewEvidence;
        }

        Set<Id> accountIds = new Set<Id>();
        if (leftAccountId != null) {
            accountIds.add(leftAccountId);
        }
        if (rightAccountId != null) {
            accountIds.add(rightAccountId);
        }

        if (accountIds.isEmpty() && !String.isBlank(candidatePairId)) {
            for (Governance_Case__c governanceCase : [
                SELECT Left_Account__c, Right_Account__c
                FROM Governance_Case__c
                WHERE Candidate_Pair_Id__c = :candidatePairId
                LIMIT 1
            ]) {
                if (governanceCase.Left_Account__c != null) {
                    accountIds.add(governanceCase.Left_Account__c);
                }
                if (governanceCase.Right_Account__c != null) {
                    accountIds.add(governanceCase.Right_Account__c);
                }
            }
        }

        if (accountIds.isEmpty()) {
            if (!String.isBlank(candidatePairId)) {
                return getPulse360CspDataCloudReviewEvidence(candidatePairId);
            }
            return unavailableReviewEvidence(candidatePairId, 'No governance pair accounts or Data Cloud review key were supplied for the direct evidence read.');
        }

        Map<String, String> accountNamesById = new Map<String, String>();
        for (Account accountRecord : [
            SELECT Id, Name
            FROM Account
            WHERE Id IN :accountIds
        ]) {
            accountNamesById.put(String.valueOf(accountRecord.Id), accountRecord.Name);
        }

        try {
            String soql =
                'SELECT Id, ssot__Id__c, External_Legal_Name__c, Unified_Profile_Id__c, ' +
                'Validity_Score_External__c, Hierarchy_Payload__c, Last_Synced_Timestamp__c, ' +
                'ssot__DataSourceId__c, ssot__DataSourceObjectId__c ' +
                ' FROM ' + reviewEvidenceObjectApiName +
                ' WHERE ssot__Id__c IN (' + quotedIds(accountIds) + ')';

            List<SObject> rows = Database.query(soql);
            if (rows.isEmpty()) {
                return unavailableReviewEvidence(candidatePairId, 'No direct Data Cloud evidence rows were returned for the governance pair.');
            }

            List<Map<String, Object>> normalizedRows = new List<Map<String, Object>>();
            for (SObject row : rows) {
                Map<String, Object> normalizedRow = new Map<String, Object>();
                normalizedRow.put('Id', row.get('Id'));
                normalizedRow.put('ssot__Id__c', row.get('ssot__Id__c'));
                normalizedRow.put('ssot__Name__c', accountNamesById.get(stringValue(row.get('ssot__Id__c'))));
                normalizedRow.put('External_Legal_Name__c', row.get('External_Legal_Name__c'));
                normalizedRow.put('External_Registration_Number__c', null);
                normalizedRow.put('Unified_Profile_Id__c', row.get('Unified_Profile_Id__c'));
                normalizedRow.put('Identity_Confidence__c', null);
                normalizedRow.put('Validity_Score_External__c', row.get('Validity_Score_External__c'));
                normalizedRow.put('Hierarchy_Payload__c', row.get('Hierarchy_Payload__c'));
                normalizedRow.put('Last_Synced_Timestamp__c', row.get('Last_Synced_Timestamp__c'));
                normalizedRow.put('ssot__DataSourceId__c', row.get('ssot__DataSourceId__c'));
                normalizedRow.put('ssot__DataSourceObjectId__c', row.get('ssot__DataSourceObjectId__c'));
                normalizedRows.add(normalizedRow);
            }
            return buildReviewEvidenceFromRows(candidatePairId, accountIds, normalizedRows);
        } catch (Exception ex) {
            if (ex.getMessage() != null && ex.getMessage().contains('sObject type')) {
                return unavailableReviewEvidence(candidatePairId, 'The configured Data Cloud review object is not available in this org.');
            }
            if (ex.getMessage() != null && ex.getMessage().contains('ssot__Id__c')) {
                return unavailableReviewEvidence(candidatePairId, 'The configured Data Cloud review object is missing ssot__Id__c, so governance evidence cannot be grounded safely.');
            }
            return unavailableReviewEvidence(candidatePairId, 'Direct Data Cloud evidence lookup failed: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static ExecutionResult recordPulse360GovernanceDecision(
        Id governanceCaseId,
        String decision,
        String reasonCode,
        Id survivingAccountId,
        String approvedByUser,
        String decisionReasonText,
        Boolean reviewFollowupRequired,
        Id mergedAccountId
    ) {
        if (governanceCaseId == null) {
            throw new AuraHandledException('Governance Case Id is required.');
        }
        if (String.isBlank(decision) || String.isBlank(reasonCode)) {
            throw new AuraHandledException('A governance decision and reason code are required.');
        }
        if (String.isBlank(approvedByUser) || approvedByUser != UserInfo.getUserId()) {
            throw new AuraHandledException('Governance execution requires an explicit approval from the current user.');
        }

        ReviewContext context = getPulse360ReviewContext(governanceCaseId);
        String evidenceLookupKey = coalesce(context.sourceRecordId, context.reviewQueueId, context.candidatePairId);
        ReviewEvidence evidence = getPulse360DataCloudReviewEvidence(
            evidenceLookupKey,
            context.leftAccountId,
            context.rightAccountId
        );
        if (evidence == null || evidence.available != true) {
            throw new AuraHandledException(
                'Direct Data Cloud review evidence is unavailable. Governance decisions are blocked until the evidence surface is restored.'
            );
        }

        Governance_Case__c governanceCase = [
            SELECT
                Id,
                Left_Account__c,
                Right_Account__c
            FROM Governance_Case__c
            WHERE Id = :governanceCaseId
            LIMIT 1
            FOR UPDATE
        ];

        governanceCase.Decision_Status__c = decision;
        governanceCase.Decision_Reason_Code__c = reasonCode;
        governanceCase.Decision_Reason_Text__c = decisionReasonText;
        governanceCase.Review_Followup_Required__c = reviewFollowupRequired;
        governanceCase.Surviving_Account__c = survivingAccountId;
        governanceCase.Merged_Account__c = mergedAccountId;
        governanceCase.Status__c = decision;
        governanceCase.Audit_Event_Id__c = newAuditEventId();
        governanceCase.Downstream_Update_Status__c = 'Queued';
        update governanceCase;

        ExecutionResult result = new ExecutionResult();
        result.status = 'Completed';
        result.approvalRequired = true;
        result.approvalState = 'APPROVED';
        result.auditEventId = governanceCase.Audit_Event_Id__c;
        result.primaryRecordId = governanceCase.Id;
        result.primaryObjectApiName = 'Governance_Case__c';
        result.subagentName = 'Governance Review Manager';
        result.agentSummary =
            'Governance decision ' + decision +
            ' recorded with direct Data Cloud grounding for ' + coalesce(evidenceLookupKey, 'unknown review evidence') + '.';
        return result;
    }

    private static ReviewEvidence getPulse360CspDataCloudReviewEvidence(String reviewLookupKey) {
        String escapedLookupKey = String.escapeSingleQuotes(reviewLookupKey);
        try {
            String soql =
                'SELECT Id, review_queue_id__c, source_product__c, source_record_id__c, ' +
                'target_entity_name__c, country_code__c, market__c, offering_family__c, offer_bundle__c, ' +
                'target_b2b_customer_ids__c, target_b2b_customer_names__c, recommended_next_actions__c, ' +
                'review_priority__c, confidence_score__c, activation_block_reasons__c, source_refs__c, ' +
                'source_run_timestamp__c ' +
                'FROM ' + cspReviewEvidenceObjectApiName + ' ' +
                'WHERE source_product__c = \'csp_smart_city_proposition_readiness\' ' +
                'AND (source_record_id__c = \'' + escapedLookupKey + '\' OR review_queue_id__c = \'' + escapedLookupKey + '\') ' +
                ' LIMIT 1';

            List<SObject> rows = Database.query(soql);
            if (rows.isEmpty()) {
                return unavailableReviewEvidence(reviewLookupKey, 'No CSP smart-city review row was returned from Data Cloud for ' + reviewLookupKey + '.');
            }
            return buildCspReviewEvidence(reviewLookupKey, rows[0]);
        } catch (Exception ex) {
            if (ex.getMessage() != null && ex.getMessage().contains('sObject type')) {
                return unavailableReviewEvidence(reviewLookupKey, 'The CSP Data Cloud review object is not available in this org.');
            }
            return unavailableReviewEvidence(reviewLookupKey, 'CSP Data Cloud evidence lookup failed: ' + ex.getMessage());
        }
    }

    private static ReviewEvidence buildCspReviewEvidence(String reviewLookupKey, SObject row) {
        ReviewEvidence evidence = new ReviewEvidence();
        evidence.available = true;
        evidence.failClosed = false;
        evidence.candidatePairId = reviewLookupKey;
        evidence.dataCloudSource = cspReviewEvidenceObjectApiName;
        evidence.reviewQueueId = stringValue(row.get('review_queue_id__c'));
        evidence.sourceProduct = stringValue(row.get('source_product__c'));
        evidence.sourceRecordId = stringValue(row.get('source_record_id__c'));
        evidence.targetEntityName = stringValue(row.get('target_entity_name__c'));
        evidence.countryCode = stringValue(row.get('country_code__c'));
        evidence.market = stringValue(row.get('market__c'));
        evidence.offeringFamily = stringValue(row.get('offering_family__c'));
        evidence.offerBundle = stringValue(row.get('offer_bundle__c'));
        evidence.targetB2bCustomerIds = stringValue(row.get('target_b2b_customer_ids__c'));
        evidence.targetB2bCustomerNames = stringValue(row.get('target_b2b_customer_names__c'));
        evidence.recommendedNextActions = stringValue(row.get('recommended_next_actions__c'));
        evidence.reviewPriority = stringValue(row.get('review_priority__c'));
        evidence.confidenceScore = decimalValue(row.get('confidence_score__c'));
        evidence.activationBlockReasons = stringValue(row.get('activation_block_reasons__c'));
        evidence.evidenceTimestamp = formatDatetime(datetimeValue(row.get('source_run_timestamp__c')));
        evidence.sourceRefs.add(coalesce(stringValue(row.get('source_refs__c')), 'Direct CSP Data Cloud review queue read'));
        evidence.attributeValidity =
            coalesce(evidence.targetEntityName, 'CSP smart-city target') +
            ' / ' + coalesce(evidence.offeringFamily, 'unknown offering') +
            ' readiness ' + (evidence.confidenceScore == null ? 'not scored' : String.valueOf(evidence.confidenceScore));
        evidence.hierarchyImpact =
            'Target B2B customers: ' + coalesce(evidence.targetB2bCustomerNames, '[]') +
            '. Review priority: ' + coalesce(evidence.reviewPriority, 'not assigned') + '.';
        return evidence;
    }

    @TestVisible
    private static ReviewEvidence buildReviewEvidenceFromRows(
        String candidatePairId,
        Set<Id> accountIds,
        List<Map<String, Object>> rows
    ) {
        Map<String, Map<String, Object>> rowsByCrmId = new Map<String, Map<String, Object>>();
        for (Map<String, Object> row : rows) {
            String crmRecordId = stringValue(row.get('ssot__Id__c'));
            if (!String.isBlank(crmRecordId)) {
                rowsByCrmId.put(crmRecordId, row);
            }
        }

        ReviewEvidence evidence = new ReviewEvidence();
        evidence.available = rowsByCrmId.size() == accountIds.size();
        evidence.failClosed = !evidence.available;
        evidence.candidatePairId = candidatePairId;
        evidence.dataCloudSource = reviewEvidenceObjectApiName;
        evidence.sourceRefs.add('Direct Data Cloud DMO read');

        List<String> validityTokens = new List<String>();
        List<String> hierarchyTokens = new List<String>();
        Datetime latestTimestamp;
        Set<String> unifiedProfiles = new Set<String>();

        for (Id accountId : accountIds) {
            Map<String, Object> row = rowsByCrmId.get(String.valueOf(accountId));
            if (row == null) {
                continue;
            }

            ReviewEvidenceEntity entity = new ReviewEvidenceEntity();
            entity.crmRecordId = stringValue(row.get('ssot__Id__c'));
            entity.dataCloudRecordId = stringValue(row.get('Id'));
            entity.accountName = coalesce(
                stringValue(row.get('ssot__Name__c')),
                stringValue(accountId)
            );
            entity.externalLegalName = stringValue(row.get('External_Legal_Name__c'));
            entity.registrationNumber = stringValue(row.get('External_Registration_Number__c'));
            entity.unifiedProfileId = stringValue(row.get('Unified_Profile_Id__c'));
            entity.identityConfidence = decimalValue(row.get('Identity_Confidence__c'));
            entity.validityScore = decimalValue(row.get('Validity_Score_External__c'));
            entity.dataSourceId = stringValue(row.get('ssot__DataSourceId__c'));
            entity.dataSourceObjectId = stringValue(row.get('ssot__DataSourceObjectId__c'));
            entity.hierarchyPayload = stringValue(row.get('Hierarchy_Payload__c'));
            evidence.entityMatches.add(entity);

            if (!String.isBlank(entity.unifiedProfileId)) {
                unifiedProfiles.add(entity.unifiedProfileId);
            }
            if (entity.validityScore != null) {
                validityTokens.add(entity.accountName + ' validity ' + entity.validityScore.setScale(0));
            }
            if (!String.isBlank(entity.hierarchyPayload)) {
                hierarchyTokens.add(entity.accountName + ' carries live hierarchy payload');
            }
            Datetime rowTimestamp = datetimeValue(row.get('Last_Synced_Timestamp__c'));
            if (rowTimestamp != null && (latestTimestamp == null || rowTimestamp.getTime() > latestTimestamp.getTime())) {
                latestTimestamp = rowTimestamp;
            }
            if (!String.isBlank(entity.dataSourceId)) {
                evidence.sourceRefs.add(entity.dataSourceId + ' / ' + coalesce(entity.dataSourceObjectId, 'unknown source object'));
            }
        }

        evidence.attributeValidity = validityTokens.isEmpty()
            ? 'No direct validity signals are available on the Data Cloud review surface.'
            : String.join(validityTokens, '; ');
        evidence.hierarchyImpact = hierarchyTokens.isEmpty()
            ? 'Direct Data Cloud hierarchy payloads were not available for this pair.'
            : String.join(hierarchyTokens, '; ');
        if (unifiedProfiles.size() == 1 && evidence.entityMatches.size() > 1) {
            evidence.hierarchyImpact += ' Shared unified profile detected.';
        }
        evidence.evidenceTimestamp = formatDatetime(latestTimestamp);
        evidence.errorMessage = evidence.available
            ? null
            : 'Only a partial direct Data Cloud evidence set was returned for the governance pair.';
        return evidence;
    }

    private static ReviewEvidence unavailableReviewEvidence(String candidatePairId, String message) {
        ReviewEvidence evidence = new ReviewEvidence();
        evidence.available = false;
        evidence.failClosed = true;
        evidence.candidatePairId = candidatePairId;
        evidence.dataCloudSource = reviewEvidenceObjectApiName;
        evidence.errorMessage = message;
        return evidence;
    }

    private static String quotedIds(Set<Id> ids) {
        List<String> quoted = new List<String>();
        for (Id idValue : ids) {
            quoted.add('\'' + String.escapeSingleQuotes(String.valueOf(idValue)) + '\'');
        }
        return String.join(quoted, ', ');
    }

    private static String newAuditEventId() {
        return 'P360-' + Datetime.now().formatGmt('yyyyMMddHHmmss') + '-' + String.valueOf(Math.abs(Crypto.getRandomInteger()));
    }

    private static String coalesce(String leftValue, String rightValue) {
        return !String.isBlank(leftValue) ? leftValue : rightValue;
    }

    private static String coalesce(String firstValue, String secondValue, String thirdValue) {
        return coalesce(coalesce(firstValue, secondValue), thirdValue);
    }

    private static String coalesce(String firstValue, String secondValue, String thirdValue, String fourthValue) {
        return coalesce(coalesce(firstValue, secondValue, thirdValue), fourthValue);
    }

    private static String stringValue(Object value) {
        return value == null ? null : String.valueOf(value);
    }

    private static Decimal decimalValue(Object value) {
        if (value == null) {
            return null;
        }
        return Decimal.valueOf(String.valueOf(value));
    }

    private static Datetime datetimeValue(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof Datetime) {
            return (Datetime)value;
        }
        try {
            return Datetime.valueOf(String.valueOf(value));
        } catch (Exception ex) {
            return null;
        }
    }

    private static String formatDatetime(Datetime value) {
        return value == null ? null : value.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
    }
}
