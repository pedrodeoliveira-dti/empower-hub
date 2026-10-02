---
name: pbi-clarification
description: Methodology for finding the ambiguities in a spec that are worth asking about, asking a small focused set of questions, and closing the loop by updating the spec instead of just logging answers. Use inside /speckit.clarify, before /speckit.plan.
---

# PBI Clarification

The method behind [`/speckit.clarify`](../../commands/speckit.clarify.md). That command owns the steps and the scan list; this skill owns *which questions are worth asking* and *how to close them*. Unknowns are recorded, never guessed ([`ENGINEERING-PRINCIPLES.md`](../../../constitution/ENGINEERING-PRINCIPLES.md) Principle 1).

## 1. Ask only what changes the plan

A question earns its place only if a different answer would change Scope, the acceptance criteria, the contract impact, or the implementation order. Wording, naming, and cosmetic preferences are not clarification questions. If you cannot say "if the answer is A we do X, if B we do Y", drop it.

## 2. Keep it small

Ask the few highest-value questions, not an exhaustive checklist. Rank by impact; ask the top ones, and leave the rest as Open Questions in the spec rather than interrogating the user. Prefer bounded choices over open prose, with a recommended default marked so the user can answer in one word.

## 3. Where Empower ambiguity usually hides

| Source | Typical question |
|---|---|
| Platform scope | Does this apply to Android, iOS, both, or Mockoon only? Does it differ per platform on purpose? |
| Third-party contract | What is the before/after shape? Additive or breaking? Which app versions in the field still call the old shape? |
| States | Behavior when offline, unauthenticated, permission denied, empty, or on a server error |
| Flags and rollout | Is it behind a Remote Config flag? What is the default? |
| Sensitive flows | Login/Jumio, ISN ID wallet, geolocation, certificates, worker forms: what must never be shown, stored, or logged? |
| Acceptance criteria | Not observable or not testable; see [`bdd-specification`](../bdd-specification/SKILL.md) |
| Design | A UI value the [`docs/style-guide.md`](../../../docs/style-guide.md) does not document |

## 4. Look before asking

Before asking, try to answer from the spec, the repo's docs, `docs/*.md`, and the code (`graphify query` first when a graph exists). Never ask the user something the code already answers; confirm it instead ("code shows X, correct?").

## 5. Close the loop in the spec

An answer that lives only in chat is lost ([`ENGINEERING-PRINCIPLES.md`](../../../constitution/ENGINEERING-PRINCIPLES.md) Principle 7). For every answer:

- Edit the affected section of `spec.md` (Scope, Acceptance Criteria, Third-Party Contract Impact), not just the Open Questions list.
- Remove the resolved question from Open Questions; keep genuinely unresolved ones with an owner if known.
- If the answer rewrites an acceptance criterion, rewrite it as Given/When/Then.
- Do not invent an answer the user did not give; an unanswered question stays open and is carried into `plan.md` Risks.

## 6. Report

State what changed in the spec, what remains open, and any answer that widened scope (suggest `/orchestrate-feature` again if a new repo is now affected). Clarification adds no approval step; the gates remain those in [Constitution §6](../../../constitution/EMPOWER-HUB-CONSTITUTION.md#6-formal-human-gates).
