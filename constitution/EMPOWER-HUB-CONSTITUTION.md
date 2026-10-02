# Empower' Hub Constitution

## 1. Purpose

**empower-hub** orchestrates AI-assisted engineering work across the
Empower product surface (ISN).
It holds **no product source code**. It turns an Azure DevOps work item
into a spec, a cross-platform plan, tasks, an implementation, a reviewed
result, and a draft PR — coordinating three sibling repositories rather
than replacing any of them.

Nothing here is generic engineering advice — every rule exists to make a
specific `speckit.*` command, agent, or artifact enforceable, not just
aspirational.

## 2. Repository Scope

| Repository | Platform |
|---|---|
| `MyIsn.Android` | Android |
| `MyIsn.iOS` | iOS |
| `Mockoon` | Mock backend |

Real paths come from `workspace.config.json` — never hardcode a path.
Whether a repo is actually cloned is checked live with `ls <path>`, and
never write speculative analysis about a repo that isn't present.

## 3. What the Hub Owns

- workflow orchestration (`.claude/commands/speckit.*`, `.claude/skills/`)
- durable artifacts (`specs/pbis/`, `specs/features/`, `specs/bugs/`)
- cross-platform documentation (`docs/`)
- this constitution and `ENGINEERING-PRINCIPLES.md`

The Hub does **not** own: product source code, deployment, CI/CD, secrets,
infrastructure, release approval, or a repository's own code-review
process — `/speckit.review` checks an implementation against the spec/plan/
tasks; it does not replace a repository's own review conventions.

## 4. Repository Boundary

