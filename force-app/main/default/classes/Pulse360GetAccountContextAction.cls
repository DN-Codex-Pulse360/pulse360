public with sharing class Pulse360GetAccountContextAction {
    public class Request {
        @InvocableVariable(required=true)
        public Id accountId;
    }

    public class Response {
        @InvocableVariable
        public Id accountId;

        @InvocableVariable
        public String payloadJson;
    }

    @InvocableMethod(label='Get Pulse360 Account Context')
    public static List<Response> invoke(List<Request> requests) {
        List<Response> responses = new List<Response>();
        if (requests == null || requests.isEmpty()) {
            return responses;
        }

        for (Request request : requests) {
            Response response = new Response();
            response.accountId = request == null ? null : request.accountId;
            response.payloadJson = JSON.serialize(
                Pulse360SellerOrchestratorService.getPulse360AccountContext(
                    request == null ? null : request.accountId
                )
            );
            responses.add(response);
        }
        return responses;
    }
}
