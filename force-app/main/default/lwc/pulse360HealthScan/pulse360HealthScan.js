import { LightningElement, api } from "lwc";

export default class Pulse360HealthScan extends LightningElement {
  @api healthScore = 86;
  @api crossSellEstimate = 83;
  @api maxDuplicateConfidence = 92;
  @api status = "degraded";
  @api retryDisposition = "manual_retry_available";
  @api runId = "run_20260309_064746";
  @api aiImpactSummary =
    "Duplicate evidence supports merge review while preserving non-blocking health scan behavior.";
}
