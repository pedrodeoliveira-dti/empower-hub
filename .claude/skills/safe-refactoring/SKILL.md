---
name: safe-refactoring
description: Rules for behavior-preserving refactors in the Kotlin/Jetpack Compose (MyIsn.Android) and Swift/SwiftUI (MyIsn.iOS) repos — tests first, small steps, no contract or UI change. Use when a task restructures, cleans up, or simplifies existing code. Not for feature work or when behavior is meant to change.
---

# Safe Refactoring

A refactor changes structure, never behavior. The `code-refactor-planner` agent plans with these rules; `/speckit.implement` and `/speckit.review` hold the change to them. The target repo's own `CLAUDE.md` and conventions win over anything generic here ([`ENGINEERING-PRINCIPLES.md`](../../../constitution/ENGINEERING-PRINCIPLES.md) Principle 6).

## 1. Pin behavior before touching code

Identify what is observable: UI output, API calls and payloads, analytics events, persisted data, navigation. If existing tests do not pin it, add characterization tests first and run them green on the untouched code. No safety net, no refactor.

## 2. Small steps, always green

One mechanical move per step (extract, rename, move, inline). The repo builds, lints, and passes tests after each step, using the repo's own commands. Never mix a refactor with a fix or feature in the same step or commit; a bug found on the way becomes a separate item.

## 3. Hard no-change list

| Must not change | Because |
|---|---|
| Third-party contract (request/response shape, headers, status handling) | Older installed versions and Mockoon depend on it ([Constitution §9](../../../constitution/EMPOWER-HUB-CONSTITUTION.md#9-api-compatibility-and-client-impact)) |
| Visible UI, copy, accessibility labels | A visual change is a feature; see [`docs/style-guide.md`](../../../docs/style-guide.md) |
| Analytics event names/params, feature-flag keys | Downstream reporting and Remote Config |
| Persisted formats, keychain / secure storage keys, DB schema | Upgrades must keep reading old data |
| Public module APIs used across modules or targets | Wider blast radius than the task |

## 4. Platform notes

- **Kotlin / Compose:** keep state hoisting and recomposition behavior; do not change a composable's observable state, keys, or side-effect scope. Respect the module graph (`:app`, `:data`, `:compose`) and the DI setup as documented in the repo. Prefer migrating an area the repo already marks for migration over inventing a new pattern.
- **Swift / SwiftUI:** keep property-wrapper semantics (`@State`, `@StateObject`, `@ObservedObject`), view identity, and main-actor isolation; do not change async/threading behavior casually. Follow the repo's existing architecture and design-token layer.
- **Mockoon:** keep route paths, methods, status codes, and response shapes identical; restructuring an environment file is a refactor only if the served responses are byte-equivalent in meaning.

## 5. Stay inside scope

Touch only files the plan names. Reuse existing components over new abstractions, and delete only code proven unused (check callers, DI bindings, navigation, reflection, flag usage; use `graphify` when available). Dead-code removal that is uncertain becomes an Open Question.

## 6. Verify and record

Show real build/lint/test output. Where the tests cannot prove equivalence (UI), record a manual before/after smoke step in `pr-evidence.md`. If any behavior did change, stop: it is no longer a refactor and needs a spec.
