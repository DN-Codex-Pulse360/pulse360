import { api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { LightningElement } from 'lwc';

export default class Pulse360AccountWorkspace extends NavigationMixin(LightningElement) {
    @api recordId;
    @api showRenewalModule;
    @api showHealthScan;
    @api showPortfolioLink;
    @api showGovernanceLink;

    get hasRenewalModule() {
        return this.normalizeBoolean(this.showRenewalModule, true);
    }

    get hasHealthScan() {
        return this.normalizeBoolean(this.showHealthScan, true);
    }

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

    normalizeBoolean(value, fallbackValue) {
        if (value === undefined || value === null || value === '') {
            return fallbackValue;
        }
        if (typeof value === 'boolean') {
            return value;
        }
        return String(value).toLowerCase() === 'true';
    }
}
