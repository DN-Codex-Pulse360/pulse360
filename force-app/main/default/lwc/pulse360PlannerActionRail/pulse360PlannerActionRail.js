import { api, LightningElement } from 'lwc';

export default class Pulse360PlannerActionRail extends LightningElement {
    @api eyebrow;
    @api sectionTitle;
    @api queue = [];

    get hasQueue() {
        return (this.queue || []).length > 0;
    }

    handleOpenAccount(event) {
        this.dispatchEvent(
            new CustomEvent('openaccount', {
                detail: { accountId: event.currentTarget.dataset.accountId }
            })
        );
    }
}
