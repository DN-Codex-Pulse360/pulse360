@IsTest
private class Pulse360SellerDirServiceTest {
    @IsTest
    static void returnsPreviewAccountsOrderedByCommercialWeight() {
        insert new Account(
            Name = 'Singtel Group',
            BillingCountry = 'Singapore',
            Primary_Brand_Name__c = 'Singtel',
            Group_Revenue_Rollup__c = Decimal.valueOf('14146100000'),
            Group_Revenue_Visible__c = Decimal.valueOf('10400000000'),
            Coverage_Gap_Flag__c = true,
            Cross_Sell_Propensity__c = 84,
            Health_Score__c = 76,
            DataCloud_Last_Synced__c = Datetime.now().addDays(-2),
            AI_Narrative_Generated__c = Datetime.now().addDays(-2)
        );
        insert new Account(
            Name = 'Ayala Corporation',
            BillingCountry = 'Philippines',
            Group_Revenue_Rollup__c = Decimal.valueOf('325700000000'),
            Group_Revenue_Visible__c = Decimal.valueOf('317000000000'),
            Coverage_Gap_Flag__c = false,
            Cross_Sell_Propensity__c = 61,
            Health_Score__c = 48,
            DataCloud_Last_Synced__c = Datetime.now().addDays(-15),
            AI_Narrative_Generated__c = Datetime.now().addDays(-15)
        );

        Test.startTest();
        List<Pulse360SellerWorkspaceDirectoryService.PreviewAccount> results =
            Pulse360SellerWorkspaceDirectoryService.getPreviewAccounts(10);
        Test.stopTest();

        System.assertEquals(2, results.size());
        System.assertEquals('Ayala Corporation', results[0].accountName);
        System.assertEquals('PHP', results[0].currencyCode);
        System.assertEquals(false, results[0].coverageGapFlag);
        System.assertEquals('Monitor freshness', results[0].freshnessLabel);

        System.assertEquals('Singtel Group', results[1].accountName);
        System.assertEquals('Singtel', results[1].primaryBrandName);
        System.assertEquals(Decimal.valueOf('3746100000'), results[1].hiddenRevenue);
        System.assertEquals(true, results[1].coverageGapFlag);
        System.assertEquals('Fresh', results[1].freshnessLabel);
    }

    @IsTest
    static void returnsEmptyListWhenNoQualifiedAccountsExist() {
        insert new Account(Name = 'Plain Account');

        Test.startTest();
        List<Pulse360SellerWorkspaceDirectoryService.PreviewAccount> results =
            Pulse360SellerWorkspaceDirectoryService.getPreviewAccounts(10);
        Test.stopTest();

        System.assertEquals(0, results.size());
    }
}
