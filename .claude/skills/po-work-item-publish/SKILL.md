---
name: po-work-item-publish
description: Use this skill when a Product Owner wants to actually create in Azure DevOps (isnsoftware org, ISN project) a work item that was already drafted and approved under specs/po/<feature-slug>/work-items/ by the po-functional-documentation skill, and does not have a real Azure DevOps ID yet. Create-only — never updates, deletes, or links an existing work item; see po-pbi-sync for that.
---

# PO Work Item Publish

Takes an approved local draft under
`specs/po/<feature-slug>/work-items/NNN-<slug>.md` (produced by the
`po-functional-documentation` skill) and **create-only** publishes it into
Azure DevOps (org `isnsoftware`, project `ISN`) — one new work item per
approved draft, never touching an item that already has a real ID.

**If the item already exists in Azure DevOps and you want to change it**,
this is the wrong skill — use `po-pbi-sync` instead. This skill only ever
creates a work item that doesn't exist yet.

## When to Use

- A PO has one or more approved drafts in `specs/po/<feature-slug>/work-items/`
  and wants them actually created in Azure DevOps, not just pasted manually.
- The draft's `## Azure DevOps Fields` table still has `TBD`/`[TBD]` values
  that need to be resolved with the PO before it's publish-ready.

**Not for:** updating, commenting on, linking, or moving a work item that
already has an ID (`po-pbi-sync`), drafting new functional documentation or
work items (`po-functional-documentation`), or any bulk/batch creation
without per-item approval.

## Boundaries

- **Create-only.** Never call `wit_work_item_write` with `action: update`
  or `update_batch`, never call `wit_work_item_link_write`, and never
  change an item's `State`/Board Column after creation — that's out of
  scope for this skill entirely, including for an item this skill itself
  just created.
- Never publish an item whose required fields are still `TBD` — Work Item
  Type, Area Path, State, and Tags are required; Iteration Path is
  required only if the team's process demands sprint assignment before
  creation.
- Never invent Area Path, Tags, Iteration Path, Target Release, Story
  Points, or Original Estimate. Every one of these must come from the PO,
  explicitly, in this run or a prior one recorded in the draft.
- Never publish more than one work item per `wit_work_item_write` call.
- Never publish an item twice — check `ado-sync.md` first (see Tracking
  below); if it already shows `Published`, stop and tell the PO instead of
  creating a duplicate.
- Requires an explicit approval phrase before the actual write — see
  Stage 3 below. A vague "sim" or "pode publicar" is not enough; ask the
  PO to use the exact phrase.
- Keep all generated/updated content in English.

## Stage 1 — Metadata Check

Read the target draft(s)' `## Azure DevOps Fields` table. For every `TBD`
in a required field, ask the PO directly — don't ask about a field that's
already filled, and don't ask about an Optional field unless the PO brings
it up:

```
This item is missing required Azure DevOps fields before it can be published:

- Area Path: TBD
- Tags: TBD

What should these be?
```

Update the draft file in place with whatever the PO provides. Leave
Optional fields (`Board Column`, `Target Release`, `Parent`, `Story
Points`, `Original Estimate`) as `TBD`/`N/A` unless the PO volunteers a
value.

## Stage 2 — Preview (default, no Azure DevOps call)

Show exactly what would be created, without calling Azure DevOps:

```markdown
## Publish Preview: <feature-slug>

| # | Title | Type | Area Path | Tags | Readiness |
|---|---|---|---|---|---|
| 1 | <title> | <type> | <area path> | <tags> | Ready / Blocked: <missing field> |
```

An item is `Ready` only when Work Item Type, Area Path, State, and Tags
are all filled (not `TBD`) — `N/A` counts as filled when the PO explicitly
confirmed it. `Blocked` items are never published in Stage 3, even if the
PO approves the batch — call out which ones are excluded and why.

## Stage 3 — Publish (create-only, gated)

Only for items marked `Ready`. Ask for explicit approval, exact phrase:

```
Approve publishing <item numbers> to Azure DevOps by replying exactly:
"aprovo publicar <item numbers>"
```

On receiving that exact phrase, for each approved item, call
`wit_work_item_write` with `action: create`, `project: ISN`, and
`fields` mapped from the draft:

| Draft field | Azure DevOps field |
|---|---|
| Title | `System.Title` |
| Work Item Type | `workItemType` parameter |
| Description / Notes / Context+Objective | `System.Description` (Markdown format) |
| Acceptance Criteria | `Microsoft.VSTS.Common.AcceptanceCriteria` (User Story/Bug) |
| Area Path | `System.AreaPath` |
| Iteration Path | `System.IterationPath` (only if provided) |
| Tags | `System.Tags` (semicolon-separated, as given) |
| State | `System.State` (defaults to `New`) |

After each successful create, update:

- The draft file's header: `Status: Published`, `Azure DevOps ID: <id>`,
  `Azure DevOps URL: <url>`.
- The feature's `README.md` Related Work Items table: `Status: Published`,
  `Link: <url>`.
- `ado-sync.md` (see Tracking below).

If a create call fails, report the exact error, mark that item `Failed` in
`ado-sync.md`, and do not retry silently — ask the PO how to proceed.

## Tracking — `ado-sync.md`

`specs/po/<feature-slug>/ado-sync.md` is the source of truth for what's
been published, shared with `po-pbi-sync`:

```markdown
# Azure DevOps Sync: <Feature Name>

| # | Draft | Azure DevOps ID | Status | Last Action | Date |
|---|---|---|---|---|---|
| 1 | work-items/001-<slug>.md | 123456 | Published | Created | <YYYY-MM-DD> |
| 2 | work-items/002-<slug>.md | — | Not Synced | — | — |
```

`Status` values: `Not Synced`, `Ready`, `Published`, `Failed`. Create this
file the first time any item in the feature is published; append/update
rows on every subsequent run rather than rewriting history.

## Output Format

```markdown
# PO Work Item Publish Result

## Feature

- <Feature Name>

## Published

| # | Title | Azure DevOps ID | Link |
|---|---|---|---|

## Blocked (not published)

| # | Title | Missing Field(s) |
|---|---|---|

## Recommended Next Step
```

**Recommended Next Step — exactly one:**

- Provide the missing field(s) for the blocked item(s) and re-run
- Nothing further — all approved items published
- Use `po-pbi-sync` if you need to change a published item

## References

- `po-functional-documentation` — produces the drafts this skill consumes;
  never publishes them itself.
- `po-pbi-sync` — the companion skill for updating a work item that
  already has an ID; this skill never updates, only creates.
- Ported from `dti-potbelly-ai-hub`'s `/pb-ado-publish-work-items`
  command + `azure-devops-work-item-publisher` agent, scoped down to
  create-only (no metadata `--prepare-metadata`/`--live-discovery` modes,
  no PI/Sprint/Team planning-folder integration) to match this hub's
  lean, single-skill pattern.
