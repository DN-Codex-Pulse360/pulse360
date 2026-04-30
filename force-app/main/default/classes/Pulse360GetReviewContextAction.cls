public with sharing class Pulse360GetReviewContextAction {
    public class Request {
        @InvocableVariable(required=true)
        public Id governanceCaseId;
    }

    public class Response {
        @InvocableVariable
        public Id governanceCaseId;

        @InvocableVariable
        public String payloadJson;
    }

    @InvocableMethod(label='Get Pulse360 Review Context')
    public static List<Response> invoke(List<Request> requests) {
        List<Response> responses = new List<Response>();
        if (requests == null || requests.isEmpty()) {
            return responses;
        }

        for (Request request : requests) {
            Response response = new Response();
            response.governanceCaseId = request == null ? null : request.governanceCaseId;
            response.payloadJson = JSON.serialize(
                Pulse360AgentOrchestratorService.getPulse360ReviewContext(
                    request == null ? null : request.governanceCaseId
                )
            );
            responses.add(response);
        }
        return responses;
    }
}
