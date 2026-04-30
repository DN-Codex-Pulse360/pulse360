import { NavigationMixin } from 'lightning/navigation';
import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';

import getSellerWorkspace from '@salesforce/apex/Pulse360SellerWorkspaceService.getSellerWorkspace';
import getPreviewAccounts from '@salesforce/apex/Pulse360SellerWorkspaceDirectoryService.getPreviewAccounts';
import executePulse360SellerAction from '@salesforce/apex/Pulse360SellerOrchestratorService.executePulse360SellerAction';
import {
    buildExecutionRequest,
    normalizeActionContext,
    requiresApproval,
    whyNotNow
} from 'c/pulse360SellerWorkspaceActionSupport';

export default class Pulse360SellerWorkspaceV2 extends NavigationMixin(LightningElement) {
    @api recordId;
    @api previewRecordId;
    @api embeddedMode;

    activeAccountId;
    workspace;
    errorMessage;
    selectedActionContext;
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
            this.errorMessage = error?.body?.message || 'Unable to load preview accounts for Pulse360 seller workspace v2.';
        }
    }

    @wire(getSellerWorkspace, { accountId: '$activeAccountId' })
    wiredWorkspace({ data, error }) {
        if (data) {
            this.workspace = data;
            this.errorMessage = undefined;
            this.selectedActionContext = this.defaultActionContext();
            return;
        }

        this.workspace = undefined;
        if (this.activeAccountId) {
            this.errorMessage = error?.body?.message || 'Unable to load Pulse360 seller workspace v2.';
        }
        this.selectedActionContext = undefined;
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

    get primaryAction() {
        return this.selectedActionContext;
    }

    get validationLabel() {
        return this.workspace?.externallyValidated ? 'Externally validated' : 'Needs validation';
    }

    get coverageSummary() {
        return `${this.workspace?.crmCoveredSubsidiaryCount || 0} of ${this.workspace?.groupKnownSubsidiaryCount || 0} entities represented in CRM`;
    }

    get freshnessClass() {
        const tone = this.workspace?.freshnessTone || 'fresh';
        return `badge badge_${tone}`;
    }

    get freshnessSummary() {
        return `${this.workspace?.freshnessLabel || 'Freshness unknown'} across synced context. Model ${this.workspace?.modelId || 'unknown'} and prompt ${this.workspace?.promptVersion || 'unknown'} generated the current recommendation.`;
    }

    get uncertaintySummary() {
        if (this.workspace?.coverageGapFlag) {
            return 'Coverage is still partial across the group, so the seller should verify whether the current sponsor map is complete before committing.';
        }
        return 'The current move is credible, but the seller should still pressure-test sponsor fit and timing in the next conversation.';
    }

    get hasSupportingSources() {
        return this.topSupportingSources.length > 0;
    }

    get topSupportingSources() {
        return (this.primaryAction?.supportingSources || []).slice(0, 3);
    }

    get normalizedHierarchyEntities() {
        const selectedEntity = (this.primaryAction?.targetEntity || '').toLowerCase();
        return (this.workspace?.hierarchyEntities || []).map((entity) => {
            const isFocused = entity.entityName?.toLowerCase() === selectedEntity;
            return {
                ...entity,
                className: `entity-card${isFocused ? ' entity-card_selected' : ''}`,
                focusLabel: isFocused ? 'Focused now' : 'Set as focus',
                badgeClass: `badge ${entity.coverageStatus === 'uncovered' ? 'badge_warning' : 'badge_soft'}`
            };
        });
    }

    get otherMoves() {
        return (this.workspace?.secondaryActions || []).map((action, index) => {
            const normalizedAction = normalizeActionContext({
                action,
                accountId: this.activeAccountId,
                accountName: this.workspace?.accountName,
                promptVersion: this.workspace?.promptVersion,
                sourceContext: 'seller_v2_secondary',
                targetEntity: action.targetEntity || action.target || this.workspace?.accountName,
                rank: action.rank || index + 2
            });

            return {
                ...normalizedAction,
                key: `${normalizedAction.rank || index}-${normalizedAction.targetEntity || index}`,
                whyNotNow: whyNotNow(normalizedAction, this.primaryAction?.rawAction || this.primaryAction)
            };
        });
    }

    get hasOtherMoves() {
        return this.otherMoves.length > 0;
    }

    get topThingsToKnow() {
        return [
            {
                key: 'group',
                label: 'Group revenue story',
                value: this.hiddenRevenueLabel,
                copy: `${this.workspace?.groupKnownSubsidiaryCount || 0} entities are known in the commercial group, with ${this.workspace?.uncoveredEntityCount || 0} still outside visible CRM coverage.`
            },
            {
                key: 'whitespace',
                label: 'Whitespace readiness',
                value: `${this.workspace?.crossSellPropensity ?? 'N/A'}`,
                copy: this.primaryAction?.outreachObjective || 'Pulse360 has not yet generated a whitespace objective.'
            },
            {
                key: 'risk',
                label: 'Risk and health',
                value: `${this.workspace?.competitorRiskSignal ?? 'N/A'} / ${this.workspace?.healthScore ?? 'N/A'}`,
                copy: this.workspace?.engagementLabel || 'Engagement context is limited.'
            }
        ];
    }

    get hiddenRevenueLabel() {
        return this.compactCurrency(this.workspace?.hiddenRevenue, this.workspace?.currencyCode);
    }

    defaultActionContext() {
        if (!this.workspace) {
            return undefined;
        }

        return normalizeActionContext({
            action: this.workspace.primaryAction || {},
            accountId: this.activeAccountId,
            accountName: this.workspace.accountName,
            promptVersion: this.workspace.promptVersion,
            sourceContext: 'seller_v2_default',
            actionType: this.workspace.primaryAction?.actionType || 'create_task',
            targetEntity: this.workspace.primaryAction?.targetEntity || this.workspace.accountName
        });
    }

    handlePreviewAccountChange(event) {
        this.activeAccountId = event.detail.value;
        this.workspace = undefined;
        this.selectedActionContext = undefined;
    }

    handleFocusEntity(event) {
        const entityName = event.currentTarget.dataset.entityName;
        const entity = (this.workspace?.hierarchyEntities || []).find((candidate) => candidate.entityName === entityName);
        if (!entity) {
            return;
        }

        this.selectedActionContext = this.buildEntityFocusContext(entity);
    }

    async handleEntityTask(event) {
        const entityName = event.currentTarget.dataset.entityName;
        const entity = (this.workspace?.hierarchyEntities || []).find((candidate) => candidate.entityName === entityName);
        if (!entity) {
            return;
        }

        const actionContext = this.buildEntityFocusContext(entity, {
            actionType: 'create_task',
            sourceContext: 'seller_v2_group_task'
        });
        this.selectedActionContext = actionContext;
        await this.executeSellerAction(actionContext);
    }

    handleSelectSecondaryMove(event) {
        const rank = Number(event.currentTarget.dataset.rank);
        const action = (this.workspace?.secondaryActions || []).find((candidate) => candidate.rank === rank);
        if (!action) {
            return;
        }

        this.selectedActionContext = normalizeActionContext({
            action,
            accountId: this.activeAccountId,
            accountName: this.workspace?.accountName,
            promptVersion: this.workspace?.promptVersion,
            sourceContext: 'seller_v2_secondary_focus',
            targetEntity: action.targetEntity || action.target || this.workspace?.accountName
        });
    }

    async handleSecondaryTask(event) {
        const rank = Number(event.currentTarget.dataset.rank);
        const action = (this.workspace?.secondaryActions || []).find((candidate) => candidate.rank === rank);
        if (!action) {
            return;
        }

        const actionContext = normalizeActionContext({
            action,
            accountId: this.activeAccountId,
            accountName: this.workspace?.accountName,
            promptVersion: this.workspace?.promptVersion,
            sourceContext: 'seller_v2_secondary_task',
            actionType: 'create_task',
            targetEntity: action.targetEntity || action.target || this.workspace?.accountName
        });
        this.selectedActionContext = actionContext;
        await this.executeSellerAction(actionContext);
    }

    async handleCreateOpportunity() {
        await this.executeNamedAction('create_opportunity', 'seller_v2_create_opportunity');
    }

    async handleCreateTask() {
        await this.executeNamedAction('create_task', 'seller_v2_create_task');
    }

    async handleRouteSpecialist() {
        await this.executeNamedAction('route_specialist', 'seller_v2_route_specialist');
    }

    handleOpenPlanner() {
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Pulse360_Planner'
            }
        });
    }

    buildEntityFocusContext(entity, overrides = {}) {
        const baseAction = this.selectedActionContext?.rawAction || this.workspace?.primaryAction || {};
        const suggestedPlay = entity.suggestedPlay || this.selectedActionContext?.solutionFamily || 'Account Intelligence';
        return normalizeActionContext({
            action: baseAction,
            accountId: this.activeAccountId,
            accountName: this.workspace?.accountName,
            promptVersion: this.workspace?.promptVersion,
            sourceContext: overrides.sourceContext || 'seller_v2_group_focus',
            actionType: overrides.actionType || this.selectedActionContext?.actionType || 'create_task',
            targetEntity: entity.entityName,
            hierarchyEntity: entity,
            recommendedPlay: baseAction.recommendedPlay || suggestedPlay,
            solutionFamily: suggestedPlay,
            reasoning: entity.signal || this.selectedActionContext?.reasoning,
            buyingGroupGap:
                entity.coverageStatus === 'uncovered'
                    ? `Bring ${entity.entityName} into the operating plan and confirm sponsor coverage before the next seller motion.`
                    : this.selectedActionContext?.buyingGroupGap,
            outreachObjective: entity.signal || this.selectedActionContext?.outreachObjective,
            estimatedRevenueImpact: this.selectedActionContext?.estimatedRevenueImpact,
            confidence: this.selectedActionContext?.confidence,
            confidenceLabel: this.selectedActionContext?.confidenceLabel,
            agentGoal: 'analyze_whitespace',
            mode: overrides.mode || 'focus',
            rank: this.selectedActionContext?.rank,
            ...overrides
        });
    }

    async executeNamedAction(actionType, sourceContext) {
        const actionContext = this.normalizeIncomingActionContext({
            ...(this.selectedActionContext || this.defaultActionContext() || {}),
            actionType,
            sourceContext
        });
        this.selectedActionContext = actionContext;
        await this.executeSellerAction(actionContext);
    }

    async executeSellerAction(actionContext) {
        const normalizedActionContext = this.normalizeIncomingActionContext(actionContext);
        const previewRequest = buildExecutionRequest(
            normalizedActionContext,
            requiresApproval(normalizedActionContext.actionType) ? 'preview' : 'auto_prepare'
        );

        try {
            let result = await executePulse360SellerAction({ request: previewRequest });

            if (result?.status === 'ApprovalRequired') {
                const confirmed = await LightningConfirm.open({
                    label: 'Approve Pulse360 seller action',
                    message: result.agentSummary,
                    theme: 'warning'
                });

                if (!confirmed) {
                    return;
                }

                result = await executePulse360SellerAction({
                    request: buildExecutionRequest(normalizedActionContext, 'approved')
                });
            }

            this.showToast(
                'Pulse360 action executed',
                `Created ${result.primaryObjectApiName || 'follow-up'} for ${normalizedActionContext.targetEntity || this.workspace.accountName}.`,
                'success'
            );

            if (result?.primaryRecordId && result?.primaryObjectApiName) {
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: result.primaryRecordId,
                        objectApiName: result.primaryObjectApiName,
                        actionName: 'view'
                    }
                });
            }
        } catch (error) {
            this.showToast(
                'Pulse360 action failed',
                error?.body?.message || 'Unable to execute the seller action.',
                'error'
            );
        }
    }

    normalizeIncomingActionContext(actionContext) {
        if (!actionContext) {
            return actionContext;
        }

        return {
            ...actionContext,
            accountId: actionContext.accountId || this.activeAccountId || this.workspace?.accountId || null,
            accountName: actionContext.accountName || this.workspace?.accountName,
            promptVersion: actionContext.promptVersion || this.workspace?.promptVersion,
            targetEntity: actionContext.targetEntity || this.workspace?.accountName
        };
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
