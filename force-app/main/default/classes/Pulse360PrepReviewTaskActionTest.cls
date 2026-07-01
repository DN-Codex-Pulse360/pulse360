@IsTest
private class Pulse360PrepReviewTaskActionTest {
    @IsTest
    static void createsTaskAfterConfirmationWithSourceRefs() {
        Account accountRecord = sourceBackedAccount();
        insert accountRecord;

        Pulse360PrepReviewTaskAction.Request request =
            new Pulse360PrepReviewTaskAction.Request();
        request.accountId = accountRecord.Id;
        request.confirmed = true;
        request.requestedActionType = 'route_specialist';
        request.nextMove = 'Route aftermarket specialist for preventive maintenance coverage review.';

        Test.startTest();
        List<Pulse360PrepReviewTaskAction.Response> results =
            Pulse360PrepReviewTaskAction.invoke(
                new List<Pulse360PrepReviewTaskAction.Request>{ request }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        Pulse360PrepReviewTaskAction.Response actionResult = results[0];
        System.assertEquals('task_created', actionResult.status);
        System.assertEquals(accountRecord.Id, actionResult.accountId);
        System.assertNotEquals(null, actionResult.taskId);
        System.assert(actionResult.taskUrl.contains('/lightning/r/Task/'));
        System.assert(actionResult.auditJson.contains('"confirmation_received":true'));
        System.assert(actionResult.auditJson.contains('route_specialist'));

        Task createdTask = [
            SELECT Id, WhatId, Subject, Status, Priority, Description
            FROM Task
            WHERE Id = :actionResult.taskId
        ];
        System.assertEquals(accountRecord.Id, createdTask.WhatId);
        System.assertEquals('Not Started', createdTask.Status);
        System.assertEquals('High', createdTask.Priority);
        System.assert(createdTask.Subject.contains('Pulse360'));
        System.assert(createdTask.Subject.contains('coverage review'));
        System.assert(createdTask.Description.contains('Northstar Foods Group'));
        System.assert(createdTask.Description.contains('source refs'));
    }

    @IsTest
    static void blocksWithoutConfirmationAndDoesNotMutate() {
        Account accountRecord = sourceBackedAccount();
        insert accountRecord;

        Pulse360PrepReviewTaskAction.Request request =
            new Pulse360PrepReviewTaskAction.Request();
        request.accountId = accountRecord.Id;
        request.confirmed = false;
        request.requestedActionType = 'create_task';

        Test.startTest();
        List<Pulse360PrepReviewTaskAction.Response> results =
            Pulse360PrepReviewTaskAction.invoke(
                new List<Pulse360PrepReviewTaskAction.Request>{ request }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals('blocked_confirmation_required', results[0].status);
        System.assertEquals(null, results[0].taskId);
        System.assertEquals(0, [SELECT count() FROM Task WHERE WhatId = :accountRecord.Id]);
    }

    @IsTest
    static void requiresReviewWhenSourceRefsAreMissingAndDoesNotMutate() {
        Account accountRecord = new Account(
            Name = 'Northstar Foods Group',
            Coverage_Gap_Flag__c = true,
            AI_Narrative__c = 'Signal exists but citations are missing.'
        );
        insert accountRecord;

        Pulse360PrepReviewTaskAction.Request request =
            new Pulse360PrepReviewTaskAction.Request();
        request.accountId = accountRecord.Id;
        request.confirmed = true;
        request.requestedActionType = 'create_task';

        Test.startTest();
        List<Pulse360PrepReviewTaskAction.Response> results =
            Pulse360PrepReviewTaskAction.invoke(
                new List<Pulse360PrepReviewTaskAction.Request>{ request }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals('review_required_missing_source_refs', results[0].status);
        System.assertEquals(null, results[0].taskId);
        System.assertEquals(0, [SELECT count() FROM Task WHERE WhatId = :accountRecord.Id]);
    }

    @IsTest
    static void blocksOpportunityCreationAndDoesNotMutate() {
        Account accountRecord = sourceBackedAccount();
        insert accountRecord;

        Pulse360PrepReviewTaskAction.Request request =
            new Pulse360PrepReviewTaskAction.Request();
        request.accountId = accountRecord.Id;
        request.confirmed = true;
        request.requestedActionType = 'create_opportunity';

        Test.startTest();
        List<Pulse360PrepReviewTaskAction.Response> results =
            Pulse360PrepReviewTaskAction.invoke(
                new List<Pulse360PrepReviewTaskAction.Request>{ request }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals('blocked_high_impact_action_requires_separate_approval', results[0].status);
        System.assertEquals(null, results[0].taskId);
        System.assertEquals(0, [SELECT count() FROM Task WHERE WhatId = :accountRecord.Id]);
    }

    private static Account sourceBackedAccount() {
        return new Account(
            Name = 'Northstar Foods Group',
            Coverage_Gap_Flag__c = true,
            DataCloud_Last_Synced__c = Datetime.newInstance(2026, 6, 30, 12, 58, 26),
            AI_Narrative_Generated__c = Datetime.newInstance(2026, 6, 30, 13, 0, 0),
            AI_Narrative__c = 'Northstar has installed equipment, warranty urgency, and no visible maintenance coverage.',
            AI_Recommended_Actions__c =
                '[{"rank":1,"action_type":"route_specialist","target":"aftermarket coverage review","approval_required":false}]',
            AI_Source_Refs__c =
                '[{"source_id":"svc_asset_001","source_name":"Installed Base","source_type":"service_asset","excerpt":"Indonesia plant equipment is active."}]',
            Intent_Signal_Payload__c =
                '{"signal_label":"Coverage-led review","routing_confidence":0.82,"why_now":"Warranty expiry and missing coverage crossed the routed-review threshold."}'
        );
    }
}
