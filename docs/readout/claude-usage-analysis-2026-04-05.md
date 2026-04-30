# Claude Usage Analysis for Pulse360

This summary is based on the local Codex session store in `~/.codex/sessions`, filtered to the project workspace at `/Users/danielnortje/Documents/Pulse360`, plus keyword search over the same history for `salesforce`, `databricks`, `data cloud`, `agentforce`, `governance`, `epf`, `linear`, `notion`, `mcp`, `dashboard`, `runbook`, `contract`, `package`, `ci`, `github`, and `claude`.

I could not call `recent_chats` / `conversation_search` directly because those MCPs were not exposed in this thread, so I replicated that analysis from the local conversation store.

## Stats Overview

- Project conversations found: `16`
- Timeline covered: `2026-03-08` to `2026-04-05` (`28` days)
- Raw execution intensity:
  - `2606` shell command runs
  - `492` long-running command polls
  - `200` Linear comments posted
  - `177` Linear issue updates
  - `14` milestone writes
  - `20` Notion page updates
  - `7` Notion pages created
  - `14` Notion comments created
  - `3` Linear docs created
  - `8` Linear docs updated
- Tangible workspace outputs present by the end of this history:
  - Salesforce metadata: `32` Account fields, `32` `Governance_Case__c` fields, `6` validation rules, `5` LWC bundles, `4` Apex classes, `1` trigger, `2` flexipages, `2` permission sets
  - Databricks assets: `9` silver SQL files, `4` gold SQL files, `1` dashboard SQL
  - Contracts/config: `6` JSON contracts, `14` validation scripts
  - Packaging/tooling: generated Salesforce package workspace flow, Databricks bundle workspace flow, CI validation hooks, GitHub PR/update flow

## Category Breakdown

Primary-bucket assignment only. Many sessions crossed categories.

### Architecture design

- Conversation count: `2`
- Examples:
  - `2026-03-08` canonical data model alignment
  - `2026-03-10` to `2026-03-12` Pulse360 Account Intelligence product-definition reframing
- What was produced:
  - Data Cloud-aligned canonical model decisions for Account + related entities + products/brands/engagement
  - Product-definition reframing from milestone completion to innovative Account Intelligence
  - Contract-alignment direction that later showed up in [`/Users/danielnortje/Documents/Pulse360/contracts`](/Users/danielnortje/Documents/Pulse360/contracts) and downstream field/mapping work
- Claude surface used:
  - Chat for strategy
  - Code for repo and contract inspection
- MCP integrations involved:
  - Linear
  - Notion
- Compound memory / cross-session pattern:
  - Canonical-model decisions from March 8 informed later Data Cloud mapping, activation, and DMO field work

### Prototype building

- Conversation count: `3`
- Examples:
  - `2026-03-09` dashboard completion and DAN-71/72/73 work
  - `2026-03-10` Milestone C remediation and DAN-114 build work
- What was produced:
  - Databricks dashboard/data-source verification and dataset mapping
  - Salesforce Account activation field remediation
  - DAN-114 build work that later became the Account Intelligence runtime slice
  - Concrete repo artifacts across SQL, fields, validation scripts, and runtime checks
- Claude surface used:
  - Code
- MCP integrations involved:
  - Linear
- Compound memory / cross-session pattern:
  - Each build session resumed from prior branch/milestone state and pushed code/config forward rather than re-planning from scratch

### Methodology/framework development

- Conversation count: `2`
- Examples:
  - `2026-03-08` EPF-based prototype build plan
  - `2026-03-10` backlog and milestone logic review
- What was produced:
  - EPF-driven build plan
  - Initial milestone, label, and issue structure in Linear
  - Notion and Linear scaffolding around execution
  - Later milestone rationalisation and activity cleanup
- Claude surface used:
  - Chat for structuring
  - Cowork for operationalising into systems
- MCP integrations involved:
  - Linear
  - Notion
- Compound memory / cross-session pattern:
  - Methodology was continuously revised as the actual build diverged from the original plan

### Client deliverables

- Conversation count: `1`
- Example:
  - `2026-03-09` dashboard evidence and closure-material session
- What was produced:
  - UI evidence capture steps
  - Validation links
  - Completion narrative for dashboard-related items
- Claude surface used:
  - Cowork
