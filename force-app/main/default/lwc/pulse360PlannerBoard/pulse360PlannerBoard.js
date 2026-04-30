import { api, LightningElement } from 'lwc';

export default class Pulse360PlannerBoard extends LightningElement {
    @api eyebrow;
    @api sectionTitle;
    @api sectionCopy;
    @api groups = [];
    @api boardDensity = 'compact';
    @api showExecutivePrompts;

    get hasGroups() {
        return (this.groups || []).length > 0;
    }

    get groupCount() {
        return (this.groups || []).length;
    }

    get boardClass() {
        return `group-list group-list_${this.boardDensity === 'expanded' ? 'expanded' : 'compact'}`;
    }

    handleOpenAccount(event) {
        this.dispatchEvent(
            new CustomEvent('openaccount', {
                detail: { accountId: event.currentTarget.dataset.accountId }
            })
        );
    }

    handleOpenSellerWorkspace(event) {
        this.dispatchEvent(
            new CustomEvent('opensellerworkspace', {
                detail: { accountId: event.currentTarget.dataset.accountId }
            })
        );
    }
}
