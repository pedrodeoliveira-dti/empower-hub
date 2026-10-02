---
name: qa-review
description: Methodology for verifying an implementation actually satisfies its spec — tracing Given/When/Then acceptance criteria to real tests or evidence, judging whether a test genuinely exercises the claimed behavior, and spotting undocumented spec drift. Use during /speckit.review (Stage 3) and from the qa-reviewer agent.
---

# QA Review

The method behind the `qa-reviewer` agent. It checks that "review is against artifacts, not preference" actually held — see [`constitution/ENGINEERING-PRINCIPLES.md`](../../../constitution/ENGINEERING-PRINCIPLES.md).

## 1. Trace, don't sample

Go through `spec.md`'s Acceptance Criteria scenario by scenario. A change can look well tested while the one failure-mode scenario that matters has no test at all. A sampled review gives false confidence.

## 2. A passing test is not a correct test

Check what a test asserts, not that it exists. Red flags:

- It exercises the path but asserts something trivial ("does not crash").
- It mocks away the exact behavior the scenario is meant to verify.
- Its assertions are weaker than the scenario's `Then`.

Ask: *if the implementation regressed exactly this behavior, would this test fail?* If not, it is a gap even though a test file exists.

## 3. Evidence by type

| Change | Acceptable evidence |
|---|---|
| Android / iOS logic | Unit or UI test output from the Stage 1 mechanical gate |
| UI-visible behavior | Explicit manual smoke steps and results in `pr-evidence.md` (screenshots where useful) |
| Mockoon route | Valid environment JSON, starts locally, expected response shown |
| Cross-platform | Evidence per platform — one platform's proof never covers the other |

Never fabricate smoke results. A manual step that could not run is recorded as a manual follow-up.

## 4. Security considerations need verification, not trust

For each security consideration in the spec, find concrete evidence (a check at the right boundary, an input rule, a test for the abuse case). Mark it `verified`, `not verified`, or `unable to verify`. This is mandatory when the change touches login, tokens, ISN ID wallet, Jumio/KYC, geolocation, documents, or PII, even if the spec listed nothing. Manual review only — never run a scanner.

## 5. Spec drift is a finding

If the implementation does something reasonable but different from `spec.md` or `plan.md`, flag it. The fix may be to update the spec with the reasoning recorded, but it must not pass silently.

## 6. Separate "verified" from "could not verify"

Say plainly whether a finding rests on static inspection or a confirmed run, so a downstream human or CI knows what still needs confirming.

## 7. Report in an actionable form

Per scenario: `covered` / `partially covered` / `gap`, and for gaps exactly what is missing — not "needs more tests". Per security item: the verdict and what was checked. Feed these into `/speckit.review`'s Stage 3 checklist; the verdict itself stays with that command.
