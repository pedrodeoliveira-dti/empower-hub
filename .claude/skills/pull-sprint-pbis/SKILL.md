---
name: pull-sprint-pbis
description: Query Azure DevOps for PBIs/Bugs/Tasks matching a keyword or tag within a given sprint. Automatically archives every result as research history under specs/pbis/<platform>/<id>-<slug>/, and optionally scaffolds full spec stubs for the ones the user selects.
---

# pull-sprint-pbis

Answers the recurring question: "what are the `<keyword>` work items in `<sprint>`?". Each execution of this command **automatically archives** its results and, over time, builds a search history.

## Step 0 — Confirm inputs

Ask the user (if not already given) for:
1. **Sprint / iteration** — e.g. `Sprint 24`, or "current sprint" (resolve to the actual iteration path — see Step 2).
2. **Area Path** — only if the team uses one to split work (this hub has no confirmed Area Path convention for the ISN project yet — ask rather than guessing `WEB`/`APP`-style values).
2. **Filter** — a keyword matched against title/description and/or a tag (e.g. `Android`, `migration`, `iOS`, `Mockoon`).
3. Work item type(s) — default to `Product Backlog Item` unless the user also wants `Bug`/`Improvement`.

## Step 1 — Check prerequisites

```bash
az account show
```

If this fails, tell the user to run `az login` first.

## Step 2 — Resolve the iteration path

Org is **isnsoftware**, project is **ISN**. If the user said "current sprint" rather than a specific name, resolve it first:

```bash
az boards iteration project list --project ISN --org https://dev.azure.com/isnsoftware
```

If more than one iteration matches "current," ask the user to confirm which one. Don't guess silently.

## Step 3 — Run the WIQL query

```bash
az boards query --org https://dev.azure.com/isnsoftware --wiql "
SELECT [System.Id], [System.Title], [System.State], [System.WorkItemType], [System.Tags]
FROM WorkItems
WHERE [System.TeamProject] = 'ISN'
  AND [System.WorkItemType] IN ('Product Backlog Item')
  AND [System.IterationPath] UNDER '<resolved iteration path>'
  AND ( [System.Title] CONTAINS 'Android' OR [System.Tags] CONTAINS 'Android' )
  AND ( [System.Title] CONTAINS 'migration' OR [System.Tags] CONTAINS 'migration' )
ORDER BY [System.Id]
"
```

Adjust the `WHERE` clause to the actual filter/work-item-type the user asked for. Quote values exactly as given — don't invent tag names that weren't confirmed.

If this returns nothing, don't assume the feature doesn't exist — loosen the filter (drop one `CONTAINS` clause) and tell the user you widened it, rather than silently reporting zero results as final.

## Step 4 — Present results

```
| ID | Title | Type | State | Tags |
|---|---|---|---|---|
| 123456 | ... | PBI | Active | Android, Migration |
```

Ask the user which of these (if any) they want turned into a hub spec.

## Step 5 — Automatically archive results as research history

Run it for every result returned in Step 3, right after presenting the table, before asking anything else.

1. **Classify each work item by platform:**
   - `System.Tags` contains `Android`, or the title starts with `[Android]` → `android/`
   - `System.Tags` contains `iOS`, or the title starts with `[iOS]` → `ios/`
   - `System.Tags` contains `Mockoon`, or the title starts with `[Mockoon]` → `mockoon/`
   - Spans more than one repo, or no platform can be determined → `shared/`
   - Don't force an ambiguous item just to avoid creating a folder.

2. **Ensure the folders exist**: `specs/pbis/android/`, `.../ios/`, `.../mockoon/` and `.../shared/`

3. **Write or update one folder per work item**: `specs/pbis/<platform>/<id>-<slug>/`, containing a `pbi.md` file (`<slug>` is a short kebab-case version of the title). This is the same folder `/speckit.specify` writes `spec.md` into later — don't create a sibling folder for it. Use this template for `pbi.md`:

   ```markdown
   # [<ID>] <Title>

   - **ADO Link:** <url from the query result>
   - **Type:** <System.WorkItemType>
   - **Tags:** <System.Tags, or "—" if empty>
   - **Sprint:** Sprint <N> (`<resolved iteration path>`)
   - **Platform:** Android | iOS | Mockoon | Shared

   ## Pull history

   | Date | Filter used | State at time of pull |
   |---|---|---|
   | <today's date> | <the keyword/tag filter used this run> | <System.State> |
   ```

   - If `pbi.md` **doesn't exist yet**, create it with the header filled in and a one-row
     history table.
   - If `pbi.md` **already exists** (this PBI was pulled before), keep the existing header as-is
     (refresh Tags/Type only if they changed) and **append a new row** to the `Pull history`
     table — don't overwrite prior rows. This is what makes the folder an actual history rather
     than a snapshot.
   - Never invent a "today's date" — use the current date given in your session context.

5. **Tell the user** where things were saved, briefly (e.g. "Archived 8 items under `specs/pbis/` — 6 android, 1 ios, 1 shared"). Don't dump the full file contents unless asked.

## Step 6 — Optional: scaffold spec stubs

For each PBI the user selects, create `specs/pbis/<platform>/<id>-<slug>/spec.md` (same folder as `pbi.md` from Step 5) with just the header filled in (ID, title, ADO link, empty Scope table) — do **not** write full acceptance criteria from the work item title alone. Then tell the user to run `/speckit.specify <id>` to properly flesh it out.

## Rules

- Read-only against Azure DevOps — this command never edits or closes a work item.
- Don't fabricate iteration names, tag names, or work item results. If the query fails or returns nothing, say so plainly.
- If `az` isn't authenticated and the user doesn't want to `az login` right now, offer the alternative.
- Step 5 (archiving) always runs, even if the user doesn't end up selecting anything for Step 6.
- Never overwrite an existing `Pull history` row — always append. The archive's value is in showing how a work item's state changed across pulls over time.
