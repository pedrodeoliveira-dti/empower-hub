---
name: speckit.validate
description: Organize REAL validation evidence (test output, screenshots, smoke results) into pr-evidence.md after implementation and before review. Never fabricates results.
argument-hint: [repo name, optional]
allowed-tools: Read, Glob, Grep, Write, Edit, Bash(ls:*), Bash(git -C * status:*), Bash(git -C * diff:*)
---

# speckit.validate

Runs after `/speckit.implement` and before `/speckit.review`. It collects evidence that **already exists or that the user provides** and organizes it in `pr-evidence.md`. It is **not** a gate and does not decide any verdict — the review verdict stays with `/speckit.review` ([`constitution/EMPOWER-HUB-CONSTITUTION.md`](../../constitution/EMPOWER-HUB-CONSTITUTION.md#6-formal-human-gates)).

## Step 0 — Locate the task and scope

Find the task folder (`specs/<type>/<task-id>-<slug>/`; a Bug is `specs/bugs/<task-id>-<slug>.md`). Ask which repo is being validated if it is not obvious. Resolve its path from `workspace.config.json` and `ls` it. Run `git -C <path> diff --stat` to confirm what actually changed.

## Step 1 — Read what must be proven

- Acceptance criteria in `spec.md`
- The repo's test plan in `plan.md` and, if present, `validation-plan.md` (the evidence matrix)
- This repo's section of `tasks.md`

## Step 2 — Collect evidence

Ask the user to paste or point to real artifacts for each item:

| Evidence | Examples |
|---|---|
| Automated | Gradle / xcodebuild test output, lint output, build result |
| Manual smoke | Steps run, device/simulator, build variant, outcome |
| Screenshots / recordings | File path or description of what is visible |
| Mockoon | Environment + route exercised, scenario, observed response |

You may run read-only or local validation commands the plan already lists if the user asks you to. Quote real output only.

## Step 3 — Write or update `pr-evidence.md`

Create it if missing, otherwise update only the sections below (one file per [`docs/lean-artifact-policy.md`](../../docs/lean-artifact-policy.md)):

```markdown
## Validation Evidence — <repo> (<YYYY-MM-DD>)
| Criterion / plan item | Evidence type | Source | Result | Notes |
|---|---|---|---|---|

### Key output
(trimmed real output, with the command that produced it)

### Not Run — Manual Follow-ups
- [ ] <step> — reason it could not run, who/what is needed
```

Result values: `Passed`, `Failed`, `Not run`. Any acceptance criterion with no evidence is listed as `Not run`.

## Rules

- **Never fabricate** test results, screenshots, or smoke outcomes. If it was not observed or provided, it is `Not run` and goes under Manual Follow-ups.
- A failed result is recorded as `Failed`, not softened. Do not fix code here — report it and tell the user to return to `/speckit.implement`.
- Do not create files other than `pr-evidence.md`. Do not commit or push.
- Do not claim the change is ready — only `/speckit.review` can.

## Output

End with a short summary: criteria covered, `Failed` count, `Not run` count, and the path to `pr-evidence.md`.

## Next command

```
/speckit.review
```

If anything is `Failed`, recommend `/speckit.implement` instead.
