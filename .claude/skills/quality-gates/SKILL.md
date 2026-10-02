---
name: quality-gates
description: Reference for what evidence each workflow stage needs (spec, plan, tasks, implement, validate, review), which flows are high-risk enough to warrant a validation plan, and an evidence checklist. Adds NO new formal gate. Use when judging readiness at any stage or deciding whether to run validation planning.
---

# Quality Gates (evidence guide)

**This skill adds no formal gate.** The hub has exactly three human gates (plan approval, tasks approval, review verdict) defined in [Constitution §6](../../../constitution/EMPOWER-HUB-CONSTITUTION.md#6-formal-human-gates), and no others may be introduced. What follows is advisory: what good evidence looks like at each stage, so the three real gates are decided on facts. A "not ready" finding here is reported to the user and recorded in the artifact; it is never a new blocker.

## Evidence by stage

| Stage | Ready when |
|---|---|
| Spec | Scope per repo, observable Given/When/Then criteria ([`bdd-specification`](../bdd-specification/SKILL.md)), explicit non-goals, security considerations, Open Questions visible |
| Plan | Per-repo approach, additive-vs-breaking contract call, older-app-version strategy ([`cross-platform-impact`](../cross-platform-impact/SKILL.md)), test approach mapped to criteria, risks |
| Tasks | Each task traces to a plan item and one repo, includes its test, small enough to verify alone |
| Implement | Changes match tasks, repo's own build/lint/test commands run and their real output kept, no work outside the task list |
| Validate | Each criterion has a test or recorded manual step; high-risk flows have unhappy-path evidence |
| Review | Criteria traced to evidence ([`qa-review`](../qa-review/SKILL.md)), diff reviewed, drift and open risks listed in `pr-evidence.md` |

## High-risk flows

When a change touches one of these, plan validation explicitly with [`/speckit.validation-plan`](../../commands/speckit.validation-plan.md) and record results with [`/speckit.validate`](../../commands/speckit.validate.md). Both are optional aids, not gates.

| Trigger | Why |
|---|---|
| Login, session, or Jumio/identity verification | Lockout and data-exposure risk; third-party SDK behavior |
| ISN ID wallet (card, pass, QR) | Identity data; Google Wallet / Apple Wallet integration |
| Geolocation or location permission | Permission states, background behavior, privacy |
| Certificates and documents | Upload/view integrity, sensitive files |
| Worker forms | Data entry, submission, offline and retry |
| Third-party contract change (shape, status, header) | Older installed app versions and Mockoon parity |
| Shared infrastructure (feature flags, analytics, navigation) | Wide blast radius |

## Evidence checklist

- [ ] Each acceptance criterion maps to a test or a manual step with a result
- [ ] Commands were actually run and output kept; nothing is reported passed that did not run ([Constitution §5](../../../constitution/EMPOWER-HUB-CONSTITUTION.md#5-operational-invariants))
- [ ] Unhappy paths covered for high-risk flows: denied permission, offline, expired session, server error
- [ ] Per-platform proof; Android evidence never covers iOS
- [ ] Mockoon routes validated (valid JSON, starts, expected response) when touched
- [ ] Security considerations marked verified / not verified / unable to verify ([`security-review`](../security-review/SKILL.md))
- [ ] Steps that could not run are recorded as manual follow-ups, never faked
- [ ] Decisions and risk acceptances written into the owning artifact ([Constitution §6](../../../constitution/EMPOWER-HUB-CONSTITUTION.md#6-formal-human-gates))

## Rules

- Do not restate gate definitions; link to the constitution.
- Keep evidence in the existing artifact (`pr-evidence.md`); do not create extra files for it ([`docs/lean-artifact-policy.md`](../../../docs/lean-artifact-policy.md)).
