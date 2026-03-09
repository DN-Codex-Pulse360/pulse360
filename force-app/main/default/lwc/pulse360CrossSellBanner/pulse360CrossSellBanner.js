import { LightningElement, api } from "lwc";

export default class Pulse360CrossSellBanner extends LightningElement {
  @api crossSellPropensity = 83;
  @api coverageGapFlag = false;
  @api openOpportunityCount = 2;

  get coverageGapText() {
    return this.coverageGapFlag ? "Yes" : "No";
  }

  handleQuickCreate() {
    // Placeholder action hook for DAN-66 deployment proof.
    this.dispatchEvent(
      new CustomEvent("pulse360quickcreate", {
        detail: { source: "pulse360CrossSellBanner" }
      })
    );
  }
}
