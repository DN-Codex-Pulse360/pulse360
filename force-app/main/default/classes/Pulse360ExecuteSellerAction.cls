public with sharing class Pulse360ExecuteSellerAction {
    public class Request {
        @InvocableVariable(required=true)
        public Id recordId;

        @InvocableVariable
        public String actionType;

        @InvocableVariable
        public String targetRecordId;

        @InvocableVariable
        public String approvalMode;

        @InvocableVariable
        public String accountName;

        @InvocableVariable
        public String targetEntity;

        @InvocableVariable
        public String recommendedPlay;

        @InvocableVariable
        public String solutionFamily;

        @InvocableVariable
        public String specialistRoute;

        @InvocableVariable
        public String reasoning;

        @InvocableVariable
        public String estimatedRevenueImpact;

        @InvocableVariable
        public String buyingGroupGap;

        @InvocableVariable
        public String outreachObjective;

        @InvocableVariable
        public String promptVersion;

        @InvocableVariable
        public String confidenceLabel;

        @InvocableVariable
        public Decimal confidence;

        @InvocableVariable
        public String sourceContext;

        @InvocableVariable
        public String agentGoal;
    }

    public class Response {
        @InvocableVariable
        public String status;

        @InvocableVariable
        public String payloadJson;
    }

    @InvocableMethod(label='Execute Pulse360 Seller Action')
    public static List<Response> invoke(List<Request> requests) {
        List<Response> responses = new List<Response>();
        if (requests == null || requests.isEmpty()) {
            return responses;
        }

        for (Request request : requests) {
            Pulse360SellerOrchestratorService.ExecutionRequest executionRequest =
                new Pulse360SellerOrchestratorService.ExecutionRequest();
            if (request != null) {
                executionRequest.recordId = request.recordId == null ? null : String.valueOf(request.recordId);
                executionRequest.actionType = request.actionType;
                executionRequest.targetRecordId = request.targetRecordId;
                executionRequest.approvalMode = request.approvalMode;
                executionRequest.accountName = request.accountName;
                executionRequest.targetEntity = request.targetEntity;
                executionRequest.recommendedPlay = request.recommendedPlay;
                executionRequest.solutionFamily = request.solutionFamily;
                executionRequest.specialistRoute = request.specialistRoute;
                executionRequest.reasoning = request.reasoning;
                executionRequest.estimatedRevenueImpact = request.estimatedRevenueImpact;
                executionRequest.buyingGroupGap = request.buyingGroupGap;
                executionRequest.outreachObjective = request.outreachObjective;
                executionRequest.promptVersion = request.promptVersion;
                executionRequest.confidenceLabel = request.confidenceLabel;
                executionRequest.confidence = request.confidence;
                executionRequest.sourceContext = request.sourceContext;
                executionRequest.agentGoal = request.agentGoal;
            }

            Pulse360SellerOrchestratorService.ExecutionResult result =
                Pulse360SellerOrchestratorService.executePulse360SellerAction(executionRequest);

            Response response = new Response();
            response.status = result.status;
            response.payloadJson = JSON.serialize(result);
            responses.add(response);
        }
        return responses;
    }
}
