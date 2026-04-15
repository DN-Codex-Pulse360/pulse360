import { LightningElement, api } from 'lwc';
import { normalizeActionContext } from 'c/pulse360SellerWorkspaceActionSupport';

export default class Pulse360SellerWorkspaceHeader extends LightningElement {
    @api accountId;
    @api accountName;
    @api hiddenRevenue;
    @api currencyCode = 'USD';
    @api groupKnownSubsidiaryCount = 0;
    @api uncoveredEntityCount = 0;
    @api freshnessLabel;
    @api freshnessTone;
    @api coverageGapFlag = false;
    @api coveragePercent = 0;
    @api actionContext;

    get freshnessClassName() {
        return `badge badge_${this.freshnessTone || 'fresh'}`;
    }

    get formattedHiddenRevenue() {
        const value = Number(this.hiddenRevenue || 0);
        try {
            return new Intl.NumberFormat('en-US', {
                style: 'currency',
                currency: this.currencyCode || 'USD',
                maximumFractionDigits: 0
            }).format(value);
        } catch (error) {
            return value.toLocaleString();
        }
    }

    get topActionLabel() {
        return this.actionContext?.recommendedPlay;
    }

    get showCoverageBadge() {
        return this.coveragePercent > 0;
    }

    handleAskAgent() {
        const context = normalizeActionContext({
            action: this.actionContext?.rawAction || this.actionContext || {},
            accountId: this.accountId,
            accountName: this.accountName,
            promptVersion: this.actionContext?.promptVersion,
            sourceContext: 'header_agent',
            actionType: 'launch_agent',
            targetEntity: this.actionContext?.targetEntity || this.accountName,
            agentGoal: 'generate_opportunity_brief'
        });

        this.dispatchEvent(
            new CustomEvent('workspaceaction', {
                detail: context
            })
        );
    }
}
