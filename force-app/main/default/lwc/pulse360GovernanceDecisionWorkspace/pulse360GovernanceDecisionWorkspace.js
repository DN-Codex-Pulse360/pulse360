import { LightningElement, api, wire } from 'lwc';
import {
    getRecord,
    getFieldDisplayValue,
    getFieldValue,
    notifyRecordUpdateAvailable
} from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';
import USER_ID from '@salesforce/user/Id';
import getPulse360ReviewContext from '@salesforce/apex/Pulse360AgentOrchestratorService.getPulse360ReviewContext';
import getPulse360DataCloudReviewEvidence from '@salesforce/apex/Pulse360AgentOrchestratorService.getPulse360DataCloudReviewEvidence';
import recordPulse360GovernanceDecision from '@salesforce/apex/Pulse360AgentOrchestratorService.recordPulse360GovernanceDecision';

import LEFT_ACCOUNT_FIELD from '@salesforce/schema/Governance_Case__c.Left_Account__c';
import RIGHT_ACCOUNT_FIELD from '@salesforce/schema/Governance_Case__c.Right_Account__c';
import MERGED_ACCOUNT_FIELD from '@salesforce/schema/Governance_Case__c.Merged_Account__c';
import SURVIVING_ACCOUNT_FIELD from '@salesforce/schema/Governance_Case__c.Surviving_Account__c';
import DECISION_REASON_CODE_FIELD from '@salesforce/schema/Governance_Case__c.Decision_Reason_Code__c';
import DECISION_REASON_TEXT_FIELD from '@salesforce/schema/Governance_Case__c.Decision_Reason_Text__c';
import REVIEW_FOLLOWUP_REQUIRED_FIELD from '@salesforce/schema/Governance_Case__c.Review_Followup_Required__c';
import RECOMMENDED_ACTION_FIELD from '@salesforce/schema/Governance_Case__c.Recommended_Action__c';
import ACCOUNT_NAME_FIELD from '@salesforce/schema/Account.Name';

const CASE_FIELDS = [
    LEFT_ACCOUNT_FIELD,
    RIGHT_ACCOUNT_FIELD,
    MERGED_ACCOUNT_FIELD,
    SURVIVING_ACCOUNT_FIELD,
    DECISION_REASON_CODE_FIELD,
    DECISION_REASON_TEXT_FIELD,
    REVIEW_FOLLOWUP_REQUIRED_FIELD,
    RECOMMENDED_ACTION_FIELD
];

const DECISION_REASON_OPTIONS = [
    { label: 'Clear Duplicate Match', value: 'CLEAR_DUPLICATE_MATCH' },
    { label: 'Legal Entity Match Confirmed', value: 'LEGAL_ENTITY_MATCH_CONFIRMED' },
    { label: 'Trusted Attribute Alignment', value: 'TRUSTED_ATTRIBUTE_ALIGNMENT' },
    { label: 'Hierarchy Alignment Confirmed', value: 'HIERARCHY_ALIGNMENT_CONFIRMED' },
    { label: 'Reference Data Confirmed', value: 'REFERENCE_DATA_CONFIRMED' },
    { label: 'Different Legal Entities', value: 'DIFFERENT_LEGAL_ENTITIES' },
    { label: 'Insufficient Match Evidence', value: 'INSUFFICIENT_MATCH_EVIDENCE' },
    { label: 'Hierarchy Conflict Blocks Match', value: 'HIERARCHY_CONFLICT_BLOCKS_MATCH' },
    { label: 'Trusted Attribute Conflict', value: 'TRUSTED_ATTRIBUTE_CONFLICT' },
    { label: 'False Positive Model Output', value: 'FALSE_POSITIVE_MODEL_OUTPUT' },
    { label: 'Needs External Reference Check', value: 'NEEDS_EXTERNAL_REFERENCE_CHECK' },
    { label: 'Needs Business Owner Review', value: 'NEEDS_BUSINESS_OWNER_REVIEW' },
    { label: 'Needs Hierarchy Validation', value: 'NEEDS_HIERARCHY_VALIDATION' },
    { label: 'Needs Data Remediation', value: 'NEEDS_DATA_REMEDIATION' },
    { label: 'Needs Policy Decision', value: 'NEEDS_POLICY_DECISION' },
    { label: 'CSP Account Mapping Confirmed', value: 'CSP_ACCOUNT_MAPPING_CONFIRMED' },
    { label: 'CSP Proposition Qualified', value: 'CSP_PROPOSITION_QUALIFIED' },
    { label: 'CSP Governance Review Required', value: 'CSP_GOVERNANCE_REVIEW_REQUIRED' },
    { label: 'CSP Insufficient Evidence', value: 'CSP_INSUFFICIENT_EVIDENCE' }
];

export default class Pulse360GovernanceDecisionWorkspace extends LightningElement {
    @api recordId;

    decisionReasonCode;
    decisionReasonText;
    reviewFollowupRequired = false;
    survivingAccountId;
    mergedAccountId;
    isSaving = false;
    isLoadingEvidence = false;
    record;
    error;
    hasWireResolved = false;
    reviewContext;
    reviewEvidence;
    reviewEvidenceError;
    lastLoadedRecordId;

