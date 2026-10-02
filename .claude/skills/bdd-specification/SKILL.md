---
name: bdd-specification
description: Methodology for writing behavior-oriented Given/When/Then acceptance criteria for Empower specs. Use when writing or reviewing the Acceptance Criteria section in /speckit.specify or /speckit.clarify, when converting PBI/PO notes into testable scenarios, or when checking that scenarios are specific, observable, testable, and free of implementation details.
---

# BDD Specification

Given/When/Then is not a formatting rule. It is a way to turn product intent into concrete, observable examples that Product, Engineering, and QA read the same way. Start from the behavior, then write the scenario.

## 1. Find the behavior first

Before writing, answer: who is the actor, what do they want, what rule governs it, what proves the rule, what happens when the rule is not met, and what is visible to the user or system observer.

Weak: `Given the user is on login / When they sign in / Then it works`.

Better:

```gherkin
Scenario: Worker signs in with valid credentials on a fresh install
  Given a registered worker has installed the app and is on the login screen
  When the worker submits a valid email and password
  Then the worker lands on the home screen
  And the worker's name is shown in the header
```

## 2. One scenario, one behavior

If a scenario has more than one `When`, or its `Then` mixes unrelated outcomes, split it. Separate scenarios for the happy path, each validation rule, each error state, and each empty/loading state.

## 3. Rules for each keyword

| Keyword | Rule |
|---|---|
| Given | State that exists before the action; business-level, not setup steps |
| When | One user or system action |
| Then | Observable outcomes only — what a user sees, hears, or a system emits |
| And / But | Continue the previous keyword; do not smuggle in a new action |

## 4. Make `Then` testable

Specific values over adjectives: "shows the error 'Invalid credentials'", not "shows an appropriate error". If the exact copy is undecided, record it under the spec's **Open Questions** instead of guessing.

## 5. No implementation details

Avoid class names, endpoints paths, view IDs, database fields, or framework terms. Describe behavior from the outside. A third-party contract detail belongs in the spec's *Third-Party Contract Impact* section, not in the scenario.

## 6. Cover what usually gets missed

For each feature, ask whether it needs a scenario for: no network / timeout, expired session, empty list, permission denied (camera, location, notifications), first launch vs. returning user, older installed app version against a changed contract, and per-brand or per-user-type differences (see `docs/product-overview.md`).

## 7. Cross-platform wording

Write scenarios platform-neutral. Add a platform tag (`@android`, `@ios`, `@mockoon`) only when behavior genuinely differs, and explain why in *Cross-Platform Consistency Notes*.

## 8. Map scenarios to validation

Each scenario ends up as one of: automated test, manual smoke step recorded in `pr-evidence.md`, or Mockoon-backed check. A scenario that cannot be validated by any of those is too vague — rewrite it. `/speckit.plan` and `/speckit.tasks` trace tasks and tests back to scenario names, so give each scenario a unique, descriptive title.

## 9. Review checklist

- [ ] Title names the behavior, not the screen
- [ ] Single `When`; `Then` is observable and specific
- [ ] No implementation terms
- [ ] Failure and edge states covered
- [ ] No duplicate of another scenario
- [ ] Unknowns are in Open Questions, not guessed
