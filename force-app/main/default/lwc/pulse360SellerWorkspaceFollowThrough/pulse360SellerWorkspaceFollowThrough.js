import { LightningElement, api } from 'lwc';
import { normalizeActionContext, whyNotNow } from 'c/pulse360SellerWorkspaceActionSupport';

export default class Pulse360SellerWorkspaceFollowThrough extends LightningElement {
    @api actions = [];
    @api primaryAction;
    @api accountId;
    @api accountName;
    @api promptVersion;

    get normalizedActions() {
        return (this.actions || []).map((action) => ({
            ...action,
            whyNotNow: whyNotNow(action, this.primaryAction?.rawAction || this.primaryAction)
        }));
    }

    handleAction(event) {
        const rank = Number(event.currentTarget.dataset.rank);
        const action = (this.actions || []).find((candidate) => candidate.rank === rank);
        if (!action) {
            return;
        }

        const detail = normalizeActionContext({
            action,
            accountId: this.accountId,
            accountName: this.accountName,
            promptVersion: this.promptVersion,
            sourceContext: `secondary_${event.currentTarget.dataset.actionType}`,
            actionType: event.currentTarget.dataset.actionType,
            targetEntity: action.targetEntity || action.target,
            mode: event.currentTarget.dataset.mode || 'execute',
            agentGoal: event.currentTarget.dataset.actionType === 'launch_agent' ? 'generate_opportunity_brief' : undefined
        });

        this.dispatchEvent(
            new CustomEvent('workspaceaction', {
                detail
            })
        );
    }
}