    @wire(getRecord, { recordId: '$recordId', optionalFields: CASE_FIELDS })
    wiredRecord({ data, error }) {
        this.hasWireResolved = true;
        if (data) {
            this.record = data;
            this.error = undefined;
            this.decisionReasonCode = this.fieldValue(DECISION_REASON_CODE_FIELD);
            this.decisionReasonText = this.fieldValue(DECISION_REASON_TEXT_FIELD);
            this.reviewFollowupRequired = Boolean(this.fieldValue(REVIEW_FOLLOWUP_REQUIRED_FIELD));
            this.survivingAccountId = this.fieldValue(SURVIVING_ACCOUNT_FIELD);
            this.mergedAccountId = this.fieldValue(MERGED_ACCOUNT_FIELD);
            this.loadAgentReviewState();
        } else if (error) {
            this.error = error;
            this.record = undefined;
        }
    }

    @wire(getRecord, { recordId: '$survivingAccountId', fields: [ACCOUNT_NAME_FIELD] })
    survivingAccountRecord;

    @wire(getRecord, { recordId: '$mergedAccountId', fields: [ACCOUNT_NAME_FIELD] })
    mergedAccountRecord;

    get decisionReasonOptions() {
        return DECISION_REASON_OPTIONS;
    }

    get isLoaded() {
        return Boolean(this.record);
    }

    get isLoading() {
        return !this.hasWireResolved;
    }

    get hasError() {
        return Boolean(this.error);
    }

    get errorMessage() {
        return this.error?.body?.message || 'Unable to load the decision workspace.';
    }

    get recommendedAction() {
        return this.displayValue(RECOMMENDED_ACTION_FIELD) || 'Not available';
    }

    get isCspReview() {
        return this.reviewContext?.sourceProduct === 'csp_smart_city_proposition_readiness' ||
            this.reviewEvidence?.sourceProduct === 'csp_smart_city_proposition_readiness';
    }

    get showMergeControls() {
        return !this.isCspReview;
    }

    get cspTargetSummary() {
        const target = this.reviewEvidence?.targetEntityName || this.reviewContext?.targetEntityName || 'Target proposition';
        const offering = this.reviewEvidence?.offeringFamily || this.reviewContext?.offeringFamily || 'smart city offering';
        const market = this.reviewEvidence?.market || 'market not available';
        return `${target} / ${offering} / ${market}`;
    }

    get cspTargetCustomers() {
        return this.reviewEvidence?.targetB2bCustomerNames || 'Target customer list is not available.';
    }

    get cspReviewPriority() {
        return this.reviewEvidence?.reviewPriority || this.reviewContext?.reviewPriority || 'Not assigned';
    }

    get cspRecommendedNextActions() {
        return this.reviewEvidence?.recommendedNextActions || 'No recommended next actions are available.';
    }

    get mergeSelectionHelp() {
        if (!this.canCommitDecision) {
            return 'Direct Data Cloud evidence must be available before the steward can commit a decision.';
        }
        if (this.recommendedAction === 'Approve Merge') {
            return 'Confirm the surviving and merged accounts, then approve the case.';
        }
        if (this.isCspReview) {
            return 'Review the target customer route and record the account mapping, proposition qualification, or governance outcome.';
        }
        return 'Use the decision controls to confirm, reject, or defer after reviewing the evidence.';
    }

    get reviewEvidenceStatus() {
        if (this.isLoadingEvidence) {
            return 'Loading direct Data Cloud evidence';
        }
        if (this.reviewEvidence?.available) {
            return 'Direct Data Cloud evidence ready';
        }
        return 'Direct Data Cloud evidence unavailable';
    }

    get canCommitDecision() {
        return this.reviewEvidence?.available === true;
    }

    get decisionDisabled() {
        return this.isSaving || !this.canCommitDecision;
    }

    get leftAccountId() {
        return this.fieldValue(LEFT_ACCOUNT_FIELD);
    }

    get rightAccountId() {
        return this.fieldValue(RIGHT_ACCOUNT_FIELD);
    }

    get survivingAccountName() {
        return this.lookupLabel(this.survivingAccountRecord, this.survivingAccountId, 'Not selected');
    }

    get survivingAccountUrl() {
        return this.recordUrl(this.survivingAccountId);
    }

    get mergedAccountName() {
        return this.lookupLabel(this.mergedAccountRecord, this.mergedAccountId, 'Not selected');
    }

    get mergedAccountUrl() {
        return this.recordUrl(this.mergedAccountId);
    }

