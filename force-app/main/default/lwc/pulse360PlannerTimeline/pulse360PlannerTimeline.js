import { api, LightningElement } from 'lwc';

export default class Pulse360PlannerTimeline extends LightningElement {
    @api eyebrow;
    @api sectionTitle;
    @api items = [];
    @api maxItems = 8;

    get visibleItems() {
        const limit = Number(this.maxItems || 8);
        return (this.items || []).slice(0, limit);
    }

    get hasItems() {
        return this.visibleItems.length > 0;
    }

    handleOpenAccount(event) {
        this.dispatchEvent(
            new CustomEvent('openaccount', {
                detail: { accountId: event.currentTarget.dataset.accountId }
            })
        );
    }
}
