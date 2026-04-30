@IsTest
private class Pulse360SellerWorkspaceServiceTest {
    @IsTest
    static void buildsWorkspaceWithHierarchyAndMatchedPlay() {
        Account coveredChild = new Account(Name = 'NCS Pte. Ltd.');
        insert coveredChild;

        Account accountRecord = new Account(
            Name = 'Singtel Group',
            BillingCountry = 'Singapore',
            Primary_Brand_Name__c = 'Singtel',
            External_Legal_Name__c = 'Singapore Telecommunications Limited',
            Group_Revenue_Rollup__c = Decimal.valueOf('14146100000'),
            Group_Revenue_Visible__c = Decimal.valueOf('10400000000'),
            Group_Known_Subsidiary_Count__c = 3,
            CRM_Covered_Subsidiary_Count__c = 2,
            External_Subsidiaries_Found__c = 1,
            Active_Product_Count__c = 9,
            Open_Opportunity_Count__c = 4,
            Engagement_Intensity_Score__c = 79,
            Cross_Sell_Propensity__c = 82,
            Competitor_Risk_Signal__c = 67,
            Health_Score__c = 88,
            Coverage_Gap_Flag__c = true,
            Externally_Validated__c = true,
            Last_Engagement_Timestamp__c = Datetime.now().addDays(-6),
            DataCloud_Last_Synced__c = Datetime.now().addDays(-3),
            AI_Narrative__c = 'Public evidence confirms group scale and current AI hiring momentum.',
            AI_Model_Id__c = 'gpt-5.4',
            AI_Prompt_Version__c = 'pulse360-public-regional-v1',
            AI_Citation_Count__c = 2,
            AI_Narrative_Generated__c = Datetime.now().addDays(-3),
            Enrichment_Run_Id__c = 'run_public_regional_20260328',
            AI_Recommended_Actions__c = '[{"rank":1,"action_type":"create_opportunity","target":"NCS data and AI modernization program","reasoning":"Official FY2025 disclosures identify NCS as a growth driver and current hiring supports a modernization discussion.","estimated_revenue_impact":"S$12M influenced pipeline","confidence":0.84,"source_ids":["singtel_fy2025_results","singtel_aida_jobs"]}]',
            AI_Source_Refs__c = '[{"source_id":"singtel_fy2025_results","source_name":"Singtel FY2025 Financial Results","source_type":"annual_report","source_url":"https://example.com/fy25","document_date":"2025-05-22","accessed_at":"2026-03-28T00:00:00Z","excerpt":"Operating revenue remained stable for FY2025 while net profit increased.","jurisdiction":"SG"},{"source_id":"singtel_aida_jobs","source_name":"Singtel AIDA Jobs","source_type":"careers","source_url":"https://example.com/jobs","document_date":"2026-02-15","accessed_at":"2026-03-28T00:00:00Z","excerpt":"Singtel advertised AIDA and AI platform engineering roles in Singapore.","jurisdiction":"SG"}]'
        );
        insert accountRecord;

        accountRecord.Hierarchy_Payload__c =
            '{"group_id":"grp_singtel","children":[' +
            '{"entity_id":"ent_sg_001","crm_record_id":"' + accountRecord.Id + '","name":"Singtel Group","role":"Current account anchor","coverage_status":"covered","in_crm":true,"signal":"Core Singtel coverage exists in CRM, but the operating group is only partially represented."},' +
            '{"entity_id":"ent_sg_002","crm_record_id":"' + coveredChild.Id + '","name":"NCS Pte. Ltd.","role":"CRM-covered delivery subsidiary","coverage_status":"covered","in_crm":true,"signal":"NCS is already represented in CRM and is the clearest data and AI expansion path.","suggested_play":"Data and AI modernization"},' +
            '{"entity_id":"ent_sg_003","name":"Optus","role":"Whitespace growth entity","coverage_status":"uncovered","in_crm":false,"signal":"Public disclosures position Optus as a growth engine, but the seller cannot work it directly from CRM yet.","suggested_play":"Group coverage follow-up"}]}';
        update accountRecord;

        Test.startTest();
        Pulse360SellerWorkspaceService.WorkspaceResult result = Pulse360SellerWorkspaceService.getSellerWorkspace(accountRecord.Id);
        Test.stopTest();

        System.assertEquals(accountRecord.Id, result.accountId);
        System.assertEquals('Singtel Group', result.accountName);
        System.assertEquals('Singtel', result.primaryBrandName);
        System.assertEquals(Decimal.valueOf('3746100000'), result.hiddenRevenue);
        System.assertEquals('Active momentum', result.engagementLabel);
        System.assertEquals(true, result.hierarchyReady);
        System.assertEquals(3, result.hierarchyEntities.size());
        System.assertEquals('CRM anchor', result.hierarchyEntities[0].coverageLabel);
        System.assertEquals(accountRecord.Id, result.hierarchyEntities[0].crmRecordId);
        System.assertEquals('Current account anchor', result.hierarchyEntities[0].entityRole);
        System.assertEquals('CRM-covered', result.hierarchyEntities[1].coverageLabel);
        System.assertEquals(coveredChild.Id, result.hierarchyEntities[1].crmRecordId);
        System.assertEquals('Data and AI modernization', result.hierarchyEntities[1].suggestedPlay);
        System.assertEquals('Whitespace target', result.hierarchyEntities[2].coverageLabel);
        System.assertNotEquals(null, result.primaryAction);
        System.assertEquals('NCS', result.primaryAction.targetEntity);
        System.assertEquals('Data and AI Modernization', result.primaryAction.solutionFamily);
        System.assertEquals('Modernize the enterprise data and AI platform', result.primaryAction.recommendedPlay);
        System.assertEquals('Create Opportunity', result.primaryAction.buttonLabel);
        System.assertEquals(2, result.primaryAction.supportingSources.size());
    }

    @IsTest
    static void buildsFallbackActionPackWithoutHierarchyPayload() {
        Account accountRecord = new Account(
            Name = 'Ayala Corporation',
            BillingCountry = 'Philippines',
            Group_Revenue_Rollup__c = Decimal.valueOf('325700000000'),
            Group_Revenue_Visible__c = Decimal.valueOf('184000000000'),
            Group_Known_Subsidiary_Count__c = 4,
            CRM_Covered_Subsidiary_Count__c = 2,
            Last_Engagement_Timestamp__c = Datetime.now().addDays(-120),
            DataCloud_Last_Synced__c = Datetime.now().addDays(-45),
            AI_Recommended_Actions__c = '[{"rank":1,"action_type":"create_task","target":"Validate uncovered group coverage","reasoning":"CRM coverage understates the breadth of the operating portfolio.","estimated_revenue_impact":"Improved planning cycle","confidence":0.62,"source_ids":[]}]'
        );
        insert accountRecord;

        Test.startTest();
        Pulse360SellerWorkspaceService.WorkspaceResult result = Pulse360SellerWorkspaceService.getSellerWorkspace(accountRecord.Id);
        Test.stopTest();

        System.assertEquals('PHP', result.currencyCode);
        System.assertEquals(false, result.hierarchyReady);
        System.assertEquals(1, result.hierarchyEntities.size());
        System.assertEquals('Low momentum', result.engagementLabel);
        System.assertEquals('Refresh recommended', result.freshnessLabel);
        System.assertEquals('Account Coverage', result.primaryAction.solutionFamily);
        System.assertEquals('Validate uncovered group coverage', result.primaryAction.recommendedPlay);
        System.assertEquals('Create Task', result.primaryAction.buttonLabel);
    }
}
