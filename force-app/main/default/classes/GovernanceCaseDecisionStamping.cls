public with sharing class GovernanceCaseDecisionStamping {
    private static final Set<String> FINAL_DECISION_STATUSES = new Set<String>{
        'Approved',
        'Rejected',
        'Deferred'
    };

    public static void apply(List<Governance_Case__c> newRecords, Map<Id, Governance_Case__c> oldMap) {
        for (Governance_Case__c governanceCase : newRecords) {
            if (!isFinalDecision(governanceCase.Decision_Status__c)) {
                continue;
            }

            Boolean firstFinalDecision = isFirstFinalDecision(governanceCase, oldMap);
            if (firstFinalDecision) {
                governanceCase.Decided_By__c = UserInfo.getUserId();
                governanceCase.Decided_At__c = System.now();

                if (governanceCase.Decision_Status__c == 'Approved'
                    && String.isBlank(governanceCase.Merge_Execution_Status__c)) {
                    governanceCase.Merge_Execution_Status__c = 'Ready for Merge';
                } else if (governanceCase.Decision_Status__c != 'Approved'
                    && String.isBlank(governanceCase.Merge_Execution_Status__c)) {
                    governanceCase.Merge_Execution_Status__c = 'Not Started';
                }
            }
        }
    }

    private static Boolean isFinalDecision(String decisionStatus) {
        return FINAL_DECISION_STATUSES.contains(decisionStatus);
    }

    private static Boolean isFirstFinalDecision(Governance_Case__c governanceCase, Map<Id, Governance_Case__c> oldMap) {
        if (governanceCase.Id == null || oldMap == null || !oldMap.containsKey(governanceCase.Id)) {
            return true;
        }

        Governance_Case__c oldRecord = oldMap.get(governanceCase.Id);
        return !isFinalDecision(oldRecord.Decision_Status__c);
    }
}
