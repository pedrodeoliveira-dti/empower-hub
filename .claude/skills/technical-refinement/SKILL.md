---
name: technical-refinement
description: Validate a PBI, ground it in the real iOS/Android/Mockoon code, and draft the matching platform template as a starting direction on each of its child task work items in Azure DevOps.
---

# technical-refinement

Answers "here's a PBI, refine it." Reads the PBI, finds every platform-specific child task it already has (a PBI can have a `Mobile Task` for iOS, a `Mobile Task` for Android, and/or a `[Mockoon]`-tagged `Task` — up to three), checks each platform's real code in `MyIsn.iOS`/`MyIsn.Android`/`Mockoon` for where the change actually lands, fills in the matching template per platform, and writes each one back to its own child task. This is a starting direction, not a full spec — don't over-fill it. If a PBI has children across multiple platforms, **each gets filled independently, from that platform's own codebase** — never assume they need identical content just because they came from the same PBI.

## Step 0 — Check prerequisites

This skill runs entirely through the Azure DevOps MCP tools (`mcp__Azure_DevOps__*`) — there's no separate login step. If a call fails with an auth/permission error, tell the user to reconnect the Azure DevOps MCP server rather than trying `az login`.

## Step 1 — Get the PBI

Ask if not already given (e.g. "PBI 259953" or a work-item URL — extract the ID from the URL).

Call `mcp__Azure_DevOps__wit_get_work_item` with `id: <id>`, `project: "ISN"`, `expand: "all"`. Read title, work item type, tags, description, and acceptance criteria (`Microsoft.VSTS.Common.AcceptanceCriteria`).

## Step 2 — Validate the PBI

This is the "validate" step the user asked for — don't skip straight to templating:

- If both description and acceptance criteria are empty, stop and tell the user the PBI has nothing to refine from — don't fabricate scope.
- If the PBI clearly spans something this skill doesn't cover (e.g. backend/infra with no iOS/Android/Mockoon ask), tell the user and confirm one of the three platforms is still in scope before continuing.
- Frame what's being fixed around its **root cause, not just the reported symptom** — if the PBI describes a symptom (e.g. "X row shows up when it shouldn't"), Step 4's grounding should surface the actual condition/flag causing it; if that's still unclear after grounding, say so rather than templating around the symptom alone.
- Note anything genuinely ambiguous about what changes, but don't block on minor gaps — this template is meant to be a light starting direction, not a finished spec.
- **Decide the PBI's own platform scope from its title**, the same `[iOS]`/`[Android]`/`[Mockoon]` prefix convention used everywhere in this hub:
  - Title starts with `[iOS]` → the PBI is **iOS-only**.
  - Title starts with `[Android]` → the PBI is **Android-only**.
  - Title starts with `[Mockoon]` → the PBI is **Mockoon-only** (a new/changed mock endpoint with no app-side ask yet).
  - Title has **none** of these prefixes → the PBI is **general** — it's potentially in scope for any of the three; let Step 3 discover which platforms actually have a child task rather than assuming all three.

  This sets the expectation for Step 3: a platform-specific PBI should have exactly one child task (that platform); a general PBI's platform set is whatever child tasks actually exist — don't force it to be all three.

## Step 3 — Find every platform task child

