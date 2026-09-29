# CLAUDE.md — Empower Workspace Hub

This repo is the cross-platform orchestration hub for the Empower product. It gives orchestration, specs and a product-wide view across repositories that are cloned as **children inside** this hub folder

```
empower/
├── Mockoon/
├── MyIsn.Android/
└── MyIsn.iOS/
```

**`workspace.config.json`** is the authoritative source for every repo's real path — every command/agent here resolves paths from it instead of hardcoding `../<repo>`. Whether a repo is actually cloned is checked live with `ls <path>` — never invent output for a repo that isn't present on disk.

Read `constitution/EMPOWER-HUB-CONSTITUTION.md` and
`constitution/ENGINEERING-PRINCIPLES.md` before doing substantive work here — they are the governing rules and the why behind every `speckit.*` command and agent in this repository.

**Lean Artifact Policy**: This hub is lean by default. Prefer fewer files, shorter files, less duplication, and proposal-before-bulk-editing. Ask before creating or updating more than 2 files unless the user explicitly requested a broad update. See `docs/lean-artifact-policy.md`.

**Hub Release Notes**: Whenever a new hub command, agent, skill, workflow, or major capability is created, update `docs/release-notes.md` in the same change — Date, Functionality, Created By, and a Documentation link. Skip it for typo fixes or wording-only edits.

## Workspace Rules

- **Do not make cross-repository changes without a plan.** Run `/orchestrate-feature` before editing code in more than one repo for the same piece of work.
- Prefer small, incremental, backward-compatible changes. Additive third-party contract changes over breaking ones.

## Feature Workflow

For any feature or bug tied to a work item (PBI, Feature, or Bug), use the same convention for branch names: `feature/<task-id>-<slug>`, `bugfix/<task-id>-<slug>`:

**Fast path:** `/orchestrate-pbi <id>` automates steps 2–5, pausing for the plan- and tasks-approval gates along the way, and stopping before implementation. Use the manual steps below when there's no ID yet, or for more control.

1. `/orchestrate-feature` — cross-platform impact analysis (read-only)
2. `/speckit.specify` — write/update spec in `specs/`
3. `/speckit.clarify` — resolve ambiguity
4. `/speckit.plan` — technical plan per repo
        ⏸ human gate — approve `plan.md` before `/speckit.tasks`
5. `/speckit.tasks` — executable tasks per repo
        ⏸ human gate — approve `tasks.md` before `/speckit.implement`
6. `/speckit.implement` — implement one repo at a time
7. `/speckit.review` — lint/build/test + code review + spec checklist
        ⏸ human gate — a `Ready for PR` verdict before `/speckit.pull-request`
8. `/speckit.pull-request` — create draft PRs with auto-generated descriptions

These three gates are the hub's only formal human gates — see
`constitution/EMPOWER-HUB-CONSTITUTION.md` Section 6.

Specs, plans, tasks, and PR evidence for a feature live **once, in this hub** (`specs/<type>/<task-id>-<slug>/`). Repo-local code changes stay in their own repos and their own branches.

## Sources of Truth

Before any non-trivial analysis or change, read what's relevant:

- `docs/product-overview.md` — product (brands, users, journeys)
- `docs/architecture.md` — cross-platform architecture
- `docs/cross-platform-flows.md` — per-journey platform behaviors and third-party deps
- `docs/api-contracts.md` — third-party contracts and breaking changes
- `docs/observability.md` — logging/analytics conventions
- `docs/style-guide.md` — design system (colors, typography, spacing, components). **Mandatory** before UI changes.
- `docs/lean-artifact-policy.md` — file-count limits and artifact-minimalism rules for this hub
- `README.md` — practical walkthrough of commands/agents/skills

## Code Exploration in Product Repos

Before grepping/reading through `MyIsn.Android/` or `MyIsn.iOS/` source to answer a question or ground an implementation, check whether that repo already has a graphify knowledge graph: `ls <repo>/graphify-out/graph.json`. If it exists, run (from inside that repo) `graphify query "<question>"` — or `graphify path "<A>" "<B>"` for a relationship, `graphify explain "<concept>"` for one node — before falling back to grep/Read. It returns a scoped subgraph instead of a full grep/read pass, at a fraction of the tokens. Grep/Read are still fine once graphify has oriented you, or for line-level edits.

This matters here specifically because a hub-rooted session does **not** inherit a product repo's own `.claude/settings.json` hooks or `CLAUDE.md` instructions just because it reads files under that path — only skills are path-scoped that way. So even though each repo with a graph already reminds itself to use graphify (via `graphify claude install`), that reminder never fires from this hub session — this instruction is what makes it happen from here instead.

If a repo has no `graphify-out/graph.json` yet, this doesn't apply — explore normally.

## Available Agents

See `.claude/agents/agents.md` for the full catalog. The one to know about at this stage: **product-orchestrator** — the agent behind `/orchestrate-feature`.

## Repository Layout

| Path | Purpose |
|---|---|
| `constitution/` | Governing rules and principles |
| `docs/` | Product and cross-platform reference material |
| `specs/` | One folder per PBI/feature/bug — spec through PR evidence |
| `.claude/commands/` | The `speckit.*` slash commands |
| `.claude/agents/` | Specialized sub-agents |
| `.claude/skills/` | Orchestration and cross-platform methodology |
</content>
