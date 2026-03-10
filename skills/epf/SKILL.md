---
name: epf
description: >
  Enterprise Prototype-First Framework (EPF) v3.2.4 — the master methodology skill for enterprise solution design and rapid prototyping. Enforces the Discover → Design → Implement flow with Socratic questioning, decision gates, and traceable outputs at every stage. Use this skill whenever the user starts a new engagement, references EPF stages or gates, asks about framework methodology, needs stage-specific outputs or gate checks, discusses phase transitions, or asks "what's next" in an engagement context. Also triggers on: engagement kickoff, phase navigation, gate validation, framework evolution, IP inventory, Solution Read Out preparation, Implementation planning, release cadence, compound memory promotion, or any mention of EPF version, stages, or principles. Do NOT use for: Socratic questioning mechanics (use socratic-design), technology cost modelling (use technology-evaluator-enhanced), integration pattern selection (use enterprise-architecture-patterns), handoff spec writing (use handoff-writer), or session state management (use session-protocol). This skill provides the WHAT and WHEN; the other skills provide the HOW for their specific domains.
---

# Enterprise Prototype-First Framework (EPF) v3.2.4

**A repeatable methodology for enterprise solution design and rapid prototyping.**
*Dialogue over documentation. Show over tell. Prototype to validated investment case.*

---

## Core Conviction

In the era of AI-generated code, the bottleneck has moved from implementation velocity to **decision quality**. Senior architectural experience is more valuable than ever — not for writing code, but for knowing what *not* to build and understanding platform-specific constraints that AI tools cannot reason about.

## Core Principles

1. **Research-first, not requirements-first.** Users don't know what's possible until they see it. Research-driven prototyping unlocks transformative ideas.
2. **The prototype IS the production blueprint.** Same IaC, same CI/CD, same observability — just smaller. Nothing is throw-away.
3. **Decision quality over implementation velocity.** AI generates code; the architect's value is in knowing what to build, what not to build, and which platform constraints bite at scale.
4. **Socratic questioning prevents premature convergence.** Every stage has questions that must be answered before proceeding. The gate validates the stage's purpose.
5. **Parallel documentation, not afterthoughts.** Features are not complete until code works, tests pass, and documentation is current.
6. **Graceful degradation by design.** Auxiliary features enhance UX but never block core functionality.
7. **IP compounds across engagements.** Every engagement produces reusable IP — inventoried at Stage 1.1, valued in the effort model.
8. **Content sanitisation is standard practice.** Customer-facing artefacts use codenames, light themes, professional presentation. Internal artefacts are unconstrained.
9. **The framework improves itself.** Every engagement produces learnings triaged into the EPF Improvement Backlog. The feedback loop is not optional.

---

## Framework Structure

**3 Phases · 14 Stages · 14 Decision Gates · 80+ Socratic Prompts**

---

## Phase 01 — Discover

*Ask before solving. Constrain before designing. Decide before building.*

Socratic exploration of the problem space, enterprise constraints, and solution boundaries. Every assumption is surfaced and tested before a single line of code. Research-first — start with what's possible and proven, then map requirements to patterns.

### Stage 1.1 — Business Context Framing
**Purpose:** Establish WHY, WHO, and WHAT OUTCOMES before touching technology. Ground every decision in measurable business value. Establish content sanitisation conventions and inventory reusable IP from prior engagements.
**Outputs:** Business Problem Statement (testable), Stakeholder Map, Constraint Register, Sanitisation Conventions, IP Inventory, Project workspace initialised.
**Gate:** *Can you explain the business problem to a new team member in 2 minutes without mentioning technology?*

### Stage 1.2 — Enterprise Constraint Mapping
**Purpose:** Surface the invisible constraints that kill projects: industry regulations, country-specific data laws, compliance requirements, procurement rules, and organisational politics.
**Outputs:** Compliance Matrix (regulations × data types × jurisdictions), Data Residency Map, Procurement Constraints, Risk Profile.
**Gate:** *Have you identified at least one constraint per category (regulatory, data, procurement, organisational) that could block production deployment?*

