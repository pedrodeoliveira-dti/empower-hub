# Course Certificates

> Functional documentation — how the feature actually works, grounded in the real code on both platforms. For new developers and POs.

## Purpose

Gives a worker a persistent, shareable, and (optionally) offline-available proof of completed training — a certificate per completed course per contractor/hiring-client relationship. The worker can search, sort, favorite, download for offline/biometric-gated access, share as a file, and inspect a full pass/fail/expiry history for each certificate.

## User journey

1. **List**: certificates grouped by contractor company by default; switchable to a flat list sorted by Name or Completion Date. Search is **local/client-side** substring filtering — unlike [Courses/LMS](courses-lms.md), there's no dedicated search API for certificates.
2. **Certificate details**: employee name, ISN ID, contractor/hiring-client name, completion date, expiration date (if any), pass/complete status, and a barcode generated from the connection's ISN ID.
3. **View Certificate History**: disabled unless the certificate `hasArchive`; opens a history view of prior completion/expiration events, fetched once and then cached for offline use.
4. **Share**: fetches (or reuses a cached/downloaded) certificate file and hands it to the OS share sheet.
5. **Favorite/Bookmark**, **Download for offline** (biometric-gated when accessing offline), **Preview image**: same mechanics as [Documents & Folders](documents-folders.md)/[Bookmarks & Favorites](bookmarks-favorites.md).

## Business rules / validation

- **Expiry is entirely server-computed** — the certificate model carries both a nullable expiration date and an `isExpired` boolean directly from the API. No client-side date-math renewal/expiry logic exists on either platform.
- **Status vocabulary is narrower than course-level status**: only `PASSED` and `COMPLETED` exist at the certificate level — no "failed"/"in progress" here, unlike [Courses/LMS](courses-lms.md)'s fuller status set.
- **History button gating**: enabled only if `hasArchive == true`; iOS additionally disables it once a history fetch already returned empty.
- **Offline behavior**: when offline, the downloaded/local copy is authoritative for both detail lookup and sharing — no network call is attempted.
- **Biometric gating**: offline access and enabling downloads both funnel through the same authorized/needs-setup/unavailable tri-state check as other document types.
- **Sort default**: by Contractor Company ascending; alternates are Name and Completion Date.
- No feature-flag/version split exists for certificates on either platform — confirming the v2/v3 LMS split is specific to [Courses/LMS](courses-lms.md), not certificates.

## Screens

| Android | iOS |
|---|---|
| `coursecertificates/list/TrainingCertificateListFragment` | `Documents/ISN Training Certificates/TrainingCertificates/TrainingCertificatesView` |
| `coursecertificates/detail/TrainingCertificateDetailsFragment` | `TrainingCertificateDetails/TrainingCertificateDetailsView` |
| — | `TrainingCertificateHistory/CertificateHistoryView` |

## Platform differences

- No feature-flag/version split, confirmed on both.
- iOS's `CourseCertificatesService` has a dev/QA-only "simulate failure" cache flag that deliberately throws when enabled — no equivalent found on Android.
- Download plumbing differs (WorkManager on Android vs. a dedicated use-case on iOS) — same concept, consistent with each platform's general download architecture elsewhere, not specific to this feature.

## Key user-facing strings

- *"View Certificate History"* / *"Certificate History Unavailable"* / *"Certificate History Available"*

## Open questions for a PO

1. Is there any renewal/reissue workflow for an expired certificate — does the worker retake the underlying course, and is that link surfaced from the certificate screen? No such cross-navigation was found on either platform.
2. What determines `hasArchive`? Appears to be a server-computed flag with no visible client-side business rule.
3. Confirm the iOS "simulate failure" cache flag is dev/QA-only and not reachable in production builds.

## Related

- [Courses/LMS](courses-lms.md) — the courses that produce these certificates.
- [Documents & Folders](documents-folders.md), [Bookmarks & Favorites](bookmarks-favorites.md) — shared offline/biometric/bookmark mechanics.
