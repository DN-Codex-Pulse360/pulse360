import { NavigationMixin } from 'lightning/navigation';
import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getRoutingQueue from '@salesforce/apex/Pulse360SignalRoutingWorkspaceService.getRoutingQueue';
import getRoutingWorkspace from '@salesforce/apex/Pulse360SignalRoutingWorkspaceService.getRoutingWorkspace';
import executePulse360SellerAction from '@salesforce/apex/Pulse360SellerOrchestratorService.executePulse360SellerAction';
import { buildExecutionRequest, normalizeActionContext } from 'c/pulse360SellerWorkspaceActionSupport';

export default class Pulse360SignalRoutingWorkspace extends NavigationMixin(LightningElement) {
    @api recordId;
    @api previewRecordId;

    activeAccountId;
    errorMessage;
    queueItems = [];
    workspace;

    @wire(getRoutingQueue, { requestedLimit: 12 })
    wiredQueue({ data, error }) {
        if (data) {
            this.queueItems = data;
            this.errorMessage = undefined;
            if (!this.activeAccountId) {
                this.activeAccountId = this.recordId || this.previewRecordId || data[0]?.accountId;
            }
            return;
        }

        if (error && !this.workspace) {
            this.errorMessage = error?.body?.message || 'Unable to load the Pulse360 routing queue.';
        }
    }

    @wire(getRoutingWorkspace, { accountId: '$activeAccountId' })
    wiredWorkspace({ data, error }) {
        if (data) {
            this.workspace = data;
            this.errorMessage = undefined;
            return;
        }

        this.workspace = undefined;
        if (this.activeAccountId) {
            this.errorMessage = error?.body?.message || 'Unable to load the Pulse360 signal routing workspace.';
        }
    }

    connectedCallback() {
        if (!this.activeAccountId) {
            this.activeAccountId = this.recordId || this.previewRecordId;
        }
    }

    get hasWorkspace() {
        return Boolean(this.workspace);
    }

    get hasError() {
        return Boolean(this.errorMessage);
    }

    get showPreviewSelector() {
        return !this.recordId;
    }

    get previewOptions() {
        return this.queueItems.map((item) => ({
            label: item.accountName,
            value: item.accountId
        }));
    }

    get queueCards() {
        return this.queueItems.map((item) => ({
            ...item,
            className: `queue-card${item.accountId === this.activeAccountId ? ' queue-card_selected' : ''}`,
            signalClass: `badge ${this.signalToneClass(item.signalLabel)}`,
            modeLabel: item.payloadBacked ? 'Payload-backed' : 'Preview'
        }));
    }

    get signalBadgeClass() {
        return `badge ${this.signalToneClass(this.workspace?.signalLabel)}`;
    }

    get freshnessBadgeClass() {
        return `badge badge_${this.workspace?.freshnessTone || 'fresh'}`;
    }

    get hasSupportingSources() {
        return this.topSupportingSources.length > 0;
    }

    get topSupportingSources() {
        return (this.workspace?.primaryAction?.supportingSources || []).slice(0, 3);
    }

    get hasTargetContacts() {
        return (this.workspace?.targetContacts || []).length > 0;
    }

    get targetContactHeader() {
        const total = (this.workspace?.targetContacts || []).length;
        if (!total) {
            return 'No CRM contacts attached yet';
        }
        if (total === 1) {
            return '1 target contact surfaced';
        }
        return `${total} target contacts surfaced`;
    }

    get recommendedPlaySummary() {
        if (!this.workspace?.primaryAction) {
            return 'Pulse360 has not attached a primary routed play yet.';
        }
        return [
            this.workspace.primaryAction.recommendedPlay,
            this.workspace.primaryAction.outreachObjective
        ].filter(Boolean).join(' ');
    }

    get freshnessSummary() {
        return `${this.workspace?.freshnessLabel || 'Freshness unknown'} based on the current synced account context. Model ${this.workspace?.modelId || 'unknown'} and prompt ${this.workspace?.promptVersion || 'unknown'} produced the current routed recommendation.`;
    }

    get commercialImpactCopy() {
        return `${this.compactCurrency(this.workspace?.hiddenRevenue, this.workspace?.currencyCode)} of group value still sits outside the directly visible operating surface, so a missed routed motion can leave commercial room untouched.`;
    }

    handleQueueSelect(event) {
        this.activeAccountId = event.currentTarget.dataset.accountId;
        this.workspace = undefined;
    }

    handlePreviewAccountChange(event) {
        this.activeAccountId = event.detail.value;
        this.workspace = undefined;
    }

    async handleCreateRoutedTask() {
        await this.executeAction('create_task', 'signal_routing_task', 'Create a routed follow-up task based on the current Pulse360 signal.');
    }

    async handleCreateOutreachTask() {
        await this.executeAction('create_task', 'signal_routing_outreach', 'Prepare the first routed outreach follow-up from the current Pulse360 signal.');
    }

    async handleRouteSpecialist() {
        await this.executeAction('route_specialist', 'signal_routing_specialist', 'Route this signal to the appropriate specialist with current context.');
    }

    handleOpenSellerV2() {
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Pulse360_Seller_V2'
            }
        });
    }

    async executeAction(actionType, sourceContext, userMessage) {
        try {
            await executePulse360SellerAction({
                request: buildExecutionRequest(this.buildActionContext(actionType, sourceContext, userMessage), 'auto_prepare')
            });

            this.showToast(
                'Pulse360 action executed',
                `Created routed follow-up for ${this.workspace?.accountName}.`,
                'success'
            );
        } catch (error) {
            this.showToast(
                'Pulse360 action failed',
                error?.body?.message || 'Unable to execute the routed action.',
                'error'
            );
        }
    }

    buildActionContext(actionType, sourceContext, userMessage) {
        return normalizeActionContext({
            action: this.workspace?.primaryAction || {},
            accountId: this.activeAccountId,
            accountName: this.workspace?.accountName,
            promptVersion: this.workspace?.promptVersion,
            sourceContext,
            actionType,
            targetEntity: this.workspace?.primaryAction?.targetEntity || this.workspace?.accountName,
            recommendedPlay: this.workspace?.primaryAction?.recommendedPlay || 'Signal routing follow-up',
            solutionFamily: this.workspace?.primaryAction?.solutionFamily || 'Account Intelligence',
            reasoning: this.workspace?.whyNow,
            estimatedRevenueImpact: this.commercialImpactCopy,
            buyingGroupGap: this.workspace?.routeLabel,
            outreachObjective: this.workspace?.draftedOutreach,
            confidence: this.workspace?.routingConfidence,
            confidenceLabel: this.workspace?.confidenceLabel,
            userMessage
        });
    }

    signalToneClass(signalLabel) {
        if (signalLabel === 'Route now') {
            return 'badge_positive';
        }
        if (signalLabel === 'Queue for review' || signalLabel === 'Coverage-led review') {
            return 'badge_warning';
        }
        return 'badge_soft';
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
