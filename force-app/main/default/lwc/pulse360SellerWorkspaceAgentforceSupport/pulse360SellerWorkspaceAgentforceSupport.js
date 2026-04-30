const ACC_COMPATIBILITY_MESSAGE =
    'This org does not expose the ACC side-panel module yet. Migrate Pulse360 Agent to Agentforce Employee Agent and enable ACC before using the native in-page handoff.';

function compact(lines = []) {
    return lines.filter((line) => line !== undefined && line !== null && line !== '').join('\n');
}

function evidenceBlock(supportingSources = []) {
    if (!supportingSources.length) {
        return 'No external evidence links were attached to this move. Use the CRM and Data Cloud context already on the page.';
    }

    return supportingSources
        .slice(0, 3)
        .map((source, index) =>
            `${index + 1}. ${source.sourceName || source.sourceId || 'Source'}${source.documentDate ? ` (${source.documentDate})` : ''}: ${
                source.excerpt || source.sourceUrl || 'No summary provided.'
            }`
        )
        .join('\n');
}

export function canLaunchAgentforce(agentId, runtimeBlocked = false) {
    return Boolean(agentId) && !runtimeBlocked && false;
}

export function buildAgentPreview({ actionContext, agentLabel = 'Pulse360 Agent' } = {}) {
    const targetEntity = actionContext?.targetEntity || 'this account';
    return `${agentLabel} can explain why ${targetEntity} is the next move, test the evidence, and help the seller decide the next step.`;
}

export function agentforceCompatibilityMessage(agentLabel = 'Pulse360 Agent') {
    return `${agentLabel} is configured conceptually for a native side-panel handoff, but ${ACC_COMPATIBILITY_MESSAGE}`;
}

export function buildSellerAgentUtterance({ actionContext, workspace } = {}) {
    const coverageSummary = workspace?.groupKnownSubsidiaryCount
        ? `${workspace.crmCoveredSubsidiaryCount || 0} of ${workspace.groupKnownSubsidiaryCount} known group entities are represented in CRM.`
        : 'Group coverage is not fully available in CRM.';

    return compact([
        `I am working the Salesforce Account "${actionContext?.accountName || workspace?.accountName || 'Unknown Account'}".`,
        `Focus the conversation on "${actionContext?.targetEntity || workspace?.accountName || 'the account'}".`,
        '',
        `Recommended move: ${actionContext?.recommendedPlay || 'Explain the next best move.'}`,
        `Why now: ${actionContext?.reasoning || workspace?.aiNarrative || 'Use the account context and explain the next step.'}`,
        `Buying-group gap: ${actionContext?.buyingGroupGap || 'Confirm sponsor, economic buyer, and technical owner coverage.'}`,
        `Outreach objective: ${actionContext?.outreachObjective || 'Recommend the most credible seller follow-up.'}`,
        `Estimated impact: ${actionContext?.estimatedRevenueImpact || 'Not specified'}`,
        `Coverage context: ${coverageSummary}`,
        '',
        'Evidence:',
        evidenceBlock(actionContext?.supportingSources || []),
        '',
        'Reply with:',
        '1. The next seller move in one sentence.',
        '2. The strongest evidence that supports it.',
        '3. The key risk or open question.',
        '4. A short seller talk track for the next conversation.'
    ]);
}

export async function launchAgentforceConversation({ agentId, utterance }) {
    void agentId;
    void utterance;
    throw new Error(ACC_COMPATIBILITY_MESSAGE);
}
