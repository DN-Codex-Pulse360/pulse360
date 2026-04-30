import { NavigationMixin } from 'lightning/navigation';
import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';

import askPulse360SellerAgent from '@salesforce/apex/Pulse360SellerOrchestratorService.askPulse360SellerAgent';
import executePulse360SellerAction from '@salesforce/apex/Pulse360SellerOrchestratorService.executePulse360SellerAction';
import getPulse360AccountContext from '@salesforce/apex/Pulse360SellerOrchestratorService.getPulse360AccountContext';

import {
    agentGoalLabel,
    buildExecutionRequest,
    normalizeActionContext,
    requiresApproval
} from 'c/pulse360SellerWorkspaceActionSupport';

const PROMPTS = [
    {
        key: 'next_move',
        label: 'What should I do next?',
        userPrompt: 'Tell me the best next seller move on this account and why now.',
        actionType: 'open_opportunity',
        agentGoal: 'generate_opportunity_brief'
    },
    {
        key: 'outreach',
        label: 'Draft outreach',
        userPrompt: 'Draft the next outreach brief with the meeting ask and commercial objective.',
        actionType: 'launch_agent',
        agentGoal: 'generate_outreach_brief'
    },
    {
        key: 'whitespace',
        label: 'Analyze whitespace',
        userPrompt: 'Explain which entity or whitespace path matters most and why.',
        actionType: 'launch_agent',
        agentGoal: 'analyze_whitespace'
    },
    {
        key: 'evidence',
        label: 'Test the evidence',
        userPrompt: 'Tell me what is grounded, what is uncertain, and what must be validated before execution.',
        actionType: 'create_task',
        agentGoal: 'validate_evidence'
    },
    {
        key: 'manager',
        label: 'Prep manager update',
        userPrompt: 'Summarize the account, move, and risk for a manager or QBR update.',
        actionType: 'create_task',
        agentGoal: 'summarize_account_for_manager'
    }
];

export default class Pulse360AgentPanel extends NavigationMixin(LightningElement) {
    @api recordId;

    context;
    errorMessage;
    loading = false;
    transcript = [];
    activePromptKey = PROMPTS[0].key;
    autoLoadedRecordId;

    @wire(getPulse360AccountContext, { accountId: '$recordId' })
    wiredContext({ data, error }) {
        if (data) {
            this.context = data;
            this.errorMessage = undefined;

            if (this.autoLoadedRecordId !== this.recordId) {
                this.autoLoadedRecordId = this.recordId;
                this.transcript = [];
                void this.askPrompt(PROMPTS[0].key);
            }
            return;
        }

        this.context = undefined;
        this.transcript = [];
        if (this.recordId) {
            this.errorMessage = error?.body?.message || 'Unable to load Pulse360 Agent for this account.';
        }
    }

    get hasContext() {
        return Boolean(this.context);
    }

    get hasError() {
        return Boolean(this.errorMessage);
    }

    get hasTranscript() {
        return this.transcript.length > 0;
    }

    get currentTurn() {
        return this.transcript[0] || null;
    }

    get executionDisabled() {
        return !this.currentTurn || this.loading;
    }

    get promptOptions() {
        return PROMPTS.map((prompt) => ({
            ...prompt,
            className: prompt.key === this.activePromptKey ? 'prompt-chip prompt-chip_active' : 'prompt-chip'
        }));
    }

    handlePromptClick(event) {
        void this.askPrompt(event.currentTarget.dataset.key);
    }

    async askPrompt(promptKey) {
        const prompt = PROMPTS.find((candidate) => candidate.key === promptKey);
        if (!prompt || !this.context) {
            return;
        }

        this.activePromptKey = prompt.key;
        this.loading = true;

        try {
            const actionContext = this.buildActionContext(prompt);
            const result = await askPulse360SellerAgent({
                request: buildExecutionRequest(actionContext, 'preview')
            });

            this.transcript = [
                {
                    id: `${prompt.key}-${Date.now()}`,
                    promptCopy: prompt.userPrompt,
                    goalLabel: agentGoalLabel(actionContext.agentGoal),
                    actionContext,
                    result
                },
                ...this.transcript
            ].slice(0, 3);
        } catch (error) {
            this.showToast(
                'Pulse360 Agent failed',
                error?.body?.message || 'Unable to get a grounded seller response right now.',
                'error'
            );
        } finally {
            this.loading = false;
        }
    }

    async handleCreateOpportunity() {
        await this.executeCurrentAction('create_opportunity');
    }

    async handleCreateTask() {
        await this.executeCurrentAction('create_task');
    }

    async handleRouteSpecialist() {
        await this.executeCurrentAction('route_specialist');
    }

    buildActionContext(prompt) {
        const primaryAction = this.context?.primaryAction || {};
        const hierarchyEntity = this.matchHierarchyEntity(primaryAction?.targetEntity);

        return normalizeActionContext({
            action: primaryAction,
            accountId: this.recordId,
            accountName: this.context?.accountName,
            promptVersion: primaryAction?.promptVersion,
            sourceContext: `account_record_agent_${prompt.key}`,
            actionType: prompt.actionType,
            targetEntity: hierarchyEntity?.entityName || primaryAction?.targetEntity || this.context?.accountName,
            hierarchyEntity,
            agentGoal: prompt.agentGoal,
            recommendedPlay: primaryAction?.recommendedPlay,
            solutionFamily: primaryAction?.solutionFamily,
            reasoning: primaryAction?.reasoning,
            estimatedRevenueImpact: primaryAction?.estimatedRevenueImpact,
            buyingGroupGap: primaryAction?.buyingGroupGap,
            outreachObjective: primaryAction?.outreachObjective,
            confidence: primaryAction?.confidence,
            confidenceLabel: primaryAction?.confidenceLabel
        });
    }

    matchHierarchyEntity(targetEntity) {
        const hierarchy = Array.isArray(this.context?.hierarchyPayload) ? this.context.hierarchyPayload : [];
        return (
            hierarchy.find((entity) => entity?.entityName === targetEntity) ||
            hierarchy.find((entity) => entity?.isCurrentAccount) ||
            hierarchy[0] ||
            null
        );
    }

    async executeCurrentAction(actionType) {
        if (!this.currentTurn) {
            return;
        }

        const actionContext = {
            ...this.currentTurn.actionContext,
            actionType,
            sourceContext: `account_record_agent_execute_${actionType}`
        };

        const previewRequest = buildExecutionRequest(
            actionContext,
            requiresApproval(actionType) ? 'preview' : 'auto_prepare'
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
                'Pulse360 agent action executed',
                `Created ${result.primaryObjectApiName || 'follow-up'} for ${actionContext.targetEntity || this.context?.accountName}.`,
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
                'Pulse360 agent action failed',
                error?.body?.message || 'Unable to execute the current Pulse360 agent action.',
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
