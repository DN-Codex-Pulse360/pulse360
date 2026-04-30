import { api, LightningElement } from 'lwc';

export default class Pulse360PlannerHeader extends LightningElement {
    @api title;
    @api summary;
    @api insight;
    @api highlightedAction;
    @api nextMoveLabel;
    @api trustCopy;
}
