---
name: speckit.pull-request
description: Create draft Azure DevOps PRs for every changed repo, linked to the ADO work item.
---

# speckit.pull-request

**Always confirm with the user before actually calling the PR-creation tool** — generating the description and showing it for approval first is not optional, even if `/speckit.review` returned "Ready for PR".

## Step 1 — Resolve repo paths and detect changed repos

Skip a repo if its branch is not `feature/<task-id>-...`. Check whether it has a feature/fix branch with real changes. e.g.:

```bash
git -C <resolved MyIsn.Android path> rev-parse --abbrev-ref HEAD
```

## Step 2 — Pre-conditions per repo (Gate 3)

Confirm `/speckit.review` was run and returned **Ready for PR** for this repo — this is the hub's Gate 3 (`constitution/EMPOWER-HUB-CONSTITUTION.md` Section 6). If not, warn the user and ask whether to proceed anyway — don't refuse outright, but don't proceed silently either. If the user says to proceed anyway, record that override explicitly in the PR description generated in Step 4 rather than presenting it as a clean pass.

## Step 3 — Collect inputs

- Spec: `specs/<type>/<task-id>-<slug>/spec.md`
- Evidence: `specs/<type>/<task-id>-<slug>/pr-evidence.md`
- Repo's own template (if exists): `<resolved repo path>/.azuredevops/pull_request_template.md`

## Step 4 — Generate PR description per repo

Fill the description and the checklist covering acceptance criteria/TestCase/lint/tests/SonarQube/design/accessibility. Don't leave template checkboxes unchecked if the evidence shows they're actually done.

Title format: `#<task-id> <concise imperative description>`.

## Step 5 — Show the draft to the user first

Print the generated title + description for each repo and ask for explicit confirmation before creating anything remotely.

## Step 6 — Create the PR (only after confirmation)

Use the Azure DevOps CLI (`az repos pr create`), authenticated via `az login` (no PAT needed). Run it from inside the target repo's working directory (`cd <resolved repo path>`) so `--org` and `--project` can be picked up from git config, or pass them explicitly.

```bash
az repos pr create \
  --org https://dev.azure.com/isnsoftware/ \
  --project ISN \
  --repository <MyIsn.Android|MyIsn.iOS|Mockoon> \
  --source-branch <current branch on the target repo> \
  --target-branch <that branch's actual parent, usually master — confirm from `git -C <resolved repo path> log`> \
  --title "#<task-id> <concise imperative description>" \
  --description "<line 1>" "<line 2>" \
  --work-items <task-id> \
  --draft true
```

Key flags for this workflow:

- `--draft true` — always, per the rule below; never pass `--draft false`.
- `--source-branch` / `-s` and `--target-branch` / `-t` — resolved per Step 1/6 above.
- `--work-items` — space-separated ADO work item IDs to link (covers the "link work item" step below, so a separate linking call usually isn't needed).
- `--description` / `-d` — each argument becomes its own line; pass the generated description broken into logical lines/paragraphs rather than one giant string.
- `--repository` / `-r` — `MyIsn.Android`, `MyIsn.iOS`, or `Mockoon`, matching the repo this PR is for.

## Step 7 — Summary

```
| Repo | Branch | PR URL | Work Item Linked |
|---|---|---|---|
| MyIsn.Android | feature/... | ... | ... |
| MyIsn.iOS | feature/... | ... | ... |
| Mockoon | feature/... | ... | ... |
```

## Failure handling

- Branch not pushed to origin yet: tell the user to `git push -u origin <branch>` first — do not push on their behalf without being asked.
- `pr-evidence.md` missing or incomplete: create the PR description anyway but flag it explicitly as missing evidence, both to the user and inside the PR description.
- `az` CLI not installed, not logged in (`az login`), or missing the `azure-devops` extension (`az extension add --name azure-devops`): report that PR creation for that repo must be done manually, and hand over the generated title/description text.

## Rules

- Never push, merge, or mark a PR non-draft on the user's behalf.
- Never create a PR without showing the description and getting explicit confirmation first.
