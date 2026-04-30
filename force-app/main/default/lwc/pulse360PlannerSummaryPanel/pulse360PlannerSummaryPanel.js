import { api, LightningElement } from 'lwc';

export default class Pulse360PlannerSummaryPanel extends LightningElement {
    @api eyebrow;
    @api heading;
    @api summaryCopy;
    @api metrics = [];
    @api groups = [];
    @api metricLimit = 4;

    get visibleMetrics() {
        const limit = Number(this.metricLimit || 4);
        return (this.metrics || []).slice(0, limit).map((metric) => ({
            ...metric,
            className: `summary-chip summary-chip_${metric.tone || 'neutral'}`
        }));
    }

    get portfolioMix() {
        const groups = this.groups || [];
        const total = groups.length || 1;

        return [
            this.mixItem('Coverage gaps', groups.filter((group) => group.coverageGapFlag || group.uncoveredEntityCount > 0).length, total, 'warning'),
            this.mixItem('Whitespace ready', groups.filter((group) => group.crossSellPropensityValue >= 65 || group.hiddenRevenueValue > 0).length, total, 'accent'),
            this.mixItem('Needs validation', groups.filter((group) => !group.externallyValidated).length, total, 'warning'),
            this.mixItem('Risk watch', groups.filter((group) => group.competitorRiskSignalValue >= 65 || group.healthScoreValue <= 45).length, total, 'negative')
        ];
    }

    get priorityDistribution() {
        const groups = this.groups || [];
        const total = groups.length || 1;

        return [
            this.mixItem('Executive now', groups.filter((group) => group.priorityBand === 'Executive now').length, total, 'negative'),
            this.mixItem('Plan this cycle', groups.filter((group) => group.priorityBand === 'Plan this cycle').length, total, 'accent'),
            this.mixItem('Monitor closely', groups.filter((group) => group.priorityBand === 'Monitor closely').length, total, 'soft'),
            this.mixItem('Watchlist', groups.filter((group) => group.priorityBand === 'Watchlist').length, total, 'neutral')
        ];
    }

    mixItem(label, value, total, tone) {
        const width = total === 0 ? 0 : Math.max(8, Math.round((value / total) * 100));
        return {
            label,
            value,
            tone,
            style: `width:${value === 0 ? 0 : width}%;`
        };
    }
}
