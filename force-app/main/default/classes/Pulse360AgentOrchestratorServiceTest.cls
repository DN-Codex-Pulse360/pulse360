@IsTest
private class Pulse360AgentOrchestratorServiceTest {
    @TestSetup
    static void setupData() {
        insert new Account(
            Name = 'Singtel Group',
            BillingCountry = 'Singapore',
            Group_Known_Subsidiary_Count__c = 3,
            CRM_Covered_Subsidiary_Count__c = 2,
            Coverage_Gap_Flag__c = true,
            Health_Score__c = 88,
            Cross_Sell_Propensity__c = 82,
            Competitor_Risk_Signal__c = 67,
            DataCloud_Last_Synced__c = Datetime.now().addDays(-2),
            AI_Narrative_Generated__c = Datetime.now().addDays(-2),
            AI_Recommended_Actions__c = '[{"rank":1,"action_type":"create_task","target":"NCS expansion review","reasoning":"Coverage exists and a next action is clear.","estimated_revenue_impact":"S$4M influenced pipeline","confidence":0.84,"source_ids":["src_1"]}]',
            AI_Source_Refs__c = '[{"source_id":"src_1","source_name":"Public filing","source_type":"annual_report","source_url":"https://example.com/report","document_date":"2025-05-22","accessed_at":"2026-04-15T00:00:00Z","excerpt":"NCS remains a growth driver.","jurisdiction":"SG"}]',
            Hierarchy_Payload__c = '{"group_id":"grp_singtel","children":[{"entity_id":"ent_sg_001","name":"Singtel Group","coverage_status":"covered","in_crm":true},{"entity_id":"ent_sg_002","name":"NCS Pte. Ltd.","coverage_status":"covered","in_crm":true}]}'
        );

        Account leftAccount = new Account(Name = 'Ayala Corporation');
        Account rightAccount = new Account(Name = 'Ayala Corp.');
        insert new List<Account>{ leftAccount, rightAccount };

        insert new Governance_Case__c(
            Candidate_Pair_Id__c = 'PAIR-AYALA-001',
            Status__c = 'Ready for Review',
            Priority__c = 'High',
            Left_Account__c = leftAccount.Id,
            Right_Account__c = rightAccount.Id,
            Duplicate_Confidence__c = 96,
            Confidence_Band__c = 'High',
            Recommended_Action__c = 'Approve Merge',
            Review_Flag__c = true,
            Top_Match_Features__c = 'legal_name,registry_id',
            Feature_Explanations__c = 'The records share strong legal and registration signals.',
            Attribute_Validity_Payload__c = 'legal_name:92; registration:91',
            Hierarchy_Conflict_Flag__c = false,
            Hierarchy_Impact_Summary__c = 'No conflict detected.',
            Source_Snapshot_Id__c = 'snapshot_ayala_001',
            Evidence_Run_Id__c = 'run_ayala_001',
            Evidence_Run_Timestamp__c = Datetime.now().addDays(-1),
            Model_Version__c = 'pulse360-dedupe-v1',
            Merge_Execution_Status__c = 'Not Started'
        );
    }

    @IsTest
    static void reviewContextRequiresGovernanceCaseId() {
        Boolean threw = false;
        try {
            Test.startTest();
            Pulse360AgentOrchestratorService.getPulse360ReviewContext(null);
            Test.stopTest();
        } catch (Exception ex) {
            threw = true;
        }
        System.assertEquals(true, threw, 'Expected the missing governance case id to throw.');
    }

    @IsTest
    static void reviewContextFallsBackToRecommendedActionWhenExplanationMissing() {
        Account leftAccount = new Account(Name = 'Fallback Left Co');
        Account rightAccount = new Account(Name = 'Fallback Right Co');
        insert new List<Account>{ leftAccount, rightAccount };

        Governance_Case__c governanceCase = new Governance_Case__c(
            Candidate_Pair_Id__c = 'PAIR-FALLBACK-001',
            Status__c = 'Ready for Review',
            Priority__c = 'Medium',
            Left_Account__c = leftAccount.Id,
            Right_Account__c = rightAccount.Id,
            Duplicate_Confidence__c = 81,
            Confidence_Band__c = 'Medium',
            Recommended_Action__c = 'Approve Merge',
            Review_Flag__c = true,
            Feature_Explanations__c = null,
            Top_Match_Features__c = 'portfolio_overlap'
        );
        insert governanceCase;

        Test.startTest();
        Pulse360AgentOrchestratorService.ReviewContext context =
            Pulse360AgentOrchestratorService.getPulse360ReviewContext(governanceCase.Id);
        Test.stopTest();

        System.assertEquals('Approve Merge', context.reasoning);
        System.assertEquals('Approve Merge', context.recommendedAction);
    }

