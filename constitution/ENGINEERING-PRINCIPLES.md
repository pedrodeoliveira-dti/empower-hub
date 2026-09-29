# Engineering Principles

## Purpose

These principles translate
[`EMPOWER-HUB-CONSTITUTION.md`](EMPOWER-HUB-CONSTITUTION.md) into what a
`speckit.*` command actually does at each stage — not general engineering
advice. Each principle names the commands that enforce it and the
artifacts it produces or checks. Repository-specific engineering
conventions (naming, architecture, testing patterns) are **not** repeated
here — each repo's own `CLAUDE.md` owns that content; this file only
covers hub-level workflow behavior.

## Principle 1: Unknowns are recorded, not guessed

A gap in what's known is not the AI's problem to solve by inference. Every
artifact this hub produces has an Open Questions section (or, for a bug,
an equivalent note) specifically so the gap stays visible instead of being
silently papered over.

**Command application:** every `speckit.*` command.

**Artifact application:** `spec.md`'s Open Questions, `plan.md`'s Risks.

**How to apply:** when a command needs a fact it cannot confirm from the
user, the target repo's own docs, or `docs/*.md` in this hub, it records
that gap rather than inventing a plausible-sounding default.

## Principle 2: Specification before implementation

No implementation work starts in a product repository until `spec.md`
exists with acceptance criteria and explicit non-goals.

**Command application:** `/speckit.specify` (produces the spec);
`/speckit.implement` (the only command that writes product code).

**Artifact application:** `spec.md`, `plan.md`, `tasks.md`.

**How to apply:** `/speckit.implement` requires `tasks.md` to exist with
`Approval Status: Approved` (Principle 4), which requires `plan.md`
`Approved` (Principle 3), which requires `spec.md` to exist. There is no
path from an idea to product code that skips `spec.md`.

## Principle 3: Plans must be approved before tasks

A plan is a proposal until a human confirms it — `/speckit.tasks` turns it
directly into a checklist `/speckit.implement` will execute against a real
repository.

**Command application:** `/speckit.plan` (writes `plan.md` as `Approval
Status: Pending`); `/speckit.tasks` (checks the gate).

**Artifact application:** `plan.md`.

**How to apply:** `/speckit.plan` always writes `Approval Status: Pending`
on first creation, never `Approved`. `/speckit.tasks` reads that field
first; if still `Pending`, it stops and asks the user to approve `plan.md`,
or records an explicit override in `tasks.md`'s Approval Notes. A material
change to an already-approved `plan.md` resets its status back to
`Pending`.

## Principle 4: Tasks must be approved before implementation

The same reasoning one stage later: `tasks.md` is what `/speckit.implement`
actually executes, one checkbox at a time, inside a real repository.

**Command application:** `/speckit.tasks` (writes `tasks.md` as `Approval
Status: Pending`); `/speckit.implement` (checks the gate).

**Artifact application:** `tasks.md`.

**How to apply:** `/speckit.implement` reads `Approval Status` for the
named repo's task section before touching anything; if `Pending`, it stops
and asks for approval or a recorded override. Approving `plan.md` does not
implicitly approve `tasks.md` — they're independent gates.

## Principle 5: Review is against artifacts, not preference

`/speckit.review` checks an implementation against the spec, plan, and
tasks it was supposed to satisfy — not against a reviewer's (or the AI's)
personal preference for how the problem could have been solved.

**Command application:** `/speckit.review`.

**Artifact application:** `spec.md`, `plan.md`, `tasks.md`,
`pr-evidence.md`.

**How to apply:** every acceptance criterion in `spec.md` traces to
evidence in `pr-evidence.md`; every task in `tasks.md` is marked done; any
🔴 Must Fix finding blocks the `Ready for PR` verdict (Gate 3) — see
[`EMPOWER-HUB-CONSTITUTION.md` Section 6](EMPOWER-HUB-CONSTITUTION.md#6-formal-human-gates).

## Principle 6: Repository conventions override hub assumptions

Anything this hub says about a repository (its `CLAUDE.md`, `docs/`,
`.claude/agents/product-orchestrator.agent.md`) is a snapshot — useful as a
starting point, dangerous as a substitute for reading the real thing.

**Command application:** `/speckit.plan`, `/speckit.tasks`,
`/speckit.implement`, `/speckit.review`, `/orchestrate-feature`,
`/orchestrate-pbi`.

**How to apply:** before a repository-specific recommendation or code
change, read that repository's own `CLAUDE.md` this session — don't rely
on what a hub doc said about it last time. When the two disagree, the
repository's own documentation wins.

## Principle 7: Decisions and context must be persisted

A decision that only exists in a chat transcript is a decision that will
be lost.

**Command application:** every `speckit.*` command; `/orchestrate-feature`;
`/orchestrate-pbi`.

**Artifact application:** `spec.md`, `plan.md`'s Approval Notes,
`pr-evidence.md`, `specs/pbis/<platform>/<id>-<slug>/pbi.md` archives.

**How to apply:** a scope cut or ambiguity resolution goes in `spec.md`'s
Open Questions or the spec itself; a plan- or task-level decision goes in
that artifact's Approval Notes; a review finding or risk acceptance goes in
`pr-evidence.md`. Chat-only decisions don't count as far as the next stage
is concerned.

## Principle 8: Prefer reviewable artifacts over exhaustive artifacts

A smaller, accurate document is better than a large, duplicated one. This
hub is lean by default.

**Command application:** every `speckit.*` command.

**Artifact application:** every hub artifact; see
[`docs/lean-artifact-policy.md`](../docs/lean-artifact-policy.md) for
file-count limits and duplication rules.

**How to apply:** one primary artifact per workflow step by default; ask
before creating or updating more than 2 files; stop and propose phases
before touching more than 5.

## Command Enforcement References

| Principle | Enforced By | Main Artifacts |
|---|---|---|
| 1. Unknowns are recorded, not guessed | every `speckit.*` command | Open Questions / Risks sections |
| 2. Specification before implementation | `/speckit.specify`, `/speckit.implement` | `spec.md`, `tasks.md` |
| 3. Plans must be approved before tasks | `/speckit.plan`, `/speckit.tasks` | `plan.md` |
| 4. Tasks must be approved before implementation | `/speckit.tasks`, `/speckit.implement` | `tasks.md` |
| 5. Review is against artifacts, not preference | `/speckit.review` | `pr-evidence.md` |
| 6. Repository conventions override hub assumptions | `/speckit.plan`, `/speckit.tasks`, `/speckit.implement`, `/speckit.review` | repo `CLAUDE.md` |
| 7. Decisions and context must be persisted | every `speckit.*` command | `spec.md`, `plan.md`, `pr-evidence.md` |
| 8. Prefer reviewable artifacts over exhaustive artifacts | every `speckit.*` command | `docs/lean-artifact-policy.md` |
