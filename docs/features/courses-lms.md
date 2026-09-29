# Courses / LMS

> Functional documentation — how the feature actually works, grounded in the real code on both platforms. For new developers and POs.

## Purpose

Lets a worker see every training/course required for the companies they're connected to, launch and complete those courses inside the app (or in a browser), rate the training afterward, and — for connected users — browse an open catalog of optional courses ("LMS Library"/"Training Library") to self-enroll in or request access to. This is how ISN tracks regulatory/site-safety training compliance.

## User journey

1. **Training dashboard** with 2–3 tabs: "Action Required," "All Assigned," and (only if LMS is enabled + user has an active connection) "Library."
2. **Action Required / All Assigned**: assigned courses/groups per connected company, sortable and filterable by company. Tapping navigates to details or a nested group screen.
3. **Library (LMS)**: curated categories plus an "All Trainings" pseudo-category, with a debounced (500ms) search, sort (Recently Added/Most Viewed), and filter (category, country, language, provider, mobile-only, max duration). The dedicated search API is only called when a search term is typed or a non-default filter/sort is applied — otherwise the client shows already-fetched category data.
4. **Course details**: description, criteria, status. Assigned course → Play/Begin. LMS-library course → Enroll or Request-Assignment depending on eligible connections.
5. **Launch ("Begin Training")**:
   - **In-app**: may first show a **consent screen** (server-provided legal text) if required — the confirm button stays disabled until the user scrolls to the end. Then the course opens in an in-app WebView; closing it runs a JS call to save progress before exiting.
   - **Device browser**: a confirmation dialog, then opens externally.
   - A dev-only override can force either behavior regardless of the server value.
6. **Completion & rating**: after a refresh detects a completed/passed status, a thumbs up/down popup appears. Down leads to a "tell us more" screen (checkboxes + character-limited free text) before a "Thanks for sharing" confirmation.
7. **LMS-only actions**: "Enroll" (self-enroll where allowed) or "Request Assignment" (ask the contractor); with >1 eligible connection the user picks a company first.

## Business rules / validation

### The v2 → v3 LMS split (identical mechanism on both platforms, one flag)

- Flag: `key_learning_management_system` (Android) / `lms_library` (iOS), remote-config-controlled, shown to devs/QA as **"LMS Library."**
- **The only code-level difference between v2 and v3**: which endpoint URL is called for "get all courses"/"get course details" — the flag switches the version, nothing else. Confirmed identically on both platforms.
- The same flag **also** independently controls whether the entire "Library" tab/optional-course catalog exists at all (further gated on the user having an active connection).
- **Practical read for a PO**: v2 vs. v3 is a single API-contract migration for the core "assigned courses" call, bundled under the flag that also turns the whole optional-training-library feature on/off. There is **no gradual/percentage rollout logic in the client** — it's a single boolean per-tenant/environment flag.

### Other rules

- **Launch destination**: server-driven (`IN_APP`/`DEVICE_BROWSER`), plus a `DESKTOP_ONLY` course status. Consent is required only if the course details response says so **and** provides consent text; consent is per-flow, not persisted.
- **Rating** is only offered when a course transitions to completed/passed **after a refresh** — not simply because the user opened it.
- **Course/renewal status vocabulary is entirely server-driven**: `notStarted`, `inProgress`, `completed`, `passed`, `failed`, `expired`, `renewalAvailable`, `retakeAvailable`, `notApplicable`, `requested`. No renewal-specific screen was found — renewal appears to reuse the same launch flow ("retake the same course").

## Screens

| Android | iOS |
|---|---|
| `training/dashboard/TrainingDashboardFragment` | `Training/Dashboard/TrainingDashboardView` |
| `training/details/TrainingDetailsFragment` | `Training/CourseDetails/CourseDetailsView` |
| `training/group/TrainingGroupFragment` | `Training/Groups/TrainingGroupsView` |
| `training/lms/alltrainings`, `lms/category` | `LMS Library/Views/LmsCategoryDetailsView`, `Sort and Filter/LibrarySortFilterView` |
| `training/launchcourse/TrainingLauncherActivity` (WebView), `TrainingConsentFragment` | `LaunchCourse/Course/LaunchCourseView`, `LaunchCourse/Consent/LaunchCourseConsentView` |

## Platform differences

- Identical v2/v3 split at the identical layer on both platforms — no divergence.
- Android's Library-tab visibility check and iOS's are functionally equivalent (flag-on AND active connection) but expressed via different connection-state plumbing.
- Android's launch-destination override is one dev-options enum; iOS uses two separate boolean flags — same capability, different modeling.
- Android's course-launch WebView lives in a dedicated `Activity`; iOS uses a ViewModel + representable pushed via navigation — same exit-JS mechanism (`Control.TriggerLegacyReturnToLMS()`) on both.

## Key user-facing strings

- *"Training is not launching — Reach out to your company admin for assistance"* (Android)
- *"Training Library"* / *"Browse optional trainings here as they become available."* (iOS)
- *"Unable to enroll in this training at this time. Please try again later."*
- *"Unable to request the assignment to this training at this time. Please try again later."*
- *"Begin Training"* (consent CTA)

## Open questions for a PO

1. Is the LMS flag fully rolled out to 100% of tenants, or still staged per-environment? No staging/percentage logic exists client-side.
2. What exactly changed in the v3 response contract that required a version bump?
3. Will the LMS Library catalog endpoints ever get their own v2 fallback, or stay permanently v3-only/flag-gated?
4. Is renewal genuinely just "retake the same course," or is there a distinct renewal workflow not yet surfaced in either client?

## Related

- [Course Certificates](course-certificates.md) — the artifact produced by completing a course.
- [Quick Check](quick-check.md) — a Quick Check line item can point at a course/training requirement.