    @IsTest
    static void governanceDecisionRequiresDecisionAndReasonCode() {
        Governance_Case__c governanceCase = [
            SELECT Id
            FROM Governance_Case__c
            WHERE Candidate_Pair_Id__c = 'PAIR-AYALA-001'
            LIMIT 1
        ];

        Boolean threw = false;
        try {
            Test.startTest();
            Pulse360AgentOrchestratorService.recordPulse360GovernanceDecision(
                governanceCase.Id,
                null,
                null,
                null,
                UserInfo.getUserId(),
                null,
                false,
                null
            );
            Test.stopTest();
        } catch (Exception ex) {
            threw = true;
        }

        System.assertEquals(true, threw, 'Expected governance execution to require a decision and reason code.');
    }

    @IsTest
    static void governanceDecisionRequiresExplicitCurrentUserApproval() {
        Governance_Case__c governanceCase = [
            SELECT Id
            FROM Governance_Case__c
            WHERE Candidate_Pair_Id__c = 'PAIR-AYALA-001'
            LIMIT 1
        ];

        Boolean threw = false;
        try {
            Test.startTest();
            Pulse360AgentOrchestratorService.recordPulse360GovernanceDecision(
                governanceCase.Id,
                'Approved',
                'CLEAR_DUPLICATE_MATCH',
                null,
                '005000000000000AAA',
                null,
                false,
                null
            );
            Test.stopTest();
        } catch (Exception ex) {
            threw = true;
        }

        System.assertEquals(true, threw, 'Expected governance execution to require approval from the current user.');
    }

    @IsTest
    static void recordsGovernanceDecisionWhenDirectEvidenceExists() {
        Governance_Case__c governanceCase = [
            SELECT Id, Candidate_Pair_Id__c, Left_Account__c, Right_Account__c
            FROM Governance_Case__c
            WHERE Candidate_Pair_Id__c = 'PAIR-AYALA-001'
            LIMIT 1
        ];

        Pulse360AgentOrchestratorService.ReviewEvidence injectedEvidence =
            new Pulse360AgentOrchestratorService.ReviewEvidence();
        injectedEvidence.available = true;
        injectedEvidence.failClosed = false;
        injectedEvidence.candidatePairId = governanceCase.Candidate_Pair_Id__c;
        injectedEvidence.dataCloudSource = 'ssot__Account__dlm';
        injectedEvidence.attributeValidity = 'Ayala Corporation validity 92; Ayala Corp. validity 91';
        injectedEvidence.hierarchyImpact = 'Shared unified profile detected.';
        Pulse360AgentOrchestratorService.injectedReviewEvidence = injectedEvidence;

        Test.startTest();
        Pulse360AgentOrchestratorService.ExecutionResult result =
            Pulse360AgentOrchestratorService.recordPulse360GovernanceDecision(
                governanceCase.Id,
                'Approved',
                'CLEAR_DUPLICATE_MATCH',
                governanceCase.Left_Account__c,
                UserInfo.getUserId(),
                'The direct Data Cloud signals support approval.',
                false,
                governanceCase.Right_Account__c
            );
        Test.stopTest();

        Governance_Case__c updatedCase = [
            SELECT
                Status__c,
                Decision_Status__c,
                Audit_Event_Id__c,
                Downstream_Update_Status__c,
                Decided_By__c,
                Decided_At__c
            FROM Governance_Case__c
            WHERE Id = :governanceCase.Id
        ];

        System.assertEquals('Completed', result.status);
        System.assertEquals('Approved', updatedCase.Status__c);
        System.assertEquals('Approved', updatedCase.Decision_Status__c);
        System.assertNotEquals(null, updatedCase.Audit_Event_Id__c);
        System.assertEquals('Queued', updatedCase.Downstream_Update_Status__c);
        System.assertEquals(UserInfo.getUserId(), updatedCase.Decided_By__c);
        System.assertNotEquals(null, updatedCase.Decided_At__c);

        Pulse360AgentOrchestratorService.injectedReviewEvidence = null;
    }

