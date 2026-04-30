import { LightningElement, api } from 'lwc';
import { normalizeActionContext } from 'c/pulse360SellerWorkspaceActionSupport';

export default class Pulse360SellerWorkspaceMetrics extends LightningElement {
    @api workspace;
    @api actionContext;

    handleMetricAction(event) {
        const metric = event.currentTarget.dataset.metric;
        const baseContext = normalizeActionContext({
            action: this.actionContext?.rawAction || this.actionContext || {},
            accountId: this.workspace?.accountId,
            accountName: this.workspace?.accountName,
            promptVersion: this.workspace?.promptVersion,
            sourceContext: `metric_${metric}`,
            targetEntity: this.actionContext?.targetEntity || this.workspace?.accountName
        });

        let detail;
        switch (metric) {
            case 'confirmed':
                detail = {
                    ...baseContext,
                    actionType: 'launch_agent',
                    agentGoal: 'summarize_account_for_manager'
                };
                break;
            case 'hidden':
                detail = {
                    ...baseContext,
                    actionType: 'open_entity',
                    mode: 'focus'
                };
                break;
            case 'engagement':
                detail = {
                    ...baseContext,
                    actionType: 'create_task',
                    outreachObjective: `Re-engage ${baseContext.targetEntity || this.workspace?.accountName} while momentum is ${this.workspace?.engagementLabel?.toLowerCase() || 'unclear'}.`
                };
                break;
            case 'products':
            default:
                detail = {
                    ...baseContext,
                    actionType: 'launch_agent',
                    agentGoal: 'analyze_whitespace'
                };
                break;
        }

        this.dispatchEvent(
            new CustomEvent('workspaceaction', {
                detail
            })
        );
    }
}
