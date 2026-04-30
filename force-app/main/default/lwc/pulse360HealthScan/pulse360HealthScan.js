import { LightningElement, api } from 'lwc';
import runHealthScan from '@salesforce/apex/Pulse360HealthScanService.runHealthScan';

export default class Pulse360HealthScan extends LightningElement {
    @api recordId;

    scanResult;
    errorMessage;
    isLoading = false;

    get hasResult() {
        return Boolean(this.scanResult);
    }

    get hasError() {
        return Boolean(this.errorMessage);
    }

    async handleRunScan() {
        if (!this.recordId) {
            return;
        }

        this.isLoading = true;
        this.errorMessage = undefined;

        try {
            this.scanResult = await runHealthScan({ accountId: this.recordId });
        } catch (error) {
            this.scanResult = undefined;
            this.errorMessage = error?.body?.message || 'Unable to run Pulse360 health scan.';
        } finally {
            this.isLoading = false;
        }
    }

    get actions() {
        return this.scanResult?.actions || [];
    }

    get sourceRefs() {
        return this.scanResult?.sourceRefs || [];
    }

    get currencyCode() {
        return this.scanResult?.currencyCode || 'USD';
    }

    get hiddenRevenue() {
        return this.scanResult?.hiddenRevenue || 0;
    }

    get visibleCoverageLabel() {
        if (!this.scanResult) {
            return '';
        }

        return `${this.scanResult.crmCoveredSubsidiaryCount || 0} of ${this.scanResult.groupKnownSubsidiaryCount || 0} known entities represented in CRM`;
    }
}