    @IsTest
    static void reviewContextIncludesCspActionFields() {
        Governance_Case__c governanceCase = new Governance_Case__c(
            Candidate_Pair_Id__c = 'smart_city_readiness_city_metro_manila_iot_intelligent_parking',
            Status__c = 'Ready for Review',
            Priority__c = 'High',
            Duplicate_Confidence__c = 74.5,
            Confidence_Band__c = 'Medium',
            Recommended_Action__c = 'Map Account',
            Review_Flag__c = true,
            Source_Product__c = 'csp_smart_city_proposition_readiness',
            Data_Cloud_Review_Queue_Id__c = 'rq_metro_manila_parking',
            Data_Cloud_Source_Record_Id__c = 'smart_city_readiness_city_metro_manila_iot_intelligent_parking',
            Target_Entity_Name__c = 'Metro Manila Intelligent Parking Opportunity',
            Country_Code__c = 'PH',
            Market__c = 'Philippines',
            Offering_Family__c = 'intelligent_parking',
            Offer_Bundle__c = 'IoT parking sensors, curbside analytics, enforcement workflow',
            Target_B2B_Customer_Names__c = 'Ayala Urban Property Group; Manila Central Parking Operator',
            Recommended_Next_Actions__c = 'Map CRM account candidates and confirm city mobility sponsor.',
            Review_Priority__c = 'account_mapping_review',
            Activation_Block_Reasons__c = 'missing_crm_activation_candidate'
        );
        insert governanceCase;

        Test.startTest();
        Pulse360AgentOrchestratorService.ReviewContext context =
            Pulse360AgentOrchestratorService.getPulse360ReviewContext(governanceCase.Id);
        Test.stopTest();

        System.assertEquals('csp_smart_city_proposition_readiness', context.sourceProduct);
        System.assertEquals('smart_city_readiness_city_metro_manila_iot_intelligent_parking', context.sourceRecordId);
        System.assertEquals('Metro Manila Intelligent Parking Opportunity', context.targetEntityName);
        System.assertEquals('intelligent_parking', context.offeringFamily);
        System.assertEquals('account_mapping_review', context.reviewPriority);
    }

