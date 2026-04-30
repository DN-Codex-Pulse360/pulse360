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

import STATUS_FIELD from '@salesforce/schema/Governance_Case__c.Status__c';
import PRIORITY_FIELD from '@salesforce/schema/Governance_Case__c.Priority__c';
import DECISION_OWNER_FIELD from '@salesforce/schema/Governance_Case__c.Decision_Owner__c';
import LEFT_ACCOUNT_FIELD from '@salesforce/schema/Governance_Case__c.Left_Account__c';
import RIGHT_ACCOUNT_FIELD from '@salesforce/schema/Governance_Case__c.Right_Account__c';
import MERGED_ACCOUNT_FIELD from '@salesforce/schema/Governance_Case__c.Merged_Account__c';
import DUPLICATE_CONFIDENCE_FIELD from '@salesforce/schema/Governance_Case__c.Duplicate_Confidence__c';
import CONFIDENCE_BAND_FIELD from '@salesforce/schema/Governance_Case__c.Confidence_Band__c';
import RECOMMENDED_ACTION_FIELD from '@salesforce/schema/Governance_Case__c.Recommended_Action__c';
import REVIEW_FLAG_FIELD from '@salesforce/schema/Governance_Case__c.Review_Flag__c';
import TOP_MATCH_FEATURES_FIELD from '@salesforce/schema/Governance_Case__c.Top_Match_Features__c';
import FEATURE_EXPLANATIONS_FIELD from '@salesforce/schema/Governance_Case__c.Feature_Explanations__c';
import SOURCE_SNAPSHOT_ID_FIELD from '@salesforce/schema/Governance_Case__c.Source_Snapshot_Id__c';
import MODEL_VERSION_FIELD from '@salesforce/schema/Governance_Case__c.Model_Version__c';
import ATTRIBUTE_VALIDITY_PAYLOAD_FIELD from '@salesforce/schema/Governance_Case__c.Attribute_Validity_Payload__c';
import HIERARCHY_CONFLICT_FIELD from '@salesforce/schema/Governance_Case__c.Hierarchy_Conflict_Flag__c';
import HIERARCHY_IMPACT_FIELD from '@salesforce/schema/Governance_Case__c.Hierarchy_Impact_Summary__c';
import DECISION_REASON_CODE_FIELD from '@salesforce/schema/Governance_Case__c.Decision_Reason_Code__c';
import DECISION_REASON_TEXT_FIELD from '@salesforce/schema/Governance_Case__c.Decision_Reason_Text__c';
import REVIEW_FOLLOWUP_REQUIRED_FIELD from '@salesforce/schema/Governance_Case__c.Review_Followup_Required__c';
import SURVIVING_ACCOUNT_FIELD from '@salesforce/schema/Governance_Case__c.Surviving_Account__c';
import DECISION_STATUS_FIELD from '@salesforce/schema/Governance_Case__c.Decision_Status__c';
import DECIDED_BY_FIELD from '@salesforce/schema/Governance_Case__c.Decided_By__c';
import DECIDED_AT_FIELD from '@salesforce/schema/Governance_Case__c.Decided_At__c';
import DOWNSTREAM_UPDATE_STATUS_FIELD from '@salesforce/schema/Governance_Case__c.Downstream_Update_Status__c';
import EVIDENCE_RUN_TIMESTAMP_FIELD from '@salesforce/schema/Governance_Case__c.Evidence_Run_Timestamp__c';
import MERGE_EXECUTION_STATUS_FIELD from '@salesforce/schema/Governance_Case__c.Merge_Execution_Status__c';
import MERGE_EXECUTED_BY_FIELD from '@salesforce/schema/Governance_Case__c.Merge_Executed_By__c';
import MERGE_EXECUTED_AT_FIELD from '@salesforce/schema/Governance_Case__c.Merge_Executed_At__c';
import ACCOUNT_NAME_FIELD from '@salesforce/schema/Account.Name';
import ACCOUNT_EXTERNAL_LEGAL_NAME_FIELD from '@salesforce/schema/Account.External_Legal_Name__c';
import ACCOUNT_EXTERNAL_REGISTRATION_FIELD from '@salesforce/schema/Account.External_Registration_Number__c';
import ACCOUNT_EXTERNALLY_VALIDATED_FIELD from '@salesforce/schema/Account.Externally_Validated__c';
import ACCOUNT_EXTERNAL_VALIDITY_SCORE_FIELD from '@salesforce/schema/Account.Validity_Score_External__c';
import ACCOUNT_AI_CITATION_COUNT_FIELD from '@salesforce/schema/Account.AI_Citation_Count__c';
import ACCOUNT_AI_MODEL_ID_FIELD from '@salesforce/schema/Account.AI_Model_Id__c';
import USER_NAME_FIELD from '@salesforce/schema/User.Name';

