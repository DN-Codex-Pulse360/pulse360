@IsTest
private class GovernanceCaseDecisionStampingTest {
    @IsTest
    static void stampsApprovedDecisionAndMergeStatus() {
        Account leftAccount = new Account(Name = 'Left Test Account');
        Account rightAccount = new Account(Name = 'Right Test Account');
        insert new List<Account>{ leftAccount, rightAccount };

        Governance_Case__c governanceCase = new Governance_Case__c(
            Status__c = 'In Review',
            Priority__c = 'Medium',
            Left_Account__c = leftAccount.Id,
            Right_Account__c = rightAccount.Id
        );
        insert governanceCase;

        governanceCase.Decision_Status__c = 'Approved';
        governanceCase.Decision_Reason_Code__c = 'CLEAR_DUPLICATE_MATCH';
        governanceCase.Surviving_Account__c = leftAccount.Id;
        governanceCase.Merged_Account__c = rightAccount.Id;

        Test.startTest();
        update governanceCase;
        Test.stopTest();

        Governance_Case__c stampedCase = [
            SELECT Decision_Status__c, Decided_By__c, Decided_At__c, Merge_Execution_Status__c
            FROM Governance_Case__c
            WHERE Id = :governanceCase.Id
        ];

        System.assertEquals('Approved', stampedCase.Decision_Status__c);
        System.assertEquals(UserInfo.getUserId(), stampedCase.Decided_By__c);
        System.assertNotEquals(null, stampedCase.Decided_At__c);
        System.assertEquals('Ready for Merge', stampedCase.Merge_Execution_Status__c);
    }

    @IsTest
    static void stampsRejectedDecisionWithoutMergePreparation() {
        Governance_Case__c governanceCase = new Governance_Case__c(
            Status__c = 'In Review',
            Priority__c = 'Low'
        );
        insert governanceCase;

        governanceCase.Decision_Status__c = 'Rejected';
        governanceCase.Decision_Reason_Code__c = 'FALSE_POSITIVE_MODEL_OUTPUT';

        Test.startTest();
        update governanceCase;
        Test.stopTest();

        Governance_Case__c stampedCase = [
            SELECT Decision_Status__c, Decided_By__c, Decided_At__c, Merge_Execution_Status__c
            FROM Governance_Case__c
            WHERE Id = :governanceCase.Id
        ];

        System.assertEquals('Rejected', stampedCase.Decision_Status__c);
        System.assertEquals(UserInfo.getUserId(), stampedCase.Decided_By__c);
        System.assertNotEquals(null, stampedCase.Decided_At__c);
        System.assertEquals('Not Started', stampedCase.Merge_Execution_Status__c);
    }
}
