@IsTest
private class Pulse360HealthScanServiceTest {
    @IsTest
    static void runsHealthScanForAccount() {
        Account accountRecord = new Account(
            Name = 'Singtel Group',
            BillingCountry = 'Singapore',
            Health_Score__c = 88,
            Regulatory_Readiness_Score__c = 72,
            Duplicate_Exposure_Count__c = 1,
            Group_Revenue_Rollup__c = Decimal.valueOf('14146100000'),
            Group_Revenue_Visible__c = Decimal.valueOf('10400000000'),
            Group_Known_Subsidiary_Count__c = 3,
            CRM_Covered_Subsidiary_Count__c = 2,
            Externally_Validated__c = true,
            External_Legal_Name__c = 'Singapore Telecommunications Limited',
            Validity_Score_External__c = 93,
            AI_Narrative__c = 'Public evidence confirms group scale and current AI hiring momentum.',
            AI_Narrative_Generated__c = System.now(),
            Enrichment_Run_Id__c = 'run_public_regional_20260328',
            AI_Model_Id__c = 'gpt-5.4',
            AI_Prompt_Version__c = 'pulse360-public-regional-v1',
            AI_Citation_Count__c = 2,
            DataCloud_Last_Synced__c = System.now(),
            AI_Recommended_Actions__c = '[{"rank":1,"action_type":"create_opportunity","target":"NCS modernization program","reasoning":"Public FY2025 disclosures and current AI hiring support the account opportunity.","estimated_revenue_impact":"S$12M influenced pipeline","confidence":0.84,"source_ids":["singtel_fy2025_results","singtel_aida_jobs"]}]',
            AI_Source_Refs__c = '[{"source_id":"singtel_fy2025_results","source_name":"Singtel FY2025 Financial Results","source_type":"annual_report","source_url":"https://www.singtel.com/content/dam/singtel/investorRelations/stockExchange/2025/FY25-MDA.pdf","document_date":"2025-05-22","accessed_at":"2026-03-28T00:00:00Z","excerpt":"Operating revenue remained stable for FY2025 while net profit increased.","jurisdiction":"SG"}]'
        );
        insert accountRecord;

        Test.startTest();
        Pulse360HealthScanService.HealthScanResult result = Pulse360HealthScanService.runHealthScan(accountRecord.Id);
        Test.stopTest();

        System.assertEquals(accountRecord.Id, result.accountId);
        System.assertEquals('Singtel Group', result.accountName);
        System.assertEquals(88, result.healthScore);
        System.assertEquals(72, result.regulatoryReadinessScore);
        System.assertEquals(2, result.crmCoveredSubsidiaryCount);
        System.assertEquals('SGD', result.currencyCode);
        System.assertEquals(1, result.actions.size());
        System.assertEquals(1, result.sourceRefs.size());
        System.assertEquals('gpt-5.4', result.modelId);
        System.assertEquals('pulse360-public-regional-v1', result.promptVersion);
    }

    @IsTest
    static void returnsEmptyCollectionsWhenJsonFieldsAreBlank() {
        Account accountRecord = new Account(
            Name = 'Ayala Corporation',
            BillingCountry = 'Philippines'
        );
        insert accountRecord;

        Test.startTest();
        Pulse360HealthScanService.HealthScanResult result = Pulse360HealthScanService.runHealthScan(accountRecord.Id);
        Test.stopTest();

        System.assertEquals('PHP', result.currencyCode);
        System.assertEquals(0, result.actions.size());
        System.assertEquals(0, result.sourceRefs.size());
    }
}