### Stage 1.3 — Platform Landscape Assessment
**Purpose:** Map the existing technology estate. Every enterprise has gravity — understand where it pulls.
**Outputs:** Current-State Architecture Diagram (C4 Context), Platform Inventory, Identity & Auth Topology, Gap Analysis.
**Gate:** *Can you draw the data flow between the 3 most critical systems without guessing at any integration point?*

### Stage 1.4 — Solution Space Exploration
**Purpose:** Explore architectural options to understand trade-offs — not to pick the best one. The Socratic method prevents premature convergence.
**Outputs:** Option Assessment Matrix (3+ approaches scored), ADRs, Risk Register (per-option), Recommended approach with explicit trade-offs.
**Gate:** *Can the stakeholder explain why Option B was rejected, not just why Option A was chosen?*

### Stage 1.5 — Decision Capture & Commitment
**Purpose:** Crystallise all Discovery outputs into committed decisions. Document existing IP applicable to the engagement. Everything from this point forward is constrained by these commitments.
**Outputs:** Decision Log (all ADRs linked), Target-State Architecture (C4 Container), Scope Commitment (MVA/deferred/excluded), IP Register with valuation, Project wiki with all artefacts.
**Gate:** *If a new architect joined tomorrow, could they understand every decision from the project wiki alone?*

---

## Phase 02 — Design

*Design the experience first, the architecture second, the infrastructure third. Build to learn. Plan from evidence, not assumptions.*

Translate decisions into requirements, architecture, working prototypes, and evidence-based implementation plans. Prototypes are design validation tools — "build to learn" — not the start of delivery. Culminates in the **Solution Read Out**: the formal go/no-go gate before any implementation begins.

### Stage 2.1 — Requirements Design
**Purpose:** Define what the solution must do (functional) and how it must perform from the user's perspective (user-facing NFRs). System-level NFRs move to Stage 2.2 where they drive architecture choices.
**Outputs:** Persona Cards (2–4), Journey Maps (current + future state), Wireframe Prototypes (interactive), Functional Requirements Register (FR-01, FR-02...), User-Facing NFRs (latency targets, confidence thresholds, UX responsiveness), Error & Edge Case Catalogue, Stakeholder Dashboard Wireframes.
**Gate:** *Can you walk the end-to-end journey for each persona using only the prototypes — including error states and user-facing performance expectations?*

### Stage 2.2 — Solution Design
**Purpose:** Design the technical architecture with enough precision to build from, enough flexibility to evolve. Every pattern choice must reference a Discovery decision. Validates internal coherence — every requirement traces to an architecture component. Design for graceful degradation.
**Outputs:** C4 Diagrams (Context, Container, Component), Integration Contract Specifications, Data Flow Diagrams with trust boundaries, Degradation Map (core vs. enhancement classification), System NFRs, ADRs for every major decision, Technology Stack Decision, Initial Cost Envelope (3-tier, explicitly low confidence), **Traceability Matrix: use cases → requirements → architecture → gap analysis** (required gate artefact).
**Gate:** *Can every requirement trace to architecture components with no undocumented gaps — and can the stakeholder understand why alternatives were rejected?*

### Stage 2.3 — Development Environment & Observability Foundation
**Purpose:** Set up dev environment and observability infrastructure as prerequisites for prototype builds. Same IaC, same CI/CD, same observability as production — just smaller. For agentic AI: observe agent-to-agent communication, tool calls, LLM token usage, confidence scores.
**Outputs:** GitHub Repository (branch protection, CI/CD, code owners), IaC Templates (dev → staging → production), CI/CD Pipeline, Secret Management, OpenTelemetry Instrumentation, Base Observability Dashboards, Dashboard deployment pipelines, Development README / CLAUDE.md.
**Gate:** *Can a new developer clone the repo and have a working local environment in under 30 minutes? Can you trace a request end-to-end through the observability stack?*

### Stage 2.4 — Prototype Build(s)
**Purpose:** Build working prototypes to validate (or invalidate) the Solution Design from Stage 2.2. "Build to learn" — the prototype discovers what paper design missed, generates empirical data for cost modelling, demonstrates feasibility. The prototype IS the production blueprint — same code, same infrastructure, same patterns — scaled down. Supports dual-prototype bake-off when multiple platforms are viable.

