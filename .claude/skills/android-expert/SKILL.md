---
name: android-expert
description: Use when analyzing, planning, implementing, or reviewing work that touches MyIsn.Android. Routes a hub session to the repo's own CLAUDE.md, docs, design-token files, graphify graph and skill catalog, and to the right repo skill per task type. Methodology only; no product code.
---

# Android Expert

A routing layer for hub sessions. `MyIsn.Android/` holds the facts; this skill says what to read first and which repo skill to hand work to. A hub session does **not** inherit the repo's `CLAUDE.md`, rules or hooks just by reading files under that path (see `CLAUDE.md` > "Code Exploration in Product Repos"), so read them explicitly. Resolve the path from `workspace.config.json` and confirm it with `ls`.

## When to use

- `/orchestrate-feature`, `/speckit.plan`, `/speckit.tasks`, `/speckit.implement` or `/speckit.review` classify Android as affected.
- Any UI work in Compose, or mapping a design to existing tokens.
- Not for iOS-only or Mockoon-only work; see `ios-expert` for iOS.

## Read before you act

1. `MyIsn.Android/CLAUDE.md` - module graph (`:app`, `:data`, `:compose`, `build-logic/`), Repository/UseCase rules, naming, commands.
2. `MyIsn.Android/docs/` - `BEST_PRACTICES.md`, `KOIN_GUIDE.md`, `DYNAMIC_LINKS.md`, `LOCAL_ENVIRONMENT.md`, `MSAL_AUTHENTICATION_GUIDE.md`, `PIPELINE_INFO.md`. Read only those relevant to the change. There is no `docs/architecture.md` in the repo; its architecture lives in `CLAUDE.md`.
3. `MyIsn.Android/.claude/rules/*.md` (composable, viewmodel, navigation, networking, testing-*, ...) matching the files being touched. The same rules are mirrored in `.github/instructions/`.
4. Design tokens, only for UI work: `MyIsn.Android/compose/src/main/java/com/isn/empower/compose/resources/` (`IsnColors.kt`, `Typography.kt`, `Spacing.kt`, `Dimens.kt`, `Radius.kt`, `Shadows.kt`, `Theme.kt`), plus the hub's `docs/style-guide.md` (mandatory before UI changes).
5. Graphify: `ls MyIsn.Android/graphify-out/graph.json`. If present, run `graphify query "<question>"` from inside the repo before grepping. If absent (true at the time of writing), explore normally.
6. Repo skill catalog: `MyIsn.Android/.claude/skills/`. Re-list it, since it changes.

## Delegate to the repo skill

Mapping owned by [`speckit.implement.md`](../../commands/speckit.implement.md) Step 4; summary of the Android side, verified against the repo's skill folders:

| Task | Skill |
|---|---|
| New screen or feature | `create-feature-screen` |
| New endpoint | `add-api-call` |
| Repository, UseCase, Fragment-to-Compose state patterns | `android-feature-patterns` |
| Feature flag (Android only) | `feature-flag`; for both apps use `/add-cross-platform-feature-flag` |
| Implement from a Figma spec | `figma-to-compose` |
| Unit tests for changed code | `add-tests` |
| PBI validation and task templates | `technical-refinement` |
| PR description | `pr-summary-creator` |

The repo also ships agents in `MyIsn.Android/.claude/agents/` (for example `Android-PR-Reviewer`, `Android-Security-Review`) that can inform a review. With no matching skill, implement by hand.

## Commands

Use only commands documented in `MyIsn.Android/CLAUDE.md`. The hub's mechanical gate (ktlint, detekt, tests, build) lives in [`speckit.review.md`](../../commands/speckit.review.md) Stage 1; link to it rather than restating it in plans.

## Rules for hub artifacts

- Say which module a change lands in (`:app`, `:data`, `:compose`) and keep the documented dependency direction; a new module needs explicit approval.
- Do not invent module names, tokens, commands or patterns. Anything not confirmed by the files above is an Open Question.
- Use existing tokens and components; do not hardcode values when a token exists.
- Specs, plans and tasks live in the hub; code lives only in `MyIsn.Android` on its own branch (see `CLAUDE.md`).
- Do not commit or push from a hub session.