Decide each child's own platform **from the child itself**, not by copying the parent's scope wholesale — but use the Step 2 scope as the expectation to validate what you find against. Mobile and Mockoon use different work item types here: iOS/Android use the dedicated `Mobile Task` type; Mockoon has no dedicated type and rides on the generic `Task` type, so it needs an extra tag/title check to avoid picking up unrelated tasks (QA Review, design, etc. already have their own distinct types and won't match `Task` anyway, but a *generic* `Task` child could exist for something unrelated to Mockoon).

1. From the Step 1 `expand: "all"` response, read the `relations` array for entries with `rel: "System.LinkTypes.Hierarchy-Forward"` (children) and collect their IDs.
2. Call `mcp__Azure_DevOps__wit_get_work_items_batch_by_ids` with those IDs, `fields: ["System.Title", "System.WorkItemType", "System.Tags", "System.Description"]`.
3. Filter to children matching either:
   - `System.WorkItemType == "Mobile Task"` → candidate for iOS or Android.
   - `System.WorkItemType == "Task"` **and** (`System.Tags` contains `Mockoon` or title starts with `[Mockoon]`) → candidate for Mockoon. A generic `Task` with no Mockoon signal is out of scope for this skill — leave it alone.
4. For each candidate, decide its platform the same way as `/pull-sprint-pbis`/`/orchestrate-pbi`:
   - `System.Tags` contains `Android`, or title starts with `[Android]` → **Android**
   - `System.Tags` contains `iOS`, or title starts with `[iOS]` → **iOS**
   - `System.Tags` contains `Mockoon`, or title starts with `[Mockoon]` → **Mockoon**
   - None of the three → if the Step 2 PBI scope is platform-specific, inherit that platform (a child task under an `[iOS]`-only PBI is iOS by inheritance, even if the child's own title doesn't repeat the tag). If the PBI scope is general, ask the user which platform that specific child task is for — don't guess.

This gives a set of **(platform, child task id)** pairs. Each pair is refined independently through the rest of this skill; nothing below assumes there's only one or that all three platforms are present.

- Zero matching children found → tell the user, and ask which platform(s) apply (defaulting to the Step 2 scope) and whether to create the missing child task(s) before continuing — `mcp__Azure_DevOps__wit_add_child_work_items` with `workItemType: "Mobile Task"` for iOS/Android, or `workItemType: "Task"` titled `[Mockoon] ...` for Mockoon. Never create one without asking.
- **PBI scope is general but fewer platforms have a child task than the PBI's own description implies** → tell the user which platform's child task looks to be missing, and ask whether to create it before continuing — don't silently narrow a general PBI's scope just because only some children happen to exist.
- **PBI scope is platform-specific but a child task for a *different* platform also exists** → flag this to the user as unexpected before deciding whether to include it — don't silently refine a platform the PBI's own title says is out of scope.
- Two children for the *same* platform → ask the user which ID is the live one, don't pick silently.

## Step 4 — Ground each platform in its real code

For every platform in scope from Step 3, before writing anything: read `workspace.config.json` at the hub root for that platform's repo `path` (`MyIsn.iOS`, `MyIsn.Android`, or `Mockoon`), confirm it's actually cloned with `ls <path>`, and search that repo — grep for the feature/screen/module names implied by the PBI's title, description, and acceptance criteria (use the Explore agent for this if it takes more than a couple of targeted greps). The goal is to find the actual files/classes/routes the change would touch, so Step 5's subtasks name something real instead of a guess.

- **Read the full file, not just the matched grep line, before deciding it's relevant.** A one-line match can be the wrong branch of an `if`, a test fixture, or a similarly-named unrelated symbol — don't write a Subtask off a grep hit you haven't actually opened and understood.
- Follow the data flow implied by the PBI, not just the first file grep surfaces — for a UI-state bug, trace from the screen backward to whatever flag/condition actually controls the behavior, not just the first file that mentions it.
- If a repo isn't cloned (`ls` shows nothing), say so and fall back to a generic, template-level subtask for that platform rather than fabricating file names.
- Treat every platform as a fully independent investigation — what you find in `MyIsn.iOS` has no bearing on what goes into the Android child task, and neither has any bearing on Mockoon. Don't copy findings across platforms.
- **iOS grounding**: the app is a single target (`Empower/`), not a multi-module split. Screens live in `Empower/Screens/<Feature>/` as `{Name}ViewModel.swift` / `{Name}ViewModel+Requests.swift` / `{Name}ViewModel+Alerts.swift` / `Views/{Name}View.swift`; services live in `Empower/Networking/Services/`; navigation registration lives in `Empower/Shared/Environment/Navigation/AppRoute.swift` and `AppRouteViewBuilder.swift`; design tokens live in `StyleKit/`. Ground the Subtasks in whichever of these actually change.
- **Android grounding**: three Gradle modules — `:app` (Activities/Fragments/ViewModels/Navigation), `:data` (Repositories/UseCases/network layer/DTOs), `:compose` (reusable composables/feature screens/theme). Ground the Subtasks in whichever module(s) actually change.
- **Mockoon grounding**: this repo has no app code, just Mockoon environment JSON under `mockoon-configs/` (`_base.json`, `default.json`, and the `empower/`/`mobile/` subfolders). Grounding here means finding which environment file and which route(s) need adding/changing — read the actual JSON, don't guess a route shape.

## Step 5 — Fill in the matching template, per platform

The templates below (already in English — this skill only ever writes English) are what actually gets written to the child task. Module/component names (`App Module`, `Data Module`, `Compose Module`, `StyleKit`) are proper nouns and stay as-is — don't translate identifiers, file names, or code symbols, and don't reintroduce Portuguese anywhere in the written body.

Fill in each heading, only as far as the PBI's description/acceptance criteria plus the Step 4 code search actually support:

- **Task Description** — one sentence, derived from what the PBI asks for on this platform. If Step 4 grounding surfaced a genuine hard constraint (a shared file that must not be touched, a build/CI file that's out of scope), append one more sentence naming it and why — e.g. "Do not modify `<file>` — it's shared by `<other consumer>`." Don't add this sentence speculatively; only when grounding actually found the constraint.
- **Subtasks** — for iOS/Android, under each existing module heading, replace the generic `Create/Update X` bullets with the specific thing that needs to change, naming the real file/class/component found in Step 4 where possible (file/component/function-level, not implementation detail); delete a module subsection entirely if Step 4 found no evidence for it. For **Mockoon**, there's no fixed heading list — create one heading per environment file Step 4 actually found needing a change (e.g. `mockoon-configs/mobile/`), naming the real route method + path.
- **Mapped Risks / External Dependencies (Libs) / External Tools / Unit Tests / Documentation / Additional Notes** — fill only if the PBI actually mentions something relevant (e.g. a specific third-party SDK named in `docs/api-contracts.md` is touched → name it under External Tools). Otherwise **delete the whole heading and its line** from what you write — an empty section that doesn't apply shouldn't appear in the final task at all. For **Mockoon Unit Tests**, there's no automated suite — note manual validation of the environment JSON instead (see `/speckit.review`'s Mockoon stage) or delete the heading.
- **Code Examples for Implementation** — leave empty; it's for whoever picks up the task.

Keep it terse. This is a direction to start the task, not the finished implementation plan — that's what `/speckit.plan` and `/speckit.tasks` are for once real spec work begins.

### Template — iOS

```markdown
# [iOS Template]

**Task Description:**
*Explain in one sentence what should be implemented in this task.*

---

## Acceptance Criteria
- [ ] The functionality must comply with the acceptance criteria defined in the corresponding US, based on this task.
- [ ] The code must comply with established coding standards (Clean Code).

---

## Subtasks

### 1. Screens (Empower/Screens/<Feature>)
- [ ] **ViewModel:** Create/Update `<Feature>ViewModel.swift`
- [ ] **View:** Create/Update `Views/<Feature>View.swift`
- [ ] **Requests:** Create/Update `<Feature>ViewModel+Requests.swift`

### 2. Networking (Empower/Networking/Services)
- [ ] **Services:** Create/Update the specified service

### 3. Navigation (if a screen is added/removed)
- [ ] Register in `AppRoute.swift` and `AppRouteViewBuilder.swift`

### 4. StyleKit
- [ ] Create/Update design tokens or components

---

## Mapped Risks
*Is there any uncertainty/risk associated with this task?*

---

## External Dependencies (Libs)
*Specific dependencies for this functionality (if any).*

---

## External Tools
*Name any third-party SDK/tool actually touched, per docs/api-contracts.md (if any).*

---

## Unit Tests
*Consider unit tests (Swift Testing) if any.*

---

## Documentation
- [ ] Create or update the documentation related to this functionality.

---

## Additional Notes
* Links to documentation or useful resources.
* Any other relevant information.

---

## Code Examples for Implementation
```

### Template — Android

```markdown
# [Android Template]

**Task Description:**
*Explain in one sentence what should be implemented in this task.*

---

## Acceptance Criteria
- [ ] The functionality must comply with the acceptance criteria defined in the corresponding US, based on this task.
- [ ] The code must comply with established coding standards (Clean Code).

---

## Subtasks

### 1. App Module (:app)
- [ ] **ViewModel:** Create/Update File
- [ ] **Fragment/Navigation:** Create/Update File

### 2. Data Module (:data)
- [ ] **DTO:** Create/Update the DTO
- [ ] **Repository/UseCase:** Create/Update the specified function

### 3. Compose Module (:compose)
- [ ] **Composable:** Create/Update the specified screen/component

---

## Mapped Risks
*Is there any uncertainty/risk associated with this task?*

---

## External Dependencies (Libs)
*Specific dependencies for this functionality (if any).*

---

## External Tools
*Name any third-party SDK/tool actually touched, per docs/api-contracts.md (if any).*

---

## Unit Tests
*Consider unit tests (if any).*

---

## Documentation
- [ ] Create or update the documentation related to this functionality.

---

## Additional Notes
* Links to documentation or useful resources.
* Any other relevant information.

---

## Code Examples for Implementation
```

### Template — Mockoon

```markdown
# [Mockoon Template]

**Task Description:**
*Explain in one sentence what mock route(s) should be added/updated in this task.*

---

## Acceptance Criteria
- [ ] The mocked response(s) must match the shape the consuming app(s) actually expect.
- [ ] The environment JSON must be valid and load without errors in Mockoon.

---

## Subtasks

<!-- One heading per environment file actually found in Step 4 — never a fixed list, derive it fresh each time. -->
### 1. mockoon-configs/<file found in Step 4>
- [ ] **Route:** Create/Update `<METHOD> <path>`
- [ ] **Response:** Create/Update the response rule(s) (status code, body shape)

---

## Mapped Risks
*Is there any uncertainty/risk associated with this task — e.g. a shape mismatch against the real backend?*

---

## Consumed By
*Which app(s) (MyIsn.Android / MyIsn.iOS) call this route, if known from Step 4.*

---

## Documentation
- [ ] Update `docs/api-contracts.md` in this hub if the route's shape changed.

---

## Additional Notes
* Links to documentation or useful resources.
* Any other relevant information.

---

## Code Examples for Implementation
```

## Step 6 — Confirm before writing

Show the user every filled-in draft exactly as it will be written, labeled by platform and child task ID (all of them at once if there's more than one). This edits work items other people on the team see — get explicit confirmation before calling any update, same as any change visible outside this session. The user may approve one and ask for changes on another; don't write any of them until its own draft is approved.

## Step 7 — Write each one to its own child task

For each approved (platform, child task id) pair, call `mcp__Azure_DevOps__wit_update_work_item` with `id: <that child task id>` and `updates: [{ op: "replace", path: "/fields/System.Description", value: "<that platform's filled template>" }]`. Never write one platform's draft onto another platform's child task — double-check the id/platform pairing right before each call.

If a child task already has a non-empty description, ask before overwriting it — don't silently discard existing content.

## Step 8 — Archive as context for future runs

Right after a successful write in Step 7, archive what was found and written — this is what lets a later `/technical-refinement` run (on this or a related PBI) see what's already been done instead of starting cold.

For each (platform, child task id) pair just written, create `specs/technical-refinement/<platform>/<task-folder>-<id>/<slug>.md` (`<platform>` is `ios`, `android`, or `mockoon`; `<task-folder>` is `mobile-task` for iOS/Android, `task` for Mockoon, matching the actual `System.WorkItemType`; `<slug>` is a short kebab-case version of the child task's title). Use this template:

```markdown
# [<child task ID>] <child task title>

- **Parent PBI/Bug:** <parent id> — <parent title>
- **Platform:** iOS | Android | Mockoon
- **Work item type:** Mobile Task | Task
- **ADO Link:** <child task URL>
- **State at refinement time:** <state>
- **Refined on:** <today's date>

## Code grounding
<the files/classes/functions/routes found in Step 4, one bullet each, same detail level as what went into Subtasks/Unit Tests>

## Content written to the child task
<the exact English body written in Step 7, verbatim>
```

- If this file already exists (the same child task was refined before), keep the existing header as-is and append a new dated section at the bottom rather than overwriting the prior record — this folder's value is the history, same principle as `pbi.md`'s Pull History table in `/pull-sprint-pbis`.
- Never invent "today's date" — use the current date given in your session context.
- This step always runs after a real write in Step 7. It never runs on its own without a corresponding ADO update, and it's not a substitute for the Step 6 confirmation.

## Rules

- Never fabricate acceptance criteria, module names, or file-level detail the PBI and Step 4 code search don't support — remove the section/bullet entirely rather than guess or leave an unfilled placeholder in the written task.
- Never create or update a work item without the explicit confirmation in Step 6.
- Never let one platform's findings leak into another platform's draft — iOS, Android, and Mockoon are separate repos with separate answers, even for the same PBI.
- For Mockoon specifically: never reuse a route list from a previous PBI, and never invent a route shape Step 4 didn't actually find in the environment JSON.
- Don't plan an edit on a file you haven't actually read in full during Step 4 — a grep match is a lead, not evidence.
- Write the entire child task body in English — this skill never writes Portuguese into a work item, headings included.
- Don't run `/speckit.specify`/`/speckit.plan`/`/speckit.tasks` from inside this skill — this is a lighter-weight refinement pass, not the full spec pipeline. If the user wants that afterward, point them at `/orchestrate-pbi`.