const CASE_FIELDS = [
    STATUS_FIELD,
    PRIORITY_FIELD,
    DECISION_OWNER_FIELD,
    LEFT_ACCOUNT_FIELD,
    RIGHT_ACCOUNT_FIELD,
    MERGED_ACCOUNT_FIELD,
    DUPLICATE_CONFIDENCE_FIELD,
    CONFIDENCE_BAND_FIELD,
    RECOMMENDED_ACTION_FIELD,
    REVIEW_FLAG_FIELD,
    TOP_MATCH_FEATURES_FIELD,
    FEATURE_EXPLANATIONS_FIELD,
    SOURCE_SNAPSHOT_ID_FIELD,
    MODEL_VERSION_FIELD,
    ATTRIBUTE_VALIDITY_PAYLOAD_FIELD,
    HIERARCHY_CONFLICT_FIELD,
    HIERARCHY_IMPACT_FIELD,
    DECISION_REASON_CODE_FIELD,
    DECISION_REASON_TEXT_FIELD,
    REVIEW_FOLLOWUP_REQUIRED_FIELD,
    SURVIVING_ACCOUNT_FIELD,
    DECISION_STATUS_FIELD,
    DECIDED_BY_FIELD,
    DECIDED_AT_FIELD,
    DOWNSTREAM_UPDATE_STATUS_FIELD,
    EVIDENCE_RUN_TIMESTAMP_FIELD,
    MERGE_EXECUTION_STATUS_FIELD,
    MERGE_EXECUTED_BY_FIELD,
    MERGE_EXECUTED_AT_FIELD
];

const ACCOUNT_FIELDS = [
    ACCOUNT_NAME_FIELD,
    ACCOUNT_EXTERNAL_LEGAL_NAME_FIELD,
    ACCOUNT_EXTERNAL_REGISTRATION_FIELD,
    ACCOUNT_EXTERNALLY_VALIDATED_FIELD,
    ACCOUNT_EXTERNAL_VALIDITY_SCORE_FIELD,
    ACCOUNT_AI_CITATION_COUNT_FIELD,
    ACCOUNT_AI_MODEL_ID_FIELD
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
    { label: 'Needs Policy Decision', value: 'NEEDS_POLICY_DECISION' }
];

export default class GovernanceCaseReview extends LightningElement {
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
    lastLoadedAgentRecordId;

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

    @wire(getRecord, { recordId: '$leftAccountId', fields: ACCOUNT_FIELDS })
    leftAccountRecord;

    @wire(getRecord, { recordId: '$rightAccountId', fields: ACCOUNT_FIELDS })
    rightAccountRecord;

    @wire(getRecord, { recordId: '$survivingAccountId', fields: ACCOUNT_FIELDS })
    survivingAccountRecord;

    @wire(getRecord, { recordId: '$mergedAccountId', fields: ACCOUNT_FIELDS })
    mergedAccountRecord;

    @wire(getRecord, { recordId: '$decisionOwnerId', fields: [USER_NAME_FIELD] })
    decisionOwnerRecord;

    @wire(getRecord, { recordId: '$decidedById', fields: [USER_NAME_FIELD] })
    decidedByRecord;