    @IsTest
    static void recordsCspGovernanceDecisionWithoutMergeAccountsWhenEvidenceExists() {
        Governance_Case__c governanceCase = new Governance_Case__c(
            Candidate_Pair_Id__c = 'smart_city_readiness_city_metro_manila_iot_data_brokerage',
            Status__c = 'Ready for Review',
            Priority__c = 'High',
            Duplicate_Confidence__c = 59.68,
            Confidence_Band__c = 'Medium',
            Recommended_Action__c = 'Governance Review',
            Review_Flag__c = true,
            Source_Product__c = 'csp_smart_city_proposition_readiness',
            Data_Cloud_Review_Queue_Id__c = 'rq_metro_manila_data_brokerage',
            Data_Cloud_Source_Record_Id__c = 'smart_city_readiness_city_metro_manila_iot_data_brokerage',
            Target_Entity_Name__c = 'Metro Manila Urban Data Brokerage Opportunity',
            Country_Code__c = 'PH',
            Market__c = 'Philippines',
            Offering_Family__c = 'urban_data_brokerage',
            Offer_Bundle__c = 'Mobility and footfall data exchange',
            Target_B2B_Customer_Names__c = 'Metro Manila Development Authority Mobility Office',
            Recommended_Next_Actions__c = 'Escalate privacy and consent review before activation.',
            Review_Priority__c = 'governance_review',
            Activation_Block_Reasons__c = 'governance/privacy'
        );
        insert governanceCase;

        Pulse360AgentOrchestratorService.ReviewEvidence injectedEvidence =
            new Pulse360AgentOrchestratorService.ReviewEvidence();
        injectedEvidence.available = true;
        injectedEvidence.failClosed = false;
        injectedEvidence.candidatePairId = governanceCase.Data_Cloud_Source_Record_Id__c;
        injectedEvidence.dataCloudSource = 'Pulse360_Activation_Review_Queue__dlm';
        injectedEvidence.sourceProduct = 'csp_smart_city_proposition_readiness';
        injectedEvidence.sourceRecordId = governanceCase.Data_Cloud_Source_Record_Id__c;
        injectedEvidence.reviewQueueId = governanceCase.Data_Cloud_Review_Queue_Id__c;
        injectedEvidence.targetEntityName = governanceCase.Target_Entity_Name__c;
        injectedEvidence.offeringFamily = governanceCase.Offering_Family__c;
        injectedEvidence.reviewPriority = governanceCase.Review_Priority__c;
        injectedEvidence.attributeValidity = 'Metro Manila Urban Data Brokerage Opportunity / urban_data_brokerage readiness 59.68';
        injectedEvidence.hierarchyImpact = 'Target B2B customers: Metro Manila Development Authority Mobility Office.';
        Pulse360AgentOrchestratorService.injectedReviewEvidence = injectedEvidence;

        Test.startTest();
        Pulse360AgentOrchestratorService.ExecutionResult result =
            Pulse360AgentOrchestratorService.recordPulse360GovernanceDecision(
                governanceCase.Id,
                'Approved',
                'CSP_GOVERNANCE_REVIEW_REQUIRED',
                null,
                UserInfo.getUserId(),
                'Governance route accepted for policy review.',
                true,
                null
            );
        Test.stopTest();

        Governance_Case__c updatedCase = [
            SELECT Status__c, Decision_Status__c, Downstream_Update_Status__c, Surviving_Account__c, Merged_Account__c
            FROM Governance_Case__c
            WHERE Id = :governanceCase.Id
        ];

        System.assertEquals('Completed', result.status);
        System.assertEquals('Approved', updatedCase.Status__c);
        System.assertEquals('Approved', updatedCase.Decision_Status__c);
        System.assertEquals('Queued', updatedCase.Downstream_Update_Status__c);
        System.assertEquals(null, updatedCase.Surviving_Account__c);
        System.assertEquals(null, updatedCase.Merged_Account__c);

        Pulse360AgentOrchestratorService.injectedReviewEvidence = null;
    }

    @IsTest
    static void blocksGovernanceDecisionWhenDirectEvidenceIsUnavailable() {
        Governance_Case__c governanceCase = [
            SELECT Id, Candidate_Pair_Id__c, Left_Account__c, Right_Account__c
            FROM Governance_Case__c
            WHERE Candidate_Pair_Id__c = 'PAIR-AYALA-001'
            LIMIT 1
        ];

        Pulse360AgentOrchestratorService.injectedReviewEvidence = null;

        Pulse360AgentOrchestratorService.ReviewEvidence evidence =
            Pulse360AgentOrchestratorService.getPulse360DataCloudReviewEvidence(
                governanceCase.Candidate_Pair_Id__c,
                governanceCase.Left_Account__c,
                governanceCase.Right_Account__c
            );
        System.assertEquals(false, evidence.available, 'The direct review evidence read should fail closed in test context without injected evidence.');

        Boolean blocked = false;
        Test.startTest();
        try {
            Pulse360AgentOrchestratorService.recordPulse360GovernanceDecision(
                governanceCase.Id,
                'Approved',
                'CLEAR_DUPLICATE_MATCH',
                null,
                UserInfo.getUserId(),
                null,
                false,
                null
            );
        } catch (Exception ex) {
            blocked = true;
        }
        Test.stopTest();
        System.assertEquals(true, blocked, 'Expected the governance decision to fail closed when direct review evidence is unavailable.');
    }

