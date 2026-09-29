# Geolocation ("Fast-Track Check-In")

> Functional documentation — how the feature actually works, grounded in the real code on both platforms. For new developers and POs.

## Purpose

Lets a worker opt in to precise/background location sharing so that, when physically near a connected Hiring Client's jobsite that requires geolocation-based check-in (a [Quick Check](quick-check.md) with a geolocation requirement), the app can proactively surface a fast check-in prompt instead of the worker navigating there manually. Powered by the Radar SDK for geofencing.

## User journey

1. A banner ("Fast-Track Your Check-in") appears on Home/My Companies when at least one connected client requires geolocation and the user hasn't already opted in or dismissed the banner.
2. Tapping it opens a flow with up to 3 steps depending on current OS permission state: (1) allow location while using the app, (2) allow "Always" (background), (3) enable push notifications — ending in "All Set!"
3. A legal disclaimer is shown before/while granting: *"By opting-in to share your precise geolocation, you agree and acknowledge that Empower will collect, process, and share your precise geolocation with an ISNetworld subscriber you are connected to..."*
4. If denied, the app offers a "Go to Device Settings" redirect.
5. Once background location is granted, the app **automatically starts Radar tracking** — granting the permission is itself the trigger, no separate "start" button.
6. A confirmation appears ("Geolocation Shared" / *"Check-ins made easier — Next time you're near a jobsite, your ISN-ID will pop up to help you check in quickly."*).
7. Manageable later under Security & Privacy — the toggle is disabled entirely if the user isn't connected to any geolocation-requiring client.

## Business rules / validation

- **Tracking start/stop is centralized on Android** in a single coordinator, invoked after every Quick Checks refresh. It starts tracking only when **all** of: the geolocation feature flag is on, at least one Quick Check has a geolocation requirement, a non-empty geo user id was returned, and background location is granted. Idempotent — won't restart for an already-tracked user.
- **Tracking mode/preset comes from remote config**, not the client (maps to Radar's efficient/continuous/responsive presets).
- **On start, the app also primes an immediate high-accuracy location fix**, so data is available right away rather than waiting for the preset's normal cadence.
- **Geofence push-notification preference is synced automatically, not user-toggleable** — whenever tracking starts, the backend preference is set enabled, fire-and-forget.
- **Opt-in banner dismissal has a 30-day cooldown.**
- **The "opted in" flag is a persisted app-level preference independent of OS permission state** — a user could have OS permission granted but the app still track a separate opted-in flag.
- **On logout, tracking is force-stopped** and the per-user geofence preference id is cleared, so the next logged-in user isn't tracked under the previous identity.
- Android has a stub/placeholder repository (`LocationTrackingRepository.getUserIdentifier()` returns a hardcoded placeholder id with a TODO) — **flag as incomplete/possibly dead code**, confirm with engineering before treating anything built on it as final.

## Screens

| Android | iOS |
|---|---|
| `FastTrackCheckInFragment` (multi-step flow) | `FastTrackCheckinView` |
| Security & Privacy settings (geolocation toggle) | (settings equivalent) |
| Home/My Companies banners | `FastTrackGeolocationBanner`, `FastTrackNotificationsBanner`, `FastTrackCheckinBanner` |
| DevOptions geolocation debug panel (mock tracking, dev-only) | not found — may not have an iOS equivalent |

## Platform differences

- **Android centralizes** the start/stop decision in one coordinator class reused by multiple ViewModels; **iOS spreads the equivalent logic** across the check-in flow's own ViewModel and a separate notification-preference sync use case — no single iOS class was found consolidating start/stop across all entry points the way Android's does. **Worth flagging as a potential logic-duplication risk on iOS.**
- Android exposes rich dev-only tooling for geolocation (mock tracking with a synthetic route, live diagnostics); no iOS equivalent was located in the files reviewed.
- iOS's flow title text conditionally differs by step/configuration in a way not obviously mirrored on Android — a minor UI nuance, not a functional gap.

## Key user-facing strings

- *"Fast-Track Your Check-in — Share your precise geolocation to fast-track check-in at jobsites."*
- The full opt-in legal disclaimer (see User Journey above) — quote it verbatim if referencing it elsewhere, don't paraphrase.
- *"Check-ins made easier — Next time you're near a jobsite, your ISN-ID will pop up to help you check in quickly."* (iOS)
- *"This setting is disabled because you are not connected to any clients who are currently using geolocation features."*

## Open questions for a PO

1. Is Android's `LocationTrackingRepository.getUserIdentifier()` placeholder dead code or an unfinished path?
2. What server-side criteria decide a Quick Check's geolocation requirement — per Hiring Client, per site, or per Quick Check template?
3. Is there an in-app way to fully opt back out (distinct from revoking the OS permission)? A repository method exists to set it false, but no call site setting it to false was found in the reviewed files — confirm the opt-out UX actually exists somewhere.

## Related

- [Quick Check](quick-check.md) — the geolocation requirement that drives this whole feature.
