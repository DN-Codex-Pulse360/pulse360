import { NavigationMixin } from 'lightning/navigation';
import { LightningElement, api } from 'lwc';

export default class Pulse360AccountWorkspaceHeader extends NavigationMixin(LightningElement) {
    @api showPortfolioLink;
    @api showGovernanceLink;

    get hasPortfolioLink() {
        return this.normalizeBoolean(this.showPortfolioLink, true);
    }

    get hasGovernanceLink() {
        return this.normalizeBoolean(this.showGovernanceLink, true);
    }

    handleOpenPortfolioDashboard() {
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Pulse360_Planner'
            }
        });
    }

    handleOpenGovernanceCases() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Governance_Case__c',
                actionName: 'home'
            }
        });
    }

    normalizeBoolean(value, fallback = false) {
        if (value === undefined || value === null || value === '') {
            return fallback;
        }
        if (typeof value === 'string') {
            return value.toLowerCase() === 'true';
        }
        return Boolean(value);
    }
}
