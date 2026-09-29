---
name: po-functional-documentation
description: Use this skill when a Product Owner has a feature brief, PO notes, Figma context, existing documentation, and/or an Azure DevOps reference and wants it turned into functional documentation and Azure DevOps-ready work item drafts — before a formal PBI exists in Azure DevOps. Interactive, wizard-based, approval-driven. Ported from dti-potbelly-ai-hub's `po-functional-documentation` skill / `/pb-po-functional-doc` command.
---

# PO Functional Documentation

Turns whatever a Product Owner has on hand — a feature brief, PO notes,
Figma context, existing documentation, and/or an Azure DevOps reference —
into functional documentation and Azure DevOps-ready work item drafts for
the Empower product (ISN), **before** any formal work item exists for the
feature.

This is the Hub's PO-facing counterpart to the engineering workflow
(`/speckit.specify` → `/speckit.plan` → `/speckit.tasks` → `/speckit.implement`
→ `/speckit.review` → `/speckit.pull-request`). It never implements, never
analyzes current code, and never creates or updates an Azure DevOps work
item — see Boundaries.

## When to Use

- A PO has a feature brief, client brief, or pasted description and wants
  functional documentation and story drafts.
- A PO has only partial input (e.g. a Figma link and some notes) and wants
  to build up source material incrementally, at their own pace.
- A PO wants Azure DevOps-ready work item drafts to review and paste into
  Azure DevOps (isnsoftware org, ISN project) themselves, optionally
  split by platform.

