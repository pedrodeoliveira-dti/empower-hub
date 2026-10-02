---
name: sync-context
description: Audit the hub for drift — docs vs. real code, and hub files vs. each other and the governance ledger — then apply only the fixes the user approves.
argument-hint: [optional focus, e.g. "governance", "docs/api-contracts.md", "Mockoon"]
allowed-tools: Read, Glob, Grep, Edit, Bash(ls:*), Bash(find:*), Bash(git -C * log:*), Bash(git -C * status:*)
---

# sync-context

Drift-control command. **Audit first: every run produces a drift report and stops. It never edits a file before the user approves.**

## What it reads

- `docs/governance/current-hub-decisions.md` — the ledger everything else is checked against
- `constitution/*.md`, `CLAUDE.md`, `README.md`
- `docs/*.md` (`product-overview`, `architecture`, `cross-platform-flows`, `api-contracts`, `observability`, `style-guide`, `features/`)
- `.claude/commands/`, `.claude/agents/` (+ `agents.md`), `.claude/skills/*/SKILL.md`, `.claude/hooks/`
- `workspace.config.json`
- Product repos (read-only, paths from `workspace.config.json`; use `graphify query` first when `<repo>/graphify-out/graph.json` exists) — only to verify `docs/` claims

If an argument is given, audit only that area.

## Audit checks

**A. Hub-internal drift**

| Check | Finding if... |
|---|---|
| Broken links / referenced files | a path in `CLAUDE.md`, `README.md`, or a doc does not exist |
| Catalog vs. disk | an agent, skill, or command exists but is missing from `agents.md` / `README.md` / `CLAUDE.md` — or listed but absent |
| Release notes | a command/agent/skill/hook exists with no `docs/release-notes.md` entry |
| Ledger vs. rules | a rule in the ledger contradicts the constitution, a command, or a hook |
| Duplicated rules | the same governance rule is restated in full in more than one file (the owning file per [`lean-artifact-policy.md`](../../docs/lean-artifact-policy.md) keeps it; others should link) |
| Workflow consistency | `CLAUDE.md` workflow steps, gate names, or branch convention differ from the `speckit.*` command files |
| Language | a hub artifact is not in English |

**B. Hub-vs-reality drift**

| Check | Finding if... |
|---|---|
| `docs/architecture.md`, `cross-platform-flows.md`, `docs/features/*` | they describe modules, screens, or flows that the product repos no longer have — or omit ones they now have |
| `docs/api-contracts.md` | an endpoint or mock contract differs from `Mockoon/mockoon-configs` or the app clients |
| `docs/style-guide.md` | tokens differ from the Android/iOS design-token files |
| `specs/technical-refinement/*/current-state.md` | older than the repo's recent commits (`git -C <path> log -1 --format=%cd`) |

Classify every finding **Stale** (says something now false) or **Incomplete** (true but missing something). Do not report stylistic differences.

## Output

```markdown
# Drift Report

## Summary
<n> findings — <n> stale, <n> incomplete. Areas audited: ...

## Findings
| # | Type | File | Evidence | Proposed fix |
|---|---|---|---|---|

## Not Checked
- <anything skipped, e.g. a repo not cloned>

## Approval Required
Reply with the finding numbers to apply (e.g. "1, 3") or "all".
```

## Applying fixes

Only after approval, and only the approved findings:

- Respect the lean limits: more than 2 files → show the file list and confirm; more than 5 → ask to split into phases.
- Fix the **owning** file; replace duplicates with a link.
- Never rewrite `constitution/` or past `docs/release-notes.md` entries automatically — report them and propose wording only.
- Documentation Update Rule applies: touch a global file only if its trigger fired.

## Rules

- Read-only on product repos. Never invent evidence — if a repo is not cloned, list it under **Not Checked**.
- Do not commit or push.
