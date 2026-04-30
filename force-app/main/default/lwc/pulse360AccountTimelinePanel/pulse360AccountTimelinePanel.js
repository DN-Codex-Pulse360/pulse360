import { LightningElement, api, wire } from 'lwc';

import getSellerWorkspace from '@salesforce/apex/Pulse360SellerWorkspaceService.getSellerWorkspace';

export default class Pulse360AccountTimelinePanel extends LightningElement {
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
            this.errorMessage = error?.body?.message || 'Unable to load the Pulse360 account timeline.';
        }
    }

    get hasWorkspace() {
        return Boolean(this.workspace);
    }

    get hasError() {
        return Boolean(this.errorMessage);
    }

    get timelineItems() {
        const items = [
            {
                key: 'sync',
                label: 'Data Cloud sync',
                badge: this.workspace?.freshnessLabel || 'Freshness unknown',
                badgeClass: this.badgeClass(this.workspace?.freshnessTone),
                markerClass: this.markerClass(this.workspace?.freshnessTone),
                copy: `Latest sync timestamp: ${this.workspace?.lastSyncedTimestamp || 'unknown'}.`
            },
            {
                key: 'narrative',
                label: 'AI narrative generated',
                badge: `Prompt ${this.workspace?.promptVersion || 'unknown'}`,
                badgeClass: 'badge badge_neutral',
                markerClass: 'timeline-marker timeline-marker_neutral',
                copy: `Narrative generated at ${this.workspace?.aiNarrativeGeneratedAt || 'unknown'} with model ${this.workspace?.modelId || 'unknown'}.`
            },
            {
                key: 'engagement',
                label: 'Last engagement signal',
                badge: this.workspace?.engagementLabel || 'Engagement limited',
                badgeClass: 'badge badge_accent',
                markerClass: 'timeline-marker timeline-marker_accent',
                copy: `Last engagement timestamp: ${this.workspace?.lastEngagementTimestamp || 'unknown'}.`
            }
        ];

        if (this.workspace?.primaryAction?.supportingSources?.length) {
            const latestSource = this.workspace.primaryAction.supportingSources[0];
            items.push({
                key: 'source',
                label: 'Latest supporting evidence',
                badge: latestSource.documentDate || 'Date unknown',
                badgeClass: 'badge badge_soft',
                markerClass: 'timeline-marker timeline-marker_soft',
                copy: `${latestSource.sourceName || 'Source'}: ${latestSource.excerpt || 'No excerpt available.'}`
            });
        }

        return items;
    }

    badgeClass(tone) {
        if (tone === 'stale') {
            return 'badge badge_negative';
        }
        if (tone === 'warning') {
            return 'badge badge_warning';
        }
        return 'badge badge_positive';
    }

    markerClass(tone) {
        if (tone === 'stale') {
            return 'timeline-marker timeline-marker_negative';
        }
        if (tone === 'warning') {
            return 'timeline-marker timeline-marker_warning';
        }
        return 'timeline-marker timeline-marker_positive';
    }
}
