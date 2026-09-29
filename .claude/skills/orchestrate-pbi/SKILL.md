---
name: orchestrate-pbi
description: End-to-end orchestration for one Azure DevOps work item — fetch it, archive it, plan it, and hand off implementation to the right repo.
---

# orchestrate-pbi

Single entry point for "look at this PBI in Azure DevOps and get it done." Chains together steps that otherwise require running several commands by hand: fetch → archive → classify → specify → plan → tasks → (confirm) → implement, one repo at a time.

## Step 0 — Resolve the workspace

Read `workspace.config.json` at this hub's root and use each repo's `path` field for every `git -C` / build / file
command in this workflow. If `ls <path>` shows a repo doesn't exist, treat it as unavailable and say so rather than fabricating anything about it.

## Step 1 — Get the work item ID

Ask if not already given (e.g. "PBI 259682" or a work-item URL — extract the ID from the URL if that's what's given).

## Step 2 — Check prerequisites

```bash
az account show
```

If this fails, tell the user to run `az login` first.

## Step 3 — Fetch the work item

```bash
az boards work-item show --id <id> --org <azure_devops.org from workspace.config.json>
```

Read title, work item type, state, tags, iteration path, description, repro steps, and acceptance criteria if present. If the description is empty, say so, don't pad it with assumptions.

## Step 4 — Archive it

This always runs, whether or not the user proceeds to implementation — it's the permanent research
record.

1. Classify the item as `android/`, `ios/`, `mockoon/`, or `shared/` (cross-platform/ambiguous) using the same rule as `/pull-sprint-pbis`.
2. Write or update `specs/pbis/<platform>/<id>-<slug>/pbi.md` using the exact template defined in `/pull-sprint-pbis` Step 5 (header + Pull History table), append a row if the file already exists, never overwrite prior rows. This is the same folder Step 6 below writes `spec.md`/`plan.md`/`tasks.md` into.

## Step 5 — Confirm scope with the user

**Ask** (if not already given) which repo(s) to proceed with — don't guess silently on a cross-platform item.

## Step 6 — Run the Spec Kit planning pipeline

These are steps against the archived work item — no product code is touched yet, so run them in sequence, but **do not skip the two formal approval gates below** (`constitution/EMPOWER-HUB-CONSTITUTION.md` Section 6) — chaining commands here never bypasses a gate:

```
/speckit.specify   → specs/pbis/<platform>/<id>-<slug>/spec.md use the full fetched work item as input
/speckit.clarify   → only if the spec has Open Questions
/speckit.plan      → specs/pbis/<platform>/<id>-<slug>/plan.md, split per repo in scope
```

**Stop here — Gate 1.** `plan.md` is written with `Approval Status: Pending`. Ask the user to approve it (or ask for changes) before continuing.

```
/speckit.tasks     → specs/pbis/<platform>/<id>-<slug>/tasks.md, split per repo in scope
```

**Stop here — Gate 2.** `tasks.md` is written with `Approval Status: Pending`. Ask the user to approve it (or ask for changes) before continuing to Step 7.

## Step 7 — Hand off implementation, one repo at a time

**Stop here and get explicit confirmation before implementing anything.** This is the first step in this whole chain that touches actual product code. Do not skip that pause even if the user's original request sounded like "just do it end to end."

For the repo the user confirms first:

```
/speckit.implement <repo>
```

If scope includes a second repo, tell the user to run `/speckit.implement <other-repo>` after this one has been through `/speckit.review` — never both repos in the same invocation.

## Rules

- Never commit, push, deploy, or create a PR from this command.
- Never fabricate a work item field, iteration name, platform folder, or repo path. If `az boards work-item show` fails, or `ls <path>` shows a repo isn't present, say so and stop rather than guessing.

## Example

```
/orchestrate-pbi

PBI: 259682
```

Resolves to android (per tags), archives it to `specs/pbis/android/259682-migrate-order-details-confirmation-screen/pbi.md`, writes `specs/pbis/android/259682-migrate-order-details-confirmation-screen/{spec,plan,tasks}.md`, then stops and asks: "Ready to implement in MyIsn.Android — confirm to proceed?"
