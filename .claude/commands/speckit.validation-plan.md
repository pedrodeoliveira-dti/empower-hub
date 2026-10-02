---
name: speckit.validation-plan
description: Optional stage after plan approval and before tasks — define how a high-risk change will be proven (per-repo evidence types) in validation-plan.md next to plan.md.
argument-hint: [optional task-id-slug]
allowed-tools: Read, Glob, Grep, Write, Bash(ls:*)
---

# speckit.validation-plan

A **conditional** stage between `/speckit.plan` (approved) and `/speckit.tasks`. It writes one file, `validation-plan.md`, next to `plan.md`. It is **not** a formal human gate — the hub's only gates are in [`constitution/EMPOWER-HUB-CONSTITUTION.md`](../../constitution/EMPOWER-HUB-CONSTITUTION.md#6-formal-human-gates). Findings or decisions made here are recorded inline in `validation-plan.md`.

## Step 0 — Decide whether this stage applies

Read `plan.md` and `spec.md` in the task folder (`specs/<type>/<task-id>-<slug>/`; a Bug lives in `specs/bugs/<task-id>-<slug>.md`). Run only when the change touches at least one high-risk flow:

- Login / Jumio identity verification
- ISN ID wallet (Google Wallet / Apple Wallet passes, JWTs)
- Geolocation
- Certificates
- Worker forms
- Anything that changes a third-party contract (see `docs/api-contracts.md`)

If none applies, say so in one line and point to `/speckit.tasks`. Do not create the file "just in case" — see [`docs/lean-artifact-policy.md`](../../docs/lean-artifact-policy.md).

If `plan.md` is not `Approval Status: Approved`, stop and send the user back to the plan gate.

## Step 1 — Read context

- `plan.md` (per-repo test plan, Third-Party Contract Changes, Observability Plan, Risks)
- Acceptance criteria in `spec.md`
- `docs/cross-platform-flows.md` and `docs/api-contracts.md` for the affected journey
- Resolve repo paths from `workspace.config.json`; `ls <path>` before referencing a repo. Skip repos that are not cloned or marked "No impact" in the plan.

## Step 2 — Write `validation-plan.md`

```markdown
# Validation Plan: <task-id> <title>

**Risk trigger**: <which high-risk flow from Step 0, one line>
**Status**: Draft

## Evidence Matrix
| # | Acceptance criterion / risk | Repo | Evidence type | How to run | Pass signal | Owner |
|---|---|---|---|---|---|---|

## Per-Repo Evidence
### MyIsn.Android
- Automated: unit/instrumented tests to add or rerun (name them)
- Manual smoke: device/emulator, build variant, steps
### MyIsn.iOS
- Automated: XCTest targets/schemes to add or rerun
- Manual smoke: simulator/device, build config, steps
### Mockoon
- Mock-backed checks: environment file, route(s), scenario (success / error / timeout / malformed payload)

## Third-Party Contract Checks
Before/after request-response behavior to confirm, and how (Mockoon route vs. real sandbox).

## Negative & Edge Cases
Expired session, denied permission, offline, empty/partial payload — only those relevant to this flow.

## Not Automatable
Steps that can only be proven manually or on a real device, with the reason.

## Evidence Hand-off
Evidence is collected by `/speckit.validate` into `pr-evidence.md`.
```

## Rules

- Evidence types are only: Android tests, iOS tests, manual smoke, Mockoon-backed checks. Do not invent tooling the repos do not have.
- Every acceptance criterion marked high-risk maps to at least one row. Do not restate the plan's test plan — reference it and add only what is missing.
- Do not write product code or run tests here — this command plans evidence, it does not produce it.
- Do not commit or push.

## Next command

Tell the user `validation-plan.md` is written and that they can continue with:

```
/speckit.tasks
```

`/speckit.tasks` should pick the matrix rows up as validation tasks per repo.
