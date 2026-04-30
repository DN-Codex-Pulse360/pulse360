@IsTest
private class Pulse360SignalRoutingServiceTest {
    @IsTest
    static void returnsPayloadBackedRoutingWorkspace() {
        Account accountRecord = new Account(
            Name = 'Signal Payload Holdings',
            BillingCountry = 'Singapore',
            Group_Revenue_Rollup__c = 8000000,
            Group_Revenue_Visible__c = 5000000,
            Cross_Sell_Propensity__c = 84,
            Engagement_Intensity_Score__c = 73,
            Competitor_Risk_Signal__c = 61,
            Coverage_Gap_Flag__c = true,
            DataCloud_Last_Synced__c = Datetime.now().addDays(-2),
            AI_Narrative_Generated__c = Datetime.now().addDays(-1),
            AI_Narrative__c = 'Payload-backed account narrative.',
            AI_Model_Id__c = 'gpt-5.4',
            AI_Prompt_Version__c = 'pulse360-intent-routing-v1',
            AI_Recommended_Actions__c =
                '[{"rank":1,"action_type":"create_task","target":"Regional expansion review","target_record_id":"","reasoning":"Whitespace and engagement justify a routed review.","estimated_revenue_impact":"SGD 1.2M influenced pipeline","confidence":0.82,"source_ids":["payload_source"]}]',
            AI_Source_Refs__c =
                '[{"source_id":"payload_source","source_name":"Payload Source","source_type":"memo","source_url":"https://example.com/payload","document_date":"2026-04-19","accessed_at":"2026-04-19T00:00:00Z","excerpt":"Payload-backed rationale.","jurisdiction":"SG"}]',
            Intent_Signal_Payload__c =
                '{"signal_score":92,"signal_label":"Route now","threshold_label":"Payload threshold crossed.","route_to":"account_owner_plus_coverage","routing_confidence":0.89,"why_now":"Payload-backed routed alert.","drafted_outreach":"Payload-backed outreach draft.","channel_readiness":"salesforce_preview","top_drivers":["Driver one","Driver two","Driver three"]}'
        );
        insert accountRecord;

        insert new Contact(
            AccountId = accountRecord.Id,
            LastName = 'Ng',
            FirstName = 'Alicia',
            Title = 'SVP, Strategy',
            Department = 'Strategy',
            Email = 'alicia.ng@example.com'
        );

        Test.startTest();
        Pulse360SignalRoutingWorkspaceService.WorkspaceResult result =
            Pulse360SignalRoutingWorkspaceService.getRoutingWorkspace(accountRecord.Id);
        Test.stopTest();

        System.assertEquals(true, result.payloadBacked);
        System.assertEquals('Route now', result.signalLabel);
        System.assertEquals('Activated intent payload', result.payloadModeLabel);
        System.assertEquals('Payload-backed routed alert.', result.whyNow);
        System.assertEquals(1, result.targetContacts.size());
        System.assertEquals('Alicia Ng', result.targetContacts[0].contactName);
        System.assertEquals('Regional expansion review', result.primaryAction.recommendedPlay);
    }

    @IsTest
    static void returnsSortedFallbackQueueWhenPayloadIsAbsent() {
        insert new Account(
            Name = 'High Signal Account',
            BillingCountry = 'Philippines',
            Cross_Sell_Propensity__c = 88,
            Engagement_Intensity_Score__c = 74,
            Competitor_Risk_Signal__c = 63,
            Coverage_Gap_Flag__c = true,
            DataCloud_Last_Synced__c = Datetime.now().addDays(-3),
            AI_Narrative_Generated__c = Datetime.now().addDays(-2)
        );
        insert new Account(
            Name = 'Monitor Account',
            BillingCountry = 'Philippines',
            Cross_Sell_Propensity__c = 51,
            Engagement_Intensity_Score__c = 42,
            Competitor_Risk_Signal__c = 25,
            Coverage_Gap_Flag__c = false,
            DataCloud_Last_Synced__c = Datetime.now().addDays(-12),
            AI_Narrative_Generated__c = Datetime.now().addDays(-12)
        );

        Test.startTest();
        List<Pulse360SignalRoutingWorkspaceService.QueueItem> queueItems =
            Pulse360SignalRoutingWorkspaceService.getRoutingQueue(10);
        Test.stopTest();

        System.assertEquals(2, queueItems.size());
        System.assertEquals('High Signal Account', queueItems[0].accountName);
        System.assertEquals(false, queueItems[0].payloadBacked);
        System.assertEquals('Route now', queueItems[0].signalLabel);
        System.assertEquals('Monitor', queueItems[1].signalLabel);
    }
}
