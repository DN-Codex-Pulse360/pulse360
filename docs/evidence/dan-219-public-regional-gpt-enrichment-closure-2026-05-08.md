# DAN-219 Public Regional GPT Enrichment Closure - 2026-05-08

## Scope

This note records the read-only closure validation for `DAN-219`:

- Deploy and validate the public regional GPT enrichment slice end to end.
- Confirm seeded Singapore and Philippines Accounts render with GPT-derived
  intelligence and provenance.
- Confirm Data Cloud activation and Copy Field Enrichment remain healthy.
- Confirm Health Scan, Next Best Action, and governance-case Salesforce
  surfaces are present and source-backed.

No Salesforce metadata deployment, permission change, folder sharing change,
seeded data load, or Data Cloud configuration mutation was performed as part of
this closure pass.

Related prerequisite issues were already closed in Linear:

| Issue | Closure basis |
| --- | --- |
| `DAN-220` | Public regional GPT DMO extension and source mapping completed. |
| `DAN-221` | Copy Field Enrichment writeback completed and runtime-validated. |
| `DAN-222` | Read-only Salesforce/Data Cloud MCP validation path completed. |

## Live Runtime Evidence

Org alias: `pulse360-agent-target`

Data Cloud Account activation remains healthy:

| Artifact | Result |
| --- | --- |
| Data stream | `DC Export Accounts P360 V2` |
| Data stream id | `1dsdL000000OMyfQAG` |
| Status | `ACTIVE` |
| Import status | `SUCCESS` |
| Last refresh | `2026-04-29T14:23:19.000+0000` |
| Rows processed | 18 |

Copy Field Enrichment remains the active CRM writeback path:

| Artifact | Result |
| --- | --- |
| Data Action | `Pulse360_Account_Intelligence_Copy_Fields_20xo47` |
| Data Action id | `3o9dL0000000IL7QAM` |
| Status | `ACTIVE` |
| Managed by | `DATA_CLOUD_USER` |
| Last action status time | `2026-04-29T22:38:49.000+0000` |
| Latest job id | `1A5dL0000001BFxSAM` |
| Latest job status | `Completed` |
| Processed / updated / failed / skipped | `18 / 18 / 0 / 0` |
| Job window | `2026-04-29T22:39:46.000+0000` to `2026-04-29T22:40:48.000+0000` |

Activation-key and payload-exception validators confirmed:

| Check | Result |
| --- | ---: |
| Salesforce target Account rows | 18 |
| Source object rows | 18 |
| Source distinct activation IDs | 18 |
| Source duplicate activation IDs | 0 |
| DMO rows | 18 |
| DMO distinct activation IDs | 18 |
| DMO duplicate activation IDs | 0 |
| Rows missing required supported fields | 0 |
| Payload dry-run source rows | 18 |
| Payload JSON error count | 0 |
| Payload missing provenance count | 0 |

## Regional Account Samples

Targeted live SOQL checks found the Singapore and Philippines regional Accounts
with GPT/provenance fields populated where the public evidence packet supports
them.

| Account | Account id | Jurisdiction | Prompt | Model | Citation count | Notes |
| --- | --- | --- | --- | --- | ---: | --- |
| `Singtel Group` | `001dL000024xl9FQAQ` | `SG` | `pulse360-public-regional-v1` | `gpt-5.4` | 2 | Narrative, recommended actions, and source refs populated. |
| `NCS Pte. Ltd.` | `001dL000024xlArQAI` | `SG` | `pulse360-public-regional-v1` | `gpt-5.4` | 0 | Scalar enrichment populated; narrative/action payloads remain sparse. |
| `Ayala Corporation` | `001dL000024wgYRQAY` | `PH` | `pulse360-public-regional-v1` | `gpt-5.4` | 2 | Narrative, recommended actions, and source refs populated. |
| `Ayala Corp.` | `001dL000024weudQAA` | `PH` | `pulse360-public-regional-v1` | `gpt-5.4` | 2 | Narrative, recommended actions, and source refs populated. |
| `JG Summit Holdings, Inc.` | `001dL000024xj2cQAA` | `PH` | `pulse360-public-regional-v1` | `gpt-5.4` | 2 | Narrative, recommended actions, and source refs populated. |

All sampled records show `LastModifiedBy.Name = Platform Integration User` and
`LastModifiedDate = 2026-04-29T22:39:52.000+0000`, proving runtime/platform
writeback rather than manual user repair.

## Salesforce Surface Validation

Source-backed Salesforce runtime assets are present in the org:

| Surface | Validation result |
| --- | --- |
| Apex classes | `Pulse360HealthScanService`, `Pulse360HealthScanServiceTest`, `GovernanceCaseDecisionStamping`, and `GovernanceCaseDecisionStampingTest` are active. |
| LWCs | `pulse360HealthScan`, `pulse360NextBestAction`, `pulse360NarrativeCard`, `pulse360GroupRevenueReveal`, and `governanceCaseReview` are present. |
| FlexiPages | `Account_Record_Page` and `Governance_Case_Record_Page` are present. |
| Account fields | GPT, health, provenance, payload, and long-text exception fields exist on `Account`. |
| Account DMO fields | Corresponding intelligence fields exist on `ssot__Account__dlm`. |

Targeted Apex tests passed:

```bash
sf apex run test \
  --target-org pulse360-agent-target \
  --tests Pulse360HealthScanServiceTest,GovernanceCaseDecisionStampingTest \
  --result-format human \
  --wait 10
```

Result:

| Metric | Value |
| --- | ---: |
| Tests ran | 5 |
| Pass rate | 100% |
| Outcome | Passed |

## Validation Commands

The following repo validators passed during the closure pass:

```bash
./scripts/validate-data-cloud-activation-key-alignment.sh
./scripts/validate-account-payload-exception-activation.sh
./scripts/validate-salesforce-account-activation-fields.sh
./scripts/validate-salesforce-firmographic-ux-pack.sh
```

The Codex operator health-check script named in `AGENTS.md` is not present or
executable in this branch. Equivalent direct checks were run through Salesforce
CLI and the Salesforce/Data Cloud MCP.

One aggregate MCP report helper still assumes the original repository path
`/Users/danielnortje/Documents/Pulse360` and failed in this worktree. The same
live state was validated through individual MCP calls and source validators.

## Acceptance Decision

`DAN-219` is satisfied for prototype acceptance.

Completion basis:

- Public regional GPT fields are deployed on Salesforce `Account` and Data
  Cloud surfaces.
- Singapore and Philippines regional sample Accounts are present with
  source-backed GPT/provenance output where evidence supports it.
- Data Cloud Account activation is healthy across all `18` Accounts.
- Copy Field Enrichment completed `18/18` updates with zero failures.
- Health Scan, Next Best Action, Narrative, Group Revenue, and governance-case
  components are present in the org.
- Targeted Apex tests for the Health Scan and governance decision behavior
  pass.

Accepted caveats:

- Native Copy Field remains limited to the supported scalar/native-compatible
  mapping set. Payload, long-text, and revenue exception fields remain governed
  by the documented exception path.
- Sparse related records such as `NCS Pte. Ltd.` may have scalar enrichment
  without narrative/action payloads when source evidence is limited.
- Sovereign identifier coverage remains `0`, expected until official registry,
  tax-authority, or filing evidence satisfies the verification gate.

Recommended Linear outcome: move `DAN-219` to Done.
