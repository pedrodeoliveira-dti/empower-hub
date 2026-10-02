---
name: ios-expert
description: Use when analyzing, planning, implementing, or reviewing work that touches MyIsn.iOS. Routes a hub session to the repo's own CLAUDE.md/AGENTS.md, StyleKit design system, graphify graph and skill catalog, and to the right repo skill per task type. Methodology only; no product code.
---

# iOS Expert

A routing layer for hub sessions. `MyIsn.iOS/` holds the facts; this skill says what to read first and which repo skill to hand work to. A hub session does **not** inherit the repo's `CLAUDE.md`, `AGENTS.md` or hooks just by reading files under that path (see `CLAUDE.md` > "Code Exploration in Product Repos"), so read them explicitly. Resolve the path from `workspace.config.json` and confirm it with `ls`.

## When to use

- `/orchestrate-feature`, `/speckit.plan`, `/speckit.tasks`, `/speckit.implement` or `/speckit.review` classify iOS as affected.
- Any SwiftUI work, or mapping a design to StyleKit.
- Not for Android-only or Mockoon-only work; see `android-expert` for Android.

## Read before you act

1. `MyIsn.iOS/CLAUDE.md` - it imports `AGENTS.md` and adds Claude-specific rules (invoke `figma-implement-ios` before writing view code for a Figma spec; ask before generating tests after ViewModel changes).
2. `MyIsn.iOS/AGENTS.md` - the single source of truth: pre-work protocol (branch hygiene, `.ai-logs/`, default branch `master`), MVVM screen file layout, navigation registration (`AppRoute` + `AppRouteViewBuilder`), Swift Testing rules, SwiftLint, secrets handling.
3. `MyIsn.iOS/README.md` - onboarding and build prerequisites. The repo has no `docs/` folder.
4. Design system, only for UI work: `MyIsn.iOS/StyleKit/` (`StyleKit/Components`, `Resources/Colors.xcassets`, `Resources/Fonts`, `ShadowStyles`, `ButtonStyles`, `StyleKit.docc/StyleKit.md`), plus the hub's `docs/style-guide.md` (mandatory before UI changes).
5. Graphify: `ls MyIsn.iOS/graphify-out/graph.json`. If present, run `graphify query "<question>"` from inside the repo before grepping. If absent (true at the time of writing), explore normally.
6. Repo skill catalog: `MyIsn.iOS/.claude/skills/` (mirrored in `.github/skills/`). Re-list it, since it changes.

## Delegate to the repo skill

Mapping owned by [`speckit.implement.md`](../../commands/speckit.implement.md) Step 4; summary of the iOS side, verified against the repo's skill folders:

| Task | Skill |
|---|---|
| New screen (ViewModel, +Requests, +Alerts, View, navigation) | `screen` |
| Service from an OpenAPI/Swagger YAML | `service` |
| Feature flag (iOS only) | `feature-flag`; for both apps use `/add-cross-platform-feature-flag` |
| Implement from a Figma spec | `figma-implement-ios` |
| ViewModel unit tests | `unit-test` |
| Test fixtures | `fixture` |
| Roll a StyleKit component out over legacy call-sites | `ds-migration` |
| Audit UI pattern implementations | `component-audit` |
| Localized strings from a spreadsheet | `add-translation` |
| Stress-test a plan or design | `grill-me` |
| PR description | `pr-summary-creator` |

With no matching skill, implement by hand.

## Commands

Use only commands documented in `MyIsn.iOS/AGENTS.md` and `README.md`. The hub's mechanical gate (SwiftLint, `xcodebuild test`) lives in [`speckit.review.md`](../../commands/speckit.review.md) Stage 1; link to it rather than restating it in plans. Tests depend on the English (US) simulator language, per `AGENTS.md`.

## Rules for hub artifacts

- Name the affected area (`Empower/Screens/<Feature>`, `Networking`, `StyleKit`) and respect the MVVM and centralized-navigation conventions.
- Do not invent targets, schemes, tokens, components or commands. Anything not confirmed by the files above is an Open Question.
- Never touch `secrets.txt` or `Empower/Keys.swift`; use existing StyleKit components rather than new ad-hoc UI.
- Specs, plans and tasks live in the hub; code lives only in `MyIsn.iOS` on its own branch (see `CLAUDE.md`).
- Do not commit or push from a hub session.
