# Pulse360 Planner Workspace Redesign Spec

Date: 2026-04-22

## Purpose

This spec translates the current review of the planner workspace into a concrete redesign direction grounded in Salesforce UI best practices.

It is intended to improve:

- use of screen real estate
- clarity of hierarchy
- decision focus
- trust cue placement
- alignment with Lightning patterns

## Design Framework

This redesign uses the following Salesforce-native principles:

1. Platform-first composition
Use Lightning base components and SLDS structure before inventing custom layout systems.

2. Clear hierarchy
The page should answer the primary planning question first, with trust and detail cues secondary.

3. Progressive disclosure
Only the information required for the next planning decision should be visible by default.

4. Responsive layout
The layout should collapse cleanly without relying on dense custom card structures.

5. Accessibility by default
Use clear labels, predictable structure, and avoid visual overload that makes scanning harder.

6. Performance and maintainability
Reduce repeated signals and decorative complexity so the UI remains easier to evolve.

## Current State Review

Reviewed source:

- [pulse360PlannerWorkspace.html](/Users/danielnortje/Documents/Pulse360/force-app/main/default/lwc/pulse360PlannerWorkspace/pulse360PlannerWorkspace.html)
- [pulse360PlannerWorkspace.js](/Users/danielnortje/Documents/Pulse360/force-app/main/default/lwc/pulse360PlannerWorkspace/pulse360PlannerWorkspace.js)
- [pulse360PlannerWorkspace.css](/Users/danielnortje/Documents/Pulse360/force-app/main/default/lwc/pulse360PlannerWorkspace/pulse360PlannerWorkspace.css)

### Strengths

- The planner has a clear intent: rank groups and move leadership toward action.
- The action queue is directionally strong and feels like the most decision-relevant secondary surface.
- The filter model is simple and understandable.
- The data model already includes the core planning signals needed for a useful comparative view.

### Problems

1. Too much prime real estate is spent above the ranked list
The hero, metric strip, and control bar all compete before the user reaches the ranked portfolio.

2. Each ranked card is carrying too many jobs
Each card currently behaves like a summary, explainer, dashboard, evidence tray, and action panel at the same time.

3. Trust cues are over-promoted
Freshness is currently shown like a planning KPI instead of a trust qualifier.

4. The UI repeats similar information in multiple forms
Priority, risk, whitespace, and recommendation appear in prose blocks and then again in micro-metrics.

5. One CTA pair is misleading
`Open account context` and `View seller workspace` currently trigger the same handler and therefore the same destination.

## Core Redesign Goal

Make the planner workspace feel like a leadership decision board, not a portfolio report.

The default experience should answer:

1. Which groups need attention now?
2. Why are they ranked that way?
3. What should leadership do next?

Everything else should be subordinate to those three questions.

## Proposed Information Hierarchy

### Level 1: Planning Decision Frame

Visible at top:

- page title
- one-sentence summary
- single highlighted planning move
- filter controls

This replaces the current heavy hero-plus-callout treatment with a lighter planning frame.

### Level 2: Ranked Portfolio

This becomes the dominant surface on the page.

Each group row/card should show only:

- rank
- account/group name
- 1-line reason for priority
- recommended planning move
- 2 or 3 supporting indicators
- primary action

### Level 3: Leadership Action Queue

Keep the right rail, but make it feel like a compact companion surface rather than a second competing destination.

### Level 4: Trust And Freshness

Freshness, validation gaps, and uncertainty should move into lightweight badges, tooltips, or expandable trust detail.

They should not occupy the same visual weight as planning KPIs.

## Before / After Layout

### Current

1. Hero with title, summary, highlighted insight
2. Large callout for next planning move
3. Five-card metric strip
4. Filter section
5. Large ranked portfolio cards
6. Right rail action queue

### Proposed

1. Compact header
2. Filter/action bar
3. Ranked portfolio as primary surface
4. Compact right rail action queue
5. Optional expandable trust/detail region

## Proposed Wireframe

```text
+---------------------------------------------------------------+
| Pulse360 Planner Workspace                                    |
| Rank groups by commercial consequence, not fragmented CRM.    |
| Next move: Reassign ownership for 3 uncovered strategic groups|
+---------------------------------------------------------------+
| Filter: [All] [Coverage] [Whitespace] [Risk] [Validation]     |
+-------------------------------------------+-------------------+
| Ranked groups                             | Leadership next   |
|                                           | actions           |
| #1 Singtel Group                          | - Reassign owner  |
| Why now: major hidden value + gap         | - Flag exec review|
| Next move: assign uncovered entity owner  | - Review renewal  |
| Priority 92 | Coverage 41% | Hidden 1.2B  |                   |
| [Open planner detail] [Open seller]       |                   |
|                                           |                   |
| #2 Ayala Corporation                      |                   |
| Why now: whitespace + low validation      |                   |
| Next move: sponsor validation review      |                   |
| Priority 86 | Coverage 55% | Risk watch   |                   |
| [Open planner detail] [Open seller]       |                   |
+-------------------------------------------+-------------------+
| Optional expandable trust/detail region                       |
| Freshness, validation notes, underlying signal caveats        |
+---------------------------------------------------------------+
```

