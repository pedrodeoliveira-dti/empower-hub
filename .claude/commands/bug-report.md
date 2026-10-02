---
name: bug-report
description: Turn bug context pasted in chat into ONE Azure DevOps-ready Bug draft saved as specs/bugs/<slug>.md. Does not create anything in Azure DevOps.
argument-hint: [optional short title or slug]
allowed-tools: Read, Glob, Grep, Write, Bash(ls:*)
---

# bug-report

Drafts a single Bug from whatever the user pastes (description, repro steps, logs, screenshots, error text). Output is a local file only. **Publishing to Azure DevOps is a separate step**, handled by the `po-work-item-publish` skill ([`.claude/skills/po-work-item-publish/SKILL.md`](../skills/po-work-item-publish/SKILL.md)) — this command never calls Azure DevOps and never duplicates that skill's rules.

## Step 1 — Gather context

Use only what is in the conversation. If critical facts are missing, ask at most 3 short questions: platform (Android / iOS / both), app version or build variant, and exact repro steps. Everything else becomes `TBD` rather than a guess.

Optionally ground the report in the product docs (`docs/cross-platform-flows.md`, `docs/api-contracts.md`) to name the affected journey. Do not investigate or fix the code here.

## Step 2 — Write the draft

Path: `specs/bugs/<slug>.md` (kebab-case slug from the title). If the file exists, ask before overwriting. There is **no real Azure DevOps ID yet** — never invent one; the filename and header carry only the slug.

```markdown
# Bug: <concise title>

**Azure DevOps ID**: None yet (draft)
**Status**: Draft — not published

## Summary
One or two sentences: what breaks, for whom.

## Environment
Platform, OS/device, app version/build variant, backend environment (real / Mockoon), account type.

## Steps to Reproduce
1. ...

## Expected Result
## Actual Result
Include verbatim error text. Mask tokens, emails, ISN IDs, and other PII from pasted logs.

## Evidence
Attachments or log excerpts referenced by the user (do not fabricate).

## Impact & Severity
Who is affected, frequency, workaround. Severity/Priority: suggested value with a one-line reason.

## Suspected Area (optional)
Only if supported by the pasted evidence; label as a hypothesis.

## Azure DevOps Fields
| Field | Value | Required? |
|---|---|---|
| Work Item Type | Bug | Yes |
| Area Path | [TBD - confirm with ISN board admin] | Yes |
| Iteration Path | TBD | Depends |
| State | New | Yes |
| Tags | TBD | Yes |
| Severity / Priority | <suggested> | Optional |
```

## Rules

- Exactly one Bug per run. If the context describes several problems, draft the main one and list the others as suggested follow-up bugs in chat.
- Never invent repro steps, versions, or log lines. Missing data is `TBD`.
- Redact secrets and PII from anything pasted (see [`docs/observability.md`](../../docs/observability.md)).
- Do not create the item in Azure DevOps, do not update an existing one (that is `po-pbi-sync`).
- Do not commit or push.

## Next steps

Tell the user the draft path, list the remaining `TBD` fields, and offer the next options:

- Review and complete the `TBD` fields, then publish with the `po-work-item-publish` skill.
- To fix it, use `/quick-fix` if it is a narrow single-repo issue, otherwise `/orchestrate-pbi <id>` once the real ID exists.
