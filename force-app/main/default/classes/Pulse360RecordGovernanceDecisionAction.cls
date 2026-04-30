public with sharing class Pulse360RecordGovernanceDecisionAction {
    public class Request {
        @InvocableVariable(required=true)
        public Id governanceCaseId;

        @InvocableVariable(required=true)
        public String decision;

        @InvocableVariable(required=true)
        public String reasonCode;

        @InvocableVariable
        public Id survivingAccountId;

        @InvocableVariable
        public Id mergedAccountId;

        @InvocableVariable(required=true)
        public String approvedByUser;

        @InvocableVariable
        public String decisionReasonText;

        @InvocableVariable
        public Boolean reviewFollowupRequired;
    }

    public class Response {
        @InvocableVariable
        public String status;

        @InvocableVariable
        public String payloadJson;
    }

    @InvocableMethod(label='Record Pulse360 Governance Decision')
    public static List<Response> invoke(List<Request> requests) {
        List<Response> responses = new List<Response>();
        if (requests == null || requests.isEmpty()) {
            return responses;
        }

        for (Request request : requests) {
            Pulse360AgentOrchestratorService.ExecutionResult result =
                Pulse360AgentOrchestratorService.recordPulse360GovernanceDecision(
                    request == null ? null : request.governanceCaseId,
                    request == null ? null : request.decision,
                    request == null ? null : request.reasonCode,
                    request == null ? null : request.survivingAccountId,
                    request == null ? null : request.approvedByUser,
                    request == null ? null : request.decisionReasonText,
                    request == null ? null : request.reviewFollowupRequired,
                    request == null ? null : request.mergedAccountId
                );

            Response response = new Response();
            response.status = result.status;
            response.payloadJson = JSON.serialize(result);
            responses.add(response);
        }
        return responses;
    }
}
