# Connections

> Functional documentation — how the feature actually works, grounded in the real code on both platforms. For new developers and POs.

## Purpose

Lets a worker link their Empower profile to one or more ISNetworld/hiring-client companies via an 8-digit **ISN-ID**, review/accept each company's Terms & Conditions, and manage those connections afterward (view details, remove a connection, recover a forgotten ISN-ID by email).

## User journey

**Enter ISN-ID**: user types 8 digits (or arrives via deep link). Both platforms require exactly 8 characters; Android additionally validates numeric-only client-side (`IsnIdModel.kt`, `VALID_ID_LENGTH = 8`) — iOS enforces the length in the UI but appears to delegate digit-only validation to the backend response. On submit, both contractor-connection creation and (if the VMS flag is on) visitor-connection creation run in parallel.

Failure maps a server error code to a specific dialog:

| Error code | Dialog |
|---|---|
| `invalid_isn_id` | "Invalid ISN-ID" |
| `record_mismatch` | "User Info Mismatch" (last name doesn't match ISNetworld) |
| `inactive_company` | "Inactive Company" |
| `inactive_employee` | "Inactive Employee" |
| `isn_id_already_in_use` | Disambiguated: if via deep link, re-checks the user's own pending connections first (recovers an interrupted flow) before showing "Already Connected" vs "Already in Use" |
| `subscription_expired` | "Subscription Expired" |
| `inactive_visitor` | "Inactive Visitor" |
| anything else | generic "Company Connection Error" with retry |

**Connect Companies / Connections Found** → user checks/unchecks which found connections to pursue (unchecked ones are marked `SKIPPED`) → **Terms & Conditions**, one connection at a time; Agree → `ACCEPTED`/`ACTIVE`, Decline → `SKIPPED` → **Successful Connections** (buckets into Active/Pending/Skipped) → if wallet-eligible, **Add to Wallet** (see [ISN ID Wallet](isn-id-wallet.md)); otherwise routes back to the originating screen.

**ISN-ID recovery**: email validated against a remote-config-supplied regex, submitted to both contractor and visitor recovery endpoints in parallel; success on **either** routes to Enter ISN-ID with an "email sent" confirmation.

**Connection Details / Removal**: "Remove" is only offered for `ACTIVE` connections. Removing sets status to `INACTIVE`. Viewing the scannable ISN-ID card requires a biometric check when online (offline uses the cached card only).

## Business rules / validation

- **ISN-ID format**: exactly 8 characters; Android additionally enforces numeric-only client-side.
- **`CreateConnectionErrorType`** (backend status strings) is the single source of truth for every error dialog — see table above.
- **Connection status categories** (for UI grouping): Active, Pending, Failed, Available, Inactive, plus "No Category."
- **Removability gate**: `INACTIVE`/`PENDING`/`SKIPPED` connections can't be "removed" (nothing active to remove). `PENDING`/`SKIPPED` can always be (re)activated; `INACTIVE` only if the `PreventConnectionsWithFailureReasonFlag` is on, or there's no failure reason.
- **Failure-reason gating**: when that same flag is on, a connection with a non-`NONE` failure reason shows a banner and disables "activate" — this materially changes what actions the user sees.
- Skipping during Enter ISN-ID requires confirming: *"To connect to your contractor company and complete Hiring Client requirements, you must enter your ISN-ID."*

## Screens

| Android | iOS |
|---|---|
| `EnterIsnIdFragment` | `EnterISNIDView` |
| `HelpFindMyIsnIdFragment` | `RecoverISNIDView` |
| `ConnectCompaniesFragment` | `ConnectionsFoundView` |
| `TermsAndConditionsFragment` | `TermsAndConditionsView` |
| `SuccessfulConnectionsFragment` | `ConnectionSuccessView` |
| `MyCompaniesFragment` (tabbed: Visit Passes/Quick Checks/Connections) | folded differently across Home/Profile — not a 1:1 match, worth confirming with the team |
| `ConnectionDetailsFragment` | `CompanyDetailsView` |
| `ConnectionRemovedFragment` | `ConnectionRemovedView` |

## Platform differences

- Android branches UI/back-button behavior on an explicit `originatingScreen == Screen.LOGIN` check across several screens; iOS achieves the same via `isAccCreationFlow` (`navigationState.tab == nil`) — same intent, different mechanism.
- Android has a distinct tabbed **My Companies** screen; iOS's equivalent is not a 1:1 folder match — not fully traced, worth confirming directly with the iOS team before assuming parity.
- The "ISN-ID already in use" disambiguation logic exists on both platforms but with materially different code paths and a subtly different check for the deep-link case.
- iOS's Terms & Conditions walks contractor connections before visitor connections using local index counters; Android maps a single flattened list built upstream — contractor-first ordering is not explicitly guaranteed in the Android code reviewed.

## Key user-facing strings

- *"The information in your Empower profile doesn't match that ISN-ID. Contact your admin to get this corrected."*
- *"It appears that the company you are trying to connect to is inactive. Please try connecting to a company that is active or reach out to ISN support for help!"*
- *"Check Your Inbox! ... No Email? Check your spam / junk folder or reach out to your admin."*

## Open questions for a PO

1. Is contractor-before-visitor T&C ordering a real business rule, or just an iOS implementation detail?
2. What exactly does `record_mismatch` check server-side — only last name, or also other PII?
3. Surface the actual ISN-ID-recovery email-validation regex (currently only in remote config, not visible in either client repo).

## Related feature flags

These three flags recur across Connections, [Visits](visits.md), and [ISN ID Wallet](isn-id-wallet.md):

- **`VisitorManagementSystemFlag`** (Android) / `Config.isFeatureFlagEnabled(.visitorManagementSystem)` (iOS) — the single most important toggle in this feature group. When off, all VMS/visitor-connection calls silently no-op and the "visitor" onboarding page doesn't appear.
- **`PreventConnectionsWithFailureReasonFlag`** — changes whether a connection with a failure reason is marked `INACTIVE` (on) vs `SKIPPED` (off), which changes what Activate/Remove actions are available.
- **`ComposeNavigationFlag`** (Android only) — a pure architecture-migration flag (legacy XML Navigation vs. Compose Navigation), not a business rule. Shows up throughout Connections/Visits/Wallet ViewModels as parallel event-emission code paths.
