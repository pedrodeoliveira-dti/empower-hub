---
name: speckit.clarify
description: Identify ambiguous or underspecified areas in a spec and ask up targeted questions.
---

# speckit.clarify

Read the target spec (`specs/pbis/<task-id>-<slug>/spec.md`, `specs/features/<task-id>-<slug>/spec.md`, or `specs/bugs/<task-id>-<slug>.md`).

## Step 1 — Scan for ambiguity

Check specifically for the kind of ambiguity that causes cross-platform drift:

- Acceptance criteria that don't specify whether repo they apply.
- Any Scope row left as "Possible impact" without enough detail to resolve it.
- Third-party contract changes without a stated before/after shape.
- Any Open Question already listed in the spec.
- Behavior that differs by platform (Android/iOS) without saying so.

## Step 2 — Ask up to targeted questions

Prioritize questions whose answers change the Scope section or the implementation order — not cosmetic wording questions. Use the AskUserQuestion mechanism available in this environment rather than open-ended prose questions when the answer is a bounded choice.

## Step 3 — Update the spec

Fold answers back into the spec: update Scope, Acceptance Criteria, and Third-Party Contract Impact sections directly. Remove resolved items from Open Questions; leave genuinely unresolved ones there.

## Step 4 — Report

State what changed in the spec and recommend:

```
/speckit.plan
```
