# empower

Cross-platform orchestration hub for the Empower product. It holds no application code — it
exists to give Claude (and whoever reads it) a view of the whole product, while `Mockoon`,
`MyIsn.Android`, and `MyIsn.iOS` remain the real repositories, cloned as **children inside** this
folder (each its own independent repo):

```
empower/                # you are here
├── Mockoon/
├── MyIsn.Android/
└── MyIsn.iOS/
```

The full workspace rules live in [`CLAUDE.md`](CLAUDE.md). This README is the practical guide
to "how I use each thing," with real examples.

---

## Setup

1. Open this folder (`empower`) in Claude Code — this is where the commands/agents/skills
   below are available.
2. Check [`workspace.config.json`](workspace.config.json) — it's the file that says where each
   repository (`Mockoon`, `MyIsn.Android`, `MyIsn.iOS`) lives on disk. It comes filled in
   with each repo's path relative to this hub (they're cloned as folders inside it). If you move a
   repo elsewhere, edit the corresponding `path` in that file — every command/agent here reads the
   path from there, and never hardcodes a repo location blindly. Whether a repo is actually present
   is checked live with `ls <path>` at the start of every command — not tracked as a stored flag,
   so it can't drift out of sync with the disk.

---

## Map of what's here

| Folder/file | What it is |
|---|---|
| `workspace.config.json` | Real path of each repository (`Mockoon`, `MyIsn.Android`, `MyIsn.iOS`) — single source of truth for where commands should look; presence is confirmed live with `ls <path>`, not stored here |
| `constitution/` | Governing rules for this hub: hard rules (incl. the 3 formal human gates) + the why behind them. Read before any substantive work here |
| `docs/` | Product knowledge: overview, cross-platform architecture, flows, third-party API contracts, observability, design style guide, lean-artifact policy, release notes |
| `specs/` | Specs for PBIs/Features/Bugs — a single place, even when the implementation touches more than one repo (Android, iOS, mock backend) |
| `.claude/agents/` | Subagents (today: `product-orchestrator`) |
| `.claude/skills/` | Skills invoked as `/<name>` (`product-context`, `orchestrate-feature`, `orchestrate-pbi`, `pull-sprint-pbis`) |
| `.claude/commands/` | Spec Kit slash commands (`speckit.*`), described below |
| `.claude/settings.local.json` | Local permission overrides — **never committed**; may hold temporary secrets used in testing |

---

## Commands — what each one does and when to use it

### `/orchestrate-pbi` — grab a PBI/work item and run the whole flow

**This is the main orchestrator.** It's the right command for "look at this work item and
get it done":

```
/orchestrate-pbi

PBI: <id>
```

What happens, in this order:
1. Reads `workspace.config.json` to know where `Mockoon`/`MyIsn.Android`/`MyIsn.iOS` are on disk.
2. Confirms access to the work item tracker (asks for authentication if needed).
3. Fetches the full work item.
4. **Archives** the PBI under the right platform folder — same convention as `/pull-sprint-pbis`:
   `specs/pbis/<android|ios|mock|shared>/<id>-<slug>/pbi.md`. This always happens, even if
   you're not implementing it right now.
5. Automatically classifies which repository is affected (Android, iOS, Mockoon, or a combination)
   from the work item's tags/title, using the names in `workspace.config.json` — asks if it's
   ambiguous.
6. Runs the Spec Kit planning steps in sequence (no pause here, since it's file-only, no code
   touched): `/speckit.specify` → `/speckit.clarify` (if questions remain) → `/speckit.plan`
   → `/speckit.tasks`.
7. **Stops and asks before implementing.** Only after you confirm does it run
   `/speckit.implement <repo>` — which already resolves the right repo path on its own and, if
   the task matches one of that repo's specialized agents, uses that agent instead of
   implementing by hand.

If the PBI affects more than one repository, it implements one at a time — never several together
in the same call.

---

### `/pull-sprint-pbis` — pull PBIs from a sprint

To find out which PBIs match a given filter in a sprint:

