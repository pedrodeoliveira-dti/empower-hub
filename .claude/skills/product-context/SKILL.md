---
name: product-context
description: Use when analyzing or implementing a change that may affect more than one repo.
---

# Product Context Skill

## Repositories

Real paths live in `workspace.config.json` at this hub's root — read `repos.<repo>.path` from there rather than assuming `../<repo>`. Confirm a repo is actually present with `ls <path>` before analyzing it.

## Core rule

Before implementing or analyzing a change, identify which repos are actually affected. Don't assume something without checking `docs/cross-platform-flows.md` and `docs/api-contracts.md` for that journey.

## Cross-platform checklist

For any change, check:
- Third-party contract (Olo, Loyalty provider, Auth0, Braze, DoorDash, POS)
- Auth/session, basket/checkout, loyalty, and payment state
- Analytics events and PII-carrying fields (see `docs/observability.md`)
- Brand scope — does this apply to all four brands or a subset?
- Tests, per platform
- Rollout/implementation order
- UI-visible changes: conformance to `docs/style-guide.md` per brand

## Third-party contract rules

- Prefer additive changes. Don't remove/rename a field either client depends on without confirming both.
- Document any contract change in the feature's own spec (`specs/.../spec.md`).

## Observability rules

Never log secrets, tokens, authorization headers, payment data, or PII, on either platform. Reference `docs/observability.md` for the concrete masking rules that exist today.

## Implementation rule

For cross-platform changes:
1. Run `/orchestrate-feature` first if this hasn't happened yet.
2. Confirm/define the third-party contract before either client starts.
3. Implement one repo at a time (`/speckit.implement <repo>`).
4. Add/adjust observability per platform.
5. Validate each repo independently (`/speckit.review`).
6. `/speckit.pull-request` per repo, only after explicit confirmation.
