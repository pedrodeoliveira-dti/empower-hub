---
name: document-projects
description: Analyze every repo actually cloned in this hub (today: MyIsn.Android, MyIsn.iOS, Mockoon) and (re)generate docs/ and specs/ baseline context from the real code. Run after cloning a repo for the first time, after a repo has changed significantly, or whenever docs/ feels stale or empty.
---

# document-projects

Answers "look at what's actually in this folder and give me the fullest possible context in `docs/` and `specs/`." This is a **read-only investigation of the child repos** followed by writes only inside the hub's own `docs/` and `specs/` — it never edits code, config, or anything inside `MyIsn.Android/`, `MyIsn.iOS/`, or `Mockoon/`.

It is meant to be re-run over time (a new screen shipped, a new mock endpoint added, a new SDK integrated) — each run regenerates the docs listed in Step 3 from a fresh read of the code, it doesn't just append to stale ones. Since this hub isn't a git repo, there's no diff/undo for that — if the user wants to compare before/after, tell them to copy `docs/` and `specs/` aside (or `git init` the hub) before a re-run; don't do it yourself unless asked.

## Step 0 — Discover what's actually here

Read `workspace.config.json` for the repo list (`repos.<name>.path`). For each entry, confirm it's actually on disk with `ls <path>` — never write documentation for a repo that isn't present, and never silently skip one that is. If a folder exists at the hub root that looks like a product repo (has its own `.git`, `README.md`, or `CLAUDE.md`) but isn't listed in `workspace.config.json`, flag it to the user before continuing — `workspace.config.json` may be stale.

Report back to the user, in one line per repo, which ones will actually be analyzed this run.

## Step 1 — Investigate each present repo in parallel

Spawn one `Explore` agent per present repo, all in a single message (parallel, not sequential) so this stays fast. Each agent is **read-only** and must not modify anything. Give each agent this shared brief plus its repo-specific focus below:

> Investigate `<repo path>` inside this hub and report back a structured summary — not prose. Start by reading that repo's own `CLAUDE.md`, `AGENTS.md`, and `README.md` if present (and anything under its own `docs/`) — they're often already authoritative; your job is to confirm, deepen, and fill gaps from the real code, not to ignore them. Every claim you report must be traceable to a real file — name the file (e.g. "detected via `build.gradle.kts`", "detected via `Package.swift`") rather than asserting something from general knowledge of the platform. If something can't be determined, say "not found" rather than guessing.
>
> Cover, as far as the repo actually supports each:
> 1. **Tech stack** — language(s), version, framework, build system, min OS/SDK version.
> 2. **Architecture** — pattern (e.g. MVVM, Clean Architecture), module/target graph and what each module owns, DI framework if any.
> 3. **Key features/flows** — the screens/features that actually exist (from folder names, navigation graph, route tables) — not a guess at what a product like this "should" have.
> 4. **Networking / API layer** — how it talks to a backend: base URL config, how environments (local/mock/staging/prod) are switched, the HTTP client/library used, auth header handling. List the concrete endpoints it calls if findable (path + method), not just "it uses REST."
> 5. **Third-party SDKs & dependencies** — anything for analytics, crash reporting, push notifications, auth, feature flags, deep links — name the actual library and where it's initialized.
> 6. **Local storage/persistence** — what's cached/persisted on-device and where (DB, key-value store, secure storage).
> 7. **Observability** — logging setup, analytics event calls, and whether anything resembling PII/secrets/tokens appears to get logged (flag it, don't fix it).
> 8. **Design system** — colors, typography, spacing, reusable UI components, wherever theme/design tokens live in this repo.
> 9. **Testing** — test frameworks in use, how to run them, coverage thresholds if configured.
> 10. **Known gaps / TODOs** — anything the repo's own docs already flag as unfinished, deprecated, or "TBD."

Repo-specific additions:

- **`MyIsn.Android`**: read the module graph from `settings.gradle.kts` and each module's `build.gradle.kts`; identify the DI framework from actual imports (don't assume); read `docs/BEST_PRACTICES.md`, `docs/KOIN_GUIDE.md`, `docs/LOCAL_ENVIRONMENT.md`, `docs/DYNAMIC_LINKS.md` if present inside the repo and fold their content into the relevant sections above instead of just citing them.
- **`MyIsn.iOS`**: read `Empower.xcodeproj`'s scheme/target list and `StyleKit` for design tokens; check for SSL pinning config (`Info.plist` `NSPinnedDomains`) and note it under Networking; read `AGENTS.md` if present — it may hold agent-specific conventions worth folding into the architecture/testing sections.
- **`Mockoon`**: this one is the source of truth for API contracts, not app code. Parse every environment file under `mockoon-configs/` (e.g. `_base.json`, `default.json`, and the `empower/` and `mobile/` subfolders) as Mockoon environment JSON — extract, per environment file: environment name, base route/port, and every route's method + path + short description of its response shape (status code(s) and top-level response keys are enough, not a full schema dump). If a route has multiple response rules (e.g. success/error), note that. Skip build/pipeline files (`Dockerfile`, `azure-pipelines.yml`, `scripts/`) unless they reveal how an environment is selected/run.

