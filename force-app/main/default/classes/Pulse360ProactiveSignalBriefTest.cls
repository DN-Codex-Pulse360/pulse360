@IsTest
private class Pulse360ProactiveSignalBriefTest {
    @IsTest
    static void returnsGroundedProactiveSignalBrief() {
        Account accountRecord = new Account(
            Name = 'Northstar Foods Group',
            Coverage_Gap_Flag__c = true,
            DataCloud_Last_Synced__c = Datetime.newInstance(2026, 6, 30, 12, 58, 26),
            AI_Narrative_Generated__c = Datetime.newInstance(2026, 6, 30, 13, 0, 0),
            AI_Narrative__c = 'Northstar has installed equipment, warranty urgency, and no visible maintenance coverage.',
            AI_Recommended_Actions__c =
                '[{"rank":1,"action_type":"recommend_next_move","target":"aftermarket coverage review","approval_required":false},{"rank":2,"action_type":"create_opportunity","target":"preventive maintenance proposal","approval_required":true}]',
            AI_Source_Refs__c =
                '[{"source_id":"svc_asset_001","source_name":"Installed Base","source_type":"service_asset","excerpt":"Indonesia plant equipment is active."}]',
            Intent_Signal_Payload__c =
                '{"signal_label":"Coverage-led review","routing_confidence":0.82,"why_now":"Warranty expiry and missing coverage crossed the routed-review threshold."}'
        );
        insert accountRecord;

        Pulse360GetProactiveSignalBriefAction.Request request =
            new Pulse360GetProactiveSignalBriefAction.Request();
        request.accountId = accountRecord.Id;
        request.userGoal = 'Explain why this account needs attention.';

        Test.startTest();
        List<Pulse360GetProactiveSignalBriefAction.Response> results =
            Pulse360GetProactiveSignalBriefAction.invoke(
                new List<Pulse360GetProactiveSignalBriefAction.Request>{ request }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        Pulse360GetProactiveSignalBriefAction.Response actionResult = results[0];
        System.assertEquals('ready', actionResult.status);
        System.assertEquals('runtime_unproven', actionResult.runtimeState);
        System.assert(actionResult.briefJson.contains('Northstar Foods Group'));
        System.assert(actionResult.briefJson.contains('maintenance_coverage_gap'));
        System.assert(actionResult.sourceRefsJson.contains('svc_asset_001'));
        System.assert(actionResult.approvalPolicyJson.contains('downstream_effects_require_confirmation'));
    }

    @IsTest
    static void blocksMissingAccountId() {
        Pulse360GetProactiveSignalBriefAction.Request request =
            new Pulse360GetProactiveSignalBriefAction.Request();

        Test.startTest();
        List<Pulse360GetProactiveSignalBriefAction.Response> results =
            Pulse360GetProactiveSignalBriefAction.invoke(
                new List<Pulse360GetProactiveSignalBriefAction.Request>{ request }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals('blocked_missing_account_id', results[0].status);
        System.assertEquals('runtime_unproven', results[0].runtimeState);
    }

    @IsTest
    static void requiresReviewWhenSourceRefsAreMissing() {
        Account accountRecord = new Account(
            Name = 'Northstar Foods Group',
            Coverage_Gap_Flag__c = true,
            AI_Narrative__c = 'Signal exists but source references are missing.'
        );
        insert accountRecord;

        Pulse360GetProactiveSignalBriefAction.Request request =
            new Pulse360GetProactiveSignalBriefAction.Request();
        request.accountId = accountRecord.Id;

        Test.startTest();
        List<Pulse360GetProactiveSignalBriefAction.Response> results =
            Pulse360GetProactiveSignalBriefAction.invoke(
                new List<Pulse360GetProactiveSignalBriefAction.Request>{ request }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals('review_required_missing_source_refs', results[0].status);
        System.assertEquals('[]', results[0].sourceRefsJson);
    }
}
