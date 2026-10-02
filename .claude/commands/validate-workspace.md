---
name: validate-workspace
description: Check that the child repos (MyIsn.Android, MyIsn.iOS, Mockoon) are cloned, on a sane branch, and clean — before any spec, plan, or implementation work.
allowed-tools: Read, Bash(ls:*), Bash(test:*), Bash(git -C * rev-parse:*), Bash(git -C * status:*), Bash(git -C * branch:*), Bash(git -C * rev-list:*)
---

# validate-workspace

A read-only **gate**, not a content-producing stage. It writes no files and runs no fetch/pull/checkout.

## Step 1 — Resolve repos

Read `workspace.config.json`. Every repo path comes from there — never hardcode `../<repo>`.

## Step 2 — Check each repo

For each entry, run these (against the resolved path):

| Check | How | Result |
|---|---|---|
| Present | `ls <path>` and `test -d <path>/.git` | `OK` / `MISSING` (not cloned) / `NOT A GIT REPO` |
| Branch | `git -C <path> rev-parse --abbrev-ref HEAD` | name; flag `PROTECTED` if `master`, `main`, or `develop` |
| Working tree | `git -C <path> status --short` | `CLEAN` / `DIRTY (<n> files)` |
| Behind upstream | `git -C <path> rev-list --count HEAD..@{u}` (skip if no upstream) | `<n> behind` / `up to date` / `no upstream` |
| Graph | `ls <path>/graphify-out/graph.json` | `present` / `absent` (informational) |

Never invent output for a repo that is not on disk — report it `MISSING`.

## Step 3 — Report

```markdown
# Workspace Validation

| Repo | Platform | Present | Branch | Tree | Upstream | Graph |
|---|---|---|---|---|---|---|

## Verdict
READY / READY WITH WARNINGS / NOT READY

## Action Needed
- <one line per problem, with the exact command the user can run>
```

Verdict rules:

- **NOT READY** — a repo needed for the work is `MISSING` or `NOT A GIT REPO`.
- **READY WITH WARNINGS** — a repo is `DIRTY`, behind upstream, or on a `PROTECTED` branch (the last matters only before `/speckit.implement`, which refuses to modify a protected branch).
- **READY** — everything present and clean.

## Rules

- Read-only: no `git fetch`, `pull`, `checkout`, or `clean`. Offer the command; let the user run it.
- Only the repos in scope for the user's task can make the verdict `NOT READY` — a missing `Mockoon` does not block an Android-only change.
- Lean: stop after the report. Do not propose follow-up files.
