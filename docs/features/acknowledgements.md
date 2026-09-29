# Acknowledgements (Workers Acknowledgement / WAck)

> Functional documentation — how the feature actually works, grounded in the real code on both platforms. For new developers and POs.

## Purpose

Lets a hiring client require a worker to read a policy/document and formally agree to it ("I have read and agree to comply with the above requirements") before continuing — a digital signature-style compliance gate. Replaces paper sign-off sheets, tracks agreement history/dates, and supports offline access to previously downloaded acknowledgements (behind biometrics) for workers without reliable connectivity.

## User journey

1. **List**: assigned acknowledgements, sortable by Status/Name/Hiring Client, searchable, each with a status (Required/Acknowledged/Expired) and a bookmark toggle. A banner surfaces if anything is unresolved.
2. Tapping an item: online → fetches full details and navigates in; offline → first checks biometric authentication before opening a previously **downloaded** copy.
3. **Details**: description, terms, associated documents, dates. If status is `REQUIRED`, an agreement section appears where the user must **scroll to the end of the terms** before "Agree" unlocks (literal "(Scroll to unlock)" copy until fully scrolled).
4. Tapping **Agree** posts the acknowledgement; on success, navigation returns to wherever the user came from (Home, Quick Check, Documents, Search, Favorites, Notifications, Visit Details — Android models this as an explicit enum of return destinations).
5. **History**: a toggle reveals prior acknowledgement dates — agreement can be a recurring/rolling requirement, distinguished from a one-time/static one.
6. **Bookmark/Favorite** (see [Bookmarks & Favorites](bookmarks-favorites.md)) and **Download for offline** both work the same way as other document types.

## Business rules / validation

- **Agreement gate**: Agree is disabled until the user has scrolled the full terms text — confirmed on iOS; Android has the equivalent enable-flag but the exact scroll-detection call site lives in the Compose UI layer (not traced in this pass — worth confirming both platforms enforce the same "must reach bottom" rule).
- **Status model**: `REQUIRED`, `ACKNOWLEDGED`/`acknowledgementApplied` (both map to the same "Acknowledged" label — likely a backend historical-vs-currently-in-effect nuance, worth a PO clarification), `EXPIRED`. **Special case**: an expired-but-**rolling** acknowledgement is treated as `REQUIRED` again rather than a dead-end expired state — confirmed on iOS; not directly confirmed whether Android implements the same rolling-reopens-as-required rule.
- **Unsupported file types guard**: `.doc/.docx/.xls/.xlsx` documents show a "File Not Supported" dialog rather than attempting to render — code explicitly flags this as a short-term edge-case workaround, since the backend isn't expected to send these types.
- **Offline access requires biometrics** — same pattern as [Documents & Folders](documents-folders.md).
- Document viewing is fetch-and-view (not client-generated), same as [Written Programs](written-programs.md); downloads queue a background worker.
- **Sort default**: Status ascending on both platforms, so unresolved items surface first.

## Screens

| Android | iOS |
|---|---|
| `AcknowledgementListFragment` | `WAckListView` |
| `AcknowledgementDetailsFragment` | `WAckDetailsView` (+ sub-views: History, Status, Terms, Documents, Description) |

## Platform differences

- Android's list ViewModel tracks an explicit 8-value "originating screen" enum for precise back-navigation after agreeing, baked directly into the ViewModel; iOS's return navigation is comparatively implicit (pop/dismiss) — either a simpler iOS navigation model or logic living elsewhere not inspected in this pass.
- iOS explicitly models `expirationType` (`.rolling`/`.staticExpiration`/`.none`) as a first-class enum, including a UTC timezone override because the API returns expiration dates with zeroed hours; the Android domain model for this distinction wasn't located in this pass — check `data/.../model/domain/acknowledgements/` directly.

## Key user-facing strings

- *"I have read and agree to comply with the above requirements"*
- *"(Scroll to unlock)"*
- *"This folder is empty. Your assigned acknowledgments will appear here."*
- *"There are new documents that require your acknowledgements."* (Home banner)
- *"We were unable to locate that acknowledgment, it may have been updated or you are no longer assigned."*

## Open questions for a PO

1. Confirm the Android scroll-to-unlock detection directly (Compose UI layer) to ensure both platforms enforce identical "must reach the bottom" behavior.
2. What's the user-facing difference between `acknowledged` and `acknowledgementApplied`?
3. Confirm whether Android has the same rolling-expiration-reopens-as-required rule found on iOS.

## Related

- [Documents & Folders](documents-folders.md), [Bookmarks & Favorites](bookmarks-favorites.md) — shared offline/biometric and bookmark mechanics.
- [Quick Check](quick-check.md) — a Quick Check line item can point at an Acknowledgement.
