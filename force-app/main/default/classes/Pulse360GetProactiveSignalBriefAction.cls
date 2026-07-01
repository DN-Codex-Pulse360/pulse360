public with sharing class Pulse360GetProactiveSignalBriefAction {
    public class Request {
        @InvocableVariable(label='Account Id' description='Salesforce Account Id for the proactive signal brief.' required=true)
        public Id accountId;

        @InvocableVariable(label='User Goal' description='Optional user goal or question that prompted the brief.')
        public String userGoal;
    }

    public class Response {
        @InvocableVariable(label='Status' description='Brief status or review/block reason.')
        public String status;

        @InvocableVariable(label='Account Id' description='Salesforce Account Id used for the brief.')
        public Id accountId;

        @InvocableVariable(label='Brief JSON' description='Agent-ready proactive signal brief grounded in Account intelligence.')
        public String briefJson;

        @InvocableVariable(label='Source Refs JSON' description='Source references the agent must cite or summarize.')
        public String sourceRefsJson;

        @InvocableVariable(label='Approval Policy JSON' description='Approval policy for any downstream seller action.')
        public String approvalPolicyJson;

        @InvocableVariable(label='Runtime State' description='Native Agentforce runtime state for claim discipline.')
        public String runtimeState;
    }

    @InvocableMethod(
        label='Get Proactive Signal Brief'
        description='Returns a non-mutating Agentforce brief for a proactive Pulse360 Account signal.'
    )
    public static List<Response> invoke(List<Request> requests) {
        List<Response> responses = new List<Response>();
        if (requests == null || requests.isEmpty()) {
            responses.add(blocked(null, 'blocked_missing_account_id', 'Account Id is required.'));
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
                    Owner.Name,
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

        for (Request request : requests) {
            if (request == null || request.accountId == null) {
                responses.add(blocked(null, 'blocked_missing_account_id', 'Account Id is required.'));
                continue;
            }

            Account accountRecord = accountsById.get(request.accountId);
            if (accountRecord == null) {
                responses.add(blocked(request.accountId, 'blocked_account_not_found', 'Account was not found.'));
                continue;
            }

            responses.add(buildBrief(accountRecord, request.userGoal));
        }

        return responses;
    }

    private static Response buildBrief(Account accountRecord, String userGoal) {
        Response response = new Response();
        response.accountId = accountRecord.Id;
        response.runtimeState = 'runtime_unproven';
        response.sourceRefsJson = blankToArray(accountRecord.AI_Source_Refs__c);
        response.approvalPolicyJson = JSON.serialize(new Map<String, Object>{
            'low_risk_agent_outputs' => new List<String>{
                'explain_signal',
                'recommend_next_move',
                'draft_seller_outreach'
            },
            'downstream_effects_require_confirmation' => new List<String>{
                'create_task',
                'route_specialist',
                'open_opportunity',
                'create_opportunity'
            },
            'blocked_without_source_refs' => true,
            'runtime_state' => 'runtime_unproven'
        });

        if (String.isBlank(accountRecord.AI_Source_Refs__c)) {
            response.status = 'review_required_missing_source_refs';
        } else {
            response.status = 'ready';
        }

        response.briefJson = JSON.serialize(new Map<String, Object>{
            'account_id' => accountRecord.Id,
            'account_name' => accountRecord.Name,
            'owner_name' => accountRecord.Owner == null ? null : accountRecord.Owner.Name,
            'user_goal' => userGoal,
            'signal_type' => accountRecord.Coverage_Gap_Flag__c == true ? 'maintenance_coverage_gap' : 'account_intelligence_review',
            'why_now' => safeText(accountRecord.AI_Narrative__c, 'No source-backed narrative is available yet.'),
            'recommended_actions_json' => blankToArray(accountRecord.AI_Recommended_Actions__c),
            'intent_signal_payload_json' => blankToObject(accountRecord.Intent_Signal_Payload__c),
            'source_refs_json' => response.sourceRefsJson,
            'freshness' => new Map<String, Object>{
                'data_cloud_last_synced' => accountRecord.DataCloud_Last_Synced__c,
                'ai_narrative_generated_at' => accountRecord.AI_Narrative_Generated__c
            },
            'agent_instruction' => 'Explain the signal with source refs, confidence/freshness cues, and approval policy before suggesting any downstream CRM action.',
            'runtime_state' => 'runtime_unproven',
            'native_runtime_claim' => 'native Agentforce runtime is not yet proven'
        });

        return response;
    }

    private static Response blocked(Id accountId, String status, String message) {
        Response response = new Response();
        response.status = status;
        response.accountId = accountId;
        response.runtimeState = 'runtime_unproven';
        response.briefJson = JSON.serialize(new Map<String, Object>{
            'error' => message,
            'agent_instruction' => 'Ask for a valid Salesforce Account Id before explaining the proactive signal.',
            'runtime_state' => 'runtime_unproven'
        });
        response.sourceRefsJson = '[]';
        response.approvalPolicyJson = JSON.serialize(new Map<String, Object>{
            'blocked' => true,
            'reason' => status,
            'runtime_state' => 'runtime_unproven'
        });
        return response;
    }

    private static String blankToArray(String value) {
        return String.isBlank(value) ? '[]' : value;
    }

    private static String blankToObject(String value) {
        return String.isBlank(value) ? '{}' : value;
    }

    private static String safeText(String value, String fallback) {
        return String.isBlank(value) ? fallback : value;
    }
}
