# Quick Check

> Functional documentation — how the feature actually works, grounded in the real code on both platforms. For new developers and POs. The largest feature area by endpoint count on both platforms.

## Purpose

A "Quick Check" is a per-site/per-client compliance snapshot for a contractor worker: it bundles together every requirement a Hiring Client demands before letting that worker onto a jobsite — training/qualification completion, worker acknowledgements, site/location assignment, and (for equipment operators) "Operator Qualifications." The worker "adds" one QuickCheck card per Hiring Client/site combination; the app shows a simple traffic-light compliance status plus drill-down detail on exactly which requirement is failing and why.

## User journey

Two entry points create a QuickCheck:

### A. Manual "Add QuickCheck" wizard

1. Tap "Add QuickCheck" → fetch "initial parameters" (Hiring Clients available for the selected Connection).
2. Step 1 — pick **Hiring Client**. If restricted (contains Drug & Alcohol data not shared in Empower), a blocking dialog stops the flow for that client.
3. Step 2 (conditional) — if the client has multiple **QuickCheck Profiles**, pick one (a profile can independently be restricted too).
4. Fetch "additional parameters" scoped to Hiring Client (+ Profile). Each further step only appears **if the server marks it visible and it has options**: Location, Training Qualifications (TQ), Operator Qualifications (OQ), Site, Worker Acknowledgement.
5. If a *required* parameter category has zero options, the user is blocked: "Not Assigned To Project."
6. Confirmation → `createQuickCheck()`. If the new QuickCheck already needs project/activity assignment, the Confirmation step is skipped and the user goes straight into QuickCheck Details.
7. Duplicate detection offers a shortcut straight to the existing card.
8. Changing an earlier answer after later steps are already answered warns that downstream selections will be cleared.

### B. QR-code entry point (jobsite signage)

1. Camera scan reads a URL that must resolve through the app's dynamic-link/universal-link domain — anything else shows a red scan-error state.
2. A valid link round-trips through the browser/deeplink handler, returning either a `quickCheckId` (contractor-assigned copy flow) or a `quickCheckQRId` (hiring-client flow).
3. Contractor-assigned → "copy quick check." Hiring-client with >1 active Connection → a company-select sheet first; single connection → auto-picked.
4. Errors are triaged: not found, not connected to the contracting company, not connected to the hiring client, invite-only project, or duplicate (same recovery as manual add).

**After creation**: QuickCheck Details (Level 1) groups modules into "Requirements Met / Waived / Unmet / Pending Assignment." Tapping a module opens Level 2, listing individual line items (courses, acknowledgements, training qualifications, worker forms, or nested "multilevel" requirement groups). Line items deep-link into their own detail screens, or a recursive Multi-Level Group screen for nested OR/AND requirement sets.

## Business rules / validation

