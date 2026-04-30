const DEFAULT_BUYING_GROUP_GAP = 'Confirm sponsor, economic buyer, and technical owner coverage.';
const DEFAULT_OUTREACH_OBJECTIVE = 'Validate the next best commercial move and agree the follow-up path.';
const SALESFORCE_RECORD_ID_PATTERN = /^[a-zA-Z0-9]{15}(?:[a-zA-Z0-9]{3})?$/;

function coalesce(...values) {
    return values.find((value) => value !== undefined && value !== null && value !== '');
}

function normalizeActionType(actionType) {
    switch (actionType) {
        case 'create_opportunity':
            return 'open_opportunity';
        default:
            return actionType || 'create_task';
    }
}

function normalizeRecordId(...values) {
    const candidate = values.find((value) => SALESFORCE_RECORD_ID_PATTERN.test(value || ''));
    return candidate || null;
}

export function normalizeActionContext({
    action = {},
    accountId,
    accountName,
    promptVersion,
    sourceContext,
    actionType,
    targetEntity,
    hierarchyEntity,
    agentGoal,
    recommendedPlay,
    solutionFamily,
    reasoning,
    estimatedRevenueImpact,
    buyingGroupGap,
    outreachObjective,
    confidence,
    confidenceLabel,
    mode,
    rank
} = {}) {
    const supportingSources = Array.isArray(action.supportingSources) ? action.supportingSources : [];
    const resolvedTargetEntity = coalesce(
        targetEntity,
        hierarchyEntity?.entityName,
        action.targetEntity,
        action.target,
        accountName
    );

    return {
        accountId,
        accountName,
        actionType: normalizeActionType(actionType || action.actionType),
        targetEntity: resolvedTargetEntity,
        targetRecordId: normalizeRecordId(
            hierarchyEntity?.targetRecordId,
            hierarchyEntity?.crmRecordId,
            hierarchyEntity?.entityId,
            action.targetRecordId
        ),
        recommendedPlay: coalesce(recommendedPlay, action.recommendedPlay, hierarchyEntity?.suggestedPlay, action.target, 'Pulse360 follow-up'),
        solutionFamily: coalesce(solutionFamily, action.solutionFamily, hierarchyEntity?.suggestedPlay, 'Account Intelligence'),
        specialistRoute: coalesce(action.specialistRoute, 'Account Team'),
        buyingGroupGap: coalesce(buyingGroupGap, action.buyingGroupGap, DEFAULT_BUYING_GROUP_GAP),
        outreachObjective: coalesce(outreachObjective, action.outreachObjective, action.reasoning, hierarchyEntity?.signal, DEFAULT_OUTREACH_OBJECTIVE),
        supportingSources,
        sourceContext: sourceContext || 'workspace',
        reasoning: coalesce(reasoning, action.reasoning, hierarchyEntity?.signal, 'Pulse360 identified a commercially relevant next step.'),
        estimatedRevenueImpact: coalesce(estimatedRevenueImpact, action.estimatedRevenueImpact, 'Not specified'),
        confidence: coalesce(confidence, action.confidence),
        confidenceLabel: coalesce(confidenceLabel, action.confidenceLabel, 'Pulse360-guided'),
        promptVersion: coalesce(promptVersion, action.promptVersion),
        agentGoal: agentGoal || 'generate_opportunity_brief',
        mode: mode || 'execute',
        entityRole: hierarchyEntity?.entityRole,
        coverageLabel: hierarchyEntity?.coverageLabel,
        coverageStatus: hierarchyEntity?.coverageStatus,
        isCurrentAccount: hierarchyEntity?.isCurrentAccount || false,
        rank: rank || action.rank,
        rawAction: action
    };
}