**Not for:** current-code analysis (there is no Hub command for that yet —
answer from the relevant repo's own code instead), a PBI ready for
`/speckit.plan` (hand approved drafts to `/speckit.specify` instead),
implementation tasks (`/speckit.tasks`/`/speckit.implement`, well
downstream), or creating/updating a work item in Azure DevOps — never,
under any circumstance.

## Boundaries

- Never create, update, comment on, or link an Azure DevOps work item, and
  never call the Azure DevOps MCP server (`mcp__Azure_DevOps__*`) to do so
  — even though it's available project-wide, this skill never invokes a
  write tool. A drafted item is only ever pasted into Azure DevOps by the
  PO themselves.
- Never inspect Figma unless content is provided or an approved
  integration exists — a Figma link alone is a reference, not inspectable
  design content.
- Never invent missing requirements, business rules, Area Paths, sprint,
  story points, estimates, or platform-specific behavior. Missing
  information becomes `[TBD]` and an Open Question — never a guess.
- Never continue past an approval gate without explicit user approval.
- Update only files under `specs/po/`. Do not modify
  `MyIsn.Android`/`MyIsn.iOS`/`Mockoon`, run build/test/deploy/
  commit/push commands, or touch CI/CD, signing, secrets, or release
  configuration.
- Never store secrets, credentials, tokens, payment data, or other user PII
  in a generated artifact.
- Keep all generated content in English, regardless of the language used
  in conversation.

## Input Wizard

Start every fresh run with:

```
What input do you want to add?

1. Feature brief
2. PO notes / open input
3. Figma input
4. Existing documentation
5. Azure DevOps reference
6. Finish input collection and generate functional documentation
7. Cancel
```

Wait for the user to choose. **Do not generate functional documentation
until the user picks option 6 or explicitly asks to generate.** After each
captured input, log it (see Source Material below) and re-show the same
menu with the current source list, so the PO can keep adding input at
their own pace.

### Input types

1. **Feature brief** — overview, description, opportunity, goal/
   hypothesis, problem, context, appetite/size, risks/assumptions, out of
   scope, technical considerations, dependencies, open questions. Extract
   only what is present — never invent. Classify as `Feature Brief`.
2. **PO notes / open input** — notes, clarifications, business rules,
   stakeholder comments. Classify as `PO Notes`.
3. **Figma input** — link, screenshot, design notes, or user flow. **A
   Figma link alone is a reference, not inspectable design content** —
   record the link, ask for screenshots/notes, never invent UI behavior
   from a link alone. Classify as `Figma Input`.
4. **Existing documentation** — markdown, wiki export (e.g.
   `docs/wiki/App/`), prior functional notes. Classify as `Existing
   Documentation`.
5. **Azure DevOps reference** — work item ID, query result, or existing
   story/acceptance-criteria text. Never call Azure DevOps MCP
   automatically for this — only if the user explicitly asks for it in
   this run. Never treat this content as guaranteed current implementation
   truth. Classify as `Azure DevOps Reference`.

## Artifact Location

```
specs/po/<feature-slug>/
├── README.md                     (landing page — links only, no duplicated content)
├── source-material.md            (captured input log)
├── functional-documentation.md   (Stage 1)
├── work-item-list.md             (Stage 2 — conditional, see Work Item Tiers)
└── work-items/
    ├── 001-<work-item-slug>.md   (Stage 3)
    ├── 002-<work-item-slug>.md
    └── ...
```

`<feature-slug>` is a short kebab-case version of the feature name. If the
feature name isn't known yet, ask "What is the feature name?" before
creating the folder — don't guess a slug and rename later.

This sits alongside `specs/pbis/`, `specs/features/`, and `specs/bugs/`
(see `specs/README.md`) as the pre-PBI stage: once work items are
approved, they become the source material an existing repo folder or
`/speckit.specify` promotes into a real spec — see Handoff below.

### Source Material log

After each captured input, update `source-material.md`:

```markdown
# Source Material: <Feature Name>

**Feature Slug**: <feature-slug>
**Status**: Collecting | Complete
**Last Updated**: <YYYY-MM-DD>

| # | Source Type | Summary | Status |
|---|---|---|---|
```

`Status` per row: `Captured`, `Needs clarification`, `Partially usable`, or
`Ignored with reason`. Never duplicate `functional-documentation.md`'s
content here — this file is raw/source material only.

## Overall Workflow

```
Input Wizard
→ Stage 1: Functional documentation
→ approval
→ [Stage 2: Work item list → approval]   (conditional — see Work Item Tiers)
→ Stage 3: Work item drafts
→ PO review
```

**Approval-driven, at every stage.** Present output → wait for approval →
continue. Approval can be natural language ("approved," "looks good,"
"proceed"). If unclear, ask — never infer approval from silence, and never
advance a stage without it.

## Stage 1 — Functional Documentation

**Output:** `specs/po/<feature-slug>/functional-documentation.md`, plus
`README.md` if this is a brand-new feature folder.

Use this exact structure:

```markdown
# Functional Documentation: <Feature Name>

**Feature Slug**: <feature-slug>
**Source Material**: ./source-material.md
**Status**: Draft | Approved
**Last Updated**: <YYYY-MM-DD>

---

## Feature Summary

Flowing prose — a few paragraphs, not bullets or a table — describing what
the feature is, who it's for, and how it functionally works end to end.
Never state business value, hypothesis, revenue/financial estimates, or
KPI targets here — that belongs in the feature brief itself, never
reproduced here.

## Users / Actors

List only real actors — human-facing roles (end user, admin, staff), plus
a non-human system only when it's an independent party the user directly
perceives. Never list a vendor SDK, payment provider, or backend service
the feature merely calls (see `docs/api-contracts.md` for the real ones) —
that belongs in Dependencies or Business Rules, not here.

## Platforms Covered

| Platform | Covered | Notes |
|---|---|---|
| android | Yes/No/Unknown | |
| ios | Yes/No/Unknown | |
| cross-platform | Yes/No/Unknown | |

Add a Notes cell only when there's a genuine caveat for that platform —
don't restate justification for every row by default. If the feature also
needs a new/changed Mockoon route for local dev, note it here rather than
as a fourth platform row — Mockoon isn't a user-facing platform.

## User Journeys

Group journeys by user-facing flow (e.g. one per payment method, one per
interaction type) — never by mechanically mirroring a source work item
1:1.

### Journey: <Name>

1. User/system does X.
2. App/system does Y.
3. Expected result is Z.
4. Error/fallback behavior is A.

## Business Rules

| Rule | Platform | Source | Confidence |
|---|---|---|---|

## Platform-Specific Behavior

Describe only where android/ios logic or user-facing behavior
diverges from the common flow already described in User Journeys.

## Acceptance Criteria

High-level, feature-level Given/When/Then criteria — every one must
describe user- or system-observable behavior a validation pass could
check. Never an implementation build-order note (that belongs in a plan).

## Edge Cases

List relevant edge cases and expected behavior in each. "Not applicable"
if none.

## Security Considerations

Mandatory when the feature touches authentication, payments, or any
PII-carrying field. "Not applicable" if genuinely none.

## Analytics and Measurement

- Metrics/events to capture:
- Open analytics questions:

Check `docs/observability.md` for which analytics provider(s) are actually
integrated per platform before assuming one — don't name a specific
provider here unless it's confirmed there.

## Dependencies

Only what's genuinely new, external, or currently blocking. Never list a
pre-existing vendor integration the feature merely continues to use
unchanged (see `docs/api-contracts.md`), or an internal sequencing
relationship.

| Dependency | Owner | Needed For | Notes |
|---|---|---|---|

## Risks and Assumptions

| Risk / Assumption | Type | Impact | Mitigation / Follow-up |
|---|---|---|---|

## Out of Scope

## Open Questions

| # | Question | Owner | Required Before Story Breakdown? | Notes |
|---|---|---|---|---|

## Approval Gate

Do you approve this functional documentation and want to continue to work
item breakdown?
```

**Generated first, updated in place** as the feature gets defined
further — new input merges into the existing document rather than
starting a fresh pass. Re-present only the changed sections and re-run the
Approval Gate when updating an already-approved document.

Stop here. Do not generate Stage 2 unless explicitly approved.

## Stage 2 — Work Item List (conditional)

### Work Item Tiers

Decide the tier before drafting anything:

**Tier 1 — inline (default for simple features).** Use when all of these
hold: 1–3 simple work items, no dependency between them, no multi-platform
coordination, not high-risk (auth/sign-in, payments, PII), and the PO
didn't ask for per-item files. Present inline, no separate file:

```
This breaks down into <N> work item(s):

1. <title> (<type>, <platform>)
2. <title> (<type>, <platform>)

Shall I add these to the Related Work Items table and draft them?
```

Wait for explicit approval — same gate, just no separate file. On
approval, go directly to Stage 3 and record each item in `README.md`'s
Related Work Items table (Status: `Draft`).

**Tier 2 — `work-item-list.md`.** Create it for 3+ items, or for 0-2 items
when any of: multi-platform coordination, a dependency/sequencing
relationship, high-risk behavior, the PO wants to approve the breakdown
before seeing drafts, or a meaningful scope split. When uncertain, create
the list — the cost of one extra approval question is lower than drafting
the wrong breakdown.

```markdown
# Work Item List: <Feature Name>

**Feature Slug**: <feature-slug>
**Functional Documentation**: ./functional-documentation.md
**Status**: Draft | Approved
**Last Updated**: <YYYY-MM-DD>

---

## Proposed Work Items

| # | Title | Type | Platform | Area Path | Depends On | Notes |
|---|---|---|---|---|---|---|

## Recommended Sequencing

## Gaps Before Drafting

## Approval Gate

Do you approve this work item list and want me to draft the full work items?
```

**Allowed types:** User Story, Technical Debt, Spike, Bug.
**Allowed platforms:** android, ios, cross-platform, unknown.

**Breakdown rules** — split into separate items when platforms can be
delivered independently, or when acceptance criteria/sequencing/QA
validation differ by platform. Use `cross-platform` only when work is
truly shared across platforms.

**Area Path** — this hub has no confirmed Area Path convention for the
ISN project yet. Never invent one: use `[TBD - confirm Area Path with
ISN board admin]` and record an Open Question, for every platform,
until a PO or admin supplies real values.

Stop here. Do not generate Stage 3 unless explicitly approved — either via
this gate, or via Tier 1's inline confirmation above.

## Stage 3 — Work Item Drafts

**Output:** one file per work item under
`specs/po/<feature-slug>/work-items/NNN-<work-item-slug>.md`. Update
`README.md`'s Related Work Items table with each drafted item (Status:
`Draft`, link to its file) — never invent a real Azure DevOps ID for a
draft that doesn't exist there yet.

