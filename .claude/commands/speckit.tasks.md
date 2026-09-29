---
name: speckit.tasks
description: Generate executable, per-repo tasks from the plan.
---

# speckit.tasks

## Step 0 — Check the plan-approval gate

Read `plan.md`'s (or the bug's `## Plan` section's) `Approval Status`. If it is not `Approved`:

- Stop before generating anything.
- Tell the user `plan.md` must be approved first (this is the hub's Gate 1 — `constitution/EMPOWER-HUB-CONSTITUTION.md` Section 6).
- If the user explicitly says to proceed anyway, record that override in `tasks.md`'s `Approval Notes` field (see below) instead of silently generating tasks as if the gate had passed.

## Step 1 — Generate tasks

Read `plan.md` (or the bug's `## Plan` section) and generate one task list per repo section that exists in the plan. Add this block once at the top of `tasks.md`:

```markdown
**Approval Status**: Pending
**Approved By**: N/A
**Approved At**: N/A
**Approval Notes**: 
```

## General Rules for All Platform Tasks

- **Include exact file paths** where the plan named them.
- **Respect layering order**: Follow the plan's architectural section order (typically data/models → infrastructure/DI → presentation/UI). Each platform has its own layer names, but the principle is consistent: build from foundations up.
- **Test-first pattern**: Write tests as their own task before the implementation task they validate, not after.
- **Include validation tasks** for every repo section the plan touches:
  - Linting (platform-specific tool per repo's CLAUDE.md)
  - Unit/integration tests for every affected target
  - Build verification (assemble/build/archive per platform)
- **Observability**: Include a task for any PII field updates (masking rules, logging, redaction) if the plan's Observability section named a new sensitive field.
- **Analytics**: Include a task for any new analytics event constants if the plan named one.

## Cross-cutting tasks (always include if relevant)

- A task to update `docs/cross-platform-flows.md` in this hub if the plan touched a flow that file documents (or added a new one worth documenting).
- A task to update `docs/api-contracts.md` if a third-party contract shape actually changed.

## Output location

- PBI: `specs/pbis/<platform>/<task-id>-<slug>/tasks.md` (same folder as `spec.md`/`plan.md`) — Feature: `specs/features/<task-id>-<slug>/tasks.md`
- Bugs: append a `## Tasks` section to `specs/bugs/<task-id>-<slug>.md`

## Next command

Tell the user `tasks.md` is written with `Approval Status: Pending`, and ask them to approve it (or ask for changes) before running:

```
/speckit.implement
```

Tell the user they'll need to specify which repo to implement first (if applied) — this command never implements more than one repo in the same invocation.