export function buildActionDescription(actionContext) {
    const lines = [
        `Account: ${actionContext.accountName || 'Not specified'}`,
        `Target entity: ${actionContext.targetEntity || 'Not specified'}`,
        `Recommended play: ${actionContext.recommendedPlay || 'Not specified'}`,
        `Solution family: ${actionContext.solutionFamily || 'Not specified'}`,
        `Why now: ${actionContext.reasoning || 'Not specified'}`,
        `Buying-group gap: ${actionContext.buyingGroupGap || 'Not specified'}`,
        `Specialist route: ${actionContext.specialistRoute || 'Not specified'}`,
        `Outreach objective: ${actionContext.outreachObjective || 'Not specified'}`,
        `Estimated impact: ${actionContext.estimatedRevenueImpact || 'Not specified'}`,
        `Confidence: ${actionContext.confidenceLabel || 'Not specified'}`,
        `Prompt version: ${actionContext.promptVersion || 'Unknown'}`,
        `Triggered from: ${actionContext.sourceContext || 'workspace'}`
    ];

    if ((actionContext.supportingSources || []).length > 0) {
        lines.push('');
        lines.push('Supporting evidence:');
        actionContext.supportingSources.forEach((source) => {
            lines.push(`- ${source.sourceName || source.sourceId || 'Source'}: ${source.sourceUrl || 'No URL provided'}`);
        });
    }

    return lines.join('\n');
}

export function buildAgentBrief(actionContext) {
    const lines = [
        `Pulse360 Agent Goal: ${agentGoalLabel(actionContext.agentGoal)}`,
        '',
        buildActionDescription(actionContext)
    ];

    if (actionContext.coverageLabel || actionContext.entityRole) {
        lines.push('');
        lines.push(`Entity context: ${coalesce(actionContext.entityRole, 'Unknown role')} / ${coalesce(actionContext.coverageLabel, 'Unknown coverage')}`);
    }

    return lines.join('\n');
}

export function requiresApproval(actionType) {
    return normalizeActionType(actionType) === 'open_opportunity';
}

export function buildExecutionRequest(actionContext, approvalMode = 'auto_prepare') {
    return {
        subagent: 'Seller Account Manager',
        actionType: normalizeActionType(actionContext.actionType),
        recordId: actionContext.accountId,
        targetRecordId: actionContext.targetRecordId || null,
        approvalRequired: requiresApproval(actionContext.actionType),
        userMessage: actionContext.userMessage || null,
        sessionId: actionContext.sessionId || null,
        approvalMode,
        accountName: actionContext.accountName,
        targetEntity: actionContext.targetEntity,
        recommendedPlay: actionContext.recommendedPlay,
        solutionFamily: actionContext.solutionFamily,
        specialistRoute: actionContext.specialistRoute,
        reasoning: actionContext.reasoning,
        estimatedRevenueImpact: actionContext.estimatedRevenueImpact,
        buyingGroupGap: actionContext.buyingGroupGap,
        outreachObjective: actionContext.outreachObjective,
        promptVersion: actionContext.promptVersion,
        confidence: actionContext.confidence,
        confidenceLabel: actionContext.confidenceLabel,
        sourceContext: actionContext.sourceContext,
        agentGoal: actionContext.agentGoal
    };
}

export function whyNotNow(action, primaryAction) {
    if (!action) {
        return 'Pulse360 has not generated a secondary action yet.';
    }
    if (!primaryAction) {
        return 'This is available as a viable fallback move if the seller wants an alternate path.';
    }

    if (primaryAction.targetEntity && action.targetEntity && primaryAction.targetEntity !== action.targetEntity) {
        return `${primaryAction.targetEntity} remains the lead target today, so this stays secondary until that motion is qualified.`;
    }

    return 'This is credible, but it is secondary because the top move has the stronger evidence and sponsor path right now.';
}

export function agentGoalLabel(agentGoal) {
    switch (agentGoal) {
        case 'generate_outreach_brief':
            return 'Generate outreach brief';
        case 'summarize_account_for_manager':
            return 'Summarize account for manager or QBR';
        case 'validate_evidence':
            return 'Validate evidence and objections';
        case 'route_to_specialist':
            return 'Route to specialist with context';
        case 'analyze_whitespace':
            return 'Analyze whitespace and group coverage';
        case 'generate_opportunity_brief':
        default:
            return 'Generate opportunity brief';
    }
}

export function summarizeSupportingSources(supportingSources = []) {
    const total = (supportingSources || []).length;
    if (!total) {
        return 'Pulse360 is relying on CRM and Data Cloud context, but no external source links were attached to this move.';
    }

    if (total === 1) {
        return `1 evidence source supports this move: ${supportingSources[0].sourceName || 'Unnamed source'}.`;
    }

    return `${total} evidence sources support this move, led by ${supportingSources
        .slice(0, 2)
        .map((source) => source.sourceName || 'Unnamed source')
        .join(' and ')}.`;
}
