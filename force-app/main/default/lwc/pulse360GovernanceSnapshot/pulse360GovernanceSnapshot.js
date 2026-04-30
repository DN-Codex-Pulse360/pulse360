import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldDisplayValue, getFieldValue } from 'lightning/uiRecordApi';
import getPulse360ReviewContext from '@salesforce/apex/Pulse360AgentOrchestratorService.getPulse360ReviewContext';
import getPulse360DataCloudReviewEvidence from '@salesforce/apex/Pulse360AgentOrchestratorService.getPulse360DataCloudReviewEvidence';

import STATUS_FIELD from '@salesforce/schema/Governance_Case__c.Status__c';
import PRIORITY_FIELD from '@salesforce/schema/Governance_Case__c.Priority__c';
import DECISION_OWNER_FIELD from '@salesforce/schema/Governance_Case__c.Decision_Owner__c';
import RECOMMENDED_ACTION_FIELD from '@salesforce/schema/Governance_Case__c.Recommended_Action__c';
import REVIEW_FLAG_FIELD from '@salesforce/schema/Governance_Case__c.Review_Flag__c';
import CONFIDENCE_BAND_FIELD from '@salesforce/schema/Governance_Case__c.Confidence_Band__c';
import HIERARCHY_CONFLICT_FIELD from '@salesforce/schema/Governance_Case__c.Hierarchy_Conflict_Flag__c';
import EVIDENCE_RUN_TIMESTAMP_FIELD from '@salesforce/schema/Governance_Case__c.Evidence_Run_Timestamp__c';
import USER_NAME_FIELD from '@salesforce/schema/User.Name';

const CASE_FIELDS = [
    STATUS_FIELD,
    PRIORITY_FIELD,
    DECISION_OWNER_FIELD,
    RECOMMENDED_ACTION_FIELD,
    REVIEW_FLAG_FIELD,
    CONFIDENCE_BAND_FIELD,
    HIERARCHY_CONFLICT_FIELD,
    EVIDENCE_RUN_TIMESTAMP_FIELD
];

export default class Pulse360GovernanceSnapshot extends LightningElement {
    @api recordId;

    record;
    error;
    hasWireResolved = false;
    reviewContext;
    reviewEvidence;
    reviewEvidenceError;
    isLoadingEvidence = false;
    lastLoadedRecordId;

    @wire(getRecord, { recordId: '$recordId', optionalFields: CASE_FIELDS })
    wiredRecord({ data, error }) {
        this.hasWireResolved = true;
        if (data) {
            this.record = data;
            this.error = undefined;
            this.loadAgentReviewState();
        } else if (error) {
            this.error = error;
            this.record = undefined;
        }
    }

    @wire(getRecord, { recordId: '$decisionOwnerId', fields: [USER_NAME_FIELD] })
    decisionOwnerRecord;

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
        return this.error?.body?.message || 'Unable to load governance snapshot.';
    }

    get status() {
        return this.displayValue(STATUS_FIELD);
    }

    get priority() {
        return this.displayValue(PRIORITY_FIELD);
    }

    get recommendedAction() {
        return this.displayValue(RECOMMENDED_ACTION_FIELD) || 'Not available';
    }

    get recommendationSummary() {
        if (this.isCspReview) {
            return 'Pulse360 recommends stewarding the smart-city proposition route before CRM activation.';
        }
        if (this.recommendedAction === 'Approve Merge') {
            return 'Pulse360 recommends merging these accounts after steward confirmation.';
        }
        if (this.recommendedAction === 'Reject Match') {
            return 'Pulse360 recommends rejecting this duplicate candidate.';
        }
        return 'Pulse360 recommends steward review before any merge action.';
    }

    get decisionOwnerId() {
        return this.fieldValue(DECISION_OWNER_FIELD);
    }

    get decisionOwnerName() {
        const label = this.decisionOwnerRecord?.data ? getFieldValue(this.decisionOwnerRecord.data, USER_NAME_FIELD) : null;
        return label || this.decisionOwnerId || 'Unassigned';
    }

    get decisionOwnerUrl() {
        return this.recordUrl(this.decisionOwnerId);
    }

    get evidenceRunTimestamp() {
        return this.displayValue(EVIDENCE_RUN_TIMESTAMP_FIELD) || 'Not available';
    }

    get caseHealthSummary() {
        return `${this.displayValue(CONFIDENCE_BAND_FIELD) || 'Unknown'} confidence, ${this.reviewFlagLabel.toLowerCase()}, ${this.hierarchyConflictLabel.toLowerCase()}.`;
    }

    get reviewFlagLabel() {
        return this.fieldValue(REVIEW_FLAG_FIELD) ? 'Review Required' : 'No';
    }

    get hierarchyConflictLabel() {
        return this.fieldValue(HIERARCHY_CONFLICT_FIELD) ? 'Conflict Present' : 'No Conflict';
    }

    get agentSubagentName() {
        return this.reviewContext?.subagentName || 'Governance Review Manager';
    }

    get reviewAgentSummary() {
        return this.reviewContext?.reasoning || 'Pulse360 is preparing the governance explanation.';
    }

    get isCspReview() {
        return this.reviewContext?.sourceProduct === 'csp_smart_city_proposition_readiness' ||
            this.reviewEvidence?.sourceProduct === 'csp_smart_city_proposition_readiness';
    }

    get cspTargetSummary() {
        const target = this.reviewEvidence?.targetEntityName || this.reviewContext?.targetEntityName || 'Target proposition';
        const offering = this.reviewEvidence?.offeringFamily || this.reviewContext?.offeringFamily || 'smart city offering';
        const priority = this.reviewEvidence?.reviewPriority || this.reviewContext?.reviewPriority || 'unprioritized';
        return `${target} / ${offering} / ${priority}`;
    }

    get cspMarketSummary() {
        const market = this.reviewEvidence?.market || 'Market not available';
        const countryCode = this.reviewEvidence?.countryCode || 'N/A';
        return `${market} (${countryCode})`;
    }

    get cspCustomersSummary() {
        return this.reviewEvidence?.targetB2bCustomerNames || 'No target B2B customer evidence is available.';
    }

    get cspActionsSummary() {
        return this.reviewEvidence?.recommendedNextActions || 'No recommended CSP actions are available.';
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

    fieldValue(fieldRef) {
        return this.record ? getFieldValue(this.record, fieldRef) : null;
    }

    displayValue(fieldRef) {
        if (!this.record) {
            return null;
        }
        return getFieldDisplayValue(this.record, fieldRef) || getFieldValue(this.record, fieldRef);
    }

    recordUrl(recordId) {
        return recordId ? `/lightning/r/${recordId}/view` : null;
    }
}