    @IsTest
    static void flowWrappersReturnPayloadJson() {
        Account accountRecord = [SELECT Id FROM Account WHERE Name = 'Singtel Group' LIMIT 1];
        Governance_Case__c governanceCase = [
            SELECT Id, Candidate_Pair_Id__c, Left_Account__c, Right_Account__c
            FROM Governance_Case__c
            WHERE Candidate_Pair_Id__c = 'PAIR-AYALA-001'
            LIMIT 1
        ];

        Pulse360GetAccountContextAction.Request accountRequest = new Pulse360GetAccountContextAction.Request();
        accountRequest.accountId = accountRecord.Id;

        Pulse360GetReviewContextAction.Request reviewRequest = new Pulse360GetReviewContextAction.Request();
        reviewRequest.governanceCaseId = governanceCase.Id;

        Pulse360AgentOrchestratorService.ReviewEvidence injectedEvidence =
            new Pulse360AgentOrchestratorService.ReviewEvidence();
        injectedEvidence.available = true;
        injectedEvidence.failClosed = false;
        injectedEvidence.candidatePairId = governanceCase.Candidate_Pair_Id__c;
        Pulse360AgentOrchestratorService.injectedReviewEvidence = injectedEvidence;

        Pulse360GetDataCloudReviewEvidenceAction.Request evidenceRequest = new Pulse360GetDataCloudReviewEvidenceAction.Request();
        evidenceRequest.candidatePairId = governanceCase.Candidate_Pair_Id__c;
        evidenceRequest.leftAccountId = governanceCase.Left_Account__c;
        evidenceRequest.rightAccountId = governanceCase.Right_Account__c;

        Test.startTest();
        List<Pulse360GetAccountContextAction.Response> accountResponses =
            Pulse360GetAccountContextAction.invoke(new List<Pulse360GetAccountContextAction.Request>{ accountRequest });
        List<Pulse360GetReviewContextAction.Response> reviewResponses =
            Pulse360GetReviewContextAction.invoke(new List<Pulse360GetReviewContextAction.Request>{ reviewRequest });
        List<Pulse360GetDataCloudReviewEvidenceAction.Response> evidenceResponses =
            Pulse360GetDataCloudReviewEvidenceAction.invoke(
                new List<Pulse360GetDataCloudReviewEvidenceAction.Request>{ evidenceRequest }
            );
        Test.stopTest();

        System.assert(accountResponses[0].payloadJson.contains('"subagentName":"Seller Account Manager"'));
        System.assert(reviewResponses[0].payloadJson.contains('"subagentName":"Governance Review Manager"'));
        System.assertEquals(true, evidenceResponses[0].available);

        Pulse360AgentOrchestratorService.injectedReviewEvidence = null;
    }

    @IsTest
    static void executionWrappersReturnPayloadJson() {
        Account accountRecord = [SELECT Id, Name FROM Account WHERE Name = 'Singtel Group' LIMIT 1];
        Governance_Case__c governanceCase = [
            SELECT Id, Candidate_Pair_Id__c, Left_Account__c, Right_Account__c
            FROM Governance_Case__c
            WHERE Candidate_Pair_Id__c = 'PAIR-AYALA-001'
            LIMIT 1
        ];

        Pulse360ExecuteSellerAction.Request sellerRequest = new Pulse360ExecuteSellerAction.Request();
        sellerRequest.recordId = accountRecord.Id;
        sellerRequest.actionType = 'create_task';
        sellerRequest.accountName = accountRecord.Name;
        sellerRequest.targetEntity = 'NCS Pte. Ltd.';
        sellerRequest.recommendedPlay = 'Confirm expansion sponsor';
        sellerRequest.reasoning = 'Coverage exists and a next action is clear.';

        Pulse360AgentOrchestratorService.ReviewEvidence injectedEvidence =
            new Pulse360AgentOrchestratorService.ReviewEvidence();
        injectedEvidence.available = true;
        injectedEvidence.failClosed = false;
        injectedEvidence.candidatePairId = governanceCase.Candidate_Pair_Id__c;
        Pulse360AgentOrchestratorService.injectedReviewEvidence = injectedEvidence;

        Pulse360RecordGovernanceDecisionAction.Request governanceRequest =
            new Pulse360RecordGovernanceDecisionAction.Request();
        governanceRequest.governanceCaseId = governanceCase.Id;
        governanceRequest.decision = 'Approved';
        governanceRequest.reasonCode = 'CLEAR_DUPLICATE_MATCH';
        governanceRequest.survivingAccountId = governanceCase.Left_Account__c;
        governanceRequest.mergedAccountId = governanceCase.Right_Account__c;
        governanceRequest.approvedByUser = UserInfo.getUserId();
        governanceRequest.decisionReasonText = 'Direct Data Cloud evidence confirms the duplicate pair.';
        governanceRequest.reviewFollowupRequired = false;

        Test.startTest();
        List<Pulse360ExecuteSellerAction.Response> sellerResponses =
            Pulse360ExecuteSellerAction.invoke(new List<Pulse360ExecuteSellerAction.Request>{ sellerRequest });
        List<Pulse360RecordGovernanceDecisionAction.Response> governanceResponses =
            Pulse360RecordGovernanceDecisionAction.invoke(
                new List<Pulse360RecordGovernanceDecisionAction.Request>{ governanceRequest }
            );
        Test.stopTest();

        System.assertEquals('Completed', sellerResponses[0].status);
        System.assert(sellerResponses[0].payloadJson.contains('"subagentName":"Seller Account Manager"'));
        System.assertEquals('Completed', governanceResponses[0].status);
        System.assert(governanceResponses[0].payloadJson.contains('"subagentName":"Governance Review Manager"'));

        Pulse360AgentOrchestratorService.injectedReviewEvidence = null;
    }

