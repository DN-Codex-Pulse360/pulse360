import { LightningElement, api } from "lwc";

export default class Pulse360Account360 extends LightningElement {
  @api accountName = "Pacific Capital Singapore";
  @api unifiedProfileId = "ucp_sf_acc_1001";
  @api sourceAccountId = "sf_acc_1001";
  @api groupRevenueRollup = "1,250,000";
  @api crossSellPropensity = 87;
  @api coverageGapFlag = false;
  @api healthStatus = "healthy";
  @api lastSyncedTimestamp = "2026-03-09T04:22:59Z";
  @api degradedModeMessage = "";

  get isDegraded() {
    return this.healthStatus === "degraded";
  }

  get coverageGapText() {
    return this.coverageGapFlag ? "Yes" : "No";
  }

  get healthBadge() {
    return `Data Health: ${this.healthStatus}`;
  }
}
