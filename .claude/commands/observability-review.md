---
name: observability-review
description: Read-only review of logging and analytics in a change or area of MyIsn.Android / MyIsn.iOS against docs/observability.md — PII masking, analytics parity, no secrets in logs.
argument-hint: <repo|both> [area, file path, or branch/diff to review]
allowed-tools: Read, Glob, Grep, Bash(ls:*), Bash(git -C * diff:*), Bash(git -C * log:*), Bash(git -C * branch:*), Bash(graphify:*)
---

# observability-review

Reports on whether the logging, crash reporting, and analytics in a given scope are safe and consistent across platforms. **Read-only: findings only.** It changes no file in the hub or in the product repos, and it is not a gate.

## Step 1 — Scope and baseline

- Ask what to review if unclear: a diff (`git -C <path> diff <base>...HEAD`), a feature area, or specific files. Resolve repo paths from `workspace.config.json` and `ls` each; list uncloned repos under **Not Checked**.
- Read [`docs/observability.md`](../../docs/observability.md) first. It owns the conventions (Timber / `os.Logger` + `PersistentLogger`, Crashlytics, Firebase Analytics, Chucker, Wormholy) and the already-known risks. Do not restate them; report only what is new or still present in scope.
- If `<repo>/graphify-out/graph.json` exists, use `graphify query` first (see hub `CLAUDE.md`), then Read the exact lines.

## Step 2 — Checks

| Check | Look for |
|---|---|
| Secrets and tokens | Access/ID tokens, JWTs, FCM/APNs tokens, subscription keys, passwords, `Authorization` values reaching `Timber.*`, `Log.*`, `println`, `os.Logger`, `print`, `NSLog`, or Crashlytics keys |
| PII masking | Email, name, phone, address, ISN ID, company/connection IDs, location, document or Jumio data interpolated into log messages, analytics properties, or crash custom keys; mask rules present on the affected platform |
| Payload logging | Full request/response bodies, push payloads, or objects logged by `toString()` / `debugDescription` that may carry PII |
| Build-variant exposure | Logs that still run in QA-distributed builds (Android `internalRelease`, iOS non-`APPSTORE`) and interact with Chucker / Wormholy / persistent log store |
| Analytics parity | Same event names, parameter keys, and trigger points on both platforms; shared constants used instead of inline strings; new events listed in the plan's Observability Plan |
| Crash/error reporting | Non-fatals carry context without bodies; swallowed errors in `catch` blocks have no signal at all |
| Log level and noise | Verbose logging in hot paths, or errors logged at debug |

## Output

```markdown
# Observability Review: <scope>

## Summary
<n> findings (<n> high, <n> medium, <n> low). Platforms reviewed: ...

## Findings
| # | Severity | Platform | File:line | Issue | Suggested fix |
|---|---|---|---|---|---|

## Analytics Parity
| Event / parameter | Android | iOS | Status (match / differs / missing) |
|---|---|---|---|

## Already-Known Risks Touched
- Items from `docs/observability.md` that this scope relates to (link, do not repeat)

## Not Checked
- ...
```

Severity: **High** = secret/token or direct PII in logs or analytics; **Medium** = unmasked identifiers, parity gaps; **Low** = level or noise.

## Rules

- Never edit files, run builds, or write a report file — output stays in chat.
- Cite real `file:line` evidence only. If nothing is found, say so; do not pad.
- Never print an actual secret value found in code — name the location and type only.
- If a finding implies a fix, point to `/quick-fix` (narrow) or `/speckit.specify` (larger); do not apply it.
