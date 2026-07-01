public with sharing class Pulse360PrepReviewTaskAction {
    private static final Set<String> TASK_ACTION_TYPES = new Set<String>{
        'create_task',
        'route_specialist'
    };

    public class Request {
        @InvocableVariable(label='Account Id' description='Salesforce Account Id for the proactive signal action.' required=true)
        public Id accountId;

        @InvocableVariable(label='Confirmed' description='True only after the user confirms the downstream CRM Task creation.' required=true)
        public Boolean confirmed;

        @InvocableVariable(label='Requested Action Type' description='Expected values: create_task or route_specialist.')
        public String requestedActionType;

        @InvocableVariable(label='Next Move' description='Seller-facing next move to include on the Task.')
        public String nextMove;
    }

    public class Response {
        @InvocableVariable(label='Status' description='Task action status or block reason.')
        public String status;

        @InvocableVariable(label='Account Id' description='Salesforce Account Id used for the Task action.')
        public Id accountId;

        @InvocableVariable(label='Task Id' description='Created Salesforce Task Id when a Task was created.')
        public Id taskId;

        @InvocableVariable(label='Task URL' description='Relative Salesforce URL for the created Task.')
        public String taskUrl;

        @InvocableVariable(label='Audit JSON' description='Agent-readable audit payload for confirmation, gating, and source evidence.')
        public String auditJson;
    }

    @InvocableMethod(
        label='Prepare Account Review Task'
        description='Creates a confirmation-gated Salesforce Task for a source-backed Pulse360 proactive Account signal.'
    )
    public static List<Response> invoke(List<Request> requests) {
        List<Response> responses = new List<Response>();
        if (requests == null || requests.isEmpty()) {
            responses.add(blocked(null, 'blocked_missing_account_id', 'Account Id is required.', null));
            return responses;
        }

        Set<Id> accountIds = new Set<Id>();
        for (Request request : requests) {
            if (request != null && request.accountId != null) {
                accountIds.add(request.accountId);
            }
        }

        Map<Id, Account> accountsById = new Map<Id, Account>();
        if (!accountIds.isEmpty()) {
            accountsById = new Map<Id, Account>([
                SELECT
                    Id,
                    Name,
                    OwnerId,
                    Coverage_Gap_Flag__c,
                    DataCloud_Last_Synced__c,
                    AI_Narrative_Generated__c,
                    AI_Narrative__c,
                    AI_Recommended_Actions__c,
                    AI_Source_Refs__c,
                    Intent_Signal_Payload__c
                FROM Account
                WHERE Id IN :accountIds
            ]);
        }

        List<Task> tasksToInsert = new List<Task>();
        List<Integer> responseIndexes = new List<Integer>();

        for (Request request : requests) {
            Response response = validateRequest(request, accountsById);
            if (response.status != 'ready_to_create') {
                responses.add(response);
                continue;
            }

            Account accountRecord = accountsById.get(request.accountId);
            responses.add(response);
            responseIndexes.add(responses.size() - 1);
            tasksToInsert.add(buildTask(accountRecord, request));
        }

        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
            for (Integer i = 0; i < tasksToInsert.size(); i++) {
                Task createdTask = tasksToInsert[i];
                Response response = responses[responseIndexes[i]];
                response.status = 'task_created';
                response.taskId = createdTask.Id;
                response.taskUrl = '/lightning/r/Task/' + createdTask.Id + '/view';
                response.auditJson = auditPayload(
                    response.accountId,
                    'task_created',
                    true,
                    true,
                    getActionType(requests[responseIndexes[i]]),
                    createdTask.Id,
                    null
                );
            }
        }

        return responses;
    }

    private static Response validateRequest(Request request, Map<Id, Account> accountsById) {
        if (request == null || request.accountId == null) {
            return blocked(null, 'blocked_missing_account_id', 'Account Id is required.', request);
        }

        if (request.confirmed != true) {
            return blocked(request.accountId, 'blocked_confirmation_required', 'User confirmation is required before creating a CRM Task.', request);
        }

        String actionType = getActionType(request);
        if (!TASK_ACTION_TYPES.contains(actionType)) {
            String status = actionType == 'create_opportunity'
                ? 'blocked_high_impact_action_requires_separate_approval'
                : 'blocked_unsupported_action_type';
            return blocked(request.accountId, status, 'Only confirmation-gated Task actions are supported by this action.', request);
        }

        Account accountRecord = accountsById.get(request.accountId);
        if (accountRecord == null) {
            return blocked(request.accountId, 'blocked_account_not_found', 'Account was not found.', request);
        }

        if (String.isBlank(accountRecord.AI_Source_Refs__c)) {
            return blocked(request.accountId, 'review_required_missing_source_refs', 'Source references are required before creating a seller Task.', request);
        }

        Response response = baseResponse(request.accountId, 'ready_to_create', request);
        response.auditJson = auditPayload(request.accountId, 'ready_to_create', true, true, actionType, null, null);
        return response;
    }

    private static Task buildTask(Account accountRecord, Request request) {
        String actionType = getActionType(request);
        String nextMove = String.isBlank(request.nextMove)
            ? 'Route aftermarket specialist for preventive maintenance coverage review.'
            : request.nextMove;

        return new Task(
            WhatId = accountRecord.Id,
            OwnerId = accountRecord.OwnerId,
            Subject = 'Pulse360 coverage review - ' + accountRecord.Name,
            Status = 'Not Started',
            Priority = 'High',
            ActivityDate = Date.today().addDays(2),
            Description = String.join(new List<String>{
                'Pulse360 governed seller action.',
                'Account: ' + accountRecord.Name,
                'Action type: ' + actionType,
                'Next move: ' + nextMove,
                'Why now: ' + safeText(accountRecord.AI_Narrative__c, 'No narrative available.'),
                'Freshness: Data Cloud last synced ' + String.valueOf(accountRecord.DataCloud_Last_Synced__c),
                'source refs: ' + accountRecord.AI_Source_Refs__c,
                'Agentforce policy: created only after user confirmation; opportunity creation requires separate approval.'
            }, '\n')
        );
    }

    private static Response blocked(Id accountId, String status, String message, Request request) {
        Response response = baseResponse(accountId, status, request);
        response.auditJson = auditPayload(
            accountId,
            status,
            request != null && request.confirmed == true,
            false,
            request == null ? null : getActionType(request),
            null,
            message
        );
        return response;
    }

    private static Response baseResponse(Id accountId, String status, Request request) {
        Response response = new Response();
        response.status = status;
        response.accountId = accountId;
        response.taskId = null;
        response.taskUrl = null;
        return response;
    }

    private static String auditPayload(
        Id accountId,
        String status,
        Boolean confirmationReceived,
        Boolean mutationExecuted,
        String actionType,
        Id taskId,
        String message
    ) {
        return JSON.serialize(new Map<String, Object>{
            'account_id' => accountId,
            'status' => status,
            'requested_action_type' => actionType,
            'confirmation_received' => confirmationReceived,
            'mutation_executed' => mutationExecuted,
            'mutation_type' => mutationExecuted ? 'Task' : null,
            'task_id' => taskId,
            'source_refs_required' => true,
            'high_impact_actions_require_separate_approval' => true,
            'message' => message
        });
    }

    private static String getActionType(Request request) {
        if (request == null || String.isBlank(request.requestedActionType)) {
            return 'create_task';
        }
        return request.requestedActionType.trim().toLowerCase();
    }

    private static String safeText(String value, String fallback) {
        return String.isBlank(value) ? fallback : value;
    }
}