Wait for all agents to finish before moving to Step 2 — the cross-platform docs in Step 3 need every repo's findings at once, not one at a time.

## Step 2 — Cross-platform synthesis

From the three reports, work out:

- Which flows/features exist on both `MyIsn.Android` and `MyIsn.iOS`, and where their implementations genuinely diverge (different libraries, different local storage, a feature present on one but not the other).
- Which endpoints each app actually calls, matched against what `Mockoon` actually mocks — call out any endpoint an app calls that Mockoon doesn't define (or vice versa) as a gap, don't silently drop the mismatch.
- A single design-token picture if both apps' design systems were findable — note per-platform where they diverge (e.g. a color only defined on one side) rather than merging them into one value silently.

If a repo wasn't present in Step 0, its rows in every table below get a `not cloned` note instead of being fabricated or omitted silently — the reader needs to know the gap exists.

## Step 3 — Write `docs/`

Overwrite each file below in full from what Steps 1–2 actually found (this is meant to be re-run, so stale content should not survive a fresh run). Every file should read like documentation, not like an agent transcript — synthesize, don't paste the raw per-repo reports.

- **`docs/product-overview.md`** — what the product actually is (name, purpose, primary users) as evidenced by the repos (app name, package/bundle id, onboarding/login flow found), the platforms it ships on, and the main user journeys found in Step 1.3.
- **`docs/architecture.md`** — one section per repo: tech stack, architecture pattern, module/target graph, DI. Then a short "how the pieces fit together" section: which repos are clients, which is the mock backend, how local dev points a client at Mockoon vs. a real backend (if findable).
- **`docs/cross-platform-flows.md`** — a table: flow/feature | Android | iOS | notes on divergence. Only include a flow if it was actually found in at least one platform.
- **`docs/api-contracts.md`** — one section per Mockoon environment (`default`, `empower`, `mobile`, etc.): a table of method + path + short response description, cited from the actual environment JSON file. Add a short "consumed by" note per route where Step 2 could match it to an app call; leave it blank rather than guessing when it couldn't.
- **`docs/observability.md`** — per platform: logging framework, analytics SDK + where events fire, anything Step 1.7 flagged as a possible PII/secret logging risk (call these out explicitly as risks to verify, not as confirmed bugs).
- **`docs/style-guide.md`** — colors, typography, spacing, and reusable components actually found per platform (Step 1.8). If a value couldn't be confirmed from code, mark it `TBD` in a "Known Gaps" section — never invent a hex value or type scale.

Do **not** touch `docs/release-notes.md` or `docs/lean-artifact-policy.md` in this step — those are hub-governance docs (tooling change log and file-count policy), not something derived from the product repos. If either is missing, note that as a gap in your final report instead of fabricating hub policy from app code.

## Step 4 — Write `specs/` baseline

Create (or refresh) one grounding doc per repo, so future `/speckit.*` and `/orchestrate-*` work starts from a real snapshot instead of cold:

- `specs/technical-refinement/android/current-state.md`
- `specs/technical-refinement/ios/current-state.md`
- `specs/technical-refinement/mockoon/current-state.md`

Each file:

```markdown
# <repo name> — Current State

**Snapshot date:** <today's date>
**Generated by:** /document-projects

## Tech stack
## Architecture
## Key features/flows found
## Networking / API layer
## Third-party SDKs
## Testing
## Known gaps
```

If the file already exists from a prior run, replace its content — it's a snapshot, not a history log (unlike `pbi.md`'s pull history elsewhere in this hub). Then make sure these scaffold folders exist for future PBI/feature/bug work (create with `.gitkeep` if missing, don't touch them if they already have real content): `specs/features/`, `specs/bugs/`, `specs/po/`, `specs/pbis/android/`, `specs/pbis/ios/`.

## Step 5 — Report back

Show the user a short summary: which repos were analyzed vs. skipped (and why), which `docs/` and `specs/` files were written, and the most notable gaps/risks surfaced (missing PII masking, an app endpoint with no matching Mockoon route, a design token that couldn't be confirmed, etc.). Don't dump the full file contents into the chat — the user can open the files.

## Rules

- Never modify anything inside `MyIsn.Android/`, `MyIsn.iOS/`, or `Mockoon/` — read-only there, always.
- Never fabricate a library, endpoint, color value, or architecture claim that Step 1 didn't actually find in a real file — write "not found"/`TBD` instead.
- Never silently skip a repo that's present, and never write content for one that isn't (`ls` said so in Step 0).
- Don't touch `docs/release-notes.md` or `docs/lean-artifact-policy.md` — out of scope for this skill.
- This hub isn't version-controlled today — mention that to the user once if they haven't been told, since re-running this skill overwrites the `docs/` files above with no built-in undo.
