const DEFAULT_BUYING_GROUP_GAP = 'Confirm sponsor, economic buyer, and technical owner coverage.';
const DEFAULT_OUTREACH_OBJECTIVE = 'Validate the next best commercial move and agree the follow-up path.';

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
        targetRecordId: coalesce(hierarchyEntity?.entityId, action.targetRecordId),
        recommendedPlay: coalesce(action.recommendedPlay, action.target, 'Pulse360 follow-up'),
        solutionFamily: coalesce(action.solutionFamily, hierarchyEntity?.suggestedPlay, 'Account Intelligence'),
        specialistRoute: coalesce(action.specialistRoute, 'Account Team'),
        buyingGroupGap: coalesce(action.buyingGroupGap, DEFAULT_BUYING_GROUP_GAP),
        outreachObjective: coalesce(action.outreachObjective, action.reasoning, hierarchyEntity?.signal, DEFAULT_OUTREACH_OBJECTIVE),
        supportingSources,
        sourceContext: sourceContext || 'workspace',
        reasoning: coalesce(action.reasoning, hierarchyEntity?.signal, 'Pulse360 identified a commercially relevant next step.'),
        estimatedRevenueImpact: coalesce(action.estimatedRevenueImpact, 'Not specified'),
        confidence: action.confidence,
        confidenceLabel: coalesce(action.confidenceLabel, 'Pulse360-guided'),
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
