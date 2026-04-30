import { LightningElement, api, wire } from 'lwc';
import getSellerWorkspace from '@salesforce/apex/Pulse360SellerWorkspaceService.getSellerWorkspace';

export default class Pulse360AccountSummaryPanel extends LightningElement {
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
            this.errorMessage = error?.body?.message || 'Unable to load the Pulse360 account summary.';
        }
    }

    get hasWorkspace() {
        return Boolean(this.workspace);
    }

    get hasError() {
        return Boolean(this.errorMessage);
    }

    get freshnessClass() {
        const tone = this.workspace?.freshnessTone || 'fresh';
        return `badge badge_${tone}`;
    }

    get coverageSummary() {
        return `${this.workspace?.crmCoveredSubsidiaryCount || 0} of ${this.workspace?.groupKnownSubsidiaryCount || 0} entities represented in CRM`;
    }

    get validationLabel() {
        return this.workspace?.externallyValidated ? 'Externally validated' : 'Needs validation';
    }

    get topThingsToKnow() {
        return [
            {
                key: 'group',
                label: 'Group revenue story',
                value: this.hiddenRevenueLabel,
                copy: `${this.workspace?.groupKnownSubsidiaryCount || 0} entities are known in the commercial group, with ${this.workspace?.uncoveredEntityCount || 0} still outside visible CRM coverage.`
            },
            {
                key: 'whitespace',
                label: 'Whitespace readiness',
                value: `${this.workspace?.crossSellPropensity ?? 'N/A'}`,
                copy: this.workspace?.primaryAction?.outreachObjective || 'Pulse360 has not yet generated a whitespace objective.'
            },
            {
                key: 'risk',
                label: 'Risk and health',
                value: `${this.workspace?.competitorRiskSignal ?? 'N/A'} / ${this.workspace?.healthScore ?? 'N/A'}`,
                copy: this.workspace?.engagementLabel || 'Engagement context is limited.'
            }
        ];
    }

    get metricCards() {
        return [
            {
                key: 'revenue',
                label: 'Group revenue story',
                value: this.hiddenRevenueLabel,
                copy: `${this.workspace?.groupKnownSubsidiaryCount || 0} entities are known, with ${this.workspace?.uncoveredEntityCount || 0} still outside CRM coverage.`
            },
            {
                key: 'coverage',
                label: 'Coverage health',
                value: `${this.coveragePercent}%`,
                copy: `${this.workspace?.crmCoveredSubsidiaryCount || 0} of ${this.workspace?.groupKnownSubsidiaryCount || 0} entities are seller-visible today.`
            },
            {
                key: 'whitespace',
                label: 'Whitespace readiness',
                value: `${this.workspace?.crossSellPropensity ?? 'N/A'}`,
                copy: this.workspace?.primaryAction?.outreachObjective || 'No whitespace objective has been generated yet.'
            },
            {
                key: 'risk',
                label: 'Risk and health',
                value: `${this.workspace?.competitorRiskSignal ?? 'N/A'} / ${this.workspace?.healthScore ?? 'N/A'}`,
                copy: this.workspace?.engagementLabel || 'Engagement context is limited.'
            }
        ];
    }

    get signalMeters() {
        return [
            {
                key: 'coverage',
                label: 'Coverage confidence',
                valueLabel: `${this.coveragePercent}%`,
                widthStyle: this.widthStyle(this.coveragePercent),
                meterClass: 'meter-fill meter-fill_positive',
                copy: this.coverageGapCopy
            },
            {
                key: 'whitespace',
                label: 'Whitespace propensity',
                valueLabel: `${this.workspace?.crossSellPropensity ?? 0}`,
                widthStyle: this.widthStyle(this.normalizePercent(this.workspace?.crossSellPropensity)),
                meterClass: 'meter-fill meter-fill_accent',
                copy: 'Higher values indicate stronger whitespace follow-up potential.'
            },
            {
                key: 'risk',
                label: 'Competitive risk',
                valueLabel: `${this.workspace?.competitorRiskSignal ?? 0}`,
                widthStyle: this.widthStyle(this.normalizePercent(this.workspace?.competitorRiskSignal)),
                meterClass: 'meter-fill meter-fill_warning',
                copy: 'This should be read together with coverage and freshness, not on its own.'
            },
            {
                key: 'engagement',
                label: 'Engagement intensity',
                valueLabel: `${this.workspace?.engagementIntensityScore ?? 0}`,
                widthStyle: this.widthStyle(this.normalizePercent(this.workspace?.engagementIntensityScore)),
                meterClass: 'meter-fill meter-fill_neutral',
                copy: this.workspace?.engagementLabel || 'Recent engagement is limited.'
            }
        ];
    }

    get coveragePercent() {
        const total = Number(this.workspace?.groupKnownSubsidiaryCount || 0);
        if (!total) {
            return 0;
        }
        const covered = Number(this.workspace?.crmCoveredSubsidiaryCount || 0);
        return Math.round((covered / total) * 100);
    }

    get coverageGapCopy() {
        if (this.workspace?.coverageGapFlag) {
            return 'Coverage is incomplete, so the team should verify the operating entity before committing to the next move.';
        }
        return 'Coverage is relatively stable for the current group view.';
    }

    get hiddenRevenueLabel() {
        return this.compactCurrency(this.workspace?.hiddenRevenue, this.workspace?.currencyCode);
    }

    normalizePercent(value) {
        const numeric = Number(value || 0);
        if (numeric <= 0) {
            return 0;
        }
        if (numeric >= 100) {
            return 100;
        }
        return Math.round(numeric);
    }

    widthStyle(value) {
        return `width:${this.normalizePercent(value)}%`;
    }

    compactCurrency(value, currencyCode) {
        const amount = Number(value || 0);
        if (amount >= 1000000000) {
            return `${(amount / 1000000000).toFixed(1)}B ${currencyCode || 'USD'}`;
        }
        if (amount >= 1000000) {
            return `${(amount / 1000000).toFixed(1)}M ${currencyCode || 'USD'}`;
        }
        return `${Math.round(amount)} ${currencyCode || 'USD'}`;
    }
}
