import { LightningElement, api, wire } from 'lwc';

import getSellerWorkspace from '@salesforce/apex/Pulse360SellerWorkspaceService.getSellerWorkspace';

export default class Pulse360TrustPanel extends LightningElement {
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
            this.errorMessage = error?.body?.message || 'Unable to load the Pulse360 trust panel.';
        }
    }

    get hasWorkspace() {
        return Boolean(this.workspace);
    }

    get hasError() {
        return Boolean(this.errorMessage);
    }

    get topSources() {
        return (this.workspace?.primaryAction?.supportingSources || []).slice(0, 4);
    }

    get hasSources() {
        return this.topSources.length > 0;
    }

    get trustSummary() {
        if (this.workspace?.freshnessTone === 'stale') {
            return 'The account story is visible, but the operating team should refresh it before acting too confidently.';
        }
        if (!this.workspace?.externallyValidated) {
            return 'The account story is directionally useful, but external validation is still incomplete.';
        }
        return 'The account story is recent enough to use, with evidence and traceability cues preserved from the upstream run.';
    }

    get freshnessSummary() {
        return `${this.workspace?.freshnessLabel || 'Freshness unknown'} with the last sync at ${this.workspace?.lastSyncedTimestamp || 'unknown'} and the current narrative generated at ${this.workspace?.aiNarrativeGeneratedAt || 'unknown'}.`;
    }

    get traceabilitySummary() {
        return `Prompt ${this.workspace?.promptVersion || 'unknown'}, model ${this.workspace?.modelId || 'unknown'}, run ${this.workspace?.enrichmentRunId || 'unknown'}, and ${this.workspace?.citationCount ?? 0} cited references shape the current account context.`;
    }

    get confidenceSummary() {
        const confidence = this.workspace?.primaryAction?.confidenceLabel || 'No action confidence available';
        return `${confidence}. ${this.workspace?.externallyValidated ? 'External validation is present.' : 'External validation is still pending.'}`;
    }
}