**Four implementation acceleration goals:**
1. **Detail architectural decisions early.** Every ADR written against a running prototype is grounded in evidence, not assumption.
2. **Plan implementation work in more detail.** Effort estimates from prototype actuals are high-confidence. Unprototyped estimates are assumptions — labelled as such.
3. **Identify critical dependencies early.** Infrastructure dependencies (identity federation, third-party APIs, data residency) must surface during prototyping.
4. **Provide a fast start for implementation after GO.** Production-quality prototype means zero rework for validated components.

**Prototype quality is measured by rework exposure, not demo quality.** At every decision point: *what does it cost the implementation team if we don't know this now?*

**Outputs:** Working Prototype(s) (all core use cases E2E), Project Scaffold, Interface Contracts (TypeScript/OpenAPI), Stub Implementations (realistic mock data), Integration Test Harness (all passing), Assumption Validation Log, Rework Exposure Register, Prototype Reuse Analysis, Platform Comparison Results (if dual-prototype), **Updated Solution Design (corrections from prototype learning)**.
**Gate:** *Does the prototype demonstrate all core use cases E2E? Have the assumptions from Solution Design been validated or corrected? Is every unprototyped component explicitly labelled as an assumption in the Implementation Estimate?*

### Stage 2.5 — Implementation & Resource Planning
**Purpose:** Plan implementation using evidence from prototype builds — not assumptions. Cost modelling, resource planning, effort estimation, and risk budgeting all grounded in empirical prototype data.

**Six evaluation dimensions (for platform comparison):**
1. Security & Identity
2. Orchestration & Integration
3. Scalability & LLM Strategy
4. Infrastructure TCO (3-tier: prototype / pilot / production)
5. Architecture Mapping (per-layer platform fit)
6. Strategic Recommendation

**Outputs:** Cost Model (3-tier, HIGH confidence from prototype evidence), 6-dimension scored comparison (if platform comparison), Resource Plan (roles × releases × FTE with RACI), Implementation Activity Plan (per-release with effort + critical path), Release Version Map (Pilot → V1 → V2+ with gate criteria), Risk-Adjusted Budget, Skills Matrix, Vendor Lock-In Assessment, Implementation Assumptions Register, Dependency Map.
**Gate:** *Can a finance stakeholder see the cost trajectory from prototype to production without surprises — and is every estimate traceable to prototype evidence?*

### Stage 2.6 — Solution Read Out & Implementation Go/No-Go
*The single most important decision point in an engagement.*

**Purpose:** Formal go/no-go gate before Implementation begins. Complete solution design — architecture, cost model, resource plan, implementation assumptions — presented to stakeholders. No implementation commences without passing this gate.

**Six deliverable categories:**
1. **Prototype Demo:** Working prototype with persona-based accounts, UX wireframes, test results.
2. **Architecture:** C4 diagrams, 6-dimension platform comparison, ADRs, integration contracts.
3. **BA & UX:** Persona cards, journey maps, UX design recommendations.
4. **Implementation Estimate & Resources:** Effort model (person-days by role by phase), infrastructure cost model, IP offset, skills matrix, resource plan, assumptions register, dependency schedule.
5. **Risk & Governance:** Risk register, compliance matrix, data residency confirmation, operational assumptions.
6. **Recommendation:** Platform recommendation with ADR, native vs. custom-build breakdown, hybrid future path, conditions to revisit, production roadmap.

**Two dashboards:**
- **Internal Readout Dashboard (SI-only):** Effort matrix, contingency slider, gate tracker, deliverable status, assumptions register, resource plan. Contains commercial detail.
- **Customer-Facing Dashboard (stakeholder-shared):** Overview, UX Demo, Architecture, Roadmap. Sanitised, light-theme, no commercial detail. Deployed via GitHub Pages.

**Three outcomes:** GO → proceed. CONDITIONAL GO → address gaps, re-present. NO-GO → archive as IP. Nothing is wasted.

**Gate:** *Has the stakeholder readout resulted in a formal GO decision? Can the commercial team issue a SOW without further analysis? Are all implementation assumptions and dependencies confirmed?*

