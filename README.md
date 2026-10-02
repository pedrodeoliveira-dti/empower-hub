# empower

Cross-platform orchestration hub for the Empower product (ISN). It holds **no application code** — it gives Claude (and whoever reads it) a single view of the whole product, and turns a work item (PBI, Feature, or Bug) into a spec, a per-repo plan, tasks, an implementation, evidence, a review, and a pull request.

The real code lives in three independent repositories, cloned as **children inside** this folder (each has its own git remote on Azure DevOps and is `.gitignore`d here):

```
empower/                # you are here (the hub)
├── Mockoon/            # mock backend (environments, routes)
├── MyIsn.Android/      # Android app (Kotlin / Jetpack Compose)
└── MyIsn.iOS/          # iOS app (Swift / SwiftUI)
```

This README is the practical guide: what exists, when to use it, and how. The rules live in [`CLAUDE.md`](CLAUDE.md) and [`constitution/`](constitution/).

**Contents**
[Quick start](#quick-start) · [Workflow at a glance](#workflow-at-a-glance) · [Which command do I use?](#which-command-do-i-use) · [Commands](#commands) · [Skills](#skills) · [Agents](#agents) · [Hooks](#hooks) · [Governance](#governance) · [Repository layout](#repository-layout) · [docs/](#docs--when-to-read-each-one) · [specs/](#specs--where-work-lives) · [Maintenance](#maintenance) · [FAQ](#frequently-asked-questions)

---

## Quick start

1. **Open this folder (`empower`) in Claude Code.** Commands, agents, skills, and hooks below are only available from here.
2. **Check [`workspace.config.json`](workspace.config.json).** It says where each repo lives on disk (paths relative to this hub). Every command reads paths from it and never hardcodes `../<repo>`. If you move a repo, edit its `path`. Whether a repo is actually cloned is checked live with `ls <path>`, never stored.
3. **Run `/validate-workspace`.** Confirms the three repos are present, on a sane branch, clean, and not behind upstream.
4. **Authenticate to Azure DevOps** if you will fetch work items: `az login` (org `isnsoftware`, project `ISN`). Skills that use the Azure DevOps MCP (`technical-refinement`, `po-*`) need that MCP server connected instead.
5. **Start work** with `/orchestrate-pbi` (you have a work item ID) or `/orchestrate-feature` (you have a free-text idea).

First time with empty `docs/` or after cloning a repo? Run `/document-projects` (see [Maintenance](#maintenance)).

---

## Workflow at a glance

```
/validate-workspace                  (optional, any time — read-only health check)
        ↓
/orchestrate-feature                 impact analysis, read-only   ─┐ or the fast path:
        ↓                                                           │ /orchestrate-pbi <id>
/speckit.specify                     spec.md                        │ runs specify → clarify → plan → tasks,
        ↓                                                           │ pausing at the gates, stopping
/speckit.clarify                     only if questions remain      ─┘ before implementation
        ↓
/speckit.plan                        plan.md, split by repo
        ⏸ GATE 1 — human approves plan.md
        ↓
/speckit.validation-plan             optional — high-risk flows only
        ↓
/speckit.tasks                       tasks.md, split by repo
        ⏸ GATE 2 — human approves tasks.md
        ↓
/speckit.implement <repo>            ONE repo per run, inside the real repo
        ↓
/speckit.validate <repo>             organize real evidence into pr-evidence.md
        ↓
/speckit.review                      mechanical → code review → spec checklist
        ⏸ GATE 3 — human sees a "Ready for PR" verdict
        ↓
/speckit.pull-request                drafts PR description, asks before creating
```

- The three gates are the hub's **only** formal human gates ([constitution §6](constitution/EMPOWER-HUB-CONSTITUTION.md#6-formal-human-gates)). Chaining commands never skips them.
- `/speckit.validation-plan` and `/speckit.validate` are *stages*, not gates.
- Specs, plans, tasks, and PR evidence live **once, here in the hub** (`specs/…`); code lives in the child repo on a `feature/<task-id>-<slug>` or `fix/<task-id>-<slug>` branch.
- Multi-repo change? Plan once, then run `implement` / `validate` / `review` **once per repo** ([constitution §11](constitution/EMPOWER-HUB-CONSTITUTION.md#11-platform-autonomy)).

---

## Which command do I use?

| I want to… | Use |
|---|---|
| Check that my three repos are ready | `/validate-workspace` |
| Take a work item from ID to a reviewed PR | `/orchestrate-pbi` → then the Spec Kit flow |
| Find PBIs in a sprint by keyword/tag | `/pull-sprint-pbis` |
| Know what a change touches before editing anything | `/orchestrate-feature` |
| Write or update a spec | `/speckit.specify` |
| Remove ambiguity from a spec | `/speckit.clarify` |
| Plan the technical work per repo | `/speckit.plan` |
| Prove a risky flow works (login, wallet, geolocation…) | `/speckit.validation-plan` |
| Break the plan into tasks | `/speckit.tasks` |
| Write the code in one repo | `/speckit.implement <repo>` |
| Gather test/smoke/screenshot evidence | `/speckit.validate <repo>` |
| Gate a change before PR | `/speckit.review` |
| Open the PR | `/speckit.pull-request` |
| Fix a broken test / tiny bug without the whole flow | `/quick-fix <repo> "<problem>"` |
| Draft a Bug for Azure DevOps from pasted context | `/bug-report` |
| Check logging, analytics, and PII masking | `/observability-review` |
| Add the same feature flag to Android *and* iOS | `/add-cross-platform-feature-flag` |
| Seed a starting direction on a PBI's platform tasks | `/technical-refinement` |
| Turn a PO brief into functional docs + work-item drafts | `/po-functional-documentation` |
| Create approved drafts in Azure DevOps | `/po-work-item-publish` |
| Sync a local PO artifact with an existing work item | `/po-pbi-sync` |
| Refresh `docs/` and baseline specs from the code | `/document-projects` |
| Detect drift in hub docs/commands | `/sync-context` |

---

## Commands

Slash commands live in `.claude/commands/`; skills that are invoked as `/<name>` are listed under [Skills](#skills). Everything produced is English.

### Fast path and discovery

#### `/orchestrate-pbi` — work item in, plan out

The main orchestrator for "look at this work item and get it done."

```
/orchestrate-pbi

PBI: <id>
```

1. Reads `workspace.config.json` for repo locations.
2. Confirms access to Azure DevOps (`az`), fetches the full work item.
3. **Archives** it at `specs/pbis/<android|ios|mockoon|shared>/<id>-<slug>/pbi.md` (always, even if you stop here).
4. Classifies the affected repos from tags/title (`[Android]`, `[iOS]`, `[Mockoon]`) — asks if ambiguous.
5. Runs `/speckit.specify` → `/speckit.clarify` (if needed) → `/speckit.plan` → `/speckit.tasks`, pausing at the plan and tasks gates.
6. **Stops and asks before implementing.** Only after you confirm does it run `/speckit.implement <repo>`, one repo at a time.

#### `/pull-sprint-pbis` — find PBIs in a sprint

```
/pull-sprint-pbis

Sprint: <sprint name or "current sprint">
Filter: <keyword or tag>
```

Resolves the exact iteration path, queries by iteration + keyword/tag, shows a table (ID, title, type, state, tags), archives every result under `specs/pbis/<platform>/<id>-<slug>/`, and offers to scaffold `spec.md` stubs for the ones you pick. Read-only against Azure DevOps. If nothing matches, it loosens the filter and tells you.

#### `/orchestrate-feature` — before touching more than one repo

Read-only cross-platform impact analysis (backed by the `product-orchestrator` agent and the `cross-platform-impact` method).

```
/orchestrate-feature

Feature: <description>
```

Returns: affected repos and why, third-party contract impact, state/observability impact, test strategy, recommended order, risks.

### The Spec Kit flow

| Command | Does | Writes |
|---|---|---|
| `/speckit.specify` | Asks work item type and ID (never invents one), determines scope (which repos), writes the spec (Summary, Story/Problem, Acceptance Criteria, Third-Party Contract Impact, Cross-Platform Notes, Out of Scope, Open Questions) | `specs/pbis/<platform>/<id>-<slug>/spec.md`, `specs/features/<id>-<slug>/spec.md`, or `specs/bugs/<id>-<slug>.md` |
| `/speckit.clarify` | Scans for ambiguity, asks a few targeted questions, folds answers back into the spec | the spec |
| `/speckit.plan` | Per-repo technical plan: cross-platform summary, per-repo plan, contract changes, observability plan, order, risks. Starts `Approval Status: Pending` | `plan.md` next to the spec |
| `/speckit.validation-plan` | *Optional.* Only for high-risk flows (login/Jumio, ISN ID wallet, geolocation, certificates, worker forms, contract changes): how the change will be proven per repo | `validation-plan.md` next to `plan.md` |
| `/speckit.tasks` | Refuses unless `plan.md` is `Approved`; produces executable tasks per repo | `tasks.md` |
| `/speckit.implement <repo>` | Refuses unless `tasks.md` is `Approved`; **one repo per run**; refuses on protected branches (`main`, `master`, `develop`, `dev`); prefers the repo's own skills (e.g. Android `create-feature-screen`, `add-api-call`; iOS `screen`, `service`) over hand-coding; reads `docs/style-guide.md` for UI work | code in the child repo; task status in `tasks.md` |
| `/speckit.validate <repo>` | Collects **real** evidence (test output, smoke steps, screenshots, Mockoon responses); anything not observed is `Not run` + a manual follow-up. Never fabricates | `pr-evidence.md` |
| `/speckit.review` | Three stages, stops at the first failure: **1** mechanical (Android `ktlintCheck detekt test assembleInternalDebug`; iOS `swiftlint --strict` + `xcodebuild test`; Mockoon JSON validity), **2** code review (`code-reviewer` lens; style-guide; hub-reference check), **3** spec & process checklist (`qa-reviewer` and, for multi-repo, `cross-platform-reviewer`). Sets the verdict | verdict in `pr-evidence.md` / chat |
| `/speckit.pull-request` | Requires a `Ready for PR` verdict (warns if missing); builds title and description from spec + evidence + the repo's own PR template; **shows the draft and asks before** calling `az repos pr create` | draft PR per changed repo |

To proceed past a gate without approval, say so explicitly; the override is recorded in the artifact's Approval Notes, never applied silently.

### Everyday shortcuts

| Command | Use |
|---|---|
| `/validate-workspace` | Read-only: each repo present? branch (flags protected)? clean/dirty? behind upstream? graphify graph present? Verdict READY / WITH WARNINGS / NOT READY. Never fetches, pulls, or checks out |
| `/quick-fix <repo> "<problem>"` | Fast lane for a broken test, simple build error, or narrow bug in **one** repo. Refuses (and redirects to `/orchestrate-pbi` or `/speckit.specify`) when it needs acceptance criteria, touches a contract/auth/CI/UI style, or the diff is large. Skips no gate because it uses none; writes no hub files |
| `/bug-report` | Turns pasted bug context (description, repro, logs, screenshots) into ONE Azure DevOps-ready Bug draft at `specs/bugs/<slug>.md`, status Draft, no invented ID. Does not touch Azure DevOps — publish with `po-work-item-publish` |
| `/observability-review <repo\|both> [scope]` | Read-only findings on logging/analytics in a diff or area: secrets/tokens in logs, PII masking, payload logging, build-variant exposure, analytics parity, crash reporting. Baseline is `docs/observability.md` |
| `/sync-context [focus]` | Drift audit. Compares hub files with each other, the decisions ledger, and `docs/` with the real code. Produces a report and **stops**; applies only findings you approve. Never rewrites the constitution or past release notes |

---

## Skills

Skills are either invoked as `/<name>` or loaded automatically when relevant. The repo-local skills of `MyIsn.Android` / `MyIsn.iOS` are separate and only appear while working under those paths.

### Orchestration and Azure DevOps

| Skill | Invoke | Use |
|---|---|---|
| `orchestrate-pbi`, `pull-sprint-pbis`, `orchestrate-feature` | `/…` | Documented under [Commands](#commands) |
| `technical-refinement` | `/technical-refinement` (give a PBI id) | Validates the PBI, finds its platform child tasks (`Mobile Task` iOS/Android, `[Mockoon]` Task), grounds each in the real code, and writes a light starting-direction template onto **each** child task. Each platform filled independently from its own code. Uses the Azure DevOps MCP |
| `document-projects` | `/document-projects` | See [Maintenance](#maintenance) |
| `add-cross-platform-feature-flag` | `/add-cross-platform-feature-flag` | Adds one feature flag to both apps by delegating to each repo's own `feature-flag` skill, keeping the Remote Config key **identical**. Single-platform flag? Use that repo's skill directly |

### Product Owner flow (before a work item exists)

| Skill | Use |
|---|---|
| `po-functional-documentation` | Interactive, approval-driven: turns a feature brief, PO notes, Figma context, or existing docs into functional documentation and Azure DevOps-ready work-item drafts under `specs/po/<feature-slug>/`. Never implements, never touches Azure DevOps |
| `po-work-item-publish` | **Create-only** publish of approved drafts from `specs/po/<feature-slug>/work-items/` into Azure DevOps (org `isnsoftware`, project `ISN`). Per-item approval; never updates, deletes, or links |
| `po-pbi-sync` | For work items that **already exist**: reads their real history, reconciles `specs/po/<feature-slug>/`, and writes back only if you explicitly ask |

PO path: `po-functional-documentation` → review → `po-work-item-publish` → (later changes) `po-pbi-sync`. Bugs found along the way: `/bug-report` → `po-work-item-publish`.

### Methodology (loaded by commands and agents; also usable directly)

| Skill | Purpose |
|---|---|
| `product-context` | Cross-platform checklist (repos, third-party contracts, observability, per-brand scope) |
| `cross-platform-impact` | Classify impact per repo, additive vs. breaking contract, older-installed-version risk, Mockoon mirroring, sequencing |
| `bdd-specification` | Write observable Given/When/Then acceptance criteria |
| `pbi-clarification` | Ask few, focused questions and close the loop by updating the spec |
| `quality-gates` | What evidence each stage needs; which flows are high-risk. Adds **no** gate |
| `qa-review` | Trace each acceptance criterion to real evidence; a passing test isn't a correct test |
| `security-review` | Manual mobile security lens (tokens/session, biometrics, Jumio/KYC, ISN ID wallet, geolocation, deep links, PII, SDKs). Never runs a scanner |
| `safe-refactoring` | Behavior-preserving refactors: tests first, small steps, no contract/UI change |
| `android-expert` / `ios-expert` | Routing layer: what to read in the repo first (its `CLAUDE.md`/`AGENTS.md`, design tokens / StyleKit, graphify graph, own skill catalog) and which repo skill to hand work to |
| `architecture-diagrams` | Mermaid flow/impact diagrams for specs, plans, and PR evidence |
| `drawio-diagram-generation` | draw.io (`mxGraphModel`) XML — only when a draw.io file is asked for |

---

## Agents

Catalog: [`.claude/agents/agents.md`](.claude/agents/agents.md). You rarely call these directly; commands delegate to them. **All are read-only** (they report or propose, never edit).

| Agent | Backs | Role |
|---|---|---|
| `product-orchestrator` | `/orchestrate-feature` | Cross-platform impact analysis |
| `code-reviewer` | `/speckit.review` stage 2 | Diff review against artifacts, repo standards, style guide, observability, contracts |
| `qa-reviewer` | `/speckit.review` stage 3 | Criteria → evidence; security considerations verified / not verified; spec drift |
| `cross-platform-reviewer` | `/speckit.review` (multi-repo) | Android vs. iOS vs. Mockoon drift: behavior, flags, contract, analytics |
| `current-state-analyzer` | `specs/technical-refinement/*/current-state.md` | How a feature is implemented today |
| `documentation-maintainer` | `/sync-context` | Deeper doc drift; proposes minimal fixes |
| `code-refactor-planner` | `safe-refactoring` | Plans a behavior-preserving refactor |

The review agents report findings only — **only `/speckit.review` sets the verdict.**

---

## Hooks

Configured in `.claude/settings.json`; scripts in `.claude/hooks/`.

| Hook | Event | What it does |
|---|---|---|
| `enforce-one-repo-per-session.sh` | `PreToolUse` (Edit/Write/MultiEdit) | Blocks a session that has started editing `MyIsn.Android` from also editing `MyIsn.iOS` (and vice-versa). Hub files are never gated. The block message names the one-time override if a task truly must switch |
| `check-upstream-updates.sh` | `SessionStart` | `git fetch origin master` in each present child repo; reports how many commits each is behind and asks whether to pull. Never pulls. Checks only `master`, not your current branch |
| `token-log-start.sh` / `token-log-stop.sh` | `UserPromptSubmit` / `Stop` | Logs per-turn token usage and a local daily budget to `.claude/token-usage/<user>.csv` (gitignored — it holds prompt snippets). Budget: `CLAUDE_TOKEN_DAILY_LIMIT` in `settings.json` (default 1,000,000). Local tracking, not Anthropic's real rate limit |

**Permissions:** `settings.json` allows read-only `ls`/`find`/`grep`/`rg` and **denies** `git -C … push|commit|reset --hard|clean`, `rm -rf`, AWS deploys, `fastlane`, and `xcrun altool|notarytool`. `settings.local.json` is your personal override and is never committed.

### Implementing Android and iOS in parallel

`/speckit.implement` touches one repo per run — a reviewability rule, not a requirement to build sequentially. For a PBI that needs both, run **two Claude Code sessions side by side**, each scoped to one platform, both reading the same approved `tasks.md`:

```
Session A:  cd MyIsn.Android  →  /speckit.implement MyIsn.Android
Session B:  cd MyIsn.iOS      →  /speckit.implement MyIsn.iOS
```

Plan and tasks are written and approved once; each session ticks off its own repo's section. `validate`, `review`, and `pull-request` then run independently per repo. The one-repo hook keeps each session out of the other's repo.

---

## Governance

Each rule has **one owning file**; everything else links to it (see [`docs/lean-artifact-policy.md`](docs/lean-artifact-policy.md)).

| Topic | Owner |
|---|---|
| Hard rules, boundaries, the 3 gates, contract/security/platform rules, amendment | [`constitution/EMPOWER-HUB-CONSTITUTION.md`](constitution/EMPOWER-HUB-CONSTITUTION.md) (§1–§12) |
| The *why*: 8 engineering principles | [`constitution/ENGINEERING-PRINCIPLES.md`](constitution/ENGINEERING-PRINCIPLES.md) |
| Current decisions at a glance (index only) | [`docs/governance/current-hub-decisions.md`](docs/governance/current-hub-decisions.md) |
| File-count limits, artifact minimalism, Lean Mode | [`docs/lean-artifact-policy.md`](docs/lean-artifact-policy.md) |
| Cross-repo architecture decisions | [`decisions/adr/`](decisions/adr/README.md) (use `ADR-Template.md`; never edit history — supersede) |
| New capability log | [`docs/release-notes.md`](docs/release-notes.md) |

**Hard rules in short** (full text in the constitution): no product code in the hub; no deploy; no commit/push/PR as a workflow side effect; no CI/CD, signing, infra, or secrets changes; artifacts in English; unknowns go to Open Questions, never guessed; product code never references the hub; never log passwords, OTPs, tokens, auth headers, payment data, secrets, or sensitive PII.

**Lean by default:** up to 2 files without asking, 2–5 with a short plan, more than 5 stop and phase it. Lean Mode phrases you can use on any command: *"Run this in lean mode…"*, *"Proposal only. Do not edit files yet."*, *"Apply only the approved minimal changes."*

**Release notes:** adding a command, agent, skill, workflow, or major capability? Add a row to `docs/release-notes.md` (Date, Functionality, Created By, Documentation link) in the same change. Skip typo/wording edits.

---

## Repository layout

```
empower/
├── CLAUDE.md                     entry point for Claude (pointers, not restatements)
├── README.md                     this guide
├── workspace.config.json         repo paths (single source of truth)
├── constitution/                 EMPOWER-HUB-CONSTITUTION.md, ENGINEERING-PRINCIPLES.md
├── decisions/adr/                ADR README + ADR-Template.md
├── docs/                         product & cross-platform reference (see below)
│   ├── governance/               current-hub-decisions.md
│   ├── features/                 one page per product feature
│   └── hub-gap-analysis.md       comparison with the Potbelly hub + what was adopted
├── specs/                        pbis/, features/, bugs/, po/, technical-refinement/
├── .claude/
│   ├── commands/                 speckit.* + validate-workspace, sync-context, quick-fix, bug-report, observability-review
│   ├── agents/                   *.agent.md + agents.md catalog
│   ├── skills/                   <name>/SKILL.md
│   ├── hooks/                    enforce-one-repo, check-upstream, token-log-*
│   └── settings.json             permissions + hooks (settings.local.json is yours, uncommitted)
├── .ai/                          LLM navigation index (repo.yaml, symbols.yaml)
├── .github/                      copilot-instructions.md, instructions/mermaid.instructions.md
├── Mockoon/  MyIsn.Android/  MyIsn.iOS/     child repos (not tracked here)
```

## docs/ — when to read each one

| File | Read it when… |
|---|---|
| `product-overview.md` | You need business context: brands, users, main journeys |
| `architecture.md` | You need the cross-platform architecture map before touching more than one repo |
| `cross-platform-flows.md` | You're on a specific flow and want Android and iOS side by side |
| `api-contracts.md` | The change touches a third-party or mock-backend contract |
| `observability.md` | The change adds/alters logs, analytics events, or any PII field |
| `style-guide.md` | **Any** UI-visible change in Android or iOS — colors, typography, spacing, components, icons, logos |
| `features/*.md` | You need a feature's behavior (login/onboarding, visits, courses/LMS, ISN ID wallet, hazard assistant, quick check, toolbox talks, and more — index in `features/README.md`) |
| `lean-artifact-policy.md` | Before creating or updating more than 2 files here |
| `governance/current-hub-decisions.md` | You want the current rules at a glance |
| `release-notes.md` | You add a new command/agent/skill/capability |
| `improvements.md` | You have an idea to improve the hub |
| `hub-gap-analysis.md` | You want to know what was adopted from the Potbelly hub and what was left out |

## specs/ — where work lives

```
specs/
├── pbis/<android|ios|mockoon|shared>/<id>-<slug>/   pbi.md (archive), spec.md, plan.md, validation-plan.md*, tasks.md, pr-evidence.md
├── features/<id>-<slug>/                            spec.md, plan.md, tasks.md, … (may decompose into PBIs)
├── bugs/<id>-<slug>.md                              single file (plan appended as ## Plan); /bug-report drafts here as <slug>.md
├── po/<feature-slug>/                               functional docs and work-item drafts (PO flow)
└── technical-refinement/<android|ios|mockoon>/      current-state.md baselines
                                                     (* optional)
```

`<id>` is the real Azure DevOps number you give — never invented. `<slug>` is a short kebab-case description of the title.

---

## Maintenance

| Task | How |
|---|---|
| Docs feel stale, or a repo was just cloned or changed a lot | `/document-projects` — read-only over the child repos; **regenerates** `docs/` and baseline `specs/technical-refinement/` from the real code (not append-only; this hub's docs have no undo beyond git), so review the diff |
| Check hub files and docs for drift | `/sync-context` (audit first, then approve fixes) |
| Added a command, agent, skill, or ADR | Add the `docs/release-notes.md` row; add it to `.claude/agents/agents.md` if an agent; extend `.ai/symbols.yaml` |
| Changed a governance rule | Edit the **owning** file only, then keep `current-hub-decisions.md` consistent |
| Code exploration in a child repo | If `<repo>/graphify-out/graph.json` exists, run `graphify query "<question>"` (or `path` / `explain`) from inside that repo before grepping. A hub session doesn't inherit a child repo's own hooks, so the hub `CLAUDE.md` asks for this explicitly |
| Mock backend | `Mockoon/` has its own README; environments are merged from `mockoon-configs/` (`scripts/merge-configs.js`) |

---

## Frequently asked questions

**Which repos are cloned here?**
`Mockoon`, `MyIsn.Android`, `MyIsn.iOS`, as folders inside this hub. Every command confirms a repo is present with `ls <path>` (resolved from `workspace.config.json`) before touching it.

**Why do specs, plans, and tasks live here instead of in the app repos?**
A cross-platform PBI has one view even when the implementation happens in two repos.

**Can `/speckit.pull-request` create the PR right away?**
No. It shows the generated title/description and asks for explicit approval before calling `az repos pr create`.

**A command refused to run. Why?**
Refusals are intentional and name what's missing: a required artifact (e.g. no `plan.md`), a missing approval (`Approval Status` not `Approved`), a protected branch, or an attempt to implement two repos in one run. Fix the cause or give an explicit override, which gets recorded.

**When do I skip the full flow?**
For a tiny, well-understood fix in one repo use `/quick-fix`. Anything needing acceptance criteria, a contract change, or UI-style change goes through the flow.

**Does the hub write product code?**
Never. Code is written only in the child repo, via `/speckit.implement` or `/quick-fix`, on a feature/fix branch. Product code must also never reference the hub.

**What if `/pull-sprint-pbis` finds nothing?**
It loosens the filter (e.g. drops a keyword) before reporting zero results, and says it did.

**Where do I put an idea for improving the hub?**
`docs/improvements.md`.
