@IsTest
private class Pulse360SellerOrchestratorServiceTest {
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
    }

    @IsTest
    static void returnsSellerAccountContext() {
        Account accountRecord = [SELECT Id FROM Account WHERE Name = 'Singtel Group' LIMIT 1];

        Test.startTest();
        Pulse360SellerOrchestratorService.AccountContext context =
            Pulse360SellerOrchestratorService.getPulse360AccountContext(accountRecord.Id);
        Test.stopTest();

        System.assertEquals('Seller Account Manager', context.subagentName);
        System.assertEquals(accountRecord.Id, context.accountId);
        System.assertEquals('Singtel Group', context.accountName);
        System.assertEquals(2, context.hierarchyPayload.size());
        System.assertEquals(
            'Freshness: Fresh | Coverage gap: present | Uncovered entities: 1 | Primary move: NCS expansion review',
            context.orchestrationSummary
        );
        System.assertNotEquals(null, context.sellerBrief);
        System.assert(context.sellerBrief.body.contains('Pulse360 Seller Brief'));
        System.assert(context.evidenceStatus.contains('Grounded'));
        System.assert(context.executionChecklist.size() >= 3);
    }

    @IsTest
    static void invocableWrapperReturnsSellerAccountContext() {
        Account accountRecord = [SELECT Id FROM Account WHERE Name = 'Singtel Group' LIMIT 1];

        Pulse360GetAccountContextAction.Request request = new Pulse360GetAccountContextAction.Request();
        request.accountId = accountRecord.Id;

        Test.startTest();
        List<Pulse360GetAccountContextAction.Response> responses =
            Pulse360GetAccountContextAction.invoke(new List<Pulse360GetAccountContextAction.Request>{ request });
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals(accountRecord.Id, responses[0].accountId);

        Pulse360SellerOrchestratorService.AccountContext payload =
            (Pulse360SellerOrchestratorService.AccountContext) JSON.deserialize(
                responses[0].payloadJson,
                Pulse360SellerOrchestratorService.AccountContext.class
            );

        System.assertEquals(accountRecord.Id, payload.accountId);
        System.assertEquals('Seller Account Manager', payload.subagentName);
        System.assert(payload.sellerBrief.body.contains('Pulse360 Seller Brief'));
    }

    @IsTest
    static void executesLowRiskSellerActionWithoutApproval() {
        Account accountRecord = [SELECT Id, Name FROM Account WHERE Name = 'Singtel Group' LIMIT 1];

        Pulse360SellerOrchestratorService.ExecutionRequest request =
            new Pulse360SellerOrchestratorService.ExecutionRequest();
        request.recordId = String.valueOf(accountRecord.Id);
        request.accountName = accountRecord.Name;
        request.actionType = 'create_task';
        request.targetEntity = 'NCS Pte. Ltd.';
        request.recommendedPlay = 'Confirm expansion sponsor';
        request.reasoning = 'Coverage exists and a next action is clear.';
        request.sourceContext = 'test';

        Test.startTest();
        Pulse360SellerOrchestratorService.ExecutionResult result =
            Pulse360SellerOrchestratorService.executePulse360SellerAction(request);
        Test.stopTest();

        Task createdTask = [SELECT Description FROM Task WHERE Id = :result.primaryRecordId];
        System.assertEquals('Completed', result.status);
        System.assertEquals('Task', result.primaryObjectApiName);
        System.assertEquals(1, result.createdRecordIds.size());
        System.assertEquals(1, [SELECT COUNT() FROM Task WHERE Id = :result.primaryRecordId]);
        System.assert(result.briefBody.contains('Execution checklist'));
        System.assert(result.evidenceStatus.contains('Grounded'));
        System.assert(createdTask.Description.contains('Pulse360 Seller Action Plan'));
        System.assert(createdTask.Description.contains('Supporting evidence'));
    }

    @IsTest
    static void requiresApprovalBeforeCreatingOpportunity() {
        Account accountRecord = [SELECT Id, Name FROM Account WHERE Name = 'Singtel Group' LIMIT 1];

        Pulse360SellerOrchestratorService.ExecutionRequest previewRequest =
            new Pulse360SellerOrchestratorService.ExecutionRequest();
        previewRequest.recordId = String.valueOf(accountRecord.Id);
        previewRequest.accountName = accountRecord.Name;
        previewRequest.actionType = 'open_opportunity';
        previewRequest.targetEntity = 'NCS Pte. Ltd.';
        previewRequest.recommendedPlay = 'AI modernization';
        previewRequest.reasoning = 'High-confidence growth motion.';
        previewRequest.approvalMode = 'preview';

        Test.startTest();
        Pulse360SellerOrchestratorService.ExecutionResult previewResult =
            Pulse360SellerOrchestratorService.executePulse360SellerAction(previewRequest);
        previewRequest.approvalMode = 'approved';
        Pulse360SellerOrchestratorService.ExecutionResult approvedResult =
            Pulse360SellerOrchestratorService.executePulse360SellerAction(previewRequest);
        Test.stopTest();

        System.assertEquals('ApprovalRequired', previewResult.status);
        System.assert(previewResult.agentSummary.contains('Evidence status:'));
        System.assert(previewResult.executionChecklist.size() >= 3);
        System.assertEquals('Completed', approvedResult.status);
        System.assertEquals('Opportunity', approvedResult.primaryObjectApiName);
        System.assertEquals(1, [SELECT COUNT() FROM Opportunity WHERE Id = :approvedResult.primaryRecordId]);
    }

    @IsTest
    static void launchAgentCreatesEvidenceAwareSellerBriefTask() {
        Account accountRecord = [SELECT Id, Name FROM Account WHERE Name = 'Singtel Group' LIMIT 1];

        Pulse360SellerOrchestratorService.ExecutionRequest request =
            new Pulse360SellerOrchestratorService.ExecutionRequest();
        request.recordId = String.valueOf(accountRecord.Id);
        request.accountName = accountRecord.Name;
        request.actionType = 'launch_agent';
        request.targetEntity = 'NCS Pte. Ltd.';
        request.recommendedPlay = 'Prepare the NCS modernization brief';
        request.solutionFamily = 'Data and AI Modernization';
        request.reasoning = 'Coverage exists and a next action is clear.';
        request.agentGoal = 'generate_outreach_brief';
        request.sourceContext = 'test_launch_agent';

        Test.startTest();
        Pulse360SellerOrchestratorService.ExecutionResult result =
            Pulse360SellerOrchestratorService.executePulse360SellerAction(request);
        Test.stopTest();

        Task createdTask = [SELECT Subject, Description FROM Task WHERE Id = :result.primaryRecordId];

        System.assertEquals('Completed', result.status);
        System.assertEquals('Task', result.primaryObjectApiName);
        System.assertEquals('generate_outreach_brief', result.agentGoal);
        System.assert(result.briefTitle.contains('Pulse360 Seller Brief'));
        System.assert(result.briefBody.contains('Goal: Generate outreach brief'));
        System.assert(result.briefBody.contains('Supporting evidence'));
        System.assert(result.executionChecklist.size() >= 3);
        System.assert(createdTask.Subject.contains('Pulse360 Agent Brief'));
        System.assert(createdTask.Description.contains('Recommendation headline: Prepare the NCS modernization brief'));
    }

    @IsTest
    static void askSellerAgentRespondsWithoutMutation() {
        Account accountRecord = [SELECT Id, Name FROM Account WHERE Name = 'Singtel Group' LIMIT 1];

        Pulse360SellerOrchestratorService.ExecutionRequest request =
            new Pulse360SellerOrchestratorService.ExecutionRequest();
        request.recordId = String.valueOf(accountRecord.Id);
        request.accountName = accountRecord.Name;
        request.actionType = 'open_opportunity';
        request.targetEntity = 'NCS Pte. Ltd.';
        request.recommendedPlay = 'AI modernization';
        request.solutionFamily = 'Data and AI Modernization';
        request.reasoning = 'Pressure-test the next move before execution.';
        request.agentGoal = 'validate_evidence';
        request.userMessage = 'What is the key evidence gap?';

        Integer taskCountBefore = [SELECT COUNT() FROM Task];
        Integer opportunityCountBefore = [SELECT COUNT() FROM Opportunity];

        Test.startTest();
        Pulse360SellerOrchestratorService.ExecutionResult result =
            Pulse360SellerOrchestratorService.askPulse360SellerAgent(request);
        Test.stopTest();

        System.assertEquals('Responded', result.status);
        System.assertEquals('AVAILABLE_ON_APPROVAL', result.approvalState);
        System.assertEquals('validate_evidence', result.agentGoal);
        System.assert(result.briefTitle.contains('Pulse360 Seller Brief'));
        System.assert(result.briefBody.contains('Goal: Validate evidence and objections'));
        System.assert(result.executionChecklist.size() >= 3);
        System.assert(result.riskFlags.size() >= 1);
        System.assert(result.evidenceHighlights.size() >= 1);
        System.assertEquals(taskCountBefore, [SELECT COUNT() FROM Task]);
        System.assertEquals(opportunityCountBefore, [SELECT COUNT() FROM Opportunity]);
    }

    @IsTest
    static void invocableWrapperExecutesSellerAction() {
        Account accountRecord = [SELECT Id, Name FROM Account WHERE Name = 'Singtel Group' LIMIT 1];

        Pulse360ExecuteSellerAction.Request request = new Pulse360ExecuteSellerAction.Request();
        request.recordId = accountRecord.Id;
        request.accountName = accountRecord.Name;
        request.actionType = 'create_task';
        request.targetEntity = 'NCS Pte. Ltd.';
        request.recommendedPlay = 'Confirm expansion sponsor';
        request.solutionFamily = 'Data and AI Modernization';
        request.reasoning = 'Coverage exists and a next action is clear.';
        request.outreachObjective = 'Confirm expansion sponsor path';
        request.sourceContext = 'invocable_test';
        request.agentGoal = 'generate_outreach_brief';

        Test.startTest();
        List<Pulse360ExecuteSellerAction.Response> responses =
            Pulse360ExecuteSellerAction.invoke(new List<Pulse360ExecuteSellerAction.Request>{ request });
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals('Completed', responses[0].status);

        Pulse360SellerOrchestratorService.ExecutionResult payload =
            (Pulse360SellerOrchestratorService.ExecutionResult) JSON.deserialize(
                responses[0].payloadJson,
                Pulse360SellerOrchestratorService.ExecutionResult.class
            );

        System.assertEquals('generate_outreach_brief', payload.agentGoal);
        System.assertEquals('Task', payload.primaryObjectApiName);
        System.assert(payload.briefBody.contains('Execution checklist'));
        System.assertEquals(1, [SELECT COUNT() FROM Task WHERE Id = :payload.primaryRecordId]);
    }
}