---

## Phase 03 — Implementation

*Deploy to validate. Scale with confidence. Hand off with independence. Maintain from day one.*

Implementation only begins after the Solution Read Out GO decision. The prototype (already on real backends from Stage 2.4) evolves into production through hardening, security review, real users, and operational handoff. Phase 03 is about **scaling and hardening, not first-time construction**. This phase encompasses Discovery Expansion, Design Evolution, Production Hardening, and Operations & Maintenance.

### Stage 3.1 — Pilot Deployment & Validation
**Purpose:** Implement the solution scaffold with real integrations, refine the product roadmap into versioned user stories, and produce detailed technical designs for each integration point. Ends with working MVP and Confirmed Release Packages (CRPs) in non-production. Solution maintenance established here — not bolted on later. The architect operates as **technical director** — vision, validation, strategic decisions while AI handles mechanical implementation.
**Outputs:** Working MVP (stubs replaced, non-prod), CRPs (versioned, tested, deployable), Versioned Product Roadmap, Detailed Integration Technical Designs, Test Suite (all green against real backends), Solution Maintenance Plan, Code Review Log, Technical Debt Register.
**Gate:** *Can you demo the MVP to stakeholders in non-prod with real integrations? Is the product roadmap detailed enough for commercial sign-off?*

### Stage 3.2 — Pilot Release & Validation
**Purpose:** Deploy MVP as initial pilot to a controlled user group. Emphasis shifts from construction to validation — extensive testing, real-user monitoring, feedback loops. V1 Discovery refinement and V1 Design begin in parallel one release ahead.
**Outputs:** Pilot Deployment (controlled user access), E2E Test Suite (real data), Failure Mode Tests, Performance Baseline, Pilot Validation Report, Actual-State Architecture Diagram, Solution Maintenance Activation, V1 Discovery Outputs, V1 Design Outputs.
**Gate:** *Is the pilot stable with monitoring active and stakeholder sign-off? Has V1 Discovery produced enough refined user stories and design updates to begin the next implementation cycle?*

### Stage 3.3 — Live Releases, Continuous Evolution & Framework Feedback
**Purpose:** Promote pilot to production. Establish iterative release cadence. Each release incorporates N+1 Discovery and Design one release ahead. Solution maintenance fully operational. Subsequent releases cycle through their own Solution Read Out gates. All documentation and cost estimation generated within each release cycle.

**EPF Framework Feedback (formal output):**
- What methodology friction points, cross-surface workflow issues, or platform gotchas emerged?
- Have engagement learnings been documented with evidence, severity, root cause?
- Have learnings been triaged into the EPF Improvement Backlog?
- Has compound memory promotion PR been submitted to epf-framework?

**Outputs:** Production Releases (automated quality gates + rollback), CI/CD Pipeline (per-release), Environment Matrix (IaC parity), Rollback Playbook, N+1 Discovery Outputs, N+1 Design Outputs, Per-Release Documentation, Operational Runbook, Cost Actuals vs. Projections, Solution Maintenance Report, Stakeholder Presentation, Commercial Handoff Pack (SOW-ready), **EPF Engagement Learnings**, **Compound Memory Promotion PR**.
**Gate:** *Is production stable with maintenance operational? Is N+1 Discovery and Design complete? Can the commercial team issue the next milestone invoice? Have engagement learnings been triaged with compound memory promotion completed?*

---

## Architect's Three Modes

1. **Decision Architecture (before implementation):** Socratic exploration, constraint mapping, option analysis. Surfaces what AI cannot — organisational politics, regulatory nuance, platform-specific gotchas at scale.
2. **Architectural Guardrails (during implementation):** Silent monitoring of coupling violations, security boundary reviews, clean architecture enforcement. Technical director; AI handles mechanical implementation.
3. **Fitness Evaluation (after releases):** Validates what was built matches what was decided. Compares actual-state vs. design-state. Verifies graceful degradation and failure mode handling.

---

## Three Surfaces, One Methodology

