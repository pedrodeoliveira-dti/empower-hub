---
name: speckit.specify
description: Create or update a cross-platform spec (PBI, Feature, or Bug).
---

# speckit.specify

Create or update a specification in this hub, scoped explicitly by which repos it affects.

## Step 1 — Determine work item type and ID

Ask the user (if not already given) for the Azure DevOps work item type (PBI / Feature / Bug) and ID. Do not invent an ID.

## Step 2 — Determine target folder

- PBI/Story → `specs/pbis/<platform>/<task-id>-<slug>/spec.md`, where `<platform>` is `android`/`ios`/`mockoon`/`shared` — reuse the folder already created by `/pull-sprint-pbis` or `/orchestrate-pbi`'s archive step if one exists for this ID; otherwise classify it the same way (Android/iOS/Mockoon tag or title prefix, else `shared` if it spans more than one repo)
- Feature (may decompose into multiple PBIs) → `specs/features/<task-id>-<slug>/spec.md`
- Bug → `specs/bugs/<task-id>-<slug>.md` (single file, no plan/tasks split)

`<slug>` is a short kebab-case description derived from the work item title, not the branch name.

## Step 3 — Determine scope (which repos)

If `/orchestrate-feature` was already run for this change, reuse its Impact Matrix. Otherwise, ask the user what repos this work item is destined for. e.g.: only Android, only iOS, both apps, or Mockoon (new/changed mock endpoints).

## Step 4 — Write the spec

Use this structure:

```markdown
# [PBI|Feature|Bug] <task-id>: <title>

**Azure DevOps**: https://dev.azure.com/isnsoftware/ISN/_workitems/edit/<task-id>
**Status**: Draft

## Summary

## User Story / Problem Statement

## Acceptance Criteria
1. ...

## Third-Party Contract Impact
(reference docs/api-contracts.md for the providers this product integrates with, and whether Mockoon's mock routes need a matching update)

## Cross-Platform Consistency Notes
(anything from docs/cross-platform-flows.md relevant here — e.g. "Android and iOS must show the
same error message for this Auth0 failure case")

## Out of Scope

## Open Questions
```

Content quality bar:
- No implementation details (languages, frameworks, specific APIs) in Acceptance Criteria — those belong in `/speckit.plan`.
- Written so a non-technical stakeholder can validate it against the Azure DevOps work item.
- Every acceptance criterion must be independently testable.

## Step 5 — Report

Tell the user the file path written, flag any Scope row marked "No impact" that they should
double check, and recommend the next command:

```
/speckit.clarify
```

if there are Open Questions, otherwise:

```
/speckit.plan
```
