import { LightningElement, api } from 'lwc';
import { normalizeActionContext } from 'c/pulse360SellerWorkspaceActionSupport';

export default class Pulse360SellerWorkspaceGroup extends LightningElement {
    @api accountId;
    @api accountName;
    @api promptVersion;
    @api primaryAction;
    @api hierarchyNote;
    @api coveragePercent = 0;
    @api crmCoveredSubsidiaryCount = 0;
    @api groupKnownSubsidiaryCount = 0;
    @api hierarchyEntities = [];
    @api selectedEntityName;

    get hasHierarchyEntities() {
        return (this.hierarchyEntities || []).length > 0;
    }

    get coverageBarStyle() {
        return `width:${this.coveragePercent || 0}%;`;
    }

    get normalizedHierarchyEntities() {
        const selected = (this.selectedEntityName || '').toLowerCase();
        return (this.hierarchyEntities || []).map((entity) => ({
            ...entity,
            className: `entity-card${entity.entityName?.toLowerCase() === selected ? ' entity-card_selected' : ''}`
        }));
    }

    handleEntityAction(event) {
        const entityName = event.currentTarget.dataset.entityName;
        const entity = (this.hierarchyEntities || []).find((candidate) => candidate.entityName === entityName);
        if (!entity) {
            return;
        }

        const detail = normalizeActionContext({
            action: this.primaryAction?.rawAction || this.primaryAction || {},
            accountId: this.accountId,
            accountName: this.accountName,
            promptVersion: this.promptVersion,
            sourceContext: `group_${event.currentTarget.dataset.actionType}`,
            actionType: event.currentTarget.dataset.actionType,
            targetEntity: entity.entityName,
            hierarchyEntity: entity,
            agentGoal: event.currentTarget.dataset.actionType === 'launch_agent' ? 'analyze_whitespace' : undefined,
            mode: event.currentTarget.dataset.mode || 'execute'
        });

        this.dispatchEvent(
            new CustomEvent('workspaceaction', {
                detail
            })
        );
    }
}