- `/speckit.implement` may modify a product repository only when explicitly
  invoked, naming exactly one repo, and only against an approved `tasks.md`
  (see [Section 6](#6-formal-human-gates)).
- `/speckit.implement` **must not** modify a product repository on a
  protected branch. Protected branches: `main`, `master`, `develop`, `dev`.
- A repository's own `CLAUDE.md` and documentation **override hub-level
  assumptions** — read it before a repository-specific recommendation or
  change; when the two disagree, follow the repository.
- The Hub must not copy product source code into hub artifacts beyond a
  short contextual excerpt needed to explain a finding — never whole files.
- **Product code never references the hub.** No comment, string, test name,
  or doc file in `MyIsn.Android`, `MyIsn.iOS`, or `Mockoon` may cite the hub,
  `.claude`, `specs/`, `docs/` of this hub, or a hub plan/spec/task/review
  artifact. Product code must stand on its own; hub artifacts may reference
  product repositories, never the reverse. `/speckit.implement` and
  `/speckit.review` check this.

## 5. Operational Invariants

Any command or skill **must refuse to proceed** when:

- a required artifact is missing (e.g. `/speckit.tasks` asked to run
  without `plan.md`)
- a required approval is missing (e.g. `/speckit.implement` asked to run
  while `tasks.md`'s Approval Status is `Pending`) — unless the user gives
  an explicit, in-the-moment override, which gets recorded in the
  artifact's Approval Notes, never silently applied
- it would invent missing architecture, endpoints, copy, or business rules
  — the gap becomes an Open Question instead
- `/speckit.implement` would modify a protected branch
- `/speckit.pull-request` is requested without `/speckit.review` having
  returned a `Ready for PR` verdict for that repo — the user may still
  choose to proceed, but only after being warned explicitly (see
  [Section 6](#6-formal-human-gates))
- a validation result would be reported as passed without it actually
  having run (or been reported by the user) — a manual step that couldn't
  run is recorded as a manual follow-up, never faked
- product code would be written into the hub
- a command would modify CI/CD, signing, infrastructure, secrets, or
  release configuration
- a command would commit, push, deploy, or create a PR as a side effect of
  the workflow — those stay separate, explicit user actions
  (`/speckit.pull-request` drafts a description and asks before it ever
  calls `az repos pr create`)
- a command would run, invoke, or simulate an automated security scanner —
  security review here is manual, in the spec's considerations and in
  `/speckit.review`
- content would be generated in a language other than English

When a command refuses, it says so explicitly and names what's missing —
it does not fail silently or produce a degraded artifact instead.

**The Hub must not create excessive artifacts by default.** See
[`docs/lean-artifact-policy.md`](../docs/lean-artifact-policy.md).

## 6. Formal Human Gates

| Gate | Required Before | Artifact | Required Status |
|---|---|---|---|
| Plan approval | `/speckit.tasks` | `plan.md` | `Approval Status: Approved` |
| Tasks approval | `/speckit.implement` | `tasks.md` | `Approval Status: Approved` |
| Review verdict | `/speckit.pull-request` | `/speckit.review` output | `Ready for PR` |

**No other formal gates are introduced.** These three apply per repo when
a change spans more than one — approving one repo's gate never approves
another's.

A decision made outside these three gates is still recorded, inline, in
whichever artifact it actually belongs to: a scope or approach decision in
`plan.md`'s Approval Notes, a task-level decision in `tasks.md`'s Approval
Notes, a review finding or risk acceptance in `pr-evidence.md`, a spec
ambiguity resolution in the spec's Open Questions.

## 7. Third-Party Contracts, Observability, and Security

Third-party contract shape and cross-platform consistency rules live in
[`docs/api-contracts.md`](../docs/api-contracts.md) and
[`docs/cross-platform-flows.md`](../docs/cross-platform-flows.md) — not
restated here, and never fabricated here either: the concrete providers
this product integrates with are whatever `docs/api-contracts.md` actually
documents (see the `/document-projects` skill, which derives it from the
real code and from Mockoon's mocked routes). `/speckit.plan` and
`/speckit.review` must treat a breaking third-party contract change as
materially different from an additive one, and must flag it explicitly
rather than leaving it implied.

Observability conventions (logging, analytics events, PII masking) live in
[`docs/observability.md`](../docs/observability.md). Never log passwords,
OTP codes, tokens, Authorization headers, payment data, secrets, or
sensitive PII — in product code or in a hub artifact's own examples.

## 8. MCP and External Tooling Boundaries

`MyIsn.Android` and `MyIsn.iOS` each already register their own Azure
DevOps MCP server in their own `.mcp.json` (org `isnsoftware`) — this hub
does not yet have its own. If one is added at the hub root, it is
**optional, opt-in tooling** — no `speckit.*` command or skill requires or
automatically calls it. `orchestrate-pbi` and `pull-sprint-pbis` fetch
work items via the `az boards work-item show` CLI, and
`/speckit.pull-request` creates PRs via `az repos pr create` — neither
goes through an MCP server. An Azure DevOps MCP server may be used for ad
hoc, manual chat queries only, never wired into the `speckit.*` workflow
as a silent dependency.

## 9. API Compatibility and Client Impact

A change to a third-party contract, a Mockoon route, or any behavior a
mobile client depends on must name the consumers it affects: `MyIsn.Android`,
`MyIsn.iOS`, `Mockoon`, and any other consumer.

Do not assume clients can tolerate a changed response shape, status code,
error message, header, or timing. An additive change (a new optional field)
carries materially different risk from a breaking one (a removed field, a
changed status code) — `plan.md` states which it is, per
[Section 7](#7-third-party-contracts-observability-and-security).

Mobile apps have install bases on older versions that cannot be updated
instantly. A contract change must keep working for an app version that has
not updated yet, or `plan.md` must state the versioning, feature-flag, or
rollout strategy that covers it. `Mockoon` must mirror the contract the apps
will actually receive — a mock that drifts from the real contract is a
defect in the hub's own validation story.

## 10. Security and Privacy Rules

Security and privacy are considered for every change, with extra care for
authentication and session handling, tokens, identity verification and
biometrics, the ISN ID wallet, geolocation, documents and certificates,
worker forms, analytics, and any third-party integration.

The never-log list lives in [Section 7](#7-third-party-contracts-observability-and-security)
and applies identically to what a hub command writes into an artifact and to
what product code logs at runtime. Security review is manual and spec-driven
(Section 5): record verified / not verified / unable to verify, never a
guess.

## 11. Platform Autonomy

Every implementation belongs to a repo: `MyIsn.Android`, `MyIsn.iOS`, or
`Mockoon`. A change that touches more than one is planned once in the hub
(`/orchestrate-feature`) and then executed per repo.

- **Plans and specs are shared; execution is per repo.** Each repo gets its
  own tasks, implementation, review, and PR, on its own branch and schedule.
- **No fourth formal human gate.** The three gates in
  [Section 6](#6-formal-human-gates) apply per repo; approving one repo's
  gate never approves another's.
- **One session, one app repo.** A session never edits both
  `MyIsn.Android` and `MyIsn.iOS`; parallel work uses parallel sessions
  (enforced by `.claude/hooks/enforce-one-repo-per-session.sh`).
- **Repo-scoped commands take exactly one repo per run.** `/speckit.implement`,
  `/speckit.validate`, and `/speckit.review` refuse to run across several
  repos at once; a multi-repo change runs the command once per repo.
- **Cross-platform consistency is checked, not assumed** — by
  `/speckit.review` with the `cross-platform-reviewer` agent.
- **A repo ships ahead of another only when compatibility is addressed**,
  per [Section 9](#9-api-compatibility-and-client-impact).

## 12. Amendment and Precedence

This constitution and
[`ENGINEERING-PRINCIPLES.md`](ENGINEERING-PRINCIPLES.md) govern how work is
done in this hub. Changes to either should be deliberate and visible, not
silent edits made in passing during unrelated work.

- **Constitution wins over engineering principles.** If the two disagree,
  this document is authoritative.
- **Product repository documentation wins for implementation details
  inside that repository.** This constitution governs the hub's process;
  it does not override a product repository's own engineering standards or
  review requirements.
- **Hard rules are not waivable by convenience.** A command does not bypass
  a refusal condition in [Section 5](#5-operational-invariants) because
  the user is in a hurry. An explicit override of a human gate
  ([Section 6](#6-formal-human-gates)) is the one exception already built
  into the workflow, and even that gets recorded, never silently applied.

[`docs/governance/current-hub-decisions.md`](../docs/governance/current-hub-decisions.md)
is the day-to-day ledger this constitution is checked against by
`/sync-context`; a change here keeps the ledger consistent in the same pass.
Cross-repo architectural decisions that outlive one PBI are recorded as ADRs
in [`decisions/adr/`](../decisions/adr/README.md) — never edited after the
fact, only superseded.

> **Open Question:** No owner or approval authority is defined yet for
> amending this constitution or accepting ADRs. Until it is, treat any
> change to governing documents as requiring explicit sign-off from whoever
> owns the Empower hub initiative.
