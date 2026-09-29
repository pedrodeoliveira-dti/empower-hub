# Visits (Visitor Management System)

> Functional documentation — how the feature actually works, grounded in the real code on both platforms. For new developers and POs.

## Purpose

Gives a visitor (a non-employee guest, e.g. a contractor's contact visiting a hiring client's site) a digital "visit pass": pre-visit requirements to complete, a check-in/check-out flow tied to a time window, host contact info, and arrival instructions. This is the entire Visitor Management System (VMS) surface, gated end-to-end behind the `VisitorManagementSystemFlag`/`visitorManagementSystem` flag (see [Connections](connections.md#related-feature-flags)).

## User journey

1. Visit Details loads via the visits endpoint. On failure, Android's dialog dismissal navigates back (the screen is unusable without visit data); iOS keeps showing the previously-loaded visit alongside an alert.
2. The visit's status drives everything shown: `SCHEDULED`, `CHECKED_IN`, `CHECKED_OUT`, `CANCELLED`, `COMPLETED`, `EXPIRED`.
3. **Check-in eligibility**: a visit is "green" (compliant) only if requirements status is `GREEN`/`GREEN_WAIVED`. Check-in is only available inside the server-provided time window **and** while green. Tapping the disabled check-in explains *why* (time restriction vs. unmet requirements) via a "Check-In Unavailable" dialog, and both reasons are logged to analytics.
4. Confirming branches purely on current status: `SCHEDULED` → check in; otherwise → check out.
   - **Idempotency safeguard**: a "bad request" response carrying an "already checked in/out" error code is treated as a soft-success (silent refresh) rather than an error — protects against double-taps or stale state, confirmed on both platforms.
   - Any other failure → "Check-In/Check-Out Failed" with retry.
5. Requirement rows (acknowledgements/training) are tappable only while unmet (`RED`); completing them elsewhere feeds back into the visit's compliance status on refresh.
6. "Remove Visit Pass" only appears once the visit is archived; deletion navigates back with an event fired for analytics.
7. Contact Host is only offered if available and not expired; a missing mail client falls back to an "Email Not Found" dialog (Android).

## Business rules / validation

- **Status meaning**: precise business distinction between `CHECKED_OUT` and `COMPLETED` was **not found** in either client — likely a backend-only distinction. Flag as an open question.
- **Check-in/out window**: entirely server-provided (`checkInAvailableAt`/`checkInExpiresAt`) — no hardcoded hours client-side. UI copy references a configurable lead time.
- **Archived threshold**: 24 hours, used to gate a "recently archived" state/banner — confirmed identical on both platforms.
- **Home-screen filter**: only non-archived `SCHEDULED`/`CHECKED_IN`/`CHECKED_OUT` visits show on Home; `CANCELLED`/`COMPLETED`/`EXPIRED` and anything archived are excluded.

## Screens

- **Android**: `VisitDetailsFragment` — under its own `ui/visits` package. No separate list screen; the visit *list* lives inside `MyCompaniesFragment`'s "Visit Passes" tab.
- **iOS**: `VisitPassDetailsView` and supporting card/summary views — architecturally folded into `Screens/Tabs/Home/VisitPass/`, i.e. this feature is part of Home on iOS, not a standalone module the way it is on Android.

## Platform differences

- Folder/architecture: Android keeps Visits as its own module; iOS folds it into Home.
- iOS observes live connectivity changes and auto-refetches on reconnect; no equivalent explicit "on reconnect" hook was found on Android (Android's offline awareness is the shared `BaseViewModel.isOffline` flag only).
- Android's error dialogs are modeled per-error-type with distinct retry/dismiss callbacks; iOS centralizes this into a more generic `alert`/`toastType` property.
- iOS's "check-in unavailable" copy hardcodes "hours" in the lead-time message; Android's copy takes a unit placeholder (`%2$s`) — possible copy drift worth flagging.

## Key user-facing strings

- *"Check-In Unavailable"*
- *"You must meet all requirements before checking in."* (identical copy both platforms)
- *"You may not check in until %1$d %2$s prior to your visit."* (Android, unit-agnostic) vs. *"You may not check in until %@ hours prior to your visit."* (iOS, hardcodes "hours")
- *"Remember to check out before leaving!"*

## Open questions for a PO

1. What's the precise business difference between `CHECKED_OUT` and `COMPLETED`?
2. Is the iOS "hours" hardcoding in the check-in-unavailable copy a latent bug, or is lead time always expressed in hours?
3. Confirm both platforms are expected to have identical "already checked in/out → silent refresh" behavior (iOS does have it, via distinct `ServiceError` cases).

## Related

- [Connections](connections.md#related-feature-flags) — the `VisitorManagementSystemFlag` that gates this entire feature.
