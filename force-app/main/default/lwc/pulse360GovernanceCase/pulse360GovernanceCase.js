import { LightningElement, api } from "lwc";

export default class Pulse360GovernanceCase extends LightningElement {
  @api leftAccountName = "Pacific Holdings (APAC)";
  @api rightAccountName = "Pacific Holdings Pte Ltd";
  @api leftSourceAccountId = "ACC-LEFT-1001";
  @api rightSourceAccountId = "ACC-RIGHT-2002";
  @api leftValidityScore = 94;
  @api rightValidityScore = 91;
  @api pairConfidence = 96;
  @api runId = "run_20260309_dan63";

  get pairConfidenceLabel() {
    return `Pair Confidence: ${this.pairConfidence}%`;
  }
}
