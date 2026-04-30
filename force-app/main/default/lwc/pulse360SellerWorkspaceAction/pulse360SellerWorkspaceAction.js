import { LightningElement, api } from 'lwc';
import { normalizeActionContext } from 'c/pulse360SellerWorkspaceActionSupport';

export default class Pulse360SellerWorkspaceAction extends LightningElement {
    @api action;
    @api promptVersion;

    get hasSupportingSources() {
        return (this.action?.supportingSources || []).length > 0;
    }

    handleAction(event) {
        if (!this.action) {
            return;
        }

        const actionType = event.currentTarget.dataset.actionType;
        const detail = normalizeActionContext({
            action: this.action.rawAction || this.action,
            accountId: this.action.accountId,
            accountName: this.action.accountName,
            promptVersion: this.promptVersion || this.action.promptVersion,
            sourceContext: `primary_${actionType}`,
            actionType,
            targetEntity: this.action.targetEntity,
            agentGoal: actionType === 'launch_agent' ? 'generate_opportunity_brief' : this.action.agentGoal
        });

        this.dispatchEvent(
            new CustomEvent('workspaceaction', {
                detail
            })
        );
    }
}
