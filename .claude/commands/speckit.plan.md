---
name: speckit.plan
description: Build a per-repo technical plan from a spec.
---

# speckit.plan

Read the spec's scope section to determine which repos need a plan section. For each repo with impact, read that repo's own `CLAUDE.md` before writing its section — don't plan against a repo you haven't actually inspected this session.

## Plan structure

```markdown
# Plan: <task-id> <title>

**Approval Status**: Pending
**Approved By**: N/A
**Approved At**: N/A
**Approval Notes**: 

## Cross-Platform Summary
(one paragraph — what's changing and why, in plain terms)

## Per-Repo Plan

### {repo} Plan
(omit entirely if Scope says "No impact" or if `ls <path>` shows the repo isn't present)

**Affected code areas:**
- Modules, frameworks, or packages that will change

**Data & API layer:**
- request/model changes
- Contract changes (DI, environment config)

**Presentation & UI:**
- UI changes, component reuse, architectural patterns

**Test plan:**
- Unit/integration tests needed

## Third-Party Contract Changes
Explicit before/after shape for any third-party contract touched (see docs/api-contracts.md), including whether Mockoon's mock routes need a matching update

## Observability Plan
New logs, new analytics events, PII fields needing mask-rule updates on each affected platform

## Implementation Order
Which repo first, and why — e.g. "third-party contract must be confirmed before either client work starts" or "Android first since it has the existing pattern to mirror on iOS"

## Risks
```

## Rules

- Do not implement anything, this command only writes `plan.md` 
- Do not propose breaking third-party contract changes without flagging them explicitly as breaking and asking for confirmation.
- Always write `Approval Status: Pending` on first creation, never `Approved` — this is the hub's Gate 1 (`constitution/EMPOWER-HUB-CONSTITUTION.md` Section 6). `/speckit.tasks` will not generate tasks until a human flips this to `Approved` (or records an explicit override). A material change to an already-approved plan resets its status back to `Pending`.

## Output location

- PBI: `specs/pbis/<platform>/<task-id>-<slug>/plan.md` (same folder as `spec.md`) — Feature: `specs/features/<task-id>-<slug>/plan.md`
- Bug: append a `## Plan` section to `specs/bugs/<task-id>-<slug>.md`

## Next command

Tell the user `plan.md` is written with `Approval Status: Pending`, and ask them to approve it (or ask for changes) before running:

```
/speckit.tasks
```
