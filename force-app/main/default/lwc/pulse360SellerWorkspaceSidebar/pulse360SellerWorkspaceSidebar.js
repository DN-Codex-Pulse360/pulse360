import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { LightningElement, api, wire } from 'lwc';
import { MessageContext, publish, subscribe, unsubscribe, APPLICATION_SCOPE } from 'lightning/messageService';

import getSellerWorkspace from '@salesforce/apex/Pulse360SellerWorkspaceService.getSellerWorkspace';
import SELLER_WORKSPACE_CONTEXT from '@salesforce/messageChannel/Pulse360SellerWorkspaceContext__c';
import {
    buildActionDescription,
    buildAgentBrief,
    normalizeActionContext
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
        const actionContext = message?.actionContext;
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

    handleWorkspaceAction(event) {
        const actionContext = event.detail;
        if (!actionContext?.actionType) {
            return;
        }

        this.selectedActionContext = actionContext;
        this.publishSelectedContext();

        if (actionContext.mode === 'focus' || actionContext.mode === 'promote') {
            return;
        }

        this.resolveAction(actionContext);
    }

    resolveAction(actionContext) {
        switch (actionContext.actionType) {
            case 'open_opportunity':
                this.openOpportunity(actionContext);
                return;
            case 'route_specialist':
                this.createTask(actionContext, `Pulse360 Route: ${actionContext.specialistRoute || actionContext.recommendedPlay}`);
                return;
            case 'launch_agent':
                this.createTask(actionContext, `Pulse360 Agent Brief: ${actionContext.targetEntity || actionContext.accountName}`, buildAgentBrief(actionContext));
                return;
            case 'open_entity':
                this.openEntity(actionContext);
                return;
            case 'create_task':
            default:
                this.createTask(actionContext, `Pulse360: ${actionContext.recommendedPlay || actionContext.targetEntity}`);
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

    openOpportunity(actionContext) {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Opportunity',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: encodeDefaultFieldValues({
                    Name: `${actionContext.targetEntity || this.workspace.accountName} - ${actionContext.recommendedPlay || 'Pulse360 opportunity'}`,
                    AccountId: this.recordId,
                    Description: buildActionDescription(actionContext)
                })
            }
        });
    }

    createTask(actionContext, subject, descriptionOverride) {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Task',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: encodeDefaultFieldValues({
                    Subject: subject,
                    WhatId: this.recordId,
                    Description: descriptionOverride || buildActionDescription(actionContext)
                })
            }
        });
    }
}
