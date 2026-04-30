import { NavigationMixin } from 'lightning/navigation';
import { LightningElement, api, wire } from 'lwc';

import getSellerWorkspace from '@salesforce/apex/Pulse360SellerWorkspaceService.getSellerWorkspace';

export default class Pulse360EntityFocusPanel extends NavigationMixin(LightningElement) {
    @api recordId;

    workspace;
    entityRows = [];
    errorMessage;

    @wire(getSellerWorkspace, { accountId: '$recordId' })
    wiredWorkspace({ data, error }) {
        if (data) {
            this.workspace = data;
            this.errorMessage = undefined;
            void this.decorateEntities(data.hierarchyEntities || []);
            return;
        }

        this.workspace = undefined;
        this.entityRows = [];
        if (this.recordId) {
            this.errorMessage = error?.body?.message || 'Unable to load the Pulse360 entity focus.';
        }
    }

    get hasWorkspace() {
        return Boolean(this.workspace);
    }

    get hasError() {
        return Boolean(this.errorMessage);
    }

    get hierarchySummary() {
        return this.workspace?.hierarchyNote || 'Hierarchy confidence is still limited for this account.';
    }

    get hierarchyReadinessLabel() {
        return this.workspace?.hierarchyReady ? 'Hierarchy confidence ready' : 'Hierarchy confidence building';
    }

    get readinessClass() {
        return `badge ${this.workspace?.hierarchyReady ? 'badge_ready' : 'badge_warning'}`;
    }

    get coverageSummary() {
        return `${this.workspace?.crmCoveredSubsidiaryCount || 0} of ${this.workspace?.groupKnownSubsidiaryCount || 0} entities covered in CRM`;
    }

    async decorateEntities(entities) {
        this.entityRows = await Promise.all(
            entities.map(async (entity) => ({
                ...entity,
                crmRecordUrl: entity.crmRecordId
                    ? await this[NavigationMixin.GenerateUrl]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: entity.crmRecordId,
                            objectApiName: 'Account',
                            actionName: 'view'
                        }
                    })
                    : null,
                coverageClass: this.coverageClass(entity.coverageStatus)
            }))
        );
    }

    coverageClass(status) {
        if (status === 'covered') {
            return 'badge badge_ready';
        }
        if (status === 'current') {
            return 'badge badge_current';
        }
        return 'badge badge_warning';
    }
}
