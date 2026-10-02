---
name: speckit.review
description: Three-stage review gate (mechanical, code review, spec checklist) for implementation, before PR.
---

Perform a review gate before PR. **Do not skip a stage.** Stop and report failure immediately if a stage does not pass — don't continue to the next stage on a failure.

The `Ready for PR` verdict this command produces is the hub's Gate 3 (`constitution/EMPOWER-HUB-CONSTITUTION.md` Section 6) — `/speckit.pull-request` checks it before it will draft a PR.

## Step 0 — Detect scope and resolve repo paths

Review exactly **one repo per run** (constitution §11). Ask which repo if not stated, or detect it from the working context; when more than one repo changed, run the review once per repo. Also check the diff for any comment, string, or test that references the hub (constitution §4) — that is a 🔴 Must Fix. Run `git -C <resolved path> status` and `git -C <resolved path> diff` to see the actual changed files.

---

## Stage 1 — Mechanical gate

### MyIsn.Android

From the resolved `MyIsn.Android` path:

```bash
./gradlew ktlintCheck detekt
./gradlew test                 # unit tests
./gradlew assembleInternalDebug   # build verification
```

### MyIsn.iOS

From the resolved `MyIsn.iOS` path:

```bash
swiftlint lint --strict
xcodebuild test -project Empower.xcodeproj -scheme Empower \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

### Mockoon

Mockoon has no automated test suite — if the change added/edited a route, validate the environment JSON is well-formed (e.g. `python3 -m json.tool <file>` or opening it in Mockoon Studio) and that the environment actually starts locally. N/A if the change didn't touch `mockoon-configs/`.

Every repo actually in scope must pass before Stage 2.

---

## Stage 2 — Code review

Identify changed files in the resolved repo path (Step 0), then invoke the `code-review` skill (the `code-reviewer` agent defines the Empower-specific lens: [`.claude/agents/agents.md`](../agents/agents.md)) against that diff at `medium` effort by default. Use `high` effort if the spec's Scope marks this as touching more than one repo or a third-party contract.

- **If this task touches any UI-visible code**: also check it against `docs/style-guide.md` in this hub. Treat a style-guide violation as a finding in this stage, same severity rules as any other code review finding. If the style guide doesn't document a value the diff needs, don't fail the review over it — note it as an open question instead

Organize findings as:

- 🔴 Must Fix
- 🟢 Looks Good

Any 🔴 Must Fix item: mark **Not Ready for PR**, stop.

---

## Stage 3 — Spec & process checklist

Read `specs/<type>/<task-id>-<slug>/spec.md` and `tasks.md`. Use the `qa-reviewer` agent (method: `qa-review` skill) to trace acceptance criteria to evidence, and the `cross-platform-reviewer` agent when more than one repo changed. They report findings only — this command sets the verdict. Verify:

1. Scope matches spec.
2. All acceptance criteria are covered by implemented behavior.
3. Every task in `tasks.md` for this repo is marked done.
4. Lint/build/test evidence from Stage 1 is captured (paste key output into `pr-evidence.md`, creating it if it doesn't exist, at `specs/<type>/<task-id>-<slug>/pr-evidence.md`).
5. Manual smoke evidence is present and explicit in `pr-evidence.md` — if it's missing, ask the user to provide it or perform it (don't fabricate smoke results).
6. Any PII/analytics changes have their `docs/observability.md`-required updates (mask rules, analytics constants) done on the affected platform.
7. Any UI-visible changes conform to `docs/style-guide.md` (checked in Stage 2) — no unresolved 🔴 Must Fix style-guide findings remain.
8. Risks and follow-ups from the plan are documented in `pr-evidence.md`.

---

## Output format

```
## Stage 1 — Mechanical Gate
MyIsn.Android: PASSED | FAILED | N/A
MyIsn.iOS: PASSED | FAILED | N/A
Mockoon: PASSED | FAILED | N/A

## Stage 2 — Code Review Findings
🔴 Must Fix
- ...
🟢 Looks Good
- ...

## Stage 3 — Spec & Process Checklist
- [ ] Scope matches spec
- [ ] Acceptance criteria covered
- [ ] All tasks marked done
- [ ] Lint/build/test evidence in pr-evidence.md
- [ ] Manual smoke evidence present
- [ ] Observability updates done (mask rules / analytics constants)
- [ ] Style-guide compliance checked (if UI-visible changes) — no unresolved findings
- [ ] Risks documented

## Verdict
Ready for PR | Not Ready for PR — <reason>
```

**If and only if Ready for PR**, tell the user explicitly:

> "All stages passed. You can now run `/speckit.pull-request`."

If Not Ready for PR, do not mention that handoff — list what needs fixing and stop.

## Rules

- Do not modify implementation files during review — findings only. Fixing is a separate, explicit step the user asks for.
- Do not commit, push, or deploy.
- Do not fabricate manual smoke test evidence.
