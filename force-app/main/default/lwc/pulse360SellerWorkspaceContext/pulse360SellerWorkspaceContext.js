import { LightningElement, api } from 'lwc';
import { normalizeActionContext } from 'c/pulse360SellerWorkspaceActionSupport';

export default class Pulse360SellerWorkspaceContext extends LightningElement {
    @api workspace;
    @api actionContext;

    get externalValidationLabel() {
        return this.workspace?.externallyValidated ? 'Validated' : 'Unvalidated';
    }

    get evidenceSummary() {
        const count = this.workspace?.citationCount || 0;
        if (count > 0) {
            return `${count} evidence source${count === 1 ? '' : 's'} support the current recommendation, and the recommended move carries source-linked provenance.`;
        }
        return 'Pulse360 has not attached direct citations to this move yet.';
    }

    get uncertaintySummary() {
        const notes = [];
        if (!this.workspace?.externallyValidated) {
            notes.push('external validation is still incomplete');
        }
        if (this.workspace?.coverageGapFlag) {
            notes.push('CRM coverage is still partial across the group');
        }
        if ((this.workspace?.freshnessTone || 'fresh') !== 'fresh') {
            notes.push(`freshness is ${this.workspace?.freshnessLabel?.toLowerCase() || 'monitor-worthy'}`);
        }

        if (!notes.length) {
            return 'The recommendation is ready to action; the remaining work is commercial execution rather than evidence cleanup.';
        }

        return `Pulse360 still sees uncertainty because ${notes.join(', ')}.`;
    }

    handleAgentAction(event) {
        const detail = normalizeActionContext({
            action: this.actionContext?.rawAction || this.actionContext || {},
            accountId: this.workspace?.accountId,
            accountName: this.workspace?.accountName,
            promptVersion: this.workspace?.promptVersion,
            sourceContext: `context_${event.currentTarget.dataset.agentGoal}`,
            actionType: 'launch_agent',
            targetEntity: this.actionContext?.targetEntity || this.workspace?.accountName,
            agentGoal: event.currentTarget.dataset.agentGoal
        });

        this.dispatchEvent(
            new CustomEvent('workspaceaction', {
                detail
            })
        );
    }
}
