import { NavigationMixin } from 'lightning/navigation';
import { LightningElement, api, wire } from 'lwc';
import { MessageContext, publish, subscribe, unsubscribe, APPLICATION_SCOPE } from 'lightning/messageService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';

import getSellerWorkspace from '@salesforce/apex/Pulse360SellerWorkspaceService.getSellerWorkspace';
import executePulse360SellerAction from '@salesforce/apex/Pulse360SellerOrchestratorService.executePulse360SellerAction';
import SELLER_WORKSPACE_CONTEXT from '@salesforce/messageChannel/Pulse360SellerWorkspaceContext__c';
import {
    buildExecutionRequest,
    normalizeActionContext,
    requiresApproval
} from 'c/pulse360SellerWorkspaceActionSupport';

export default class Pulse360SellerWorkspaceSidebar extends NavigationMixin(LightningElement) {
    @api recordId;

    workspace;
    errorMessage;
    selectedActionContext;
    subscription;

    @wire(MessageContext)
    messageContext;

    @wire(getSellerWorkspace, { accountId: '$recordId' })
    wiredWorkspace({ data, error }) {
        if (data) {
            this.workspace = data;
            this.errorMessage = undefined;
            this.selectedActionContext = this.selectedActionContext || this.defaultActionContext();
            return;
        }

        this.workspace = undefined;
        this.errorMessage = error?.body?.message || 'Unable to load Pulse360 seller sidebar.';
        this.selectedActionContext = undefined;
    }

    connectedCallback() {
        this.subscribeToWorkspaceContext();
    }

    disconnectedCallback() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    get hasWorkspace() {
        return Boolean(this.workspace);
    }

    get hasError() {
        return Boolean(this.errorMessage);
    }

    get hierarchyEntities() {
        return this.workspace?.hierarchyEntities || [];
    }

    get selectedEntityName() {
        return this.selectedActionContext?.targetEntity || this.workspace?.accountName;
    }

    get coveragePercent() {
        const known = this.workspace?.groupKnownSubsidiaryCount || 0;
        const covered = this.workspace?.crmCoveredSubsidiaryCount || 0;
        if (!known) {
            return 0;
        }
        return Math.round((covered / known) * 100);
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
            sourceContext: 'sidebar_default',
            actionType: this.workspace.primaryAction?.actionType || 'launch_agent',
            targetEntity: this.workspace.primaryAction?.targetEntity || this.workspace.accountName
        });
    }

    subscribeToWorkspaceContext() {
        if (this.subscription) {
            return;
        }

        this.subscription = subscribe(
            this.messageContext,
            SELLER_WORKSPACE_CONTEXT,
            (message) => this.handleWorkspaceMessage(message),
            { scope: APPLICATION_SCOPE }
        );
    }

    handleWorkspaceMessage(message) {
        const actionContext = this.normalizeIncomingActionContext(message?.actionContext);
        if (!actionContext || actionContext.accountId !== this.recordId) {
            return;
        }

        this.selectedActionContext = actionContext;
    }

    publishSelectedContext() {
        if (!this.messageContext || !this.selectedActionContext) {
            return;
        }

        publish(this.messageContext, SELLER_WORKSPACE_CONTEXT, {
            messageType: 'context_sync',
            actionContext: this.selectedActionContext
        });
    }

    async handleWorkspaceAction(event) {
        const actionContext = this.normalizeIncomingActionContext(event.detail);
        if (!actionContext?.actionType) {
            return;
        }

        this.selectedActionContext = actionContext;
        this.publishSelectedContext();

        if (actionContext.mode === 'focus' || actionContext.mode === 'promote') {
            return;
        }

        await this.resolveAction(actionContext);
    }

    async resolveAction(actionContext) {
        switch (actionContext.actionType) {
            case 'open_entity':
                this.openEntity(actionContext);
                return;
            default:
                await this.executeSellerAction(actionContext);
                return;
        }
    }

    openEntity(actionContext) {
        if (actionContext.targetRecordId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: actionContext.targetRecordId,
                    objectApiName: 'Account',
                    actionName: 'view'
                }
            });
        }
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
