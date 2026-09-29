---
name: add-cross-platform-feature-flag
description: Add the same feature flag to both MyIsn.Android and MyIsn.iOS by invoking each platform's own feature-flag skill, keeping the Remote Config key and description identical across both. Use whenever a flag is needed on both apps for the same feature — not for a single-platform flag.
---

# add-cross-platform-feature-flag

Both `MyIsn.Android` and `MyIsn.iOS` already have their own `feature-flag` skill (`MyIsn.Android:feature-flag`, `MyIsn.iOS:feature-flag`) — each wires a flag through that repo's own Firebase Remote Config plumbing correctly on its own. This skill exists for exactly one gap: **nothing today keeps the two platforms' flag key naming in sync.** A real example already found in this codebase: the Courses/LMS v2→v3 split is the same conceptual flag on both platforms, but is named `key_learning_management_system` on Android and `lms_library` on iOS (see `docs/features/courses-lms.md`) — this skill exists to stop that pattern from happening again, not to fix that specific one (don't rename an existing shipped flag as a side effect of running this skill).

This is a thin orchestration wrapper — it does not reimplement flag wiring itself. It always delegates the actual file changes to each platform's own skill.

## Step 1 — Define the flag once, for both platforms

Ask (if not already given):
- **Purpose** — one sentence, what this flag gates.
- **Scope** — both platforms (default), or explicitly one-sided (if only one platform needs it, tell the user to just invoke that platform's own `feature-flag` skill directly instead — this skill isn't needed for a single-platform flag).
- **Remote Config key** — propose one if the user hasn't given one (short, `snake_case` or the repo's existing convention — check a couple of existing keys in each repo's own feature-flag model first, e.g. Android's `FeatureFlag.kt` / iOS's `FeatureFlags.swift`, and match whichever convention each already uses for its *own* key strings — the key can still be identical in value across both even if each repo's surrounding Kotlin/Swift identifier naming differs).

**The Remote Config key value itself must be identical on both platforms unless the user explicitly says otherwise.** If the user gives two different key names without stating a reason, stop and ask them to confirm that's intentional before proceeding — don't silently accept drift.

## Step 2 — Resolve workspace paths and confirm scope

Read `workspace.config.json`, confirm `MyIsn.Android`/`MyIsn.iOS` are present with `ls`. If a platform in scope isn't present, say so and stop for that platform rather than fabricating what its skill would have done.

## Step 3 — Android

1. Check `git -C <MyIsn.Android path> branch --show-current` — same convention as `/speckit.implement` Step 3 (a `feature/<task-id>-<slug>` or `fix/<task-id>-<slug>` branch, or confirm with the user if it doesn't match).
2. Invoke the `MyIsn.Android:feature-flag` skill, giving it the flag's purpose and the agreed Remote Config key.
3. Report what it changed (files touched) before moving to Step 4 — don't start iOS until Android's result has been shown.

## Step 4 — iOS

1. Same branch check against `<MyIsn.iOS path>`.
2. Invoke the `MyIsn.iOS:feature-flag` skill, giving it the same purpose and the **same** Remote Config key from Step 1.
3. Report what it changed.

## Step 5 — Confirm parity and summarize

```
## Cross-Platform Feature Flag: <key>

| Platform | Remote Config key | Files changed |
|---|---|---|
| MyIsn.Android | <key> | ... |
| MyIsn.iOS | <key> | ... |

Key matches across both platforms: Yes | No — <reason if intentionally different>
```

Recommend next command per repo, same as any implementation: `/speckit.review`.

## Rules

- Never invent a Remote Config key without asking — see Step 1.
- Never silently give each platform a different key name for what's meant to be the same flag.
- Never touch both repos' code without a per-repo branch check first (Steps 3.1/4.1) — this writes product code, same boundary rules as `/speckit.implement`.
- Always do Android and iOS as two separate, reported steps — never invoke both platform skills before showing the first one's result.
- If only one platform is actually in scope for this flag, don't invoke the other platform's skill at all — tell the user to use that platform's own `feature-flag` skill directly for a single-platform flag; this skill is specifically for the both-platforms case.
- This skill does not touch `/speckit.plan`/`/speckit.tasks` — if the flag is part of a larger PBI already going through the full Spec Kit pipeline, `/speckit.implement` should call this skill for the flag-adding task rather than hand-writing it (see the mapping table in `.claude/commands/speckit.implement.md`).