```
/pull-sprint-pbis

Sprint: <sprint name>
Filter: <keyword or tag>
```

What happens:
1. Confirms you're authenticated with the work item tracker.
2. Resolves the exact iteration path — if you say "current sprint," it lists the iterations and
   identifies the active one by date.
3. Runs a query filtering by iteration + keyword/tag in the title or tags.
4. Shows a table: ID, title, type, state, tags.
5. Asks if you want to turn any item into a spec — if so, creates the skeleton at
   `specs/pbis/<platform>/<id>-<slug>/spec.md` (same folder as the archive) and recommends running
   `/speckit.specify <id>` to fill it in for real (reading the full work item description, not
   just the title).

This is read-only — it never closes, moves, or edits a work item in the tracker.

---

### `/orchestrate-feature` — before touching more than one repo

Use whenever a change might affect more than one client — Android, iOS, and/or the mock backend
(or a third-party contract more than one of them consumes). It's read-only — it doesn't implement
anything.

```
/orchestrate-feature

Feature: <description>
```

Returns: which repos are affected and why, third-party contract impact, state/observability
impact, test strategy, recommended implementation order, and risks.

---

### Spec Kit flow — from PBI to PR

For any PBI/Feature/Bug:

```
/orchestrate-feature        # (optional, but recommended if cross-platform)
      ↓
/speckit.specify            # creates specs/pbis/<platform>/<id>-<slug>/spec.md
      ↓
/speckit.clarify            # only if open questions remain
      ↓
/speckit.plan                # specs/pbis/<platform>/<id>-<slug>/plan.md — split by repo
      ↓
   ⏸ Gate 1 — a human must approve plan.md (Approval Status → Approved) before /speckit.tasks
      ↓
/speckit.tasks                # specs/pbis/<platform>/<id>-<slug>/tasks.md — split by repo
      ↓
   ⏸ Gate 2 — a human must approve tasks.md before /speckit.implement
      ↓
/speckit.implement <repo>    # implements ONE repo at a time, inside the real repo
      ↓
/speckit.review               # 3-stage gate: mechanical (lint/build/test) → code review → spec checklist
      ↓
   ⏸ Gate 3 — a human must see a "Ready for PR" verdict before /speckit.pull-request
      ↓
/speckit.pull-request          # generates PR description and asks for confirmation before creating
```

These three are this hub's only formal human gates. Chaining commands (e.g. via
`/orchestrate-pbi`) never skips them.

Specs, plans, tasks, and PR evidence always live **here in the hub**
(`specs/<type>/<id>-<slug>/`, or `specs/pbis/<platform>/<id>-<slug>/` for PBIs), even when the
code changes in `MyIsn.Android`/`MyIsn.iOS`.
The code itself lives in the origin repo, on that repo's `feature/<id>-<slug>` branch.

---

### Implementing Android and iOS in parallel

`/speckit.implement` only ever touches one repo per invocation (Rule, see above) — that's a
hub-level safety rule for reviewability, not a claim that the two platforms have to be built one
after the other. When a PBI needs both, the fastest path is **two separate Claude Code sessions
running at the same time**, each scoped to one platform, both reading the same already-approved
`tasks.md` from this hub:

```
Session A (terminal/window 1):  cd MyIsn.Android  →  /speckit.implement MyIsn.Android
Session B (terminal/window 2):  cd MyIsn.iOS      →  /speckit.implement MyIsn.iOS
```

Both sessions work off the same `specs/<type>/<id>-<slug>/{spec,plan,tasks}.md` in this hub — plan
and tasks are written once, gates are approved once, and each session just marks its own repo's
task-list section done as it goes. They don't need to coordinate beyond that; each `/speckit.review`
and `/speckit.pull-request` still runs independently per repo afterward.

