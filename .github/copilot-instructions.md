# Copilot Instructions - Empower Hub

## What this repo is

The cross-platform orchestration hub for the Empower product: specs, plans, tasks, PR evidence, decisions and product-wide docs. The product repositories are cloned as children inside this folder: `MyIsn.Android/`, `MyIsn.iOS/` and `Mockoon/`. There is no backend or web app. Real paths come from `workspace.config.json`.

## Read first

1. `CLAUDE.md` - workspace rules, feature workflow, sources of truth.
2. `constitution/EMPOWER-HUB-CONSTITUTION.md` and `constitution/ENGINEERING-PRINCIPLES.md` - the governing rules.
3. `docs/lean-artifact-policy.md` - lean by default: fewer, shorter files; ask before touching more than 2 files.
4. `docs/style-guide.md` - mandatory before any UI-related work.

Workflow commands live in `.claude/commands/` (`speckit.*`) and methodology in `.claude/skills/`. Follow them rather than improvising a process.

## Ground rules

- **No product source code in the hub.** Code changes happen inside the child repo, on its own branch, following that repo's own guidance (`MyIsn.Android/CLAUDE.md`, `MyIsn.iOS/AGENTS.md`, `Mockoon/.github/copilot-instructions.md`).
- **English only** for all hub artifacts.
- Do not make cross-repository changes without a plan.
- Never invent module names, commands, endpoints or components; verify against the files on disk and record unknowns as open questions.
- Do not commit, push or deploy unless asked.
- Diagrams use Mermaid; see `.github/instructions/mermaid.instructions.md`.

## Where things live

| Path | Purpose |
|---|---|
| `specs/<type>/<task-id>-<slug>/` | Spec, plan, tasks and PR evidence for one work item |
| `decisions/adr/` | Cross-repo architecture decisions |
| `docs/` | Product and cross-platform reference |
| `.claude/skills/` | `android-expert` and `ios-expert` route to each child repo's own docs and skills |
