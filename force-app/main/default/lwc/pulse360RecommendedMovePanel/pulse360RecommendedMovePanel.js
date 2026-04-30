import { NavigationMixin } from 'lightning/navigation';
import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';

import getSellerWorkspace from '@salesforce/apex/Pulse360SellerWorkspaceService.getSellerWorkspace';
import executePulse360SellerAction from '@salesforce/apex/Pulse360SellerOrchestratorService.executePulse360SellerAction';
import { buildExecutionRequest, normalizeActionContext, requiresApproval } from 'c/pulse360SellerWorkspaceActionSupport';

export default class Pulse360RecommendedMovePanel extends NavigationMixin(LightningElement) {
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
            this.errorMessage = error?.body?.message || 'Unable to load the Pulse360 recommended move.';
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
            sourceContext: 'account_record_recommended_move',
            actionType: this.workspace?.primaryAction?.actionType || 'create_task',
            targetEntity: this.workspace?.primaryAction?.targetEntity || this.workspace?.accountName
        });
    }

    async handleCreateOpportunity() {
        await this.executeNamedAction('create_opportunity', 'account_record_create_opportunity');
    }

    async handleCreateTask() {
        await this.executeNamedAction('create_task', 'account_record_create_task');
    }

    async handleRouteSpecialist() {
        await this.executeNamedAction('route_specialist', 'account_record_route_specialist');
    }

    handleOpenPlanner() {
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Pulse360_Planner'
            }
        });
    }

    async executeNamedAction(actionType, sourceContext) {
        const actionContext = {
            ...this.primaryAction,
            actionType,
            sourceContext
        };
        await this.executeSellerAction(actionContext);
    }

    async executeSellerAction(actionContext) {
        const previewRequest = buildExecutionRequest(
            actionContext,
            requiresApproval(actionContext.actionType) ? 'preview' : 'auto_prepare'
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
                    request: buildExecutionRequest(actionContext, 'approved')
                });
            }

            this.showToast(
                'Pulse360 action executed',
                `Created ${result.primaryObjectApiName || 'follow-up'} for ${actionContext.targetEntity || this.workspace?.accountName}.`,
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
