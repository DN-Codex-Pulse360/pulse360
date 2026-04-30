import { NavigationMixin } from 'lightning/navigation';
import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getSellerWorkspace from '@salesforce/apex/Pulse360SellerWorkspaceService.getSellerWorkspace';
import executePulse360SellerAction from '@salesforce/apex/Pulse360SellerOrchestratorService.executePulse360SellerAction';
import { buildExecutionRequest, normalizeActionContext } from 'c/pulse360SellerWorkspaceActionSupport';

export default class Pulse360RenewalRiskPanel extends NavigationMixin(LightningElement) {
    @api recordId;

    workspace;
    errorMessage;

    @wire(getSellerWorkspace, { accountId: '$recordId' })
    wiredWorkspace({ data, error }) {
        if (data) {
            this.workspace = data;
            this.errorMessage = undefined;
            return;
        }

        this.workspace = undefined;
        if (this.recordId) {
            this.errorMessage = error?.body?.message || 'Unable to load the Pulse360 renewal risk panel.';
        }
    }

    get hasWorkspace() {
        return Boolean(this.workspace);
    }

    get hasError() {
        return Boolean(this.errorMessage);
    }

    get primaryAction() {
        return normalizeActionContext({
            action: this.workspace?.primaryAction || {},
            accountId: this.recordId,
            accountName: this.workspace?.accountName,
            promptVersion: this.workspace?.promptVersion,
            sourceContext: 'account_record_renewal_risk',
            targetEntity: this.workspace?.primaryAction?.targetEntity || this.workspace?.accountName
        });
    }

    get riskState() {
        const risk = Number(this.workspace?.competitorRiskSignal || 0);
        const health = Number(this.workspace?.healthScore || 100);
        if (risk >= 70 || health <= 45) {
            return { label: 'High risk', tone: 'negative' };
        }
        if (risk >= 50 || health <= 60 || this.workspace?.freshnessTone === 'stale') {
            return { label: 'Watch closely', tone: 'warning' };
        }
        return { label: 'Manageable risk', tone: 'positive' };
    }

    get riskLevelLabel() {
        return this.riskState.label;
    }

    get riskBadgeClass() {
        return `badge badge_${this.riskState.tone}`;
    }

    get freshnessBadgeClass() {
        return `badge badge_${this.workspace?.freshnessTone || 'positive'}`;
    }

    get riskNarrative() {
        return `${this.workspace?.accountName} currently reads as ${this.riskLevelLabel.toLowerCase()} because the health, competitive, coverage, and freshness signals do not fully agree.`;
    }

    get riskChangeExplanation() {
        if (this.workspace?.competitorRiskSignal >= 70 && this.workspace?.healthScore <= 45) {
            return 'Both competitive pressure and weak account health are pushing the account into a proactive save motion.';
        }
        if (this.workspace?.freshnessTone === 'stale') {
            return 'The risk story is directionally useful, but the team should refresh the account context before acting too confidently.';
        }
        if (this.workspace?.coverageGapFlag) {
            return 'Coverage is incomplete across the group, which raises the chance that sponsor or renewal owner context is missing.';
        }
        return 'Risk is building from the mix of competitive, health, and engagement signals rather than from one isolated failure mode.';
    }

    get recommendedSavePlay() {
        if (this.workspace?.freshnessTone === 'stale') {
            return {
                title: 'Refresh the signal set, then reassess the renewal posture',
                copy: 'Update the account context first so the team does not act on stale or partial signals.'
            };
        }
        if (this.workspace?.competitorRiskSignal >= 70 || this.workspace?.healthScore <= 45) {
            return {
                title: 'Create a save plan and escalate sponsor coverage',
                copy: 'Treat this as a proactive save motion and move quickly on leadership or specialist involvement.'
            };
        }
        if (this.workspace?.coverageGapFlag) {
            return {
                title: 'Close coverage gaps before renewal risk hardens',
                copy: 'Bring missing entities or stakeholders into the operating picture before the renewal view becomes misleading.'
            };
        }
        return {
            title: 'Protect the account and keep the sponsor path warm',
            copy: 'The account is not yet a severe save case, but the team should document intervention and maintain sponsor attention.'
        };
    }

    get coverageRiskCopy() {
        if (this.workspace?.coverageGapFlag) {
            return 'Group coverage is incomplete, so renewal confidence is lower than the raw account score suggests.';
        }
        return 'Coverage looks more stable, which reduces the risk that the team is missing the main renewal stakeholders.';
    }

    get commercialImpactCopy() {
        return `${this.compactCurrency(this.workspace?.hiddenRevenue, this.workspace?.currencyCode)} of group value still sits outside the seller-visible operating surface.`;
    }

    async handleCreateSavePlan() {
        await this.executeTaskAction('renewal_save_plan', 'Create a renewal save plan with the current risk explanation and next intervention.');
    }

    async handleCreateExecutiveOutreach() {
        await this.executeTaskAction('renewal_executive_outreach', 'Prepare executive outreach because Pulse360 sees a material renewal risk pattern.');
    }

    async handleRouteSpecialist() {
        const actionContext = this.buildBaseActionContext('route_specialist', 'renewal_route_specialist');
        await this.executeAction(actionContext);
    }

    handleOpenSellerV2() {
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Pulse360_Seller_V2'
            }
        });
    }

    buildBaseActionContext(actionType, sourceContext, userMessage) {
        return {
            ...this.primaryAction,
            actionType,
            sourceContext,
            accountId: this.recordId,
            accountName: this.workspace?.accountName,
            targetEntity: this.workspace?.accountName,
            recommendedPlay: this.recommendedSavePlay.title,
            reasoning: this.riskChangeExplanation,
            buyingGroupGap: this.coverageRiskCopy,
            outreachObjective: this.recommendedSavePlay.copy,
            estimatedRevenueImpact: this.commercialImpactCopy,
            userMessage
        };
    }

    async executeTaskAction(sourceContext, userMessage) {
        const actionContext = this.buildBaseActionContext('create_task', sourceContext, userMessage);
        await this.executeAction(actionContext);
    }

    async executeAction(actionContext) {
        try {
            const result = await executePulse360SellerAction({
                request: buildExecutionRequest(actionContext, 'auto_prepare')
            });
            this.showToast(
                'Pulse360 action executed',
                `Created ${result.primaryObjectApiName || 'follow-up'} for ${this.workspace?.accountName}.`,
                'success'
            );
        } catch (error) {
            this.showToast(
                'Pulse360 action failed',
                error?.body?.message || 'Unable to execute the renewal action.',
                'error'
            );
        }
    }

    compactCurrency(value, currencyCode) {
        const amount = Number(value || 0);
        if (amount >= 1000000000) {
            return `${(amount / 1000000000).toFixed(1)}B ${currencyCode || 'USD'}`;
        }
        if (amount >= 1000000) {
            return `${(amount / 1000000).toFixed(1)}M ${currencyCode || 'USD'}`;
        }
        return `${Math.round(amount)} ${currencyCode || 'USD'}`;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}