A `PreToolUse` hook (`.claude/settings.json` → `.claude/hooks/enforce-one-repo-per-session.sh`)
enforces the "one repo per session" half of this mechanically: if a single session's own tool calls
start writing into both `MyIsn.Android/` and `MyIsn.iOS/`, the second repo's edit is blocked with an
explanation — this is what makes the two-session pattern above safe (each session provably never
drifts into the other's repo), not something that blocks the two sessions from running side by side.
If a task genuinely does need to switch repos inside one session, the block's message names the
exact one-time override command to run first.

---

### Upstream check on session start

A `SessionStart` hook (`.claude/settings.json` → `.claude/hooks/check-upstream-updates.sh`) runs
`git fetch origin master` in each child repo present on disk (`MyIsn.Android`, `MyIsn.iOS`,
`Mockoon`) every time a Claude Code session starts in this hub. If any repo's local `master` is
behind `origin/master`, the session is told how many commits per repo and asks whether to pull —
it never pulls automatically. This only checks the `master` branch; it doesn't know about the
branch you currently have checked out in each repo.

---

### `docs/style-guide.md` — design style guide (Android + iOS)

Design system reference (colors, typography, grid/spacing, components, icons, logos). Both apps
implement this design system.

This isn't a command — it's applied automatically whenever a task touches UI:

- `/speckit.implement` reads this file before implementing any UI-visible code.
- `/speckit.review` checks the diff against it in Stage 2 (code review) and enforces it in
  Stage 3 (spec checklist) before approving the PR.
- The `product-context` skill includes style guide compliance in its cross-platform checklist.
- This applies even to quick tasks outside the `/speckit.*` flow — any UI-visible change in
  `MyIsn.Android` or `MyIsn.iOS` must be checked against `docs/style-guide.md`.

---

## Agents

| Agent | Use |
|---|---|
| `product-orchestrator` | Runs behind `/orchestrate-feature`. Doesn't need to be called directly — it's triggered by the command. |

## Skills

`orchestrate-feature`, `orchestrate-pbi`, and `pull-sprint-pbis` are also skills (invoked as
`/<name>`) — documented in full above under **Commands**, since that's how you actually use them.
The one not covered above:

| Skill | Use |
|---|---|
| `product-context` | Cross-platform checklist (repos, third-party contracts, observability, per-brand scope). Loaded automatically when relevant; doesn't need to be invoked manually. |

---

## docs/ — when to read each one

| File | Read it when... |
|---|---|
| `docs/product-overview.md` | You need business context: users, main journeys |
| `docs/architecture.md` | You need the cross-platform architecture map before touching more than one repo |
| `docs/cross-platform-flows.md` | You're working on a specific flow and want to see what Android and iOS do side by side |
| `docs/api-contracts.md` | The change touches a third-party or mock backend contract |
| `docs/observability.md` | The change adds/alters logs, analytics events, or any field with PII |
| `docs/style-guide.md` | **Any** UI-visible change in `MyIsn.Android` or `MyIsn.iOS` — colors, typography, spacing, components, icons, logos |
| `docs/lean-artifact-policy.md` | Before creating or updating more than 2 files in this hub — this hub stays lean by default; ask first unless a broad update was explicitly requested |
| `docs/release-notes.md` | You add a new command, agent, skill, workflow, or major capability — log it here in the same change (skip for typo/wording-only edits) |

---

## Frequently asked questions

**"Which repos are cloned here?"**
`Mockoon`, `MyIsn.Android`, and `MyIsn.iOS` — all three, as folders inside this hub. Every
command still confirms a repo is actually present with `ls <path>` (resolved from
`workspace.config.json`) before touching it, rather than assuming.

**"Why do specs/plans/tasks live here instead of inside `MyIsn.Android`/`MyIsn.iOS`?"**
Because a cross-platform PBI has a single view, even when the implementation happens in two
separate repos.

**"Can I run `/speckit.pull-request` and it'll create the PR right away?"**
Not without confirming with you first. The command always shows the generated title/description
and asks for explicit approval before calling the tool that actually creates the PR.

**"What happens if `/pull-sprint-pbis` finds nothing?"**
The command loosens the filter (for example, drops one of the keywords) before reporting "zero
results" as the final answer — and tells you it loosened it.
</content>