Every work item ends with the same `## Azure DevOps Fields` table:

```markdown
## Azure DevOps Fields

| Field | Value | Required? |
|---|---|---|
| Work Item Type | <type> | Yes |
| Area Path | [TBD - confirm with ISN board admin] | Yes |
| Iteration Path | TBD | Depends |
| State | New | Yes |
| Board Column | New | Optional |
| Tags | TBD | Yes |
| Target Release | TBD | Optional |
| Parent | TBD | Optional |
| Story Points | TBD | Optional |
| Original Estimate | TBD | Optional |

---

**Source Traceability**: ./functional-documentation.md and/or ./work-item-list.md
**Open Questions**: <list, or "None">
```

Never invent Tags — leave `TBD` unless the PO explicitly provides
semicolon-separated values, or confirms `N/A`. Never invent Story Points,
Original Estimate, or Iteration Path.

### User Story

```markdown
Title: [Verb + object, action-oriented — e.g. "Add push notification opt-in prompt to onboarding"]

As a [user subject]
I want to [action]
Goal: [what this delivers and why it matters]

Notes:

- [expected behavior details]
- [platform-specific notes]
- [accessibility requirements, if any]
- [security considerations, if any]
- [edge cases]
- [Figma: URL]
- [related documentation or dependencies]

Acceptance Criteria:

- Given [context] When [action] Then [expected outcome]
- Given [context] When [action] Then [expected outcome]
```

Skip the "As a... I want to..." framing for a technical/infrastructure
item with no direct user impact — open with `Context:` / `Objective:`
instead (see Technical Debt below), regardless of ADO type.

### Bug

```markdown
Title: [Symptom + where it happens — e.g. "Login fails with valid credentials on Android"]

Repro Steps:

- [step]
- [step]

Expected Behavior:
[What should happen.]

Current Behavior:
[What actually happens. Include error messages if applicable.]

Environment:

- Platform: [Android | iOS]
- Version: [app version]
- Device: [device model, if relevant]
- OS version: [if relevant]
- User state: [logged in/out, guest, etc.]
```

