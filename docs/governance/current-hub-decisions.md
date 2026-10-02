# Current Hub Decisions

At-a-glance ledger of the Empower hub's current governance decisions. It is
an index, not a second narrative: for the *why*, follow each link to the
owning file. Other docs link here instead of restating a rule. Keep it
concise.

## Operating Model

- The hub holds no product source code; code changes happen only in the
  child repos (`MyIsn.Android`, `MyIsn.iOS`, `Mockoon`).
- Repo paths come from `workspace.config.json`; presence is checked live
  with `ls`, never assumed.
- Hub artifacts are written in English.
- Specs, plans, tasks, and PR evidence live once, in this hub
  (`specs/<type>/<task-id>-<slug>/`).

See [`constitution/EMPOWER-HUB-CONSTITUTION.md`](../../constitution/EMPOWER-HUB-CONSTITUTION.md).

## Lean Artifacts

- One primary artifact per workflow step; ask before creating or updating
  more than 2 files; stop and ask above 5.

See [`docs/lean-artifact-policy.md`](../lean-artifact-policy.md).

## Gates

- Three formal human gates only: `plan.md` approved before
  `/speckit.tasks`, `tasks.md` approved before `/speckit.implement`,
  `Ready for PR` verdict before `/speckit.pull-request`.
- Gates apply per repo when a change spans more than one.

See [`constitution/EMPOWER-HUB-CONSTITUTION.md#6-formal-human-gates`](../../constitution/EMPOWER-HUB-CONSTITUTION.md#6-formal-human-gates).

## Cross-Repo Work

- No multi-repo edits without a plan (`/orchestrate-feature`).
- One session edits only one of `MyIsn.Android` / `MyIsn.iOS`
  (enforced by a `PreToolUse` hook); parallel platforms use parallel
  sessions.
- Branches: `feature/<task-id>-<slug>`, `bugfix/<task-id>-<slug>`.

See [`.claude/hooks/enforce-one-repo-per-session.sh`](../../.claude/hooks/enforce-one-repo-per-session.sh)
and [`README.md`](../../README.md#implementing-android-and-ios-in-parallel).

## Compatibility, Security, and Decisions

- A contract or mock change names affected consumers and states additive vs. breaking; it must keep working for older installed app versions.
- Security review is manual; the never-log list applies to hub artifacts too.
- Cross-repo decisions that outlive one PBI are ADRs; ADRs are superseded, never edited.

See [`constitution/EMPOWER-HUB-CONSTITUTION.md`](../../constitution/EMPOWER-HUB-CONSTITUTION.md) §9–§11 and [`decisions/adr/README.md`](../../decisions/adr/README.md).

## MCP and Tooling

- MCP is optional, opt-in tooling; no `speckit.*` command silently depends on it.
- Work items are fetched with the `az boards` CLI and PRs created with `az repos pr create` (after explicit confirmation), not through an MCP server.
- Azure DevOps MCP, where a product repo registers one, is for ad hoc manual queries unless the user asks for a specific run. Skills that already use it (`technical-refinement`, `po-*`, `pull-sprint-pbis`) do so only when the user invokes them.

See [`constitution/EMPOWER-HUB-CONSTITUTION.md#8-mcp-and-external-tooling-boundaries`](../../constitution/EMPOWER-HUB-CONSTITUTION.md#8-mcp-and-external-tooling-boundaries).

## Repo Scope of Commands

- `/speckit.implement`, `/speckit.validate`, and `/speckit.review` run on exactly one repo per invocation; multi-repo changes run once per repo.

See [`constitution/EMPOWER-HUB-CONSTITUTION.md`](../../constitution/EMPOWER-HUB-CONSTITUTION.md) §11.

## Code Exploration

- Check `<repo>/graphify-out/graph.json` and use `graphify query` before
  grepping a product repo.

See [`CLAUDE.md`](../../CLAUDE.md#code-exploration-in-product-repos).

## Release Notes

- New command, agent, skill, workflow, or major capability →
  entry in `docs/release-notes.md` in the same change.

See [`docs/release-notes.md`](../release-notes.md).

## Deferred Decisions

- None currently.