- **Restricted profiles**: a Hiring Client or QuickCheck Profile can be flagged restricted — blocks with a dialog rather than proceeding silently.
- **Required-without-options guard**: a required additional-parameter category with zero options blocks the user ("Not Assigned to Project").
- **QuickCheckStatus** (top-level): `RED` (unmet), `GREEN` (met), `RED_SUSPENDED` (suspended by hiring client), `GREEN_WAIVED` (waived), `INVALID` (must be removed and re-added).
- **QuickCheckModuleStatus** (per requirement group): same 4 values, feeding the Level 1 buckets.
- **Line-item status**: only `RED`/`GREEN` — no suspended/waived nuance at the leaf level.
- **Requirements quantity**: `ONE` (pass any one of the group) vs. `ALL` (pass every item) — drives OR/AND grouping and copy.
- **Assignment gating**: `ASSIGNED` / `PROJECT_ASSIGNMENT_REQUIRED` / `ACTIVITY_ASSIGNMENT_REQUIRED` — when required, the Confirmation screen is skipped and the user lands directly in Details. Resolvable via self-assignment or "request assignment" (admin approval), which can be throttled by a next-available-date.
- **Operator Qualifications (OQ)**: distinct from Training Qualifications (TQ) — a module-level flag with an optional PDF "OQ report" the user can view. TQ instead surfaces qualification name/provider/dates, with support for nested (multi-level) TQ groups.
- **Multilevel/nested groups**: gated by their own feature flags (`OtMultilevelPhase1Flag`/`TqMultilevelPhase1Flag`) — when off, the app shows a "please visit the Trainings Dashboard" dialog instead of rendering the nested UI. This is a gradual rollout, not fully shipped.
- **Duplicate detection**: server returns a `duplicate_quick_check` error with the existing QuickCheck's id — both entry flows recover by offering a jump to the existing card.
- **API versioning ("v1"–"v4")** is per-endpoint REST versioning, not an entity/schema version: `getAllQuickChecks` is unversioned, `getInitialQuickCheckParameters` is v2, `getOqReportDocument`/`getQuickCheckShareInfo` are v3, `assignQuickCheck`/`createQuickCheck`/`getAdditionalQuickCheckParameters`/`getQuickCheckDetails`/copy/QR-create are all v4. Android additionally tags and invalidates its cached list payload on the v4 shape. **What actually changed between versions is not documented in either client** — needs backend/PO history.
- **No client-side QR expiry logic** was found — "retry" just re-arms the camera after a scan error, not a code-expiry timer.

## Screens

| Android | iOS |
|---|---|
| `AddQuickCheckFragment` (wizard) | `AddQuickCheckView` |
| `QuickCheckScanQRFragment` | `QRCodeReaderView` |
| `QuickCheckDetailsLevelOneFragment` | `QuickCheckDetailsView` |
| `QuickCheckDetailsLevelTwoFragment` | `QuickCheckModuleView` |
| `MultiLevelGroupFragment` | `TrainingMultilevelView` |
| `TrainingQualificationListFragment`/`DetailsFragment` | `TrainingQualificationListView`/`DetailView` |
| — | `ShareQuickCheckSetupView` — possible iOS-first screen, worth confirming with Android team whether an equivalent exists under a different name |

## Platform differences

- Same wizard steps, different internal modeling (`StateFlow<List<AddQuickCheckStep>>` on Android vs. `[AddQuickCheckCategory]` on iOS).
- **Cache invalidation strategy genuinely differs**: Android explicitly versions/invalidates the QuickCheck-list cache on API version bump; iOS caches by connection id with no version tag.
- Both have geolocation-driven "Fast Track" banners (see [Geolocation](geolocation.md)) tied to a QuickCheck's geolocation requirement, implemented under different names/flags on each platform.

## Key user-facing strings

- *"Add a QuickCheck Card"* (wizard title)
- *"This QuickCheck Card includes certain Drug & Alcohol details that are not shared in Empower. Please contact your Admin if you require this information."*
- *"You are not assigned to a project for this QuickCheck Profile. Please contact your company's ISN Admin for assistance."*
- *"This QuickCheck is Invalid — Remove it and add a new one to make sure you see the latest requirements."*
- *"Please note that a red status indicates only that the available data regarding an individual's completion has not met the particular Client and/or Data Provider requirement; it may indicate any of the following: failure, incomplete data, or the absence of data altogether."*
- *"Suspended by %1$s until %2$s. Contact your admin if you need access to the jobsite or if you think this is an error."*

## Open questions for a PO

1. What functionally changed between QuickCheck API versions v1→v4?
2. Is there server-side QR-code expiry the clients simply don't need to model?
3. Is `ShareQuickCheckSetupView` iOS-only, or does Android have an equivalent under a different name?
4. What exactly triggers `PROJECT_ASSIGNMENT_REQUIRED` vs. `ACTIVITY_ASSIGNMENT_REQUIRED` server-side?

## Related

- [Geolocation](geolocation.md) — the "Fast Track" banner tied to a QuickCheck's geolocation requirement.
- [Acknowledgements](acknowledgements.md), [Courses/LMS](courses-lms.md), [Worker Forms](worker-forms.md) — line-item types a QuickCheck module can point into.
