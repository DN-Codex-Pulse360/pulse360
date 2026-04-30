public with sharing class Pulse360SellerOrchestratorService {
    private static final Set<String> HIGH_RISK_SELLER_ACTIONS = new Set<String>{
        'open_opportunity',
        'create_opportunity'
    };
    private static final Pattern SALESFORCE_RECORD_ID_PATTERN = Pattern.compile('^[a-zA-Z0-9]{15}(?:[a-zA-Z0-9]{3})?$');

    public class HealthMetrics {
        @AuraEnabled public Decimal healthScore;
        @AuraEnabled public Decimal crossSellPropensity;
        @AuraEnabled public Decimal competitorRiskSignal;
        @AuraEnabled public Integer uncoveredEntityCount;
        @AuraEnabled public Integer crmCoveredSubsidiaryCount;
    }

    public class BriefStep {
        @AuraEnabled public Integer rank;
        @AuraEnabled public String label;
        @AuraEnabled public String owner;
        @AuraEnabled public String rationale;
        @AuraEnabled public Boolean requiresApproval;
    }

    public class BriefArtifact {
        @AuraEnabled public String title;
        @AuraEnabled public String headline;
        @AuraEnabled public String goalLabel;
        @AuraEnabled public String evidenceStatus;
        @AuraEnabled public String readinessLabel;
        @AuraEnabled public String whatChanged;
        @AuraEnabled public String body;
        @AuraEnabled public List<BriefStep> executionChecklist = new List<BriefStep>();
        @AuraEnabled public List<String> riskFlags = new List<String>();
        @AuraEnabled public List<String> evidenceHighlights = new List<String>();
    }

    public class AccountContext {
        @AuraEnabled public String subagentName;
        @AuraEnabled public Id accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public List<Pulse360SellerWorkspaceService.HierarchyEntity> hierarchyPayload = new List<Pulse360SellerWorkspaceService.HierarchyEntity>();
        @AuraEnabled public Pulse360SellerWorkspaceService.ActionPack primaryAction;
        @AuraEnabled public List<Pulse360SellerWorkspaceService.ActionPack> secondaryActions = new List<Pulse360SellerWorkspaceService.ActionPack>();
        @AuraEnabled public List<Pulse360SellerWorkspaceService.SourceRef> sourceRefs = new List<Pulse360SellerWorkspaceService.SourceRef>();
        @AuraEnabled public String freshness;
        @AuraEnabled public String freshnessTone;
        @AuraEnabled public HealthMetrics healthMetrics;
        @AuraEnabled public String orchestrationSummary;
        @AuraEnabled public BriefArtifact sellerBrief;
        @AuraEnabled public List<BriefStep> executionChecklist = new List<BriefStep>();
        @AuraEnabled public List<String> riskFlags = new List<String>();
        @AuraEnabled public String evidenceStatus;
    }

    public class ExecutionRequest {
        @AuraEnabled public String subagent { get; set; }
        @AuraEnabled public String actionType { get; set; }
        @AuraEnabled public String recordId { get; set; }
        @AuraEnabled public String targetRecordId { get; set; }
        @AuraEnabled public Boolean approvalRequired { get; set; }
        @AuraEnabled public String userMessage { get; set; }
        @AuraEnabled public String sessionId { get; set; }
        @AuraEnabled public String approvalMode { get; set; }
        @AuraEnabled public String accountName { get; set; }
        @AuraEnabled public String targetEntity { get; set; }
        @AuraEnabled public String recommendedPlay { get; set; }
        @AuraEnabled public String solutionFamily { get; set; }
        @AuraEnabled public String specialistRoute { get; set; }
        @AuraEnabled public String reasoning { get; set; }
        @AuraEnabled public String estimatedRevenueImpact { get; set; }
        @AuraEnabled public String buyingGroupGap { get; set; }
        @AuraEnabled public String outreachObjective { get; set; }
        @AuraEnabled public String promptVersion { get; set; }
        @AuraEnabled public Decimal confidence { get; set; }
        @AuraEnabled public String confidenceLabel { get; set; }
        @AuraEnabled public String sourceContext { get; set; }
        @AuraEnabled public String agentGoal { get; set; }
        @AuraEnabled public String entityRole { get; set; }
        @AuraEnabled public String coverageLabel { get; set; }
        @AuraEnabled public String coverageStatus { get; set; }
        @AuraEnabled public Boolean isCurrentAccount { get; set; }
    }

    public class ExecutionResult {
        @AuraEnabled public String status;
        @AuraEnabled public List<String> createdRecordIds = new List<String>();
        @AuraEnabled public String agentSummary;
        @AuraEnabled public String approvalState;
        @AuraEnabled public String auditEventId;
        @AuraEnabled public String errorCode;
        @AuraEnabled public Boolean approvalRequired;
        @AuraEnabled public String primaryRecordId;
        @AuraEnabled public String primaryObjectApiName;
        @AuraEnabled public String subagentName;
        @AuraEnabled public String agentGoal;
        @AuraEnabled public String briefTitle;
        @AuraEnabled public String briefHeadline;
        @AuraEnabled public String briefBody;
        @AuraEnabled public String evidenceStatus;
        @AuraEnabled public String readinessLabel;
        @AuraEnabled public String whatChanged;
        @AuraEnabled public List<BriefStep> executionChecklist = new List<BriefStep>();
        @AuraEnabled public List<String> riskFlags = new List<String>();
        @AuraEnabled public List<String> evidenceHighlights = new List<String>();
    }

    private class SellerExecutionContext {
        Pulse360SellerWorkspaceService.WorkspaceResult workspace;
        Pulse360SellerWorkspaceService.HierarchyEntity matchedEntity;
        Pulse360SellerWorkspaceService.ActionPack matchedAction;
        ExecutionRequest request;
        BriefArtifact brief;
    }

    @AuraEnabled(cacheable=true)
    public static AccountContext getPulse360AccountContext(Id accountId) {
        Pulse360SellerWorkspaceService.WorkspaceResult workspace = Pulse360SellerWorkspaceService.getSellerWorkspace(accountId);
        ExecutionRequest request = defaultExecutionRequest(workspace);
        BriefArtifact brief = buildSellerBriefArtifact(
            workspace,
            request,
            defaultHierarchyEntity(workspace.hierarchyEntities),
            workspace.primaryAction
        );

        AccountContext context = new AccountContext();
        context.subagentName = 'Seller Account Manager';
        context.accountId = workspace.accountId;
        context.accountName = workspace.accountName;
        context.hierarchyPayload = workspace.hierarchyEntities;
        context.primaryAction = workspace.primaryAction;
        context.secondaryActions = workspace.secondaryActions;
        context.sourceRefs = collectSupportingSources(workspace);
        context.freshness = workspace.freshnessLabel;
        context.freshnessTone = workspace.freshnessTone;
        context.healthMetrics = new HealthMetrics();
        context.healthMetrics.healthScore = workspace.healthScore;
        context.healthMetrics.crossSellPropensity = workspace.crossSellPropensity;
        context.healthMetrics.competitorRiskSignal = workspace.competitorRiskSignal;
        context.healthMetrics.uncoveredEntityCount = workspace.uncoveredEntityCount;
        context.healthMetrics.crmCoveredSubsidiaryCount = workspace.crmCoveredSubsidiaryCount;
        context.orchestrationSummary = buildSellerContextSummary(workspace);
        context.sellerBrief = brief;
        context.executionChecklist.addAll(brief.executionChecklist);
        context.riskFlags.addAll(brief.riskFlags);
        context.evidenceStatus = brief.evidenceStatus;
        return context;
    }

    @AuraEnabled
    public static ExecutionResult executePulse360SellerAction(ExecutionRequest request) {
        Id contextAccountId = resolveExecutionContextAccountId(request);
        if (request == null || contextAccountId == null) {
            throw new AuraHandledException('A seller execution request with a recordId is required.');
        }

        SellerExecutionContext executionContext = buildSellerExecutionContext(contextAccountId, request);
        String normalizedActionType = normalizeSellerActionType(executionContext.request.actionType);
        Boolean approvalRequired = HIGH_RISK_SELLER_ACTIONS.contains(normalizedActionType);

        ExecutionResult result = initializeExecutionResult(executionContext, approvalRequired);

        if (approvalRequired && String.valueOf(executionContext.request.approvalMode).toLowerCase() != 'approved') {
            result.status = 'ApprovalRequired';
            result.approvalState = 'REQUIRED';
            result.errorCode = 'SELLER_APPROVAL_REQUIRED';
            return result;
        }

        Id targetAccountId = preferredAccountTarget(contextAccountId, executionContext.request.targetRecordId);

        if (normalizedActionType == 'open_opportunity') {
            Opportunity opportunity = new Opportunity(
                Name = opportunityName(executionContext.request),
                AccountId = targetAccountId,
                StageName = firstActiveOpportunityStageName(),
                CloseDate = Date.today().addDays(30),
                Description = executionContext.brief.body
            );
            insert opportunity;

            result.status = 'Completed';
            result.approvalState = approvalRequired ? 'APPROVED' : 'AUTO_EXECUTED';
            result.primaryRecordId = opportunity.Id;
            result.primaryObjectApiName = 'Opportunity';
            result.createdRecordIds.add(opportunity.Id);
            return result;
        }

        if (normalizedActionType == 'open_entity' && hasSalesforceRecordId(executionContext.request.targetRecordId)) {
            result.status = 'Completed';
            result.approvalState = 'NOT_REQUIRED';
            result.primaryRecordId = executionContext.request.targetRecordId;
            result.primaryObjectApiName = 'Account';
            return result;
        }

        Task followUp = new Task(
            Subject = taskSubject(executionContext.request, normalizedActionType, executionContext.brief),
            WhatId = targetAccountId == null ? contextAccountId : targetAccountId,
            Description = normalizedActionType == 'launch_agent'
                ? executionContext.brief.body
                : buildSellerActionDescription(executionContext),
            Status = 'Not Started',
            Priority = taskPriority(approvalRequired, executionContext.brief)
        );
        insert followUp;

        result.status = 'Completed';
        result.approvalState = approvalRequired ? 'APPROVED' : 'AUTO_EXECUTED';
        result.primaryRecordId = followUp.Id;
        result.primaryObjectApiName = 'Task';
        result.createdRecordIds.add(followUp.Id);
        return result;
    }

    @AuraEnabled
    public static ExecutionResult askPulse360SellerAgent(ExecutionRequest request) {
        Id contextAccountId = resolveExecutionContextAccountId(request);
        if (request == null || contextAccountId == null) {
            throw new AuraHandledException('A seller agent request with a recordId is required.');
        }

        SellerExecutionContext executionContext = buildSellerExecutionContext(contextAccountId, request);
        String normalizedActionType = normalizeSellerActionType(executionContext.request.actionType);
        Boolean approvalRequired = HIGH_RISK_SELLER_ACTIONS.contains(normalizedActionType);

        ExecutionResult result = initializeExecutionResult(executionContext, approvalRequired);
        result.status = 'Responded';
        result.approvalState = approvalRequired ? 'AVAILABLE_ON_APPROVAL' : 'READY';
        return result;
    }

    private static SellerExecutionContext buildSellerExecutionContext(Id accountId, ExecutionRequest request) {
        Pulse360SellerWorkspaceService.WorkspaceResult workspace = Pulse360SellerWorkspaceService.getSellerWorkspace(accountId);
        Pulse360SellerWorkspaceService.HierarchyEntity matchedEntity = matchHierarchyEntity(workspace, request);
        Pulse360SellerWorkspaceService.ActionPack matchedAction = matchActionPack(workspace, request, matchedEntity);
        ExecutionRequest hydratedRequest = hydrateExecutionRequest(request, workspace, matchedEntity, matchedAction, accountId);
        BriefArtifact brief = buildSellerBriefArtifact(workspace, hydratedRequest, matchedEntity, matchedAction);

        SellerExecutionContext context = new SellerExecutionContext();
        context.workspace = workspace;
        context.matchedEntity = matchedEntity;
        context.matchedAction = matchedAction;
        context.request = hydratedRequest;
        context.brief = brief;
        return context;
    }

    private static ExecutionRequest defaultExecutionRequest(Pulse360SellerWorkspaceService.WorkspaceResult workspace) {
        ExecutionRequest request = new ExecutionRequest();
        request.subagent = 'Seller Account Manager';
        request.actionType = workspace.primaryAction == null ? 'create_task' : normalizeSellerActionType(workspace.primaryAction.actionType);
        request.recordId = workspace.accountId == null ? null : String.valueOf(workspace.accountId);
        request.accountName = workspace.accountName;
        request.targetEntity = workspace.primaryAction == null
            ? workspace.accountName
            : coalesce(workspace.primaryAction.targetEntity, workspace.primaryAction.target, workspace.accountName);
        request.recommendedPlay = workspace.primaryAction == null
            ? 'Pulse360 follow-up'
            : coalesce(workspace.primaryAction.recommendedPlay, workspace.primaryAction.target, 'Pulse360 follow-up');
        request.solutionFamily = workspace.primaryAction == null ? 'Account Intelligence' : workspace.primaryAction.solutionFamily;
        request.specialistRoute = workspace.primaryAction == null ? 'Account Team' : workspace.primaryAction.specialistRoute;
        request.reasoning = workspace.primaryAction == null ? workspace.aiNarrative : workspace.primaryAction.reasoning;
        request.estimatedRevenueImpact = workspace.primaryAction == null ? 'Not specified' : workspace.primaryAction.estimatedRevenueImpact;
        request.buyingGroupGap = workspace.primaryAction == null ? null : workspace.primaryAction.buyingGroupGap;
        request.outreachObjective = workspace.primaryAction == null ? null : workspace.primaryAction.outreachObjective;
        request.promptVersion = workspace.promptVersion;
        request.confidence = workspace.primaryAction == null ? null : workspace.primaryAction.confidence;
        request.confidenceLabel = workspace.primaryAction == null ? null : workspace.primaryAction.confidenceLabel;
        request.sourceContext = 'agent_context';
        request.agentGoal = 'generate_opportunity_brief';
        return request;
    }

    private static ExecutionRequest hydrateExecutionRequest(
        ExecutionRequest request,
        Pulse360SellerWorkspaceService.WorkspaceResult workspace,
        Pulse360SellerWorkspaceService.HierarchyEntity matchedEntity,
        Pulse360SellerWorkspaceService.ActionPack matchedAction,
        Id accountId
    ) {
        ExecutionRequest hydrated = new ExecutionRequest();
        hydrated.subagent = String.isBlank(request == null ? null : request.subagent)
            ? 'Seller Account Manager'
            : request.subagent;
        hydrated.actionType = normalizeSellerActionType(request == null ? null : request.actionType);
        hydrated.recordId = String.isBlank(request == null ? null : request.recordId)
            ? String.valueOf(accountId)
            : request.recordId;
        hydrated.targetRecordId = coalesce(
            request == null ? null : request.targetRecordId,
            matchedEntity == null ? null : matchedEntity.crmRecordId
        );
        hydrated.approvalRequired = request == null ? null : request.approvalRequired;
        hydrated.userMessage = request == null ? null : request.userMessage;
        hydrated.sessionId = request == null ? null : request.sessionId;
        hydrated.approvalMode = request == null ? null : request.approvalMode;
        hydrated.accountName = coalesce(request == null ? null : request.accountName, workspace.accountName);
        hydrated.targetEntity = coalesce(
            request == null ? null : request.targetEntity,
            matchedEntity == null ? null : matchedEntity.entityName,
            matchedAction == null ? null : matchedAction.targetEntity,
            matchedAction == null ? null : matchedAction.target,
            workspace.accountName
        );
        hydrated.recommendedPlay = coalesce(
            request == null ? null : request.recommendedPlay,
            matchedAction == null ? null : matchedAction.recommendedPlay,
            matchedAction == null ? null : matchedAction.target,
            'Pulse360 follow-up'
        );
        hydrated.solutionFamily = coalesce(
            request == null ? null : request.solutionFamily,
            matchedAction == null ? null : matchedAction.solutionFamily,
            'Account Intelligence'
        );
        hydrated.specialistRoute = coalesce(
            request == null ? null : request.specialistRoute,
            matchedAction == null ? null : matchedAction.specialistRoute,
            'Account Team'
        );
        hydrated.reasoning = coalesce(
            request == null ? null : request.reasoning,
            matchedAction == null ? null : matchedAction.reasoning,
            matchedEntity == null ? null : matchedEntity.signal,
            workspace.aiNarrative,
            'Pulse360 identified a commercially relevant next step.'
        );
        hydrated.estimatedRevenueImpact = coalesce(
            request == null ? null : request.estimatedRevenueImpact,
            matchedAction == null ? null : matchedAction.estimatedRevenueImpact,
            'Not specified'
        );
        hydrated.buyingGroupGap = coalesce(
            request == null ? null : request.buyingGroupGap,
            matchedAction == null ? null : matchedAction.buyingGroupGap,
            'Confirm sponsor, economic buyer, and technical owner coverage.'
        );
        hydrated.outreachObjective = coalesce(
            request == null ? null : request.outreachObjective,
            matchedAction == null ? null : matchedAction.outreachObjective,
            matchedEntity == null ? null : matchedEntity.signal,
            'Validate the next best commercial move and agree the follow-up path.'
        );
        hydrated.promptVersion = coalesce(request == null ? null : request.promptVersion, workspace.promptVersion);
        hydrated.confidence = request != null && request.confidence != null
            ? request.confidence
            : matchedAction == null ? null : matchedAction.confidence;
        hydrated.confidenceLabel = deriveConfidenceLabel(
            request == null ? null : request.confidenceLabel,
            hydrated.confidence,
            matchedAction == null ? null : matchedAction.confidenceLabel
        );
        hydrated.sourceContext = coalesce(request == null ? null : request.sourceContext, 'workspace');
        hydrated.agentGoal = normalizeAgentGoal(request == null ? null : request.agentGoal);
        hydrated.entityRole = coalesce(request == null ? null : request.entityRole, matchedEntity == null ? null : matchedEntity.entityRole);
        hydrated.coverageLabel = coalesce(request == null ? null : request.coverageLabel, matchedEntity == null ? null : matchedEntity.coverageLabel);
        hydrated.coverageStatus = coalesce(request == null ? null : request.coverageStatus, matchedEntity == null ? null : matchedEntity.coverageStatus);
        hydrated.isCurrentAccount = request != null && request.isCurrentAccount != null
            ? request.isCurrentAccount
            : matchedEntity == null ? false : matchedEntity.isCurrentAccount;
        return hydrated;
    }

    private static ExecutionResult initializeExecutionResult(SellerExecutionContext executionContext, Boolean approvalRequired) {
        ExecutionResult result = new ExecutionResult();
        result.subagentName = 'Seller Account Manager';
        result.agentGoal = executionContext.request.agentGoal;
        result.approvalRequired = approvalRequired;
        result.auditEventId = newAuditEventId();
        result.briefTitle = executionContext.brief.title;
        result.briefHeadline = executionContext.brief.headline;
        result.briefBody = executionContext.brief.body;
        result.evidenceStatus = executionContext.brief.evidenceStatus;
        result.readinessLabel = executionContext.brief.readinessLabel;
        result.whatChanged = executionContext.brief.whatChanged;
        result.executionChecklist.addAll(executionContext.brief.executionChecklist);
        result.riskFlags.addAll(executionContext.brief.riskFlags);
        result.evidenceHighlights.addAll(executionContext.brief.evidenceHighlights);
        result.agentSummary = buildSellerExecutionSummary(executionContext, approvalRequired);
        return result;
    }

    private static Pulse360SellerWorkspaceService.HierarchyEntity matchHierarchyEntity(
        Pulse360SellerWorkspaceService.WorkspaceResult workspace,
        ExecutionRequest request
    ) {
        if (workspace == null || workspace.hierarchyEntities == null || workspace.hierarchyEntities.isEmpty()) {
            return null;
        }

        String targetRecordId = request == null ? null : request.targetRecordId;
        String targetEntity = request == null ? null : request.targetEntity;
        for (Pulse360SellerWorkspaceService.HierarchyEntity entity : workspace.hierarchyEntities) {
            if (entity == null) {
                continue;
            }
            if (hasSalesforceRecordId(targetRecordId) && entity.crmRecordId == targetRecordId) {
                return entity;
            }
            if (!String.isBlank(targetEntity) && equalsNormalized(entity.entityName, targetEntity)) {
                return entity;
            }
            if (entity.isCurrentAccount == true) {
                targetEntity = targetEntity == null ? workspace.accountName : targetEntity;
            }
        }

        return defaultHierarchyEntity(workspace.hierarchyEntities);
    }

    private static Pulse360SellerWorkspaceService.HierarchyEntity defaultHierarchyEntity(
        List<Pulse360SellerWorkspaceService.HierarchyEntity> hierarchyEntities
    ) {
        if (hierarchyEntities == null || hierarchyEntities.isEmpty()) {
            return null;
        }
        for (Pulse360SellerWorkspaceService.HierarchyEntity entity : hierarchyEntities) {
            if (entity != null && entity.isCurrentAccount == true) {
                return entity;
            }
        }
        return hierarchyEntities[0];
    }

    private static Pulse360SellerWorkspaceService.ActionPack matchActionPack(
        Pulse360SellerWorkspaceService.WorkspaceResult workspace,
        ExecutionRequest request,
        Pulse360SellerWorkspaceService.HierarchyEntity matchedEntity
    ) {
        List<Pulse360SellerWorkspaceService.ActionPack> candidates = new List<Pulse360SellerWorkspaceService.ActionPack>();
        if (workspace.primaryAction != null) {
            candidates.add(workspace.primaryAction);
        }
        candidates.addAll(workspace.secondaryActions);

        String targetEntity = request == null ? null : request.targetEntity;
        String recommendedPlay = request == null ? null : request.recommendedPlay;
        for (Pulse360SellerWorkspaceService.ActionPack action : candidates) {
            if (action == null) {
                continue;
            }
            if (!String.isBlank(recommendedPlay) && equalsNormalized(action.recommendedPlay, recommendedPlay)) {
                return action;
            }
            if (!String.isBlank(targetEntity) && (
                equalsNormalized(action.targetEntity, targetEntity) ||
                equalsNormalized(action.target, targetEntity)
            )) {
                return action;
            }
            if (matchedEntity != null && !String.isBlank(matchedEntity.entityName) && (
                equalsNormalized(action.targetEntity, matchedEntity.entityName) ||
                equalsNormalized(action.target, matchedEntity.entityName)
            )) {
                return action;
            }
        }

        return workspace.primaryAction;
    }

    private static BriefArtifact buildSellerBriefArtifact(
        Pulse360SellerWorkspaceService.WorkspaceResult workspace,
        ExecutionRequest request,
        Pulse360SellerWorkspaceService.HierarchyEntity matchedEntity,
        Pulse360SellerWorkspaceService.ActionPack matchedAction
    ) {
        BriefArtifact brief = new BriefArtifact();
        brief.goalLabel = goalLabel(request.agentGoal);
        brief.headline = coalesce(
            request.recommendedPlay,
            matchedAction == null ? null : matchedAction.recommendedPlay,
            matchedAction == null ? null : matchedAction.target,
            'Validate the next move'
        );
        brief.title = 'Pulse360 Seller Brief: ' + coalesce(request.targetEntity, workspace.accountName, 'Account follow-up');
        brief.evidenceStatus = buildEvidenceStatus(workspace, matchedAction);
        brief.readinessLabel = buildReadinessLabel(workspace, request);
        brief.whatChanged = buildWhatChanged(workspace, request, matchedEntity);
        brief.executionChecklist = buildExecutionChecklist(workspace, request, matchedEntity);
        brief.riskFlags = buildRiskFlags(workspace, request, matchedEntity);
        brief.evidenceHighlights = buildEvidenceHighlights(workspace, matchedAction);
        brief.body = buildSellerBriefBody(brief, workspace, request, matchedEntity);
        return brief;
    }

    private static List<Pulse360SellerWorkspaceService.SourceRef> collectSupportingSources(
        Pulse360SellerWorkspaceService.WorkspaceResult workspace
    ) {
        Map<String, Pulse360SellerWorkspaceService.SourceRef> refsById = new Map<String, Pulse360SellerWorkspaceService.SourceRef>();

        if (workspace.primaryAction != null) {
            addSupportingSources(refsById, workspace.primaryAction.supportingSources);
        }
        for (Pulse360SellerWorkspaceService.ActionPack action : workspace.secondaryActions) {
            addSupportingSources(refsById, action.supportingSources);
        }
        return refsById.values();
    }

    private static void addSupportingSources(
        Map<String, Pulse360SellerWorkspaceService.SourceRef> refsById,
        List<Pulse360SellerWorkspaceService.SourceRef> refs
    ) {
        if (refs == null) {
            return;
        }
        for (Pulse360SellerWorkspaceService.SourceRef ref : refs) {
            if (ref == null || String.isBlank(ref.sourceId)) {
                continue;
            }
            refsById.put(ref.sourceId, ref);
        }
    }

    private static String buildSellerContextSummary(Pulse360SellerWorkspaceService.WorkspaceResult workspace) {
        List<String> tokens = new List<String>();
        tokens.add('Freshness: ' + coalesce(workspace.freshnessLabel, 'unknown'));
        tokens.add('Coverage gap: ' + (workspace.coverageGapFlag == true ? 'present' : 'not flagged'));
        tokens.add('Uncovered entities: ' + String.valueOf(workspace.uncoveredEntityCount));
        if (workspace.primaryAction != null) {
            tokens.add('Primary move: ' + coalesce(workspace.primaryAction.recommendedPlay, workspace.primaryAction.target, 'Not generated'));
        }
        return String.join(tokens, ' | ');
    }

    private static String buildSellerExecutionSummary(SellerExecutionContext executionContext, Boolean approvalRequired) {
        List<String> lines = new List<String>();
        lines.add('Recommendation headline: ' + executionContext.brief.headline);
        lines.add('Target entity: ' + coalesce(executionContext.request.targetEntity, executionContext.request.accountName, 'Not specified'));
        lines.add('Evidence status: ' + executionContext.brief.evidenceStatus);
        lines.add('Readiness: ' + executionContext.brief.readinessLabel);
        lines.add('Approval: ' + (approvalRequired ? 'required before mutation' : 'auto-executable'));
        if (!executionContext.brief.riskFlags.isEmpty()) {
            lines.add('Risks to resolve: ' + String.join(executionContext.brief.riskFlags, ' | '));
        }
        return String.join(lines, '\n');
    }

    private static String buildSellerActionDescription(SellerExecutionContext executionContext) {
        List<String> lines = new List<String>{
            'Pulse360 Seller Action Plan',
            '',
            'Goal: ' + executionContext.brief.goalLabel,
            'Recommendation headline: ' + executionContext.brief.headline,
            'Target entity: ' + coalesce(executionContext.request.targetEntity, 'Not specified'),
            'Solution family: ' + coalesce(executionContext.request.solutionFamily, 'Not specified'),
            'Evidence status: ' + executionContext.brief.evidenceStatus,
            'Readiness: ' + executionContext.brief.readinessLabel,
            'Why now: ' + coalesce(executionContext.request.reasoning, 'Not specified'),
            'What changed: ' + executionContext.brief.whatChanged,
            'Outreach objective: ' + coalesce(executionContext.request.outreachObjective, 'Not specified'),
            'Estimated impact: ' + coalesce(executionContext.request.estimatedRevenueImpact, 'Not specified'),
            'Prompt version: ' + coalesce(executionContext.request.promptVersion, 'Unknown'),
            'Triggered from: ' + coalesce(executionContext.request.sourceContext, 'workspace')
        };

        if (!executionContext.brief.executionChecklist.isEmpty()) {
            lines.add('');
            lines.add('Execution checklist:');
            for (BriefStep step : executionContext.brief.executionChecklist) {
                lines.add(
                    String.valueOf(step.rank) + '. ' + step.label +
                    ' (' + step.owner + ')' +
                    ': ' + step.rationale
                );
            }
        }

        if (!executionContext.brief.riskFlags.isEmpty()) {
            lines.add('');
            lines.add('Risks to resolve:');
            for (String risk : executionContext.brief.riskFlags) {
                lines.add('- ' + risk);
            }
        }

        if (!executionContext.brief.evidenceHighlights.isEmpty()) {
            lines.add('');
            lines.add('Supporting evidence:');
            for (String highlight : executionContext.brief.evidenceHighlights) {
                lines.add('- ' + highlight);
            }
        }

        if (!String.isBlank(executionContext.request.userMessage)) {
            lines.add('');
            lines.add('User message: ' + executionContext.request.userMessage);
        }

        return String.join(lines, '\n');
    }

    private static String buildSellerBriefBody(
        BriefArtifact brief,
        Pulse360SellerWorkspaceService.WorkspaceResult workspace,
        ExecutionRequest request,
        Pulse360SellerWorkspaceService.HierarchyEntity matchedEntity
    ) {
        List<String> lines = new List<String>{
            'Pulse360 Seller Brief',
            '',
            'Goal: ' + brief.goalLabel,
            'Recommendation headline: ' + brief.headline,
            'Target entity: ' + coalesce(request.targetEntity, workspace.accountName, 'Not specified'),
            'Entity context: ' + buildEntityContextSummary(request, matchedEntity),
            'Evidence status: ' + brief.evidenceStatus,
            'Readiness: ' + brief.readinessLabel,
            'Why now: ' + coalesce(request.reasoning, 'Not specified'),
            'What changed: ' + brief.whatChanged,
            'Buying-group gap: ' + coalesce(request.buyingGroupGap, 'Not specified'),
            'Outreach objective: ' + coalesce(request.outreachObjective, 'Not specified'),
            'Estimated impact: ' + coalesce(request.estimatedRevenueImpact, 'Not specified')
        };

        if (!brief.executionChecklist.isEmpty()) {
            lines.add('');
            lines.add('Execution checklist:');
            for (BriefStep step : brief.executionChecklist) {
                lines.add(
                    String.valueOf(step.rank) + '. ' + step.label +
                    ' (' + step.owner + ')' +
                    ': ' + step.rationale
                );
            }
        }

        if (!brief.riskFlags.isEmpty()) {
            lines.add('');
            lines.add('Risks to resolve:');
            for (String risk : brief.riskFlags) {
                lines.add('- ' + risk);
            }
        }

        if (!brief.evidenceHighlights.isEmpty()) {
            lines.add('');
            lines.add('Supporting evidence:');
            for (String highlight : brief.evidenceHighlights) {
                lines.add('- ' + highlight);
            }
        }

        if (!String.isBlank(request.promptVersion)) {
            lines.add('');
            lines.add('Prompt version: ' + request.promptVersion);
        }

        return String.join(lines, '\n');
    }

    private static String buildEntityContextSummary(
        ExecutionRequest request,
        Pulse360SellerWorkspaceService.HierarchyEntity matchedEntity
    ) {
        List<String> tokens = new List<String>();
        if (!String.isBlank(request.entityRole)) {
            tokens.add(request.entityRole);
        } else if (matchedEntity != null && !String.isBlank(matchedEntity.entityRole)) {
            tokens.add(matchedEntity.entityRole);
        }
        if (!String.isBlank(request.coverageLabel)) {
            tokens.add(request.coverageLabel);
        } else if (matchedEntity != null && !String.isBlank(matchedEntity.coverageLabel)) {
            tokens.add(matchedEntity.coverageLabel);
        }
        if (request.isCurrentAccount == true || (matchedEntity != null && matchedEntity.isCurrentAccount == true)) {
            tokens.add('Current account anchor');
        }
        return tokens.isEmpty() ? 'No additional entity context is available.' : String.join(tokens, ' / ');
    }

    private static List<BriefStep> buildExecutionChecklist(
        Pulse360SellerWorkspaceService.WorkspaceResult workspace,
        ExecutionRequest request,
        Pulse360SellerWorkspaceService.HierarchyEntity matchedEntity
    ) {
        String freshnessTone = normalizedFreshnessTone(workspace);
        List<BriefStep> steps = new List<BriefStep>();
        steps.add(step(
            1,
            'Confirm the operating entity and sponsor path',
            'Seller',
            firstChecklistRationale(workspace, request, matchedEntity),
            false
        ));
        steps.add(step(
            2,
            actionSpecificStepLabel(request.agentGoal),
            actionSpecificOwner(request.agentGoal),
            actionSpecificRationale(request),
            false
        ));
        steps.add(step(
            3,
            'Capture the next CRM-safe follow-through',
            HIGH_RISK_SELLER_ACTIONS.contains(normalizeSellerActionType(request.actionType)) ? 'Seller + manager' : 'Seller',
            HIGH_RISK_SELLER_ACTIONS.contains(normalizeSellerActionType(request.actionType))
                ? 'Opening pipeline is a governed step here, so approval should happen only after the brief is reviewed.'
                : 'Turn the agreed move into a task, specialist route, or follow-up note with the same grounded context.',
            HIGH_RISK_SELLER_ACTIONS.contains(normalizeSellerActionType(request.actionType))
        ));
        if (freshnessTone != 'fresh' || workspace.coverageGapFlag == true) {
            steps.add(step(
                4,
                'Refresh trust signals before overcommitting',
                'RevOps / data steward',
                'Freshness or coverage is not fully clean, so the seller should confirm the evidence surface before escalating the motion.',
                false
            ));
        }
        return steps;
    }

    private static BriefStep step(Integer rank, String label, String owner, String rationale, Boolean requiresApproval) {
        BriefStep step = new BriefStep();
        step.rank = rank;
        step.label = label;
        step.owner = owner;
        step.rationale = rationale;
        step.requiresApproval = requiresApproval;
        return step;
    }

    private static List<String> buildRiskFlags(
        Pulse360SellerWorkspaceService.WorkspaceResult workspace,
        ExecutionRequest request,
        Pulse360SellerWorkspaceService.HierarchyEntity matchedEntity
    ) {
        String freshnessTone = normalizedFreshnessTone(workspace);
        List<String> risks = new List<String>();
        if (workspace.coverageGapFlag == true) {
            risks.add('CRM coverage is still partial across the group, so the chosen entity must be confirmed before the next seller motion.');
        }
        if (freshnessTone != 'fresh') {
            risks.add('Freshness is ' + String.valueOf(workspace.freshnessLabel).toLowerCase() + ', so the brief should be checked against the latest account state.');
        }
        if (workspace.externallyValidated != true) {
            risks.add('External validation is still incomplete, so Pulse360 is leaning more heavily on CRM and Data Cloud context than on direct third-party confirmation.');
        }
        if (workspace.competitorRiskSignal != null && workspace.competitorRiskSignal >= 70) {
            risks.add('Competitive pressure is elevated, so this move should be framed against the current save or defend posture.');
        }
        if (matchedEntity != null && matchedEntity.inCrm != true) {
            risks.add(matchedEntity.entityName + ' is not directly represented in CRM yet, which can make seller follow-through drift to the wrong account anchor.');
        }
        if (String.isBlank(request.targetEntity) || equalsNormalized(request.targetEntity, workspace.accountName)) {
            risks.add('The target entity is still broad, so the seller should sharpen the operating-entity focus before escalation.');
        }
        return risks;
    }

    private static List<String> buildEvidenceHighlights(
        Pulse360SellerWorkspaceService.WorkspaceResult workspace,
        Pulse360SellerWorkspaceService.ActionPack matchedAction
    ) {
        List<String> highlights = new List<String>();
        List<Pulse360SellerWorkspaceService.SourceRef> supportingSources = matchedAction == null
            ? new List<Pulse360SellerWorkspaceService.SourceRef>()
            : matchedAction.supportingSources;

        Integer maxItems = Math.min(supportingSources.size(), 3);
        for (Integer index = 0; index < maxItems; index++) {
            Pulse360SellerWorkspaceService.SourceRef source = supportingSources[index];
            highlights.add(
                coalesce(source.sourceName, 'Unnamed source') +
                ' (' + coalesce(source.documentDate, 'Date unknown') + '): ' +
                coalesce(source.excerpt, 'No excerpt available.')
            );
        }

        if (highlights.isEmpty()) {
            highlights.add(
                'Pulse360 is relying on CRM coverage, Data Cloud freshness, and the current account narrative; no direct supporting source links were attached to this move.'
            );
        } else if (workspace.citationCount != null && workspace.citationCount > maxItems) {
            highlights.add('Additional cited sources are available in the workspace evidence panel.');
        }
        return highlights;
    }

    private static String buildEvidenceStatus(
        Pulse360SellerWorkspaceService.WorkspaceResult workspace,
        Pulse360SellerWorkspaceService.ActionPack matchedAction
    ) {
        Integer supportingSources = matchedAction == null || matchedAction.supportingSources == null
            ? 0
            : matchedAction.supportingSources.size();

        if (supportingSources > 0 && workspace.externallyValidated == true) {
            return 'Grounded in cited external evidence, CRM context, and validated account data.';
        }
        if (supportingSources > 0) {
            return 'Grounded in cited evidence and CRM context, but external validation is still incomplete.';
        }
        if (workspace.externallyValidated == true) {
            return 'Grounded in CRM and validated account data, but no linked supporting source is attached to this move.';
        }
        return 'Grounded mainly in CRM and Data Cloud context; external evidence is limited.';
    }

    private static String buildReadinessLabel(Pulse360SellerWorkspaceService.WorkspaceResult workspace, ExecutionRequest request) {
        String freshnessTone = normalizedFreshnessTone(workspace);
        Boolean cleanCoverage = workspace.coverageGapFlag != true;
        Boolean freshEnough = freshnessTone == 'fresh';
        Decimal confidence = request.confidence == null ? 0 : request.confidence;

        if (cleanCoverage && freshEnough && confidence >= 0.8) {
            return 'Ready to execute';
        }
        if (cleanCoverage && confidence >= 0.6) {
            return 'Execute with light validation';
        }
        if (freshnessTone != 'stale') {
            return 'Prepare first, then execute';
        }
        return 'Needs evidence refresh before escalation';
    }

    private static String buildWhatChanged(
        Pulse360SellerWorkspaceService.WorkspaceResult workspace,
        ExecutionRequest request,
        Pulse360SellerWorkspaceService.HierarchyEntity matchedEntity
    ) {
        String freshnessTone = normalizedFreshnessTone(workspace);
        List<String> notes = new List<String>();
        if (workspace.coverageGapFlag == true) {
            notes.add(
                'CRM still misses ' + String.valueOf(workspace.uncoveredEntityCount) +
                ' group entit' + (workspace.uncoveredEntityCount == 1 ? 'y' : 'ies')
            );
        }
        if (freshnessTone != 'fresh') {
            notes.add('freshness is ' + String.valueOf(workspace.freshnessLabel).toLowerCase());
        }
        if (!String.isBlank(workspace.engagementLabel)) {
            notes.add('engagement reads as ' + workspace.engagementLabel.toLowerCase());
        }
        if (matchedEntity != null && matchedEntity.inCrm != true) {
            notes.add(matchedEntity.entityName + ' is not directly seller-visible in CRM');
        }
        if (!String.isBlank(request.outreachObjective)) {
            notes.add('the current objective is to ' + request.outreachObjective.toLowerCase());
        }

        if (notes.isEmpty()) {
            return 'The current recommendation remains stable across coverage, freshness, and engagement cues.';
        }
        return String.join(notes, '; ') + '.';
    }

    private static String normalizedFreshnessTone(Pulse360SellerWorkspaceService.WorkspaceResult workspace) {
        return workspace == null || String.isBlank(workspace.freshnessTone) ? 'fresh' : workspace.freshnessTone;
    }

    private static String firstChecklistRationale(
        Pulse360SellerWorkspaceService.WorkspaceResult workspace,
        ExecutionRequest request,
        Pulse360SellerWorkspaceService.HierarchyEntity matchedEntity
    ) {
        if (matchedEntity != null && matchedEntity.inCrm != true) {
            return matchedEntity.entityName + ' is not fully seller-visible in CRM, so confirm the operating entity before moving the opportunity or task flow there.';
        }
        if (workspace.coverageGapFlag == true) {
            return 'Coverage is incomplete across the group, so verify that the sponsor path and operating entity are still the right ones before escalation.';
        }
        return 'The current account anchor is relatively stable, but it is still worth validating the sponsor path before execution.';
    }

    private static String actionSpecificStepLabel(String agentGoal) {
        if (agentGoal == 'route_to_specialist') {
            return 'Package the specialist handoff';
        }
        if (agentGoal == 'analyze_whitespace') {
            return 'Map whitespace against the group footprint';
        }
        if (agentGoal == 'generate_outreach_brief') {
            return 'Prepare the outreach message and meeting ask';
        }
        if (agentGoal == 'summarize_account_for_manager') {
            return 'Translate the account story into an executive-ready update';
        }
        if (agentGoal == 'validate_evidence') {
            return 'Check objections, assumptions, and evidence gaps';
        }
        return 'Prepare the opportunity brief and next call stance';
    }

    private static String actionSpecificOwner(String agentGoal) {
        if (agentGoal == 'route_to_specialist') {
            return 'Seller + specialist';
        }
        if (agentGoal == 'summarize_account_for_manager') {
            return 'Seller / manager';
        }
        if (agentGoal == 'validate_evidence') {
            return 'Seller + RevOps';
        }
        return 'Seller';
    }

    private static String actionSpecificRationale(ExecutionRequest request) {
        if (request.agentGoal == 'route_to_specialist') {
            return 'Give the specialist the target entity, buying-group gap, and evidence-backed why-now so the handoff stays commercially grounded.';
        }
        if (request.agentGoal == 'analyze_whitespace') {
            return 'Use the group view to confirm which uncovered entities and sponsor gaps make this whitespace move credible.';
        }
        if (request.agentGoal == 'generate_outreach_brief') {
            return 'Turn the recommendation into a concrete seller message with a meeting ask and a clear commercial objective.';
        }
        if (request.agentGoal == 'summarize_account_for_manager') {
            return 'Prepare a concise manager-ready summary of the move, the evidence status, and the revenue rationale.';
        }
        if (request.agentGoal == 'validate_evidence') {
            return 'Pressure-test the recommendation against freshness, citations, and unresolved objections before execution.';
        }
        return 'Translate the recommendation into a seller-ready opportunity narrative with the right target entity and sponsor path.';
    }

    private static String normalizeSellerActionType(String actionType) {
        String normalized = actionType == null ? null : actionType.trim().toLowerCase();
        if (normalized == 'create_opportunity') {
            return 'open_opportunity';
        }
        return String.isBlank(normalized) ? 'create_task' : normalized;
    }

    private static String normalizeAgentGoal(String agentGoal) {
        String normalized = agentGoal == null ? null : agentGoal.trim().toLowerCase();
        if (String.isBlank(normalized)) {
            return 'generate_opportunity_brief';
        }
        return normalized;
    }

    private static String deriveConfidenceLabel(String explicitLabel, Decimal confidence, String fallbackLabel) {
        if (!String.isBlank(explicitLabel)) {
            return explicitLabel;
        }
        if (!String.isBlank(fallbackLabel)) {
            return fallbackLabel;
        }
        Decimal safeConfidence = confidence == null ? 0 : confidence;
        if (safeConfidence >= 0.85) {
            return 'High confidence';
        }
        if (safeConfidence >= 0.65) {
            return 'Medium confidence';
        }
        if (safeConfidence > 0) {
            return 'Developing confidence';
        }
        return 'Pulse360-guided';
    }

    private static Id resolveExecutionContextAccountId(ExecutionRequest request) {
        if (request == null) {
            return null;
        }
        if (hasSalesforceRecordId(request.recordId)) {
            try {
                return (Id)request.recordId;
            } catch (Exception ex) {
            }
        }
        if (hasSalesforceRecordId(request.targetRecordId)) {
            try {
                return (Id)request.targetRecordId;
            } catch (Exception ex) {
            }
        }

        Set<String> candidateNames = new Set<String>();
        if (!String.isBlank(request.accountName)) {
            candidateNames.add(request.accountName.trim());
        }
        if (!String.isBlank(request.targetEntity)) {
            candidateNames.add(request.targetEntity.trim());
        }
        if (candidateNames.isEmpty()) {
            return null;
        }

        List<Account> matches = [
            SELECT Id
            FROM Account
            WHERE Name IN :candidateNames
            LIMIT 2
        ];
        return matches.size() == 1 ? matches[0].Id : null;
    }

    private static Id preferredAccountTarget(Id accountId, String targetRecordId) {
        if (hasSalesforceRecordId(targetRecordId)) {
            try {
                return (Id)targetRecordId;
            } catch (Exception ex) {
            }
        }
        return accountId;
    }

    private static Boolean hasSalesforceRecordId(String candidate) {
        return !String.isBlank(candidate) && SALESFORCE_RECORD_ID_PATTERN.matcher(candidate).matches();
    }

    private static Boolean equalsNormalized(String leftValue, String rightValue) {
        if (String.isBlank(leftValue) || String.isBlank(rightValue)) {
            return false;
        }
        return leftValue.trim().toLowerCase() == rightValue.trim().toLowerCase();
    }

    private static String taskSubject(ExecutionRequest request, String normalizedActionType, BriefArtifact brief) {
        if (normalizedActionType == 'route_specialist') {
            return 'Pulse360 Route: ' + coalesce(request.specialistRoute, brief.headline, request.targetEntity, 'Specialist follow-up');
        }
        if (normalizedActionType == 'launch_agent') {
            return 'Pulse360 Agent Brief: ' + coalesce(brief.headline, request.targetEntity, request.accountName, 'Account follow-up');
        }
        return 'Pulse360: ' + coalesce(request.recommendedPlay, brief.headline, request.targetEntity, 'Account follow-up');
    }

    private static String opportunityName(ExecutionRequest request) {
        return coalesce(request.targetEntity, request.accountName, 'Pulse360 Account') +
            ' - ' +
            coalesce(request.recommendedPlay, 'Pulse360 opportunity');
    }

    private static String taskPriority(Boolean approvalRequired, BriefArtifact brief) {
        if (approvalRequired || !brief.riskFlags.isEmpty()) {
            return 'High';
        }
        return 'Normal';
    }

    private static String goalLabel(String agentGoal) {
        if (agentGoal == 'generate_outreach_brief') {
            return 'Generate outreach brief';
        }
        if (agentGoal == 'summarize_account_for_manager') {
            return 'Summarize account for manager or QBR';
        }
        if (agentGoal == 'validate_evidence') {
            return 'Validate evidence and objections';
        }
        if (agentGoal == 'route_to_specialist') {
            return 'Route to specialist with context';
        }
        if (agentGoal == 'analyze_whitespace') {
            return 'Analyze whitespace and group coverage';
        }
        return 'Generate opportunity brief';
    }

    private static String firstActiveOpportunityStageName() {
        for (OpportunityStage stage : [
            SELECT MasterLabel
            FROM OpportunityStage
            WHERE IsActive = true
            ORDER BY SortOrder ASC
            LIMIT 1
        ]) {
            return stage.MasterLabel;
        }
        throw new AuraHandledException('No active Opportunity stage is available for Pulse360 seller execution.');
    }

    private static String newAuditEventId() {
        return 'P360-' + Datetime.now().formatGmt('yyyyMMddHHmmss') + '-' + String.valueOf(Math.abs(Crypto.getRandomInteger()));
    }

    private static String coalesce(String leftValue, String rightValue) {
        return !String.isBlank(leftValue) ? leftValue : rightValue;
    }

    private static String coalesce(String firstValue, String secondValue, String thirdValue) {
        return coalesce(coalesce(firstValue, secondValue), thirdValue);
    }

    private static String coalesce(String firstValue, String secondValue, String thirdValue, String fourthValue) {
        return coalesce(coalesce(firstValue, secondValue, thirdValue), fourthValue);
    }

    private static String coalesce(String firstValue, String secondValue, String thirdValue, String fourthValue, String fifthValue) {
        return coalesce(coalesce(firstValue, secondValue, thirdValue, fourthValue), fifthValue);
    }
}
