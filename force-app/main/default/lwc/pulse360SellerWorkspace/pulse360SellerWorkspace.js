import { NavigationMixin } from 'lightning/navigation';
import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';

import getSellerWorkspace from '@salesforce/apex/Pulse360SellerWorkspaceService.getSellerWorkspace';
import executePulse360SellerAction from '@salesforce/apex/Pulse360SellerOrchestratorService.executePulse360SellerAction';
import {
    buildExecutionRequest,
    normalizeActionContext,
    requiresApproval,
    summarizeSupportingSources,
    whyNotNow
} from 'c/pulse360SellerWorkspaceActionSupport';
import {
    agentforceCompatibilityMessage,
    buildAgentPreview,
    buildSellerAgentUtterance,
    canLaunchAgentforce as canLaunchAgentforceTarget,
    launchAgentforceConversation
} from 'c/pulse360SellerWorkspaceAgentforceSupport';

export default class Pulse360SellerWorkspace extends NavigationMixin(LightningElement) {
    @api recordId;
    @api agentId;
    @api agentLabel = 'Pulse360 Agent';

    workspace;
    errorMessage;
    selectedActionContext;
    agentLaunchError;
    agentRuntimeBlocked = false;

    @wire(getSellerWorkspace, { accountId: '$recordId' })
    wiredWorkspace({ data, error }) {
        if (data) {
            this.workspace = data;
            this.errorMessage = undefined;
            this.selectedActionContext = this.defaultActionContext();
            this.agentLaunchError = undefined;
            return;
        }

        this.workspace = undefined;
        this.errorMessage = error?.body?.message || 'Unable to load Pulse360 seller workspace.';
        this.selectedActionContext = undefined;
    }

    get hasWorkspace() {
        return Boolean(this.workspace);
    }

    get hasError() {
        return Boolean(this.errorMessage);
    }

    get hasOtherMoves() {
        return this.otherMoves.length > 0;
    }

    get secondaryActions() {
        return this.workspace?.secondaryActions || [];
    }

    get coveragePercent() {
        const known = this.workspace?.groupKnownSubsidiaryCount || 0;
        const covered = this.workspace?.crmCoveredSubsidiaryCount || 0;
        if (!known) {
            return 0;
        }
        return Math.round((covered / known) * 100);
    }

    get coverageBarStyle() {
        return `width:${this.coveragePercent || 0}%;`;
    }

    get canLaunchNativeAgent() {
        return canLaunchAgentforceTarget(this.agentId, this.agentRuntimeBlocked);
    }

    get showFallbackButton() {
        return !this.canLaunchNativeAgent;
    }

    get selectedEntityName() {
        return this.selectedActionContext?.targetEntity || this.workspace?.accountName;
    }

    defaultActionContext() {
        if (!this.workspace) {
            return undefined;
        }

        return normalizeActionContext({
            action: this.workspace.primaryAction || {},
            accountId: this.recordId,
            accountName: this.workspace.accountName,
            promptVersion: this.workspace.promptVersion,
            sourceContext: 'workspace_default',
            actionType: this.workspace.primaryAction?.actionType || 'create_task',
            targetEntity: this.workspace.primaryAction?.targetEntity || this.workspace.accountName
        });
    }

    get heroSummary() {
        if (!this.workspace?.hiddenRevenue) {
            return this.workspace?.hierarchyNote || 'Pulse360 is ready to guide the next move on this account.';
        }

        return `Pulse360 sees ${this.workspace.groupKnownSubsidiaryCount || 0} known group entities, with ${
            this.workspace.uncoveredEntityCount || 0
        } still outside visible CRM coverage. ${this.formattedHiddenRevenue} sits outside the seller's current operating surface.`;
    }