### Spike

```markdown
Title: Investigation: [topic]

Context:
[What uncertainty needs exploring, and why it blocks development.]

Objective:
[What "done" looks like — a decision, POC, recommendation, or finding.]

Notes:

- [references, prior research]
- [constraints: time-box, scope]
- [expected output format]
- [who should be consulted]
```

### Technical Debt

```markdown
Title: [Descriptive — e.g. "Refactor login error handling to a shared taxonomy"]

Context:
[What exists today, why this debt was incurred, what risk it causes.]

Objective:
[What needs to be done and why now.]

Technical Notes:

- [implementation approach]
- [affected repos/components]
- [references: PRs, ADRs, documentation]
```

**Drafting rules (all types):** action-oriented titles; Given/When/Then
covering happy path, edge cases, validation, and platform-specific
behavior; don't over-split into tiny tasks; don't mix unrelated platform
work into one item unless intentionally cross-platform; missing detail
becomes `[TBD]` plus an Open Question, never a guess.

Immediately after drafting, ask exactly once:

```
Would you like me to also draft a cross-platform Hub spec for these
approved items via /speckit.specify, or actually create them in Azure
DevOps via the po-work-item-publish skill? [specify / publish / later]
```

Never run `/speckit.specify` or `po-work-item-publish` yourself — both are
recommendations only, and `po-work-item-publish` still requires its own
metadata check and approval phrase before anything is created.

Final Stage 3 output:

```markdown
# PO Functional Documentation Result

## Feature

- <Feature Name>

## Files Created

## Files Updated

## Work Items

| # | Title | Type | Platform | Tier | Area Path |
|---|---|---|---|---|---|

## Open Questions

## Recommended Next Step
```

**Recommended Next Step — exactly one:**

- Review drafted work items with the PO
- Run `po-work-item-publish` to create the approved items in Azure DevOps
- Run `/speckit.specify` for approved work items (once a real Azure DevOps
  ID exists for them)
- Provide missing design/vendor information
- No next command needed

Stage 3 ends by waiting for PO review — never auto-advances.

## Handoff

- **Manual only, at every stage boundary.** Nothing here auto-advances.
- **Allowed next steps:**
  - `po-work-item-publish`, once work items are approved, to actually
    create them in Azure DevOps (this skill never does that itself).
  - `po-pbi-sync`, later, once a drafted item has a real Azure DevOps ID
    and needs to be kept in sync with what happened to it there.
  - `/speckit.specify`, only after work item drafts are approved and a
    real Azure DevOps work item ID exists for them — use the drafted
    `work-items/*.md` as source material, same as `pull-sprint-pbis`'
    `pbi.md` feeds `/speckit.specify` today.
- **Blocked:** this skill never runs `/speckit.plan`, `/speckit.tasks`,
  `/speckit.implement`, and never creates or updates an Azure DevOps work
  item itself, with or without MCP — that's `po-work-item-publish`'s and
  `po-pbi-sync`'s job, respectively.

## Rules

- Keep all generated content 100% in English.
- Update only `specs/po/<feature-slug>/`.
- Do not modify `MyIsn.Android`, `MyIsn.iOS`, or `Mockoon`.
- Do not create or update an Azure DevOps work item, ever — not even via
  the Azure DevOps MCP server's write tools.
- Do not run build/test/deploy/commit/push/publish/formatter/generator/
  destructive commands.
- Do not invent missing requirements, Area Paths, tags, sprint, story
  points, or estimates.
- Do not inspect Figma unless content is provided or an approved
  integration exists.
- Do not continue past an approval gate without explicit approval.
- Always offer the option to add more input before generating the next
  artifact.
- If information is missing, record it as an Open Question.

## References

- Ported from `dti-potbelly-ai-hub`'s `po-functional-documentation` skill,
  `/pb-po-functional-doc` command, and `po-functional-documentation-agent`
  agent — collapsed into a single skill file (no paired command/agent,
  no separate `templates/po/` folder) to match this hub's existing
  pattern (`pull-sprint-pbis`, `technical-refinement`, `orchestrate-pbi`).
  The `/pb-ado-plan-work-items` part of that ecosystem (sprint/PI planning
  folders) was intentionally left out of this port. Actual Azure DevOps
  writes were later added back as two dedicated skills instead of folded
  into this one — see `po-work-item-publish` (create-only) and
  `po-pbi-sync` (update-only, with read-history reconciliation this hub's
  port adds on top of the original potbelly-hub model).
- `docs/product-overview.md` — platform/third-party model this skill's
  Platforms Covered section relies on.
- `specs/README.md` — where `specs/po/` sits alongside `specs/pbis/`,
  `specs/features/`, and `specs/bugs/`.