    @IsTest
    static void flowWrappersReturnEmptyListsWhenNoRequestsAreSupplied() {
        Test.startTest();
        List<Pulse360GetAccountContextAction.Response> accountResponses =
            Pulse360GetAccountContextAction.invoke(null);
        List<Pulse360GetReviewContextAction.Response> reviewResponses =
            Pulse360GetReviewContextAction.invoke(new List<Pulse360GetReviewContextAction.Request>());
        List<Pulse360GetDataCloudReviewEvidenceAction.Response> evidenceResponses =
            Pulse360GetDataCloudReviewEvidenceAction.invoke(null);
        List<Pulse360ExecuteSellerAction.Response> sellerResponses =
            Pulse360ExecuteSellerAction.invoke(new List<Pulse360ExecuteSellerAction.Request>());
        List<Pulse360RecordGovernanceDecisionAction.Response> governanceResponses =
            Pulse360RecordGovernanceDecisionAction.invoke(null);
        Test.stopTest();

        System.assertEquals(0, accountResponses.size());
        System.assertEquals(0, reviewResponses.size());
        System.assertEquals(0, evidenceResponses.size());
        System.assertEquals(0, sellerResponses.size());
        System.assertEquals(0, governanceResponses.size());
    }

    @IsTest
    static void executionWrapperRejectsNullFlowRowWithHandledSellerError() {
        String message;

        try {
            Test.startTest();
            Pulse360ExecuteSellerAction.invoke(new List<Pulse360ExecuteSellerAction.Request>{ null });
            Test.stopTest();
        } catch (Exception ex) {
            message = ex.getMessage();
        }

        System.assertEquals(true, !String.isBlank(message), 'Expected the null Flow row to fail fast.');
        System.assertEquals(
            true,
            message == 'A seller execution request with a recordId is required.' ||
                message == 'Script-thrown exception',
            'Expected the Flow wrapper to preserve the seller service failure path for null request rows.'
        );
    }

    @IsTest
    static void reviewEvidenceFailsClosedWhenConfiguredObjectIsMissing() {
        Governance_Case__c governanceCase = [
            SELECT Candidate_Pair_Id__c, Left_Account__c, Right_Account__c
            FROM Governance_Case__c
            WHERE Candidate_Pair_Id__c = 'PAIR-AYALA-001'
            LIMIT 1
        ];

        Pulse360AgentOrchestratorService.reviewEvidenceObjectApiName = 'DefinitelyMissing__dlm';

        Test.startTest();
        Pulse360AgentOrchestratorService.ReviewEvidence evidence =
            Pulse360AgentOrchestratorService.getPulse360DataCloudReviewEvidence(
                governanceCase.Candidate_Pair_Id__c,
                governanceCase.Left_Account__c,
                governanceCase.Right_Account__c
            );
        Test.stopTest();

        System.assertEquals(false, evidence.available);
        System.assertEquals(true, evidence.failClosed);
        System.assert(evidence.errorMessage.contains('not available'));

        Pulse360AgentOrchestratorService.reviewEvidenceObjectApiName = 'ssot__Account__dlm';
    }

