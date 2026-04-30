import { NavigationMixin } from 'lightning/navigation';
import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getSellerWorkspace from '@salesforce/apex/Pulse360SellerWorkspaceService.getSellerWorkspace';
import getPreviewAccounts from '@salesforce/apex/Pulse360SellerWorkspaceDirectoryService.getPreviewAccounts';
import executePulse360SellerAction from '@salesforce/apex/Pulse360SellerOrchestratorService.executePulse360SellerAction';
import { buildExecutionRequest, normalizeActionContext } from 'c/pulse360SellerWorkspaceActionSupport';

export default class Pulse360RenewalRiskWorkspace extends NavigationMixin(LightningElement) {
    @api recordId;
    @api previewRecordId;
    @api embeddedMode;

    activeAccountId;
    workspace;
    errorMessage;
    previewAccounts = [];

    @wire(getPreviewAccounts, { requestedLimit: 12 })
    wiredPreviewAccounts({ data, error }) {
        if (data) {
            this.previewAccounts = data;
            this.errorMessage = undefined;
            if (!this.activeAccountId) {
                this.activeAccountId = this.recordId || this.previewRecordId || data[0]?.accountId;
            }
            return;
        }

        if (error && !this.workspace) {
            this.errorMessage = error?.body?.message || 'Unable to load preview accounts for Pulse360 renewal workspace.';
        }
    }

