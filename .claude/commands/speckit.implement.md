---
name: speckit.implement
description: Execute the tasks for ONE named repo and update task status.
---

# speckit.implement

## Step 0 — Check the tasks-approval gate

Read `tasks.md`'s `Approval Status`. If it is not `Approved`:

- Stop before touching any product repository.
- Tell the user `tasks.md` must be approved first (this is the hub's Gate 2 — `constitution/EMPOWER-HUB-CONSTITUTION.md` Section 6).
- If the user explicitly says to proceed anyway, record that override in `tasks.md`'s `Approval Notes` field instead of silently implementing as if the gate had passed.

## Step 1 — Require an explicit repo argument

This command implements exactly **one repo per invocation**. If the user hasn't stated which repo, ask before doing anything else. Never implement two repos in the same run, even if tasks.md has sections for both — that's what makes each repo's change independently reviewable.

## Step 2 — Read inputs

- `specs/<type>/<task-id>-<slug>/spec.md`
- `specs/<type>/<task-id>-<slug>/plan.md`
- `specs/<type>/<task-id>-<slug>/tasks.md` — only the section for the named repo
- The target repo's own `CLAUDE.md` and whatever architecture/docs it has (`MyIsn.Android` keeps its architecture in `CLAUDE.md`; `MyIsn.iOS` has no `docs/` — see its `AGENTS.md`/`README.md`). See the `android-expert` / `ios-expert` skills.
- **If this task touches any UI-visible code**: also read `docs/style-guide.md` in this hub. Implement against it, not just against whatever the repo's existing components already do (existing code can itself have drifted from it). If a needed value isn't documented there, say so and ask rather than guessing.

## Step 3 — Confirm the branch

Check `git -C <resolved repo path> branch --show-current`. Every repo requires a feature/fix branch named `feature/<task-id>-<slug>` or `fix/<task-id>-<slug>` — if the current branch doesn't match that convention and isn't already the intended working branch, tell the user and ask how to proceed. Do not create or check out a new branch without asking.

## Step 4 — Implement

Work directly inside the target repo (this hub has no code of its own). **Before hand-writing code for a task, check whether the target repo already has a skill that covers it — prefer that skill over reimplementing its logic by hand.** Each repo's own skills are scoped to it and only surface as available while working under its path; invoke them with the Skill tool the same as any other skill. Known mappings as of this hub's last `/document-projects` pass (re-check each repo's own skill catalog if this list looks stale):

| Task looks like... | MyIsn.Android skill | MyIsn.iOS skill |
|---|---|---|
| Scaffold a new screen/feature | `create-feature-screen` | `screen` |
| Add a new API endpoint / service | `add-api-call` | `service` (from an OpenAPI/Swagger YAML) |
| Add a feature flag — **single-platform only**; for a flag needed on both platforms in the same task, use `/add-cross-platform-feature-flag` instead so the Remote Config key stays consistent across both | `MyIsn.Android:feature-flag` | `MyIsn.iOS:feature-flag` |
| Implement a screen/component from a Figma spec | `figma-to-compose` | `figma-implement-ios` |
| Generate/update unit tests for what was just written | `add-tests` | `unit-test` |
| Create/update a test fixture | — | `fixture` |
| Roll an existing StyleKit component out to replace legacy call-sites | — | `ds-migration` |

A task with no matching skill is implemented by hand as usual — don't force-fit a skill where the task doesn't match what it does. Mark each task in `tasks.md` as done as you complete it (`- [x]`), same file, same location in this hub.

## Step 5 — Validate

Run the validation commands the plan/tasks specified for that repo. Report pass/fail plainly; do not mark a task done if its validation failed.

## Rules

- Do not commit, push, or deploy — implementation and local validation only.
- Do not touch the other platform's repo in this invocation.
- Do not silently deviate from the plan — if implementation reveals the plan was wrong, stop and report it rather than improvising a different approach.

## Next command

Once every task for this repo is done and validated:

```
/speckit.review
```

If the plan has a section for another repo not yet implemented, tell the user to run `/speckit.implement` again naming that repo, once this one is reviewed.
