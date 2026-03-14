public with sharing class GovernanceCaseDecisionStamping {
    private static final Set<String> FINAL_DECISION_STATUSES = new Set<String>{
        'Approved',
        'Rejected',
        'Deferred'
    };

    public static void apply(List<Governance_Case__c> newRecords, Map<Id, Governance_Case__c> oldMap) {
        for (Governance_Case__c governanceCase : newRecords) {
            if (!shouldStamp(governanceCase, oldMap)) {
                continue;
            }

            governanceCase.Decided_By__c = UserInfo.getUserId();
            governanceCase.Decided_At__c = System.now();

            if (governanceCase.Decision_Status__c == 'Approved') {
                governanceCase.Merge_Execution_Status__c = 'Ready for Merge';
            } else if (String.isBlank(governanceCase.Merge_Execution_Status__c)) {
                governanceCase.Merge_Execution_Status__c = 'Not Started';
            }
        }
    }

    private static Boolean shouldStamp(Governance_Case__c governanceCase, Map<Id, Governance_Case__c> oldMap) {
        if (!FINAL_DECISION_STATUSES.contains(governanceCase.Decision_Status__c)) {
            return false;
        }

        if (governanceCase.Id == null || oldMap == null || !oldMap.containsKey(governanceCase.Id)) {
            return true;
        }

        Governance_Case__c oldRecord = oldMap.get(governanceCase.Id);
        return oldRecord.Decision_Status__c != governanceCase.Decision_Status__c
            || oldRecord.Decision_Reason_Code__c != governanceCase.Decision_Reason_Code__c
            || governanceCase.Decided_By__c == null
            || governanceCase.Decided_At__c == null;
    }
}