    @wire(getRecord, { recordId: '$mergeExecutedById', fields: [USER_NAME_FIELD] })
    mergeExecutedByRecord;

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
        return this.error?.body?.message || 'Unable to load governance case.';
    }

    get status() {
        return this.displayValue(STATUS_FIELD);
    }

    get priority() {
        return this.displayValue(PRIORITY_FIELD);
    }

    get decisionOwnerId() {
        return this.fieldValue(DECISION_OWNER_FIELD);
    }

    get decisionOwnerName() {
        return this.lookupLabel(this.decisionOwnerRecord, this.decisionOwnerId, 'Unassigned');
    }

    get decisionOwnerUrl() {
        return this.recordUrl(this.decisionOwnerId);
    }

    get evidenceRunTimestamp() {
        return this.displayValue(EVIDENCE_RUN_TIMESTAMP_FIELD) || 'Not available';
    }

    get leftAccountId() {
        return this.fieldValue(LEFT_ACCOUNT_FIELD);
    }

    get leftAccountName() {
        return this.lookupLabel(this.leftAccountRecord, this.leftAccountId, 'Not available');
    }

    get leftAccountUrl() {
        return this.recordUrl(this.leftAccountId);
    }

    get rightAccountId() {
        return this.fieldValue(RIGHT_ACCOUNT_FIELD);
    }

    get rightAccountName() {
        return this.lookupLabel(this.rightAccountRecord, this.rightAccountId, 'Not available');
    }

    get rightAccountUrl() {
        return this.recordUrl(this.rightAccountId);
    }

    get duplicateConfidence() {
        return this.displayValue(DUPLICATE_CONFIDENCE_FIELD) || 'Not available';
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

    get confidenceBand() {
        return this.displayValue(CONFIDENCE_BAND_FIELD);
    }

    get recommendedAction() {
        return this.displayValue(RECOMMENDED_ACTION_FIELD) || 'Not available';
    }

    get reviewFlagLabel() {
        return this.fieldValue(REVIEW_FLAG_FIELD) ? 'Review Required' : 'No';
    }

    get recommendationSummary() {
        if (this.recommendedAction === 'Approve Merge') {
            return 'Pulse360 recommends merging these accounts after steward confirmation.';
        }
        if (this.recommendedAction === 'Reject Match') {
            return 'Pulse360 recommends rejecting this duplicate match candidate.';
        }
        return 'Pulse360 recommends steward review before any merge action.';
    }

    get mergeSelectionHelp() {
        if (!this.canCommitDecision) {
            return 'Direct Data Cloud evidence must be available before the steward can commit a decision.';
        }
        if (this.recommendedAction === 'Approve Merge') {
            return 'Confirm the surviving and merged accounts, then approve the case.';
        }
        return 'Use the decision controls to confirm, reject, or defer after reviewing the evidence.';
    }

    get caseHealthSummary() {
        return `${this.confidenceBand || 'Unknown'} confidence, ${this.reviewFlagLabel.toLowerCase()}, ${this.hierarchyConflictLabel.toLowerCase()}.`;
    }

    get agentSubagentName() {
        return this.reviewContext?.subagentName || 'Governance Review Manager';
    }

    get reviewAgentSummary() {
        return this.reviewContext?.reasoning || 'Pulse360 is preparing the governance explanation.';
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

    get directEvidenceSummary() {
        return this.reviewEvidence?.attributeValidity || 'No direct Data Cloud validity summary is available.';
    }

    get directHierarchyImpact() {
        return this.reviewEvidence?.hierarchyImpact || 'No direct Data Cloud hierarchy summary is available.';
    }

    get directEvidenceTimestamp() {
        return this.reviewEvidence?.evidenceTimestamp || 'Not available';
    }

    get canCommitDecision() {
        return this.reviewEvidence?.available === true;
    }

    get decisionDisabled() {
        return this.isSaving || !this.canCommitDecision;
    }

    get topMatchFeatures() {
        return this.fieldValue(TOP_MATCH_FEATURES_FIELD) || 'No feature payload available.';
    }

    get featureExplanations() {
        return this.fieldValue(FEATURE_EXPLANATIONS_FIELD) || 'No explanation payload available.';
    }

    get sourceSnapshotId() {
        return this.fieldValue(SOURCE_SNAPSHOT_ID_FIELD) || 'Not available';
    }

    get modelVersion() {
        return this.fieldValue(MODEL_VERSION_FIELD) || 'Not available';
    }

    get attributeValidityPayload() {
        return this.fieldValue(ATTRIBUTE_VALIDITY_PAYLOAD_FIELD) || 'No attribute trust payload available.';
    }

    get hierarchyConflictLabel() {
        return this.fieldValue(HIERARCHY_CONFLICT_FIELD) ? 'Conflict Present' : 'No Conflict';
    }

    get hierarchyImpactSummary() {
        return this.fieldValue(HIERARCHY_IMPACT_FIELD) || 'No hierarchy impact summary available.';
    }

    get hasExternalEvidence() {
        return this.leftExternalEvidence.hasEvidence || this.rightExternalEvidence.hasEvidence;
    }

    get leftExternalEvidence() {
        return this.externalEvidence(this.leftAccountRecord, this.leftAccountName);
    }

    get rightExternalEvidence() {
        return this.externalEvidence(this.rightAccountRecord, this.rightAccountName);
    }

    get registryMatchStatus() {
        const leftEvidence = this.leftExternalEvidence;
        const rightEvidence = this.rightExternalEvidence;
        if (!leftEvidence.hasEvidence || !rightEvidence.hasEvidence) {
            return 'Not enough public evidence to confirm a shared entity yet.';
        }
        if (leftEvidence.registration && rightEvidence.registration && leftEvidence.registration === rightEvidence.registration) {
            return 'Shared registration or filing reference detected.';
        }
        if (leftEvidence.legalName && rightEvidence.legalName && leftEvidence.legalName === rightEvidence.legalName) {
            return 'Matching external legal names detected.';
        }
        return 'External evidence differs across the two records.';
    }

    get decisionStatus() {
        return this.displayValue(DECISION_STATUS_FIELD) || 'Not decided';
    }

    get decidedById() {
        return this.fieldValue(DECIDED_BY_FIELD);
    }

    get decidedByName() {
        return this.lookupLabel(this.decidedByRecord, this.decidedById, 'Not decided');
    }

    get decidedByUrl() {
        return this.recordUrl(this.decidedById);
    }

    get decidedAt() {
        return this.displayValue(DECIDED_AT_FIELD) || 'Not decided';
    }

    get downstreamUpdateStatus() {
        return this.displayValue(DOWNSTREAM_UPDATE_STATUS_FIELD) || 'Not Started';
    }

    get mergeExecutionStatus() {
        return this.displayValue(MERGE_EXECUTION_STATUS_FIELD) || 'Not Started';
    }

    get mergeExecutedById() {
        return this.fieldValue(MERGE_EXECUTED_BY_FIELD);
    }

    get mergeExecutedByName() {
        return this.lookupLabel(this.mergeExecutedByRecord, this.mergeExecutedById, 'Not executed');
    }

    get mergeExecutedByUrl() {
        return this.recordUrl(this.mergeExecutedById);
    }

    get mergeExecutedAt() {
        return this.displayValue(MERGE_EXECUTED_AT_FIELD) || 'Not executed';
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

    async loadAgentReviewState() {
        if (!this.recordId || this.lastLoadedAgentRecordId === this.recordId || !this.record) {
            return;
        }

        this.lastLoadedAgentRecordId = this.recordId;
        this.isLoadingEvidence = true;
        this.reviewEvidenceError = undefined;

        try {
            this.reviewContext = await getPulse360ReviewContext({ governanceCaseId: this.recordId });
            this.reviewEvidence = await getPulse360DataCloudReviewEvidence({
                candidatePairId: this.reviewContext?.candidatePairId,
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
        const label = lookupRecord?.data ? getFieldValue(lookupRecord.data, ACCOUNT_NAME_FIELD) || getFieldValue(lookupRecord.data, USER_NAME_FIELD) : null;
        return label || fallbackId || emptyLabel;
    }

    accountFieldValue(accountRecord, fieldRef) {
        return accountRecord?.data ? getFieldValue(accountRecord.data, fieldRef) : null;
    }

    externalEvidence(accountRecord, fallbackName) {
        const legalName = this.accountFieldValue(accountRecord, ACCOUNT_EXTERNAL_LEGAL_NAME_FIELD);
        const registration = this.accountFieldValue(accountRecord, ACCOUNT_EXTERNAL_REGISTRATION_FIELD);
        const externallyValidated = this.accountFieldValue(accountRecord, ACCOUNT_EXTERNALLY_VALIDATED_FIELD);
        const validityScore = this.accountFieldValue(accountRecord, ACCOUNT_EXTERNAL_VALIDITY_SCORE_FIELD);
        const citationCount = this.accountFieldValue(accountRecord, ACCOUNT_AI_CITATION_COUNT_FIELD);
        const modelId = this.accountFieldValue(accountRecord, ACCOUNT_AI_MODEL_ID_FIELD);

        return {
            accountName: fallbackName,
            legalName: legalName || 'Not available',
            registration: registration || 'Not available',
            externallyValidated: externallyValidated ? 'Validated' : 'Not validated',
            validityScore: validityScore || 'Not available',
            citationCount: citationCount || 0,
            modelId: modelId || 'Not available',
            hasEvidence: Boolean(legalName || registration || validityScore || citationCount || externallyValidated)
        };
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
        if (decisionStatus === 'Approved' && !this.survivingAccountId) {
            this.showToast('Surviving account required', 'Select the surviving Account before approving.', 'error');
            return false;
        }
        if (decisionStatus === 'Approved' && !this.mergedAccountId) {
            this.showToast('Merged account required', 'Select the losing Account before approving.', 'error');
            return false;
        }
        if (!this.isCasePairAccount(this.survivingAccountId)) {
            this.showToast(
                'Invalid surviving account',
                'The surviving Account must be one of the two Accounts already attached to this governance case.',
                'error'
            );
            return false;
        }
        if (!this.isCasePairAccount(this.mergedAccountId)) {
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
            this.lastLoadedAgentRecordId = null;
            this.loadAgentReviewState();
            this.showToast('Governance case updated', result.agentSummary, 'success');
            this.dispatchDecisionEvent(decisionStatus.toLowerCase());
        } catch (error) {
            this.showToast('Save failed', error.body?.message || 'Unable to save governance decision.', 'error');
        } finally {
            this.isSaving = false;
        }
    }

    dispatchDecisionEvent(action) {
        this.dispatchEvent(
            new CustomEvent('decisionaction', {
                detail: { action, recordId: this.recordId }
            })
        );
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
