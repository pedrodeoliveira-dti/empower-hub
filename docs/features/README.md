# Feature Functional Documentation

Functional (not just technical) documentation of every feature domain in the Empower app, for new developers and Product Owners who need context fast — what a feature actually does, the real user journey, the business rules found in code, platform (Android/iOS) parity, real user-facing strings, and open questions worth a PO's attention. Grounded in the real code (`MyIsn.Android`/`MyIsn.iOS`) as of 2026-09-28 — every non-obvious claim is cited to its source file inside each doc.

This complements the cross-platform-level docs one level up (`docs/architecture.md`, `docs/api-contracts.md`, `docs/cross-platform-flows.md`) — those describe *how the apps are built*; these describe *what each feature does for the user*.

## Identity & Onboarding
- [Login & Onboarding](login-onboarding.md)
- [Connections](connections.md)
- [Visits (Visitor Management)](visits.md)
- [ISN ID Wallet](isn-id-wallet.md)

## Site Safety
- [Quick Check](quick-check.md)
- [Hazard Assistant](hazard-assistant.md)

## Training & Compliance
- [Toolbox Talks](toolbox-talks.md)
- [Worker Forms](worker-forms.md)
- [Written Programs](written-programs.md)
- [Acknowledgements](acknowledgements.md)

## Learning
- [Courses / LMS](courses-lms.md)
- [Course Certificates](course-certificates.md)

## Utility
- [Bulletins & Notifications](bulletins-notifications.md)
- [Documents & Folders](documents-folders.md)
- [Geolocation ("Fast-Track Check-In")](geolocation.md)
- [Bookmarks / Favorites](bookmarks-favorites.md)

## Recurring feature flags worth knowing up front

- **`VisitorManagementSystemFlag`** — gates the entire Visits/VMS surface end-to-end; see [Connections](connections.md#related-feature-flags).
- **`PreventConnectionsWithFailureReasonFlag`** — changes whether a failed connection is `INACTIVE` or `SKIPPED`; see [Connections](connections.md#related-feature-flags).
- **`lms_library` / `key_learning_management_system`** — the v2→v3 Courses/LMS split; see [Courses/LMS](courses-lms.md).
- **`ComposeNavigationFlag`** (Android only) — a pure navigation-architecture migration flag, not a business rule; shows up throughout many ViewModels.

## Known cross-feature gaps surfaced during this pass

- Worker Forms has no PDF/export flow, unlike every sibling compliance feature — confirm with the PO whether that's intentional.
- No cap/expiry was found anywhere for offline-downloaded documents/certificates/acknowledgements — confirm intended limits with the PO.
- Several PII/token logging risks exist on both platforms in non-production build variants — see `docs/observability.md`.
