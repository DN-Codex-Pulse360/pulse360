import { api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { LightningElement, wire } from 'lwc';

import getPlannerWorkspace from '@salesforce/apex/Pulse360PlannerWorkspaceService.getPlannerWorkspace';

const FILTER_ALL = 'all';
const FILTER_COVERAGE = 'coverage';
const FILTER_WHITESPACE = 'whitespace';
const FILTER_RISK = 'risk';
const FILTER_VALIDATION = 'validation';

export default class Pulse360PlannerWorkspace extends NavigationMixin(LightningElement) {
    _defaultFilter = FILTER_ALL;

    @api showSummaryPanel;
    @api showTimelinePanel;
    @api showActionRail;
    @api showExecutivePrompts;
    @api summaryMetricLimit = 4;
    @api maxVisibleGroups = 12;
    @api maxTimelineItems = 8;
    @api boardDensity = 'compact';

    selectedFilter = FILTER_ALL;
    workspace;
    errorMessage;

    @api
    get defaultFilter() {
        return this._defaultFilter;
    }

    set defaultFilter(value) {
        this._defaultFilter = this.normalizeFilter(value);
        this.selectedFilter = this._defaultFilter;
    }

    @wire(getPlannerWorkspace, { requestedLimit: '$requestedLimitValue' })
    wiredWorkspace({ data, error }) {
        if (data) {
            this.workspace = this.normalizeWorkspace(data);
            this.errorMessage = undefined;
            return;
        }

        this.workspace = undefined;
        this.errorMessage = error?.body?.message || 'Unable to load Pulse360 planner workspace.';
    }

    get requestedLimitValue() {
        return this.normalizeInteger(this.maxVisibleGroups, 12, 4, 20);
    }

    get summaryMetricLimitValue() {
        return this.normalizeInteger(this.summaryMetricLimit, 4, 2, 5);
    }

    get maxTimelineItemsValue() {
        return this.normalizeInteger(this.maxTimelineItems, 8, 3, 12);
    }

    get boardDensityValue() {
        return this.normalizeDensity(this.boardDensity);
    }

    get hasWorkspace() {
        return Boolean(this.workspace);
    }

    get hasError() {
        return Boolean(this.errorMessage);
    }

    get hasSummaryPanel() {
        return this.normalizeBoolean(this.showSummaryPanel, true);
    }

    get hasTimelinePanel() {
        return this.normalizeBoolean(this.showTimelinePanel, true);
    }

    get hasActionRailSection() {
        return this.normalizeBoolean(this.showActionRail, true);
    }

    get showExecutivePromptsValue() {
        return this.normalizeBoolean(this.showExecutivePrompts, true);
    }

    get filterOptions() {
        return [
            { label: 'All groups', value: FILTER_ALL },
            { label: 'Coverage gaps', value: FILTER_COVERAGE },
            { label: 'Whitespace ready', value: FILTER_WHITESPACE },
            { label: 'Risk watch', value: FILTER_RISK },
            { label: 'Needs validation', value: FILTER_VALIDATION }
        ];
    }

    get filteredGroups() {
        const groups = this.workspace?.groups || [];
        return groups.filter((group) => this.matchesFilter(group));
    }

    get displayGroups() {
        return this.filteredGroups.slice(0, this.requestedLimitValue);
    }

    get hasFilteredGroups() {
        return this.displayGroups.length > 0;
    }

    get filteredGroupCount() {
        return this.filteredGroups.length;
    }

    get currentFilterLabel() {
        const selectedOption = this.filterOptions.find((option) => option.value === this.selectedFilter);
        return selectedOption?.label || 'All groups';
    }

    get summaryMetrics() {
        const groups = this.displayGroups;
        const coverageGapCount = groups.filter((group) => group.coverageGapFlag || group.uncoveredEntityCount > 0).length;
        const whitespaceReadyCount = groups.filter((group) => group.crossSellPropensityValue >= 65 || group.hiddenRevenueValue > 0).length;
        const validationGapCount = groups.filter((group) => !group.externallyValidated).length;
        const executiveFocusCount = groups.filter((group) => group.priorityScore >= 85).length;

        return [
            this.summaryMetric('portfolio', 'Groups under review', String.valueOf(groups.length), 'Currently visible in this planner lens.', 'neutral'),
            this.summaryMetric('coverage', 'Coverage gaps', String.valueOf(coverageGapCount), 'Groups that still need owner or subsidiary coverage decisions.', coverageGapCount > 0 ? 'warning' : 'positive'),
            this.summaryMetric('whitespace', 'Whitespace-ready', String.valueOf(whitespaceReadyCount), 'Groups where hidden value or propensity justify attention now.', whitespaceReadyCount > 0 ? 'accent' : 'neutral'),
            this.summaryMetric('validation', 'Needs validation', String.valueOf(validationGapCount), 'Groups whose current view still needs stronger external confirmation.', validationGapCount > 0 ? 'warning' : 'positive'),
            this.summaryMetric('executive', 'Executive focus', String.valueOf(executiveFocusCount), 'Groups that deserve leadership review in the next planning cycle.', executiveFocusCount > 0 ? 'negative' : 'neutral')
        ].slice(0, this.summaryMetricLimitValue);
    }

    get filteredActionQueue() {
        return this.displayGroups.slice(0, 5).map((group) => ({
            accountId: group.accountId,
            accountName: group.accountName,
            actionLabel: group.nextPlanningAction,
            reason: group.priorityReason,
            priorityLabel: group.priorityBand,
            priorityClass: `badge badge_${this.badgeTone(this.groupTone(group))}`,
            className: `queue-card queue-card_${this.groupTone(group)}`
        }));
    }

    get visibleTimelineItems() {
        const groupIds = new Set(this.displayGroups.map((group) => group.accountId));
        return (this.workspace?.timeline || [])
            .filter((item) => groupIds.size === 0 || groupIds.has(item.accountId))
            .slice(0, this.maxTimelineItemsValue);
    }

    handleFilterChange(event) {
        this.selectedFilter = this.normalizeFilter(event.detail.value);
    }

    handleChildOpenAccount(event) {
        const accountId = event.detail?.accountId;
        this.navigateToAccount(accountId);
    }

    handleChildOpenSellerWorkspace(event) {
        const accountId = event.detail?.accountId;
        if (!accountId) {
            return;
        }

        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Pulse360_Seller_V2'
            },
            state: { c__previewRecordId: accountId }
        });
    }

    navigateToAccount(accountId) {
        if (!accountId) {
            return;
        }

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: accountId,
                objectApiName: 'Account',
                actionName: 'view'
            }
        });
    }

    matchesFilter(group) {
        switch (this.selectedFilter) {
            case FILTER_COVERAGE:
                return group.coverageGapFlag || group.uncoveredEntityCount > 0;
            case FILTER_WHITESPACE:
                return group.crossSellPropensityValue >= 65 || group.hiddenRevenueValue > 0;
            case FILTER_RISK:
                return group.competitorRiskSignalValue >= 65 || group.healthScoreValue <= 45;
            case FILTER_VALIDATION:
                return !group.externallyValidated;
            default:
                return true;
        }
    }

    normalizeWorkspace(workspace) {
        return {
            ...workspace,
            groups: (workspace.groups || []).map((group, index) => ({
                ...group,
                rankLabel: `#${index + 1}`,
                subheading: [group.primaryBrandName, group.topUncoveredEntity].filter(Boolean).join(' • ') || 'Commercial group',
                className: `group-card group-card_${this.groupTone(group)}`,
                priorityClass: `badge badge_${this.badgeTone(this.groupTone(group))}`,
                trustBadgeClass: `badge badge_${group.freshnessTone === 'stale' ? 'warning' : 'soft'}`,
                hiddenRevenueLabel: this.compactCurrency(group.hiddenRevenue, group.currencyCode),
                crossSellPropensityValue: Number(group.crossSellPropensity || 0),
                competitorRiskSignalValue: Number(group.competitorRiskSignal || 0),
                healthScoreValue: Number(group.healthScore || 0),
                hiddenRevenueValue: Number(group.hiddenRevenue || 0),
                scoreSummary: this.scoreSummary(group),
                trustSummary: this.trustSummary(group)
            })),
            timeline: (workspace.timeline || []).map((item) => ({
                ...item,
                badgeClass: `badge badge_${this.badgeTone(item.tone)}`,
                cardClass: `timeline-item timeline-item_${item.tone || 'neutral'}`,
                relativeLabel: this.relativeTime(item.eventTimestamp),
                eventDateLabel: this.formatDate(item.eventTimestamp)
            }))
        };
    }

    groupTone(group) {
        if ((group.priorityScore || 0) >= 90 || (group.competitorRiskSignal || 0) >= 70 || (group.healthScore || 100) <= 45) {
            return 'negative';
        }
        if (group.coverageGapFlag || !group.externallyValidated) {
            return 'warning';
        }
        if ((group.crossSellPropensity || 0) >= 75) {
            return 'accent';
        }
        return 'neutral';
    }

    badgeTone(tone) {
        if (tone === 'negative') {
            return 'negative';
        }
        if (tone === 'warning') {
            return 'warning';
        }
        if (tone === 'accent') {
            return 'accent';
        }
        if (tone === 'positive') {
            return 'positive';
        }
        return 'soft';
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

    scoreSummary(group) {
        const indicators = [
            `Priority ${group.priorityScore ?? 'N/A'}`,
            `Coverage ${group.coveragePercent ?? 0}%`
        ];

        if (this.selectedFilter === FILTER_RISK) {
            indicators.push(`Risk ${group.competitorRiskSignal ?? 'N/A'}`);
        } else if (this.selectedFilter === FILTER_VALIDATION) {
            indicators.push(group.externallyValidated ? 'Validated' : 'Needs validation');
        } else {
            indicators.push(`Hidden ${this.compactCurrency(group.hiddenRevenue, group.currencyCode)}`);
        }

        return indicators.join(' • ');
    }

    trustSummary(group) {
        const trustCues = [];

        if (!group.externallyValidated) {
            trustCues.push('Validation gap');
        }

        if (group.freshnessTone === 'stale') {
            trustCues.push(group.freshnessLabel || 'Stale sync');
        }

        return trustCues.length ? trustCues.join(' • ') : 'Signals look current enough for planning review';
    }

    summaryMetric(key, label, value, helperText, tone) {
        return {
            key,
            label,
            value,
            helperText,
            tone
        };
    }

    normalizeBoolean(value, fallbackValue) {
        if (value === undefined || value === null || value === '') {
            return fallbackValue;
        }
        if (typeof value === 'boolean') {
            return value;
        }
        return String(value).toLowerCase() === 'true';
    }

    normalizeInteger(value, fallbackValue, minValue, maxValue) {
        const parsedValue = parseInt(value, 10);
        if (Number.isNaN(parsedValue)) {
            return fallbackValue;
        }
        return Math.min(Math.max(parsedValue, minValue), maxValue);
    }

    normalizeFilter(value) {
        const normalized = String(value || FILTER_ALL).toLowerCase();
        const supportedFilters = [FILTER_ALL, FILTER_COVERAGE, FILTER_WHITESPACE, FILTER_RISK, FILTER_VALIDATION];
        return supportedFilters.includes(normalized) ? normalized : FILTER_ALL;
    }

    normalizeDensity(value) {
        return String(value || 'compact').toLowerCase() === 'expanded' ? 'expanded' : 'compact';
    }

    relativeTime(value) {
        if (!value) {
            return 'Time not available';
        }

        const eventDate = new Date(value);
        const now = new Date();
        const deltaHours = Math.max(0, Math.round((now.getTime() - eventDate.getTime()) / (1000 * 60 * 60)));

        if (deltaHours < 24) {
            return `${deltaHours || 1}h ago`;
        }

        const deltaDays = Math.round(deltaHours / 24);
        return `${deltaDays}d ago`;
    }

    formatDate(value) {
        if (!value) {
            return 'Date not available';
        }

        return new Intl.DateTimeFormat('en-US', {
            month: 'short',
            day: 'numeric',
            hour: 'numeric',
            minute: '2-digit'
        }).format(new Date(value));
    }
}