- MCP integrations involved:
  - Linear
  - Notion
- Compound memory / cross-session pattern:
  - Deliverable prep was coupled to definition-of-done questions rather than separated from build work

### Research and synthesis

- Conversation count: `1`
- Example:
  - `2026-03-28` review of [`/Users/danielnortje/Documents/Pulse360/docs/improvements/pulse360-north-star-solution-specification.md`](/Users/danielnortje/Documents/Pulse360/docs/improvements/pulse360-north-star-solution-specification.md) and the `.docx`, plus Codex-vs-Claude automation comparison
- What was produced:
  - Critique of the revised north-star design
  - Change assessment against the current build
  - Public regional data + GPT enrichment upgrade plan
  - Recommendation to add a structured Salesforce/Data Cloud MCP service
- Claude surface used:
  - Chat for synthesis
  - Code once the plan shifted into implementation
- MCP integrations involved:
  - Primarily repo inspection
  - Later fed into the custom MCP build
- Compound memory / cross-session pattern:
  - This was the hinge session that converted strategic critique into the biggest late-stage implementation change

### Governance and compliance

- Conversation count: `2`
- Examples:
  - `2026-03-09` build-vs-claimed-build audit
  - `2026-03-26` UI-driven verification and handoff steps
- What was produced:
  - Concrete reconciliation of perceived built vs actually built
  - Validation links to Databricks and Salesforce surfaces
  - Stronger emphasis on built runtime as evidence, not docs
  - Stewardship-oriented checks around governance case metadata and activation status
- Claude surface used:
  - Code
  - Cowork
- MCP integrations involved:
  - Linear
  - Notion
- Compound memory / cross-session pattern:
  - Governance here operated as operational truth-checking, not just policy documentation

### Team coordination

- Conversation count: `3`
- Examples:
  - `2026-03-08` Pulse360 queue isolation
  - `2026-03-13` Linear/GitHub/Codex-memory reconciliation
  - `2026-03-25` milestone/status validation and next-session handoff
- What was produced:
  - Cross-system reconciliation between repo, Linear, and accumulated agent memory
  - Issue status corrections
  - Progress handoff material and next-session prompt
- Claude surface used:
  - Cowork
- MCP integrations involved:
  - Linear
  - Notion
- Compound memory / cross-session pattern:
  - Claude was being used like an operations chief of staff to keep plan, tracker, and actual build aligned

### Tooling and infrastructure

- Conversation count: `2`
- Examples:
  - `2026-03-25` environment verification
  - `2026-03-29` to `2026-04-05` Data Cloud runtime, custom MCP, packaging, and GitHub update path
- What was produced:
  - Environment health checks across build systems
  - Custom Salesforce Data Cloud MCP service and validations
  - Live Data Cloud runtime investigation
  - Packaging strategy and generated package workspaces
  - GitHub branch update and PR creation
- Claude surface used:
  - Code
- MCP integrations involved:
  - Custom Pulse360 Salesforce Data Cloud MCP
  - Linear
  - GitHub via CLI rather than MCP
- Compound memory / cross-session pattern:
  - The toolchain itself became part of the architecture practice, not just a support layer

## What Specifically Got Produced

### Planning and architecture

- EPF-based build plan
- Canonical B2B customer-360 model alignment
- Product-definition reframing for Pulse360 Account Intelligence
- North-star upgrade plan

### Build artifacts

- Salesforce Account Intelligence slice: fields, LWCs, Apex service/tests, permission set, flexipage
- Governance Case slice: object fields, validation rules, trigger-driven automation, record page
- Databricks silver/gold SQL path and dashboard SQL
- Data Cloud contracts, mapping config, and validation scripts
- Package workspace generators for Salesforce and Databricks
- Custom Salesforce Data Cloud MCP service

### Operating artifacts

- Linear issue updates, comments, and milestones
- Notion pages and comments
- Progress handoff and next-session prompts
- GitHub PR and branch updates

## Claude Surface Mapping

### Chat for strategy

- Canonical model decisions
- North-star critique
- Automation-approach comparison
- Product-definition reframing

### Code for building

- Salesforce metadata
- Databricks SQL
- Validation scripts
- MCP implementation
- Package builders
- GitHub and CI fix work

