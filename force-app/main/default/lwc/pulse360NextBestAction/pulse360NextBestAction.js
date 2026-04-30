import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import ACCOUNT_NAME_FIELD from '@salesforce/schema/Account.Name';
import AI_RECOMMENDED_ACTIONS_FIELD from '@salesforce/schema/Account.AI_Recommended_Actions__c';

const FIELDS = [ACCOUNT_NAME_FIELD, AI_RECOMMENDED_ACTIONS_FIELD];

export default class Pulse360NextBestAction extends NavigationMixin(LightningElement) {
    @api recordId;

    record;
    error;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ data, error }) {
        this.record = data;
        this.error = error;
    }

    get accountName() {
        return this.record ? getFieldValue(this.record, ACCOUNT_NAME_FIELD) : 'Account';
    }

    get actions() {
        try {
            const rawValue = this.record ? getFieldValue(this.record, AI_RECOMMENDED_ACTIONS_FIELD) : null;
            const parsed = rawValue ? JSON.parse(rawValue) : [];
            if (!Array.isArray(parsed)) {
                return [];
            }

            return parsed.map((action, index) => ({
                ...action,
                index,
                buttonLabel: this.buttonLabel(action.action_type),
                sourceSummary: (action.source_ids || []).join(', ')
            }));
        } catch (error) {
            return [];
        }
    }

    get hasActions() {
        return this.actions.length > 0;
    }

    buttonLabel(actionType) {
        switch (actionType) {
            case 'create_opportunity':
                return 'Create Opportunity';
            case 'create_task':
            case 'investigate_subsidiary':
                return 'Create Task';
            case 'escalate_governance':
                return 'Open Governance';
            default:
                return 'Open Follow-up';
        }
    }

    handleActionClick(event) {
        const index = Number(event.currentTarget.dataset.index);
        const action = this.actions[index];
        if (!action) {
            return;
        }

        if (action.action_type === 'create_opportunity') {
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: 'Opportunity',
                    actionName: 'new'
                },
                state: {
                    defaultFieldValues: encodeDefaultFieldValues({
                        Name: `${this.accountName} - ${action.target}`,
                        AccountId: this.recordId
                    })
                }
            });
            return;
        }

        if (action.action_type === 'escalate_governance') {
            if (action.target_record_id) {
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: action.target_record_id,
                        objectApiName: 'Governance_Case__c',
                        actionName: 'view'
                    }
                });
            } else {
                this[NavigationMixin.Navigate]({
                    type: 'standard__objectPage',
                    attributes: {
                        objectApiName: 'Governance_Case__c',
                        actionName: 'list'
                    }
                });
            }
            return;
        }

        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Task',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: encodeDefaultFieldValues({
                    Subject: `Pulse360 follow-up: ${action.target}`,
                    WhatId: this.recordId,
                    Description: action.reasoning
                })
            }
        });
    }
}
