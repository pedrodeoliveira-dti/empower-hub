---
name: cross-platform-impact
description: Reusable method for assessing how a change affects MyIsn.Android, MyIsn.iOS, and Mockoon — classifying impact level per repo, additive vs. breaking contract change, older-installed-version risk, Mockoon mirroring, and sequencing. Use in /orchestrate-feature, product-orchestrator, and when writing plan.md.
---

# Cross-Platform Impact

The method for the impact question; [`orchestrate-feature`](../orchestrate-feature/SKILL.md) and the `product-orchestrator` agent decide *when* to ask it, [`product-context`](../product-context/SKILL.md) holds the short checklist. Rules on contracts and clients live in [Constitution §9](../../../constitution/EMPOWER-HUB-CONSTITUTION.md#9-api-compatibility-and-client-impact) and [§11](../../../constitution/EMPOWER-HUB-CONSTITUTION.md#11-platform-autonomy); do not restate them, apply them.

## 1. Ground it

Resolve repo paths from `workspace.config.json` and confirm each is cloned (`ls`); a missing repo is `not cloned`, not analyzed. Check the journey in [`docs/cross-platform-flows.md`](../../../docs/cross-platform-flows.md) and [`docs/api-contracts.md`](../../../docs/api-contracts.md). Read each repo's own `CLAUDE.md` first; use `graphify query` when a graph exists.

## 2. Classify impact per repo

| Level | Meaning |
|---|---|
| None | Nothing in the repo changes or depends on the change |
| Possible | May be affected; a named question or check would resolve it (becomes a spec Open Question) |
| Required | Code or config must change |
| Verify-only | Nothing changes but behavior must be re-validated (shared contract, shared flag) |

Give a one-line reason and an evidence path per repo. "Possible" with no resolving question is not allowed.

## 3. Contract change: additive or breaking

| | Additive | Breaking |
|---|---|---|
| Examples | New optional field, new endpoint, new enum value clients ignore safely | Removed/renamed field, changed type, status code, header, error message, or timing |
| Plan must say | That it is additive and who ignores the new data | Versioning, flag, or rollout strategy and who is affected |

State which it is explicitly, and name every consumer (Android, iOS, Mockoon, others).

## 4. Older installed versions

Ask what an app version that has not updated receives and does. It must keep working, or the plan names the flag, minimum-version, or staged-rollout cover. Check both stores' lag; Android and iOS adoption differ, so the answer is per platform.

## 5. Mockoon mirroring

Mockoon must serve the contract the apps will actually receive. For any contract change, plan the matching mock route (success and error cases) in the same change set; a mock that drifts is a defect in the hub's own validation story. Say when Mockoon is `None` and why.

## 6. Sequencing

Order by dependency: confirm the contract, then Mockoon, then clients; a client ships ahead only when compatibility is addressed. Each repo is planned once in the hub and executed separately, one repo per session, with its own gates. Note which work can run in parallel sessions.

## 7. Record

Output a per-repo table (impact level, reason, evidence, additive/breaking, older-version risk, Mockoon change, order) plus Risks and Open Questions into the spec or `plan.md`'s Cross-Platform Summary section. No separate file ([`docs/lean-artifact-policy.md`](../../../docs/lean-artifact-policy.md)).
