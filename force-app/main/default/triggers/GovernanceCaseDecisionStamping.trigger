trigger GovernanceCaseDecisionStamping on Governance_Case__c (before insert, before update) {
    GovernanceCaseDecisionStamping.apply(Trigger.new, Trigger.oldMap);
}
