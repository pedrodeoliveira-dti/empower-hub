---
name: quick-fix
description: Short path for a broken test, simple build error, or narrow bug in ONE child repo, without the full spec flow. Refuses and redirects anything larger.
argument-hint: <repo> "<short description of the problem>"
allowed-tools: Read, Glob, Grep, Edit, Bash(ls:*), Bash(git -C * branch:*), Bash(git -C * status:*), Bash(git -C * diff:*)
---

# quick-fix

A fast lane, not a bypass. It skips `spec.md` / `plan.md` / `tasks.md` for tiny, well-understood fixes, so none of the three formal gates in [`constitution/EMPOWER-HUB-CONSTITUTION.md`](../../constitution/EMPOWER-HUB-CONSTITUTION.md#6-formal-human-gates) are touched or satisfied by it. The hub holds no product code: edits happen only inside the one child repo.

## Step 1 — Resolve repo and branch

- Ask for the repo if not given. Resolve its path from `workspace.config.json`, then `ls` it. Only `MyIsn.Android` or `MyIsn.iOS` (Mockoon fixes are config-only and also allowed if tiny).
- `git -C <path> branch --show-current`. **Refuse on a protected branch (`main`, `master`, `develop`, `dev` — constitution §4)**: tell the user to switch to a feature/fix branch themselves. Do not create or check out branches.

## Step 2 — Read the repo's own guidance first

1. The repo's `CLAUDE.md` and any repo-local skills relevant to the problem (invoke instead of hand-writing logic, as in `/speckit.implement` Step 4).
2. Per hub `CLAUDE.md` ("Code Exploration in Product Repos"): if `<repo>/graphify-out/graph.json` exists, run `graphify query "<question>"` from inside the repo before grepping. If absent, explore normally.
3. Only the source/test files the problem implicates.

## Step 3 — Eligibility check

Classify as **Eligible** only if all hold:

- One repo, one concern; diff expected to stay small (a few files, roughly under 50 changed lines)
- Broken or flaky unit test, simple compile/build error, lint violation, or narrow bug with a clear cause
- No new feature or behavior change that needs acceptance criteria
- No third-party contract change (see `docs/api-contracts.md`), including Jumio, wallet, geolocation, certificates
- No UI-style change (`docs/style-guide.md`), auth/login design, secrets, build/CI config, or logging of PII/tokens
- Root cause can be stated in one or two sentences

Otherwise **refuse** and redirect, naming the reason:

| Situation | Redirect |
|---|---|
| Both platforms or more than one repo | `/orchestrate-feature`, then `/orchestrate-pbi <id>` |
| New or changed behavior, unclear acceptance criteria | `/speckit.specify` |
| Work item exists and needs the full flow | `/orchestrate-pbi <id>` |
| Cause unknown, needs investigation | `/orchestrate-feature` (read-only analysis) |
| Only a bug description, no fix yet | `/bug-report` |

## Step 4 — Propose, then apply

Show: root cause, the smallest change, files touched, and the narrow validation command. Apply only after the user approves. Do not refactor beyond the fix.

## Step 5 — Validate narrowly

Run only the affected test or build target (e.g. one Gradle test class or one `xcodebuild -only-testing`), not the full suite. Report pass/fail plainly; if it fails, stop and report instead of widening the change.

## Output

```markdown
## Quick Fix — <repo>
Eligibility: Eligible | Refused — <reason> → <redirect>
Root cause: ...
Changed files: ...
Validation: <command> → PASSED | FAILED | NOT RUN
Follow-ups: ...
```

## Rules

- Do not commit, push, or deploy. Leave the diff for the user.
- Do not write spec, plan, tasks, or evidence files. The summary above is chat output only.
- If the fix grows beyond the limits mid-way, stop and redirect.
- Never touch the other platform's repo in the same run.