    @IsTest
    static void reviewEvidenceFailsClosedWhenConfiguredObjectLacksCrmIdField() {
        Governance_Case__c governanceCase = [
            SELECT Candidate_Pair_Id__c, Left_Account__c, Right_Account__c
            FROM Governance_Case__c
            WHERE Candidate_Pair_Id__c = 'PAIR-AYALA-001'
            LIMIT 1
        ];

        Pulse360AgentOrchestratorService.reviewEvidenceObjectApiName = 'Account';

        Test.startTest();
        Pulse360AgentOrchestratorService.ReviewEvidence evidence =
            Pulse360AgentOrchestratorService.getPulse360DataCloudReviewEvidence(
                governanceCase.Candidate_Pair_Id__c,
                governanceCase.Left_Account__c,
                governanceCase.Right_Account__c
            );
        Test.stopTest();

        System.assertEquals(false, evidence.available);
        System.assertEquals(true, evidence.failClosed);
        System.assert(evidence.errorMessage.contains('missing ssot__Id__c'));

        Pulse360AgentOrchestratorService.reviewEvidenceObjectApiName = 'ssot__Account__dlm';
    }

    @IsTest
    static void reviewEvidenceFailsClosedWhenNoAccountsAreSupplied() {
        Test.startTest();
        Pulse360AgentOrchestratorService.ReviewEvidence evidence =
            Pulse360AgentOrchestratorService.getPulse360DataCloudReviewEvidence(null, null, null);
        Test.stopTest();

        System.assertEquals(false, evidence.available);
        System.assertEquals(true, evidence.failClosed);
        System.assert(evidence.errorMessage.contains('No governance pair accounts'));
    }

    @IsTest
    static void reviewEvidenceCanResolveAccountsFromCandidatePairLookup() {
        Governance_Case__c governanceCase = [
            SELECT Candidate_Pair_Id__c
            FROM Governance_Case__c
            WHERE Candidate_Pair_Id__c = 'PAIR-AYALA-001'
            LIMIT 1
        ];

        Pulse360AgentOrchestratorService.reviewEvidenceObjectApiName = 'DefinitelyMissing__dlm';

        Test.startTest();
        Pulse360AgentOrchestratorService.ReviewEvidence evidence =
            Pulse360AgentOrchestratorService.getPulse360DataCloudReviewEvidence(
                governanceCase.Candidate_Pair_Id__c,
                null,
                null
            );
        Test.stopTest();

        System.assertEquals(false, evidence.available);
        System.assertEquals(true, evidence.failClosed);
        System.assertEquals(governanceCase.Candidate_Pair_Id__c, evidence.candidatePairId);

        Pulse360AgentOrchestratorService.reviewEvidenceObjectApiName = 'ssot__Account__dlm';
    }

    @IsTest
    static void reviewEvidenceReturnsUnavailableWhenNoRowsExistInConfiguredObject() {
        Governance_Case__c governanceCase = [
            SELECT Candidate_Pair_Id__c, Left_Account__c, Right_Account__c
            FROM Governance_Case__c
            WHERE Candidate_Pair_Id__c = 'PAIR-AYALA-001'
            LIMIT 1
        ];

        Test.startTest();
        Pulse360AgentOrchestratorService.ReviewEvidence evidence =
            Pulse360AgentOrchestratorService.getPulse360DataCloudReviewEvidence(
                governanceCase.Candidate_Pair_Id__c,
                governanceCase.Left_Account__c,
                governanceCase.Right_Account__c
            );
        Test.stopTest();

        System.assertEquals(false, evidence.available);
        System.assertEquals(true, evidence.failClosed);
        System.assertEquals(governanceCase.Candidate_Pair_Id__c, evidence.candidatePairId);
    }

