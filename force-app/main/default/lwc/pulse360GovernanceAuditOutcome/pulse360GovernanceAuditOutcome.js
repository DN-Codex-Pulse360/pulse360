import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldDisplayValue, getFieldValue } from 'lightning/uiRecordApi';

import DECISION_STATUS_FIELD from '@salesforce/schema/Governance_Case__c.Decision_Status__c';
import DECIDED_BY_FIELD from '@salesforce/schema/Governance_Case__c.Decided_By__c';
import DECIDED_AT_FIELD from '@salesforce/schema/Governance_Case__c.Decided_At__c';
import DOWNSTREAM_UPDATE_STATUS_FIELD from '@salesforce/schema/Governance_Case__c.Downstream_Update_Status__c';
import MERGE_EXECUTION_STATUS_FIELD from '@salesforce/schema/Governance_Case__c.Merge_Execution_Status__c';
import MERGE_EXECUTED_BY_FIELD from '@salesforce/schema/Governance_Case__c.Merge_Executed_By__c';
import MERGE_EXECUTED_AT_FIELD from '@salesforce/schema/Governance_Case__c.Merge_Executed_At__c';
import USER_NAME_FIELD from '@salesforce/schema/User.Name';

const CASE_FIELDS = [
    DECISION_STATUS_FIELD,
    DECIDED_BY_FIELD,
    DECIDED_AT_FIELD,
    DOWNSTREAM_UPDATE_STATUS_FIELD,
    MERGE_EXECUTION_STATUS_FIELD,
    MERGE_EXECUTED_BY_FIELD,
    MERGE_EXECUTED_AT_FIELD
];

export default class Pulse360GovernanceAuditOutcome extends LightningElement {
    @api recordId;

    record;
    error;
    hasWireResolved = false;

    @wire(getRecord, { recordId: '$recordId', optionalFields: CASE_FIELDS })
    wiredRecord({ data, error }) {
        this.hasWireResolved = true;
        if (data) {
            this.record = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.record = undefined;
        }
    }

    @wire(getRecord, { recordId: '$decidedById', fields: [USER_NAME_FIELD] })
    decidedByRecord;

    @wire(getRecord, { recordId: '$mergeExecutedById', fields: [USER_NAME_FIELD] })
    mergeExecutedByRecord;

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
        return this.error?.body?.message || 'Unable to load audit outcome.';
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
        const label = lookupRecord?.data ? getFieldValue(lookupRecord.data, USER_NAME_FIELD) : null;
        return label || fallbackId || emptyLabel;
    }

    recordUrl(recordId) {
        return recordId ? `/lightning/r/${recordId}/view` : null;
    }
}