| Surface | Role | Best For |
|---------|------|----------|
| **Claude.ai Chat** | Dialogue & Design | Client workshops, design sessions, stakeholder demos, Socratic exploration |
| **Claude Code** | Implementation & Deploy | Prototype construction, MCP servers, CI/CD, TDD enforcement |
| **Cowork (Desktop)** | Documents & Research | Document generation, research synthesis, presentations |

**Integration points:** GitHub is source of truth across all surfaces. Local project folders shared between Cowork and Code. Chat Project knowledge base contains reference docs. Connectors (Notion, Google Drive, Slack) per-engagement.

---

## Cross-Surface Workflow

**Discovery** (primarily Chat): Socratic questioning → business context, constraints, ADRs → Notion captures → copy to local 01-discovery/
**Design** (Chat + Cowork): Architecture exploration → C4 diagrams, cost model → copy to local 02-design/
**Build** (primarily Claude Code): Autonomous implementation with TDD → slash commands → sub-agents → GitHub PRs
**Documentation** (Cowork + Chat): Autonomous doc generation → reader testing → stakeholder refinement
**Handoff**: Cowork compiles pack → Chat reviews → Code merges/tags → Notion completes wiki

---

## Skill Disambiguation

This skill (epf) is the **master methodology navigator**. It tells you WHERE you are, WHAT comes next, and WHICH outputs are required. For domain-specific HOW:

| Question | Use This Skill |
|----------|---------------|
| "What stage are we in?" / "What's the next gate?" | **epf** (this skill) |
| "Ask me the right questions before we design" | **socratic-design** |
| "Compare these platforms on cost" / "What's the TCO?" | **technology-evaluator-enhanced** |
| "What integration pattern should we use?" | **enterprise-architecture-patterns** |
| "Package this for Claude Code execution" | **handoff-writer** |
| "Start session" / "Save progress" | **session-protocol** |

---

## Framework Improvement Loop

1. **Capture** — During each engagement, document learnings as they arise (EPF Learnings pages with evidence, severity, root cause).
2. **Triage** — Decompose into discrete items in the EPF Improvement Backlog (priority, category, affected stage, target version, effort).
3. **Incorporate** — Batch into EPF version releases. Critical → immediate. High → next minor. Medium/Low → scheduled.
4. **Compound** — Compound memory system promotes engagement learnings to `epf-framework` repo through reviewed PRs. Platform skills enriched, anti-patterns documented, next engagement inherits everything.

**Governance:** Framework owner approves all methodology changes. Engagement noise filtered at triage. Tagged releases let engagements pin versions.

---

## Framework Family

**Upstream:** Sales Pursuit Framework (SPF) — Phase 00. Transforms RFPs and sales inputs into qualified opportunities. SPF outputs flow directly into EPF Phase 01.
**Downstream:** New Initiative Creation Framework (NIF) — adapts EPF for internal initiatives (not client delivery). Coming soon.

---

## Quick Reference — All Gates

| Stage | Gate Question |
|-------|--------------|
| 1.1 | Explain the business problem in 2 minutes without mentioning technology? |
| 1.2 | At least one constraint per category (regulatory, data, procurement, org)? |
| 1.3 | Draw data flow between 3 most critical systems without guessing? |
| 1.4 | Stakeholder can explain why Option B was rejected? |
| 1.5 | New architect understands every decision from the wiki alone? |
| 2.1 | Walk E2E journey per persona including error states and user-facing NFRs? |
| 2.2 | Every requirement traces to architecture with no undocumented gaps? |
| 2.3 | Clone to working env in 30 min? Trace request E2E through observability? |
| 2.4 | Prototype demos all core use cases? Assumptions validated or corrected? |
| 2.5 | Finance sees cost trajectory without surprises, traceable to prototype? |
| 2.6 | Formal GO decision? Commercial team can issue SOW? All assumptions confirmed? |
| 3.1 | Demo MVP in non-prod with real integrations? Roadmap ready for sign-off? |
| 3.2 | Pilot stable with monitoring? V1 Discovery ready for next cycle? |
| 3.3 | Production stable? N+1 ready? Invoice issuable? Learnings triaged + promoted? |

---

**Version:** 3.2.4 (March 2026)
**Author:** Daniel Nortje