    @IsTest
    static void buildReviewEvidenceFromRowsReturnsGroundedEvidence() {
        Governance_Case__c governanceCase = [
            SELECT Candidate_Pair_Id__c, Left_Account__c, Right_Account__c
            FROM Governance_Case__c
            WHERE Candidate_Pair_Id__c = 'PAIR-AYALA-001'
            LIMIT 1
        ];

        Set<Id> accountIds = new Set<Id>{ governanceCase.Left_Account__c, governanceCase.Right_Account__c };
        List<Map<String, Object>> rows = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Id' => 'q0J000000000001AAA',
                'ssot__Id__c' => String.valueOf(governanceCase.Left_Account__c),
                'ssot__Name__c' => 'Ayala Corporation',
                'External_Legal_Name__c' => 'Ayala Corporation',
                'External_Registration_Number__c' => 'REG-001',
                'Unified_Profile_Id__c' => 'unified-ayala',
                'Identity_Confidence__c' => 98,
                'Validity_Score_External__c' => 92,
                'Hierarchy_Payload__c' => '{"root":"Ayala"}',
                'Last_Synced_Timestamp__c' => Datetime.newInstanceGmt(2026, 4, 18, 4, 0, 0),
                'ssot__DataSourceId__c' => 'src_left',
                'ssot__DataSourceObjectId__c' => 'obj_left'
            },
            new Map<String, Object>{
                'Id' => 'q0J000000000002AAA',
                'ssot__Id__c' => String.valueOf(governanceCase.Right_Account__c),
                'ssot__Name__c' => 'Ayala Corp.',
                'External_Legal_Name__c' => 'Ayala Corp.',
                'Unified_Profile_Id__c' => 'unified-ayala',
                'Identity_Confidence__c' => 96,
                'Validity_Score_External__c' => 91,
                'Hierarchy_Payload__c' => '{"root":"Ayala"}',
                'Last_Synced_Timestamp__c' => '2026-04-18 05:30:00',
                'ssot__DataSourceId__c' => 'src_right',
                'ssot__DataSourceObjectId__c' => 'obj_right'
            }
        };

        Test.startTest();
        Pulse360AgentOrchestratorService.ReviewEvidence evidence =
            Pulse360AgentOrchestratorService.buildReviewEvidenceFromRows(
                governanceCase.Candidate_Pair_Id__c,
                accountIds,
                rows
            );
        Test.stopTest();

        System.assertEquals(true, evidence.available);
        System.assertEquals(false, evidence.failClosed);
        System.assertEquals(2, evidence.entityMatches.size());
        System.assert(evidence.attributeValidity.contains('Ayala Corporation validity 92'));
        System.assert(evidence.hierarchyImpact.contains('Shared unified profile detected.'));
        System.assertEquals('2026-04-18T12:30:00Z', evidence.evidenceTimestamp);
        System.assertEquals(3, evidence.sourceRefs.size());
    }

    @IsTest
    static void buildReviewEvidenceFromRowsFlagsPartialEvidence() {
        Governance_Case__c governanceCase = [
            SELECT Candidate_Pair_Id__c, Left_Account__c, Right_Account__c
            FROM Governance_Case__c
            WHERE Candidate_Pair_Id__c = 'PAIR-AYALA-001'
            LIMIT 1
        ];

        Set<Id> accountIds = new Set<Id>{ governanceCase.Left_Account__c, governanceCase.Right_Account__c };
        List<Map<String, Object>> rows = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Id' => 'q0J000000000003AAA',
                'ssot__Id__c' => String.valueOf(governanceCase.Left_Account__c),
                'Validity_Score_External__c' => null,
                'Last_Synced_Timestamp__c' => 'not-a-datetime',
                'ssot__DataSourceId__c' => null
            }
        };

        Test.startTest();
        Pulse360AgentOrchestratorService.ReviewEvidence evidence =
            Pulse360AgentOrchestratorService.buildReviewEvidenceFromRows(
                governanceCase.Candidate_Pair_Id__c,
                accountIds,
                rows
            );
        Test.stopTest();

        System.assertEquals(false, evidence.available);
        System.assertEquals(true, evidence.failClosed);
        System.assertEquals(1, evidence.entityMatches.size());
        System.assertEquals('No direct validity signals are available on the Data Cloud review surface.', evidence.attributeValidity);
        System.assertEquals('Direct Data Cloud hierarchy payloads were not available for this pair.', evidence.hierarchyImpact);
        System.assert(evidence.errorMessage.contains('partial direct Data Cloud evidence'));
    }
}
