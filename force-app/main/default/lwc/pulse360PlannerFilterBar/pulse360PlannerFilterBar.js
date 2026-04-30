import { api, LightningElement } from 'lwc';

export default class Pulse360PlannerFilterBar extends LightningElement {
    @api eyebrow;
    @api sectionTitle;
    @api sectionCopy;
    @api selectedFilter;
    @api filterOptions = [];
    @api currentFilterLabel;
    @api filteredGroupCount = 0;

    handleFilterChange(event) {
        this.dispatchEvent(
            new CustomEvent('filterchange', {
                detail: { value: event.detail.value }
            })
        );
    }
}