### Cowork for documents and coordination

- Linear cleanup
- Milestone reconciliation
- Notion page updates
- Handoff and status material

## MCP and Integration Footprint

- `Linear`: dominant project-management integration
- `Notion`: active for status pages, comments, and handoff documentation
- `GitHub`: used through `gh` CLI rather than MCP
- `Pulse360 Salesforce Data Cloud MCP`: later-stage custom integration built inside the project
- `Slack`: no meaningful evidence of Slack use in these project conversations
- `Salesforce/Data Cloud`: mostly through CLI, custom MCP, and direct platform steps rather than a stock external MCP

## Distinctive Patterns

### Claude as thinking partner

- Challenged milestone logic
- Reframed product scope from close issues to build something valuable
- Pushed canonical model decisions upstream before implementation

### Claude as production tool

- Generated repo artifacts, validation scripts, package builders, field mappings, and UI instructions
- Updated Linear and Notion as part of the same flow

### Claude as execution engine

- Ran long CLI investigations
- Drove Data Cloud runtime diagnosis
- Created and pushed Git branches and opened a PR
- Built a custom MCP service to close automation gaps

## What Would Have Taken Much Longer Without AI

- Cross-system reconciliation between repo, Linear, Notion, and GitHub
- Turning a north-star design critique into a buildable upgrade plan and then into code/config
- Repeated audits of what was actually built vs what was merely claimed built
- Packaging the implementation into reusable Salesforce and Databricks workspaces
- Data Cloud runtime troubleshooting plus the parallel packaging and GitHub work around it

## What Emerged That Probably Would Not Have Emerged Otherwise

- The shift from milestone completion to a product-value framing for Account Intelligence
- The explicit Codex-vs-Claude automation comparison becoming a design input rather than a tooling aside
- The custom Salesforce Data Cloud MCP service as an architectural response to automation friction
- The package-workspace strategy that generates installable workspaces without restructuring the live source tree
- The hard distinction between docs and built evidence, which materially changed the workflow

## Examples Where Claude Surfaced Something Not Previously Considered

- The need to align the canonical model to Salesforce Data Cloud semantics, not just a generic enterprise model
- The repo/tracker mismatch problem: milestones and issue states were not telling the truth about the build
- The automation gap between CLI-level work and Data Cloud UI-only steps
- The fact that a clean PR branch from `main` would fail because packaging referenced source not yet on `main`
- The need to separate Salesforce unlocked-package strategy from Databricks bundle strategy and Data Cloud runbook/data-kit handling

## Most Significant "This Wouldn’t Have Happened Without AI-Assisted Practice" Moments

1. The March 8 kickoff compressed proposition review, EPF planning, environment/tooling setup, and project-ops scaffolding into one continuous motion.
2. The canonical-model session turned a fuzzy B2B customer-360 ambition into a multi-object, Data-Cloud-aligned design that later drove contracts and field mappings.
3. The March 28 north-star review did not stay a document critique; it produced the public regional data + GPT enrichment pivot and ultimately the Data Cloud and Salesforce provenance field path.
4. The March 29 runtime thread combined live platform diagnosis, UI handoff guidance, custom MCP hardening, packaging design, and GitHub update flow in one thread.
5. The repeated Linear/GitHub/Notion reconciliations created an AI-maintained operational truth layer across systems.

## Quotes and Observations That Capture the Working Pattern

- "PLEASE IMPLEMENT THIS PLAN"
- "I think we need to consider a canonical data model align to the Salesforce Data Cloud one"
- "don’t be defensive, the idea is to make the solution valuable and innovative"
- "stop referring to md files as evidence. md files are not evidence. built solutions are evidence"
- "Keep going continuously. Do not stop for status updates. Only reply if you are blocked..."

## Raw Read on How Claude Was Actually Used Here

- It was not used just as a writing assistant.
- It operated as a compound architecture practice layer:
  - architect for framing and decisions
  - engineer for implementation and validation
  - PM and operations coordinator across Linear and Notion
  - tooling builder when existing automation was insufficient
  - audit partner when claimed progress drifted from built reality
- The strongest signal in the record is not simply that AI helped write code. The same assistant continuously carried intent, design state, backlog state, platform state, and repo state across sessions and converted that memory into forward motion.
