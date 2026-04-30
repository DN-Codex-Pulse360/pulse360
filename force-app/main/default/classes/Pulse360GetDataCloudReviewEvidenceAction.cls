public with sharing class Pulse360GetDataCloudReviewEvidenceAction {
    public class Request {
        @InvocableVariable
        public String candidatePairId;

        @InvocableVariable
        public Id leftAccountId;

        @InvocableVariable
        public Id rightAccountId;
    }

    public class Response {
        @InvocableVariable
        public Boolean available;

        @InvocableVariable
        public String payloadJson;

        @InvocableVariable
        public String errorMessage;
    }

    @InvocableMethod(label='Get Pulse360 Data Cloud Review Evidence')
    public static List<Response> invoke(List<Request> requests) {
        List<Response> responses = new List<Response>();
        if (requests == null || requests.isEmpty()) {
            return responses;
        }

        for (Request request : requests) {
            Pulse360AgentOrchestratorService.ReviewEvidence evidence =
                Pulse360AgentOrchestratorService.getPulse360DataCloudReviewEvidence(
                    request == null ? null : request.candidatePairId,
                    request == null ? null : request.leftAccountId,
                    request == null ? null : request.rightAccountId
                );

            Response response = new Response();
            response.available = evidence != null && evidence.available;
            response.payloadJson = JSON.serialize(evidence);
            response.errorMessage = evidence == null ? 'No evidence response returned.' : evidence.errorMessage;
            responses.add(response);
        }
        return responses;
    }
}
