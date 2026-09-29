---
name: po-pbi-sync
description: Use this skill when the user asks to update/sync a specific PBI that's already created in Azure DevOps (isnsoftware org, ISN project) and relates to the po-functional-documentation flow — reads the work item's real history from Azure DevOps, reconciles specs/po/<feature-slug>/ against it, and only then, if explicitly asked, writes further changes back to that same work item.
---

# PO PBI Sync

Keeps `specs/po/<feature-slug>/` in sync with an **existing** Azure DevOps
work item (org `isnsoftware`, project `ISN`) — read its real history
first, reconcile the local hub artifacts against it, and only then, if the
user explicitly asks for a further change, write that change back to the
same work item.

**If the work item doesn't exist yet**, this is the wrong skill — use
`po-work-item-publish` to create it. This skill only ever updates a work
item that already has a real ID.

## When to Use

- The user names a specific Azure DevOps work item ID and asks to update
  it, sync it, or check what's changed on it, and that item is (or should
  be) tracked under `specs/po/<feature-slug>/`.
- The local draft/functional documentation may be stale relative to what's
  actually happened on the work item since it was drafted or published
  (comments, field edits, state changes).

**Not for:** creating a new work item (`po-work-item-publish`), drafting
functional documentation or first-pass work items (`po-functional-documentation`),
or any bulk/batch operation across many PBIs at once.

## Boundaries

- **Update-only.** Never call `wit_work_item_write` with `action: create`
  or `add_child`, and never call `wit_work_item_link_write` — this skill
  only ever edits fields on the one work item the user named, or adds a
  comment to it.
- Never guess which work item ID the user means — ask if it isn't given
  explicitly in the request.
- Never write anything to Azure DevOps before completing the read +
  reconcile steps below, and never write without the explicit approval
  phrase in Stage 4.
- Never silently overwrite a field that changed on the Azure DevOps side
  with stale local content, or vice versa — always show the diff and let
  the user decide which side wins per field.
- Writable fields are restricted to: Title, Description, Acceptance
  Criteria (or Repro Steps for a Bug), and Tags. Never write `State`,
  `Board Column`, `Parent`, `Iteration Path`, `Area Path`, assignment, or
  estimates — those require the user to state the exact target value in
  the same message as the approval phrase; if they don't, leave that field
  untouched and note it as an Open Question instead.
- Keep all generated/updated local content in English, regardless of the
  Azure DevOps item's own language.

## Stage 1 — Resolve

Confirm the Azure DevOps work item ID from the user's request — never
infer it from context alone. Then find the matching local feature:

1. Search `specs/po/*/ado-sync.md` and `specs/po/*/work-items/*.md` for
   that ID (in an `Azure DevOps ID:` header field).
2. If found, that feature folder is the target for Stage 3.
3. If not found, ask the user which `specs/po/<feature-slug>/` this PBI
   belongs to, or whether to treat it as a first-time import (skip Stage 3
   local reconciliation of an existing draft, and instead offer to run
   `po-functional-documentation` against this PBI's current content as a
   fresh source).

## Stage 2 — Read History (read-only)

Using the Azure DevOps MCP server, in this order, and nothing else:

1. `wit_work_item` `action: get`, the named ID, `expand: All` (fields +
   relations) — current state.
2. `wit_work_item` `action: list_comments`, the same ID — discussion
   history.
3. `wit_work_item` `action: list_revisions`, the same ID — field-change
   history, so a change that happened and was later reverted is visible,
   not just the net result.

Do not call any write tool in this stage.

## Stage 3 — Reconcile

Compare what Azure DevOps shows now against the local
`work-items/NNN-<slug>.md` (and, if the change looks functional rather
than just field bookkeeping, `functional-documentation.md`/
`work-item-list.md`). Present the diff before changing anything:

```markdown
## Sync Check: PBI <id>

| Field | Local Draft | Azure DevOps (current) | Changed? |
|---|---|---|---|

## Comments Since Last Sync

| Date | Author | Summary |
|---|---|---|

## Recommended Local Updates

- ...
```

Ask for approval before writing to local files, same as any other stage:

```
Update the local draft to match what's on Azure DevOps?
```

On approval, update `work-items/NNN-<slug>.md`'s header (`Status: Synced
from ADO`, `Last Synced: <date>`) and body fields to match, and update
`ado-sync.md` (create it from `po-work-item-publish`'s template if this
feature doesn't have one yet — `Status: Synced`). If a resolved comment
answers one of `functional-documentation.md`'s Open Questions, fold that
answer in and remove it from Open Questions, the same anti-invention-safe
way `po-functional-documentation` does.

## Stage 4 — Write Back (optional, gated)

Only if the user explicitly describes a further change to make on the
work item itself (not just the local reconciliation above) — e.g. "agora
atualiza a descrição dela com X," "adiciona um comentário dizendo Y."

Show exactly what will be written, then require the exact approval phrase:

```
About to update Azure DevOps work item <id>:

- <field>: <old value> → <new value>

Approve by replying exactly: "aprovo atualizar a PBI <id>"
```

On receiving that exact phrase:

- For a field change: `wit_work_item_write`, `action: update`, `id: <id>`,
  one `updates` entry per changed field (`path: /fields/System.Title`,
  etc.), restricted to the writable fields listed in Boundaries.
- For a comment: `wit_work_item_comment_write`, `action: add`.

After a successful write, update the local draft and `ado-sync.md` to
reflect it (`Last Action: Updated <field>` / `Commented`, today's date).
If the write fails, report the exact error and do not retry silently.

## Output Format

```markdown
# PO PBI Sync Result

## PBI

- <ID> — <Title>

## Local Files Updated

## Changes Found on Azure DevOps

## Written Back to Azure DevOps

- None, or: <field(s) updated / comment added>

## Open Questions

## Recommended Next Step
```

**Recommended Next Step — exactly one:**

- Nothing further — local files are in sync
- Confirm the field values above before I write them back
- Use `po-work-item-publish` — this ID doesn't exist in Azure DevOps yet
- Review remaining Open Questions with the PO

## References

- `po-functional-documentation` — produces the drafts this skill keeps in
  sync; this skill never runs its wizard stages itself.
- `po-work-item-publish` — the companion skill for creating a work item
  that doesn't exist yet; this skill never creates, only updates.
- No direct equivalent existed in `dti-potbelly-ai-hub` — that hub's
  `/pb-ado-publish-work-items` was create-only, with no update path back
  from Azure DevOps into the Hub. This skill fills that gap for
  empower-hub specifically.
