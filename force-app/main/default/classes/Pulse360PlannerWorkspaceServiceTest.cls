@IsTest
private class Pulse360PlannerWorkspaceServiceTest {
    @IsTest
    static void ranksGroupsAndBuildsPlannerQueue() {
        Account strategicCoverageGap = new Account(
            Name = 'Singtel Group',
            BillingCountry = 'Singapore',
            Primary_Brand_Name__c = 'Singtel',
            Group_Revenue_Rollup__c = Decimal.valueOf('14146100000'),
            Group_Revenue_Visible__c = Decimal.valueOf('10400000000'),
            Group_Known_Subsidiary_Count__c = 4,
            CRM_Covered_Subsidiary_Count__c = 2,
            Open_Opportunity_Count__c = 3,
            Cross_Sell_Propensity__c = 84,
            Competitor_Risk_Signal__c = 41,
            Health_Score__c = 79,
            Coverage_Gap_Flag__c = true,
            Externally_Validated__c = true,
            DataCloud_Last_Synced__c = Datetime.now().addDays(-2),
            AI_Narrative_Generated__c = Datetime.now().addDays(-2)
        );
        insert strategicCoverageGap;

        strategicCoverageGap.Hierarchy_Payload__c =
            '{"group_id":"grp_singtel","children":[' +
            '{"entity_id":"ent_sg_001","crm_record_id":"' + strategicCoverageGap.Id + '","name":"Singtel Group","coverage_status":"covered","in_crm":true},' +
            '{"entity_id":"ent_sg_002","name":"Optus","coverage_status":"uncovered","in_crm":false},' +
            '{"entity_id":"ent_sg_003","name":"NCS Pte. Ltd.","coverage_status":"covered","in_crm":true}' +
            ']}';
        update strategicCoverageGap;

        Account riskReview = new Account(
            Name = 'Ayala Corporation',
            BillingCountry = 'Philippines',
            Group_Revenue_Rollup__c = Decimal.valueOf('325700000000'),
            Group_Revenue_Visible__c = Decimal.valueOf('317000000000'),
            Group_Known_Subsidiary_Count__c = 5,
            CRM_Covered_Subsidiary_Count__c = 5,
            Open_Opportunity_Count__c = 1,
            Cross_Sell_Propensity__c = 58,
            Competitor_Risk_Signal__c = 79,
            Health_Score__c = 34,
            Coverage_Gap_Flag__c = false,
            Externally_Validated__c = true,
            DataCloud_Last_Synced__c = Datetime.now().addDays(-12),
            AI_Narrative_Generated__c = Datetime.now().addDays(-12)
        );
        insert riskReview;

        Account watchlist = new Account(
            Name = 'Regional Services Holdings',
            BillingCountry = 'United States',
            Group_Revenue_Rollup__c = Decimal.valueOf('180000000'),
            Group_Revenue_Visible__c = Decimal.valueOf('175000000'),
            Group_Known_Subsidiary_Count__c = 2,
            CRM_Covered_Subsidiary_Count__c = 2,
            Open_Opportunity_Count__c = 2,
            Cross_Sell_Propensity__c = 36,
            Competitor_Risk_Signal__c = 18,
            Health_Score__c = 83,
            Coverage_Gap_Flag__c = false,
            Externally_Validated__c = false
        );
        insert watchlist;

        Test.startTest();
        Pulse360PlannerWorkspaceService.WorkspaceResult result = Pulse360PlannerWorkspaceService.getPlannerWorkspace(10);
        Test.stopTest();

        System.assertEquals('Pulse360 Planner Workspace', result.title);
        System.assertEquals(3, result.groups.size());
        System.assertEquals(strategicCoverageGap.Id, result.groups[0].accountId);
        System.assertEquals('Strategic', result.groups[0].suggestedTier);
        System.assertEquals('Assign owner to uncovered entities', result.groups[0].nextPlanningAction);
        System.assertEquals('Optus', result.groups[0].topUncoveredEntity);
        System.assertEquals('Executive now', result.groups[0].priorityBand);
        System.assertEquals('Fresh', result.groups[0].freshnessLabel);

        System.assertEquals(5, result.metrics.size());
        System.assertEquals('3', result.metrics[0].value);
        System.assertEquals('1', result.metrics[1].value);
        System.assertEquals('2', result.metrics[2].value);
        System.assertEquals('1', result.metrics[3].value);

        System.assertEquals(3, result.actionQueue.size());
        System.assertEquals('Singtel Group', result.actionQueue[0].accountName);
        System.assert(result.timeline.size() >= 4);
        Set<String> timelineTitles = new Set<String>();
        Set<String> timelineTypes = new Set<String>();
        for (Pulse360PlannerWorkspaceService.PlannerTimelineEvent item : result.timeline) {
            timelineTitles.add(item.title);
            timelineTypes.add(item.typeLabel);
        }
        System.assert(timelineTitles.contains('AI planning brief refreshed'));
        System.assert(timelineTitles.contains('Risk watch elevated'));
        System.assert(timelineTypes.contains('AI brief'));
        System.assert(result.highlightedInsight.contains('Singtel Group'));
        System.assertEquals('Assign owner to uncovered entities for Singtel Group.', result.highlightedAction);
    }

    @IsTest
    static void returnsEmptyWorkspaceWhenPortfolioSignalsAreMissing() {
        insert new Account(Name = 'Plain Account');

        Test.startTest();
        Pulse360PlannerWorkspaceService.WorkspaceResult result = Pulse360PlannerWorkspaceService.getPlannerWorkspace(8);
        Test.stopTest();

        System.assertEquals(0, result.groups.size());
        System.assertEquals(5, result.metrics.size());
        System.assertEquals(0, result.actionQueue.size());
        System.assertEquals(0, result.timeline.size());
        System.assert(result.highlightedInsight.contains('No ranked groups are available yet'));
    }
}