    get formattedHiddenRevenue() {
        const currency = this.workspace?.currencyCode || 'USD';
        const hiddenRevenue = Number(this.workspace?.hiddenRevenue || 0);
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency,
            maximumFractionDigits: 0
        }).format(hiddenRevenue);
    }

    get heroPills() {
        return [
            {
                key: 'freshness',
                label: this.workspace?.freshnessLabel || 'Freshness unknown',
                className: `status-pill status-pill_${this.workspace?.freshnessTone || 'fresh'}`
            },
            {
                key: 'coverage',
                label: `${this.coveragePercent}% CRM group coverage`,
                className: 'status-pill status-pill_neutral'
            },
            {
                key: 'validation',
                label: this.workspace?.externallyValidated ? 'Externally validated' : 'Needs validation',
                className: `status-pill ${this.workspace?.externallyValidated ? 'status-pill_positive' : 'status-pill_neutral'}`
            }
        ];
    }

    get agentPreview() {
        return buildAgentPreview({
            actionContext: this.selectedActionContext,
            agentLabel: this.agentLabel
        });
    }

    get agentAvailabilityCopy() {
        if (this.agentLaunchError) {
            return this.agentLaunchError;
        }
        if (!this.agentId) {
            return 'Native Agentforce is not configured on this page yet, so only deterministic seller actions are available.';
        }
        return agentforceCompatibilityMessage(this.agentLabel);
    }

    get primaryAction() {
        return this.selectedActionContext;
    }

    get supportingSources() {
        return this.selectedActionContext?.supportingSources || [];
    }

    get hasSupportingSources() {
        return this.supportingSources.length > 0;
    }

    get evidenceSummary() {
        return summarizeSupportingSources(this.supportingSources);
    }

    get uncertaintySummary() {
        if (this.workspace?.coverageGapFlag) {
            return `${this.workspace.accountName} still shows partial CRM coverage across the commercial group, so sponsor and whitespace coverage should be pressure-tested before execution.`;
        }
        return 'CRM coverage is reasonably aligned, but the seller should still confirm the sponsor path and timing.';
    }

    get externalValidationLabel() {
        return this.workspace?.externallyValidated ? 'Validated' : 'Pending';
    }

    get insightSignals() {
        return [
            {
                key: 'cross-sell',
                label: 'Cross-sell propensity',
                value: this.workspace?.crossSellPropensity ?? 'N/A'
            },
            {
                key: 'risk',
                label: 'Competitor risk',
                value: this.workspace?.competitorRiskSignal ?? 'N/A'
            },
            {
                key: 'health',
                label: 'Health score',
                value: this.workspace?.healthScore ?? 'N/A'
            },
            {
                key: 'validation',
                label: 'External validation',
                value: this.externalValidationLabel
            }
        ];
    }

    get normalizedHierarchyEntities() {
        const selectedEntity = (this.selectedEntityName || '').toLowerCase();
        return (this.workspace?.hierarchyEntities || []).map((entity) => ({
            ...entity,
            className: `entity-card${entity.entityName?.toLowerCase() === selectedEntity ? ' entity-card_selected' : ''}`,
            focusLabel: entity.entityName?.toLowerCase() === selectedEntity ? 'Focused now' : 'Set focus'
        }));
    }

    get otherMoves() {
        return this.secondaryActions.map((action, index) => {
            const normalizedAction = normalizeActionContext({
                action,
                accountId: this.recordId,
                accountName: this.workspace?.accountName,
                promptVersion: this.workspace?.promptVersion,
                sourceContext: 'secondary_option',
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
            sourceContext: 'group_create_task'
        });
        this.selectedActionContext = actionContext;
        await this.executeSellerAction(actionContext);
    }

    handleSelectSecondaryMove(event) {
        const rank = Number(event.currentTarget.dataset.rank);
        const action = this.secondaryActions.find((candidate) => candidate.rank === rank);
        if (!action) {
            return;
        }

        this.selectedActionContext = normalizeActionContext({
            action,
            accountId: this.recordId,
            accountName: this.workspace?.accountName,
            promptVersion: this.workspace?.promptVersion,
            sourceContext: 'secondary_focus',
            targetEntity: action.targetEntity || action.target || this.workspace?.accountName
        });
    }

    async handleSecondaryTask(event) {
        const rank = Number(event.currentTarget.dataset.rank);
        const action = this.secondaryActions.find((candidate) => candidate.rank === rank);
        if (!action) {
            return;
        }

        const actionContext = normalizeActionContext({
            action,
            accountId: this.recordId,
            accountName: this.workspace?.accountName,
            promptVersion: this.workspace?.promptVersion,
            sourceContext: 'secondary_create_task',
            actionType: 'create_task',
            targetEntity: action.targetEntity || action.target || this.workspace?.accountName
        });
        this.selectedActionContext = actionContext;
        await this.executeSellerAction(actionContext);
    }

    async handleCreateTask() {
        await this.executeNamedAction('create_task', 'primary_create_task');
    }

    async handleRouteSpecialist() {
        await this.executeNamedAction('route_specialist', 'primary_route_specialist');
    }

    async handleCreateSellerBrief() {
        await this.executeNamedAction('create_task', 'agent_fallback_create_task', {
            userMessage: 'Create a seller brief because native Agentforce is unavailable on this page.'
        });
    }

    async handleOpenAgent() {
        if (!this.canLaunchNativeAgent) {
            return;
        }

        try {
            const utterance = buildSellerAgentUtterance({
                actionContext: this.selectedActionContext,
                workspace: this.workspace
            });
            await launchAgentforceConversation({
                agentId: this.agentId,
                utterance
            });
            this.agentLaunchError = undefined;
            this.agentRuntimeBlocked = false;
        } catch (error) {
            this.agentRuntimeBlocked = true;
            this.agentLaunchError =
                error?.body?.message ||
                error?.message ||
                'Pulse360 Agent could not be opened from this page. Use the fallback action while the ACC target is corrected.';
            this.showToast('Pulse360 Agent unavailable', this.agentLaunchError, 'warning');
        }
    }

    buildEntityFocusContext(entity, overrides = {}) {
        const baseAction = this.selectedActionContext?.rawAction || this.workspace?.primaryAction || {};
        const suggestedPlay = entity.suggestedPlay || this.selectedActionContext?.solutionFamily || 'Account Intelligence';
        return normalizeActionContext({
            action: baseAction,
            accountId: this.recordId,
            accountName: this.workspace?.accountName,
            promptVersion: this.workspace?.promptVersion,
            sourceContext: overrides.sourceContext || 'group_focus',
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

    async executeNamedAction(actionType, sourceContext, extraContext = {}) {
        const actionContext = this.normalizeIncomingActionContext({
            ...(this.selectedActionContext || this.defaultActionContext() || {}),
            actionType,
            sourceContext,
            ...extraContext
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
            this.navigateToExecutionResult(result);
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
            accountId: actionContext.accountId || this.recordId || this.workspace?.accountId || null,
            accountName: actionContext.accountName || this.workspace?.accountName,
            promptVersion: actionContext.promptVersion || this.workspace?.promptVersion,
            targetEntity: actionContext.targetEntity || this.workspace?.accountName
        };
    }

    navigateToExecutionResult(result) {
        if (!result?.primaryRecordId || !result?.primaryObjectApiName) {
            return;
        }

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: result.primaryRecordId,
                objectApiName: result.primaryObjectApiName,
                actionName: 'view'
            }
        });
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