    @wire(getSellerWorkspace, { accountId: '$activeAccountId' })
    wiredWorkspace({ data, error }) {
        if (data) {
            this.workspace = data;
            this.errorMessage = undefined;
            return;
        }

        this.workspace = undefined;
        if (this.activeAccountId) {
            this.errorMessage = error?.body?.message || 'Unable to load Pulse360 renewal workspace.';
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

    get showWorkspaceHeader() {
        return !this.normalizeBoolean(this.embeddedMode);
    }

    get previewOptions() {
        return this.previewAccounts.map((account) => ({
            label: [account.accountName, account.primaryBrandName].filter(Boolean).join(' • ') || account.accountName,
            value: account.accountId
        }));
    }

    get validationLabel() {
        return this.workspace?.externallyValidated ? 'Externally validated' : 'Needs validation';
    }

    get riskLevelLabel() {
        return this.riskState.label;
    }

    get riskBadgeClass() {
        return `badge badge_${this.riskState.tone}`;
    }

    get freshnessBadgeClass() {
        return `badge badge_${this.workspace?.freshnessTone || 'fresh'}`;
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

    get riskNarrative() {
        return `${this.workspace?.accountName} currently reads as ${this.riskLevelLabel.toLowerCase()} because the health, competitive, coverage, and freshness signals do not fully agree. Pulse360 should make the next intervention explicit before the team loses context.`;
    }

    get topDrivers() {
        return [
            {
                key: 'health',
                label: 'Health score',
                value: this.workspace?.healthScore ?? 'N/A',
                copy: this.workspace?.healthScore <= 45
                    ? 'Health is low enough that this account should be treated as a save motion.'
                    : 'Health is not catastrophic, but it should still be monitored alongside competitive and coverage signals.'
            },
            {
                key: 'competitive',
                label: 'Competitive pressure',
                value: this.workspace?.competitorRiskSignal ?? 'N/A',
                copy: this.workspace?.competitorRiskSignal >= 70
                    ? 'Competitive pressure is materially elevated.'
                    : 'Competitive pressure is present but not yet a full crisis signal.'
            },
            {
                key: 'coverage',
                label: 'Coverage confidence',
                value: `${this.workspace?.crmCoveredSubsidiaryCount || 0}/${this.workspace?.groupKnownSubsidiaryCount || 0}`,
                copy: this.coverageRiskCopy
            }
        ];
    }

    get riskChangeExplanation() {
        if (this.workspace?.competitorRiskSignal >= 70 && this.workspace?.healthScore <= 45) {
            return 'Both competitive pressure and weak account health are pushing the renewal view into a high-risk state. This is not just a stale-data problem.';
        }
        if (this.workspace?.freshnessTone === 'stale') {
            return 'The available signals are old enough that the safest next step is to refresh the account context before interpreting the renewal story too confidently.';
        }
        if (this.workspace?.coverageGapFlag) {
            return 'Coverage is incomplete across the commercial group, which raises the chance that sponsor, renewal owner, or usage context is missing from the current view.';
        }
        return 'Risk is building from the mix of competitive, health, and engagement signals rather than from one single failure mode.';
    }

    get recommendedSavePlay() {
        if (this.workspace?.freshnessTone === 'stale') {
            return {
                title: 'Refresh the signal set, then review renewal posture',
                copy: 'Update the account context first so the team does not act on stale or partial signals.'
            };
        }
        if (this.workspace?.competitorRiskSignal >= 70 || this.workspace?.healthScore <= 45) {
            return {
                title: 'Create a save plan and escalate sponsor coverage',
                copy: 'Treat this account as a proactive save motion, confirm the sponsor map, and get leadership or specialist attention quickly.'
            };
        }
        if (this.workspace?.coverageGapFlag) {
            return {
                title: 'Close coverage gaps before renewal risk hardens',
                copy: 'Bring missing entities or stakeholders into the operating picture so the team can judge risk with more confidence.'
            };
        }
        return {
            title: 'Protect the account and stage controlled expansion',
            copy: 'The account is not yet a severe save case, but the team should still document intervention and keep the sponsor path warm.'
        };
    }

    get coverageRiskCopy() {
        if (this.workspace?.coverageGapFlag) {
            return 'Group coverage is still incomplete, so renewal confidence is lower than the raw account score suggests.';
        }
        return 'Coverage looks more stable, which reduces the risk that the team is missing the main renewal stakeholders.';
    }

    get commercialImpactCopy() {
        return `${this.compactCurrency(this.workspace?.hiddenRevenue, this.workspace?.currencyCode)} of group value still sits outside the seller-visible operating surface, so a weak renewal posture could affect more than one isolated record.`;
    }

    get freshnessSummary() {
        return `${this.workspace?.freshnessLabel || 'Freshness unknown'} based on the current Data Cloud sync and narrative timestamp. Prompt ${this.workspace?.promptVersion || 'unknown'} and model ${this.workspace?.modelId || 'unknown'} produced the current narrative.`;
    }

    get uncertaintySummary() {
        if (this.workspace?.freshnessTone === 'stale') {
            return 'This account needs a fresher data pass before the team should over-interpret the renewal signal.';
        }
        if (!this.workspace?.externallyValidated) {
            return 'External validation is still incomplete, which means some of the group context should be treated as directional rather than definitive.';
        }
        return 'The surface is usable, but it still lacks explicit usage, support, and champion-change signals, so this is an early-warning renewal view rather than a complete retention cockpit.';
    }

    get topSupportingSources() {
        return (this.primaryAction?.supportingSources || []).slice(0, 3);
    }

    get hasSupportingSources() {
        return this.topSupportingSources.length > 0;
    }

    get primaryAction() {
        return normalizeActionContext({
            action: this.workspace?.primaryAction || {},
            accountId: this.activeAccountId,
            accountName: this.workspace?.accountName,
            promptVersion: this.workspace?.promptVersion,
            sourceContext: 'renewal_workspace',
            targetEntity: this.workspace?.primaryAction?.targetEntity || this.workspace?.accountName
        });
    }

    handlePreviewAccountChange(event) {
        this.activeAccountId = event.detail.value;
        this.workspace = undefined;
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
            accountId: this.activeAccountId,
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

    normalizeBoolean(value) {
        if (value === undefined || value === null || value === '') {
            return false;
        }
        if (typeof value === 'boolean') {
            return value;
        }
        return String(value).toLowerCase() === 'true';
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
