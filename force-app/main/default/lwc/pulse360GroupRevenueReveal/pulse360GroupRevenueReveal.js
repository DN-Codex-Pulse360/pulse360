import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import BILLING_COUNTRY_FIELD from '@salesforce/schema/Account.BillingCountry';
import GROUP_REVENUE_ROLLUP_FIELD from '@salesforce/schema/Account.Group_Revenue_Rollup__c';
import GROUP_REVENUE_VISIBLE_FIELD from '@salesforce/schema/Account.Group_Revenue_Visible__c';
import GROUP_KNOWN_SUBSIDIARY_COUNT_FIELD from '@salesforce/schema/Account.Group_Known_Subsidiary_Count__c';
import CRM_COVERED_SUSBIDIARY_COUNT_FIELD from '@salesforce/schema/Account.CRM_Covered_Subsidiary_Count__c';
import EXTERNAL_SUBSIDIARIES_FOUND_FIELD from '@salesforce/schema/Account.External_Subsidiaries_Found__c';

const FIELDS = [
    BILLING_COUNTRY_FIELD,
    GROUP_REVENUE_ROLLUP_FIELD,
    GROUP_REVENUE_VISIBLE_FIELD,
    GROUP_KNOWN_SUBSIDIARY_COUNT_FIELD,
    CRM_COVERED_SUSBIDIARY_COUNT_FIELD,
    EXTERNAL_SUBSIDIARIES_FOUND_FIELD
];

export default class Pulse360GroupRevenueReveal extends LightningElement {
    @api recordId;

    record;
    error;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ data, error }) {
        this.record = data;
        this.error = error;
    }

    get totalRevenue() {
        return this.fieldValue(GROUP_REVENUE_ROLLUP_FIELD) || 0;
    }

    get visibleRevenue() {
        return this.fieldValue(GROUP_REVENUE_VISIBLE_FIELD) || 0;
    }

    get hiddenRevenue() {
        return Math.max(this.totalRevenue - this.visibleRevenue, 0);
    }

    get knownSubsidiaryCount() {
        return this.fieldValue(GROUP_KNOWN_SUBSIDIARY_COUNT_FIELD) || 0;
    }

    get crmCoveredSubsidiaryCount() {
        return this.fieldValue(CRM_COVERED_SUSBIDIARY_COUNT_FIELD) || 0;
    }

    get externalSubsidiariesFound() {
        return this.fieldValue(EXTERNAL_SUBSIDIARIES_FOUND_FIELD) || 0;
    }

    get visiblePercent() {
        if (!this.totalRevenue) {
            return 0;
        }
        return Math.round((this.visibleRevenue / this.totalRevenue) * 100);
    }

    get coveragePercent() {
        if (!this.knownSubsidiaryCount) {
            return 0;
        }
        return Math.round((this.crmCoveredSubsidiaryCount / this.knownSubsidiaryCount) * 100);
    }

    get visibleBarStyle() {
        return `width:${this.visiblePercent}%;`;
    }

    get coverageBarStyle() {
        return `width:${this.coveragePercent}%;`;
    }

    get currencyCode() {
        const billingCountry = this.fieldValue(BILLING_COUNTRY_FIELD) || '';
        const normalized = billingCountry.toLowerCase();
        if (normalized.includes('singapore')) {
            return 'SGD';
        }
        if (normalized.includes('philippines')) {
            return 'PHP';
        }
        return 'USD';
    }

    fieldValue(fieldRef) {
        return this.record ? getFieldValue(this.record, fieldRef) : null;
    }
}