    async loadAgentReviewState() {
        if (!this.recordId || this.lastLoadedRecordId === this.recordId || !this.record) {
            return;
        }

        this.lastLoadedRecordId = this.recordId;
        this.isLoadingEvidence = true;
        this.reviewEvidenceError = undefined;

        try {
            this.reviewContext = await getPulse360ReviewContext({ governanceCaseId: this.recordId });
            const evidenceLookupKey = this.reviewContext?.sourceRecordId ||
                this.reviewContext?.reviewQueueId ||
                this.reviewContext?.candidatePairId;
            this.reviewEvidence = await getPulse360DataCloudReviewEvidence({
                candidatePairId: evidenceLookupKey,
                leftAccountId: this.reviewContext?.leftAccountId,
                rightAccountId: this.reviewContext?.rightAccountId
            });
            this.reviewEvidenceError = this.reviewEvidence?.errorMessage;
        } catch (error) {
            this.reviewEvidence = undefined;
            this.reviewEvidenceError = error?.body?.message || 'Unable to load direct Data Cloud review evidence.';
        } finally {
            this.isLoadingEvidence = false;
        }
    }

    handleApprove() {
        this.persistDecision('Approved');
    }

    handleReject() {
        this.persistDecision('Rejected');
    }

    handleDefer() {
        this.persistDecision('Deferred');
    }

    handleReasonChange(event) {
        this.decisionReasonCode = event.detail.value;
    }

    handleReasonTextChange(event) {
        this.decisionReasonText = event.detail.value;
    }

    handleFollowupChange(event) {
        this.reviewFollowupRequired = event.target.checked;
    }

    handleSurvivingAccountChange(event) {
        this.survivingAccountId = event.detail.recordId || null;
    }

    handleMergedAccountChange(event) {
        this.mergedAccountId = event.detail.recordId || null;
    }

    fieldValue(fieldRef) {
        return this.record ? getFieldValue(this.record, fieldRef) : null;
    }

    displayValue(fieldRef) {
        if (!this.record) {
            return null;
        }
        return getFieldDisplayValue(this.record, fieldRef) || getFieldValue(this.record, fieldRef);
    }

    lookupLabel(lookupRecord, fallbackId, emptyLabel) {
        const label = lookupRecord?.data ? getFieldValue(lookupRecord.data, ACCOUNT_NAME_FIELD) : null;
        return label || fallbackId || emptyLabel;
    }

    recordUrl(recordId) {
        return recordId ? `/lightning/r/${recordId}/view` : null;
    }

    validateDecision(decisionStatus) {
        if (!this.canCommitDecision) {
            this.showToast(
                'Direct Data Cloud evidence required',
                this.reviewEvidenceError || 'Governance decisions are blocked until the live Data Cloud evidence read succeeds.',
                'error'
            );
            return false;
        }
        if (!this.decisionReasonCode) {
            this.showToast('Decision reason required', 'Select a decision reason code before saving.', 'error');
            return false;
        }
        const requiresMergeAccounts = !this.isCspReview || this.recommendedAction === 'Approve Merge';
        if (requiresMergeAccounts && decisionStatus === 'Approved' && !this.survivingAccountId) {
            this.showToast('Surviving account required', 'Select the surviving Account before approving.', 'error');
            return false;
        }
        if (requiresMergeAccounts && decisionStatus === 'Approved' && !this.mergedAccountId) {
            this.showToast('Merged account required', 'Select the losing Account before approving.', 'error');
            return false;
        }
        if (requiresMergeAccounts && !this.isCasePairAccount(this.survivingAccountId)) {
            this.showToast(
                'Invalid surviving account',
                'The surviving Account must be one of the two Accounts already attached to this governance case.',
                'error'
            );
            return false;
        }
        if (requiresMergeAccounts && !this.isCasePairAccount(this.mergedAccountId)) {
            this.showToast(
                'Invalid merged account',
                'The merged Account must be one of the two Accounts already attached to this governance case.',
                'error'
            );
            return false;
        }
        return true;
    }

    isCasePairAccount(accountId) {
        if (!accountId) {
            return true;
        }
        return [this.leftAccountId, this.rightAccountId].filter(Boolean).includes(accountId);
    }

    async persistDecision(decisionStatus) {
        if (!this.validateDecision(decisionStatus)) {
            return;
        }

        const confirmed = await LightningConfirm.open({
            label: 'Approve governance decision',
            message: `${decisionStatus} will be recorded with direct Data Cloud evidence and queued for downstream processing.`,
            theme: 'warning'
        });

        if (!confirmed) {
            return;
        }

        this.isSaving = true;

        try {
            const result = await recordPulse360GovernanceDecision({
                governanceCaseId: this.recordId,
                decision: decisionStatus,
                reasonCode: this.decisionReasonCode,
                survivingAccountId: this.survivingAccountId || null,
                approvedByUser: USER_ID,
                decisionReasonText: this.decisionReasonText || null,
                reviewFollowupRequired: this.reviewFollowupRequired,
                mergedAccountId: this.mergedAccountId || null
            });
            await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
            this.lastLoadedRecordId = null;
            this.loadAgentReviewState();
            this.showToast('Governance case updated', result.agentSummary, 'success');
        } catch (error) {
            this.showToast('Save failed', error.body?.message || 'Unable to save governance decision.', 'error');
        } finally {
            this.isSaving = false;
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
