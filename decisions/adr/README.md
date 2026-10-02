# Architecture Decision Records (ADRs)

Durable records of architecturally significant decisions, so future engineers and AI agents know *why* something was built a certain way. Implements "decisions and context must be persisted" from [`constitution/ENGINEERING-PRINCIPLES.md`](../../constitution/ENGINEERING-PRINCIPLES.md#principle-7-decisions-and-context-must-be-persisted).

## When to write one

A decision that **outlives a single PBI** — it affects more than one repo (`MyIsn.Android`, `MyIsn.iOS`, `Mockoon`) or more than one PBI. A decision scoped to one PBI stays inline in that PBI's `plan.md` (Approval Notes).

Typically produced during `/speckit.plan`, but any stage may produce one. Candidates: how a feature flag is named across platforms, a Mockoon contract convention, a shared analytics scheme.

## Naming

`decisions/adr/<NNNN>-<slug>.md` — zero-padded sequence in creation order, never reused (even if later superseded or rejected). Start from [`ADR-Template.md`](ADR-Template.md).

## Rule: never edit history

An ADR is never changed to alter what was decided. If the decision changes, write a new ADR and set the old one's status to `Superseded by <NNNN>`.

## Not here

- PBI-scoped decisions (stay in `plan.md`).
- Product source code, in any form.

## Index

None yet. The first ADR is `0001`.