## Element-Level Recommendations

### 1. Replace the heavy hero with a compact planning header

Current:
- large hero block
- large dark callout

Recommended:
- one compact header section
- one concise highlighted move
- no second visual block competing for attention

Why:
- better use of vertical space
- faster arrival at the ranked list
- more consistent with Salesforce workspace patterns

### 2. Remove the full KPI strip from the default view

Current metrics:
- groups under review
- coverage gaps
- whitespace-ready
- needs validation
- executive focus

Recommended:
- either remove entirely from default view
- or reduce to 2 or 3 compact chips above the ranked list

Suggested keepers:
- coverage gaps
- executive focus
- needs validation

Why:
- these are useful global portfolio framing cues
- they do not need full-height dashboard cards

### 3. Demote freshness

Current:
- freshness appears as a peer micro-metric inside each ranked card

Recommended:
- show freshness only as:
  - a small badge when stale
  - a warning icon with tooltip
  - an expandable trust detail row

Example:
- `Stale sync`
- `Validation gap`
- `Freshness review needed`

Why:
- freshness is important, but it is not the decision itself
- trust cues should qualify action, not dominate action

### 4. Collapse each ranked card into one summary row plus optional expansion

Current card structure:
- four explanatory blocks
- six micro-metrics
- executive copy
- buttons

Recommended default:
- rank
- name
- short reason
- next move
- 2-3 key indicators
- action buttons

Optional expansion:
- whitespace context
- risk context
- executive prompt
- validation and freshness detail

Why:
- supports progressive disclosure
- reduces scan cost
- makes comparison easier across multiple groups

### 5. Make indicators comparative and fewer

Recommended default indicators per row:

- priority score
- coverage percent
- one third contextual indicator chosen by filter:
  - whitespace lens: hidden value or propensity
  - risk lens: risk or health
  - validation lens: validation status

Why:
- the current six metrics per card overfit the UI to the data model
- planners compare better when the indicator set is stable and small

### 6. Keep the action queue, but tighten it

Recommended:
- shorter cards
- one-line reason
- one clear CTA
- sorted by urgency

Why:
- this area is valuable, but should support the ranked list rather than compete with it

### 7. Split navigation intentionally

Current issue:
- `Open account context` and `View seller workspace` are not truly separate experiences

Recommended:
- `Open account` should navigate to the Account record
- `Open seller workspace` should navigate to the Seller Workspace app/tab or page with context carried through

Why:
- action labels must reflect actual outcomes
- this is important for trust and navigation predictability

## Scoring Target

### Current estimated score

- Platform-first composition: 3/5
- Clear hierarchy: 2/5
- Progressive disclosure: 2/5
- Responsive layout: 3/5
- Accessibility: 4/5
- Performance and maintainability: 3/5

Overall: 2.8/5

### Target after redesign

- Platform-first composition: 4/5
- Clear hierarchy: 4/5
- Progressive disclosure: 4/5
- Responsive layout: 4/5
- Accessibility: 4/5
- Performance and maintainability: 4/5

Overall target: 4.0/5 or better

## Implementation Priorities

### Priority 1

- shrink hero into compact header
- remove or compress the metric strip
- demote freshness to a trust cue
- fix distinct navigation for seller workspace vs account record

### Priority 2

- simplify ranked cards into summary-first rows/cards
- reduce visible metrics from six to three
- move deeper context into optional expansion

### Priority 3

- align page structure more closely to SLDS layout and spacing primitives
- test mobile and narrower desktop behavior after the simplification

## Recommended Acceptance Criteria

The redesign should pass when:

1. A leadership user can identify the top group and next move within 5 seconds.
2. The ranked list is visible without excessive scrolling on a typical laptop viewport.
3. Freshness and validation are visible but do not visually outrank planning signals.
4. Each group row can be compared against another row without reading multiple paragraphs.
5. `Open seller workspace` and `Open account` are truly different navigation outcomes.
6. Trust detail is still reachable without forcing it into the default planner scan path.
