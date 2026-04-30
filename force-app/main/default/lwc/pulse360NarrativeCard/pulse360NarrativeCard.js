import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldDisplayValue, getFieldValue } from 'lightning/uiRecordApi';

import ACCOUNT_NAME_FIELD from '@salesforce/schema/Account.Name';
import AI_NARRATIVE_FIELD from '@salesforce/schema/Account.AI_Narrative__c';
import AI_NARRATIVE_GENERATED_FIELD from '@salesforce/schema/Account.AI_Narrative_Generated__c';
import AI_MODEL_ID_FIELD from '@salesforce/schema/Account.AI_Model_Id__c';
import AI_PROMPT_VERSION_FIELD from '@salesforce/schema/Account.AI_Prompt_Version__c';
import AI_SOURCE_REFS_FIELD from '@salesforce/schema/Account.AI_Source_Refs__c';
import AI_CITATION_COUNT_FIELD from '@salesforce/schema/Account.AI_Citation_Count__c';
import ENRICHMENT_RUN_ID_FIELD from '@salesforce/schema/Account.Enrichment_Run_Id__c';

const FIELDS = [
    ACCOUNT_NAME_FIELD,
    AI_NARRATIVE_FIELD,
    AI_NARRATIVE_GENERATED_FIELD,
    AI_MODEL_ID_FIELD,
    AI_PROMPT_VERSION_FIELD,
    AI_SOURCE_REFS_FIELD,
    AI_CITATION_COUNT_FIELD,
    ENRICHMENT_RUN_ID_FIELD
];

export default class Pulse360NarrativeCard extends LightningElement {
    @api recordId;

    record;
    error;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ data, error }) {
        this.record = data;
        this.error = error;
    }

    get accountName() {
        return this.fieldValue(ACCOUNT_NAME_FIELD) || 'this account';
    }

    get narrative() {
        return this.fieldValue(AI_NARRATIVE_FIELD);
    }

    get hasNarrative() {
        return Boolean(this.narrative);
    }

    get generatedAt() {
        return this.displayValue(AI_NARRATIVE_GENERATED_FIELD) || 'Not generated';
    }

    get modelId() {
        return this.fieldValue(AI_MODEL_ID_FIELD) || 'Not set';
    }

    get promptVersion() {
        return this.fieldValue(AI_PROMPT_VERSION_FIELD) || 'Not set';
    }

    get citationCount() {
        return this.fieldValue(AI_CITATION_COUNT_FIELD) || 0;
    }

    get enrichmentRunId() {
        return this.fieldValue(ENRICHMENT_RUN_ID_FIELD) || 'Not set';
    }

    get sourceRefs() {
        try {
            const rawValue = this.fieldValue(AI_SOURCE_REFS_FIELD);
            const parsed = rawValue ? JSON.parse(rawValue) : [];
            return Array.isArray(parsed) ? parsed : [];
        } catch (error) {
            return [];
        }
    }

    get hasSourceRefs() {
        return this.sourceRefs.length > 0;
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
}
