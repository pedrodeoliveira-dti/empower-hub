# Product Overview

**Product**: Empower (Android package `com.isn.empower`; iOS app target `Empower`), by **ISN** (ISNetworld, `isnetworld.com`).

**What it is**: a contractor/worker safety-and-compliance companion app. This is inferred structurally from the code in both `MyIsn.Android` and `MyIsn.iOS` — the login flow is Azure AD B2C via MSAL, and the feature set centers on: hazard assessment, safety training/certifications, site-safety "quick checks," toolbox talks, worker forms, acknowledgements, and a digital ID ("ISN ID") that connects a user to one or more companies. No product/business documentation was found in either repo — the description above is a structural read of the code, not confirmed business copy. Treat feature names as what the code calls them, not verified end-user terminology.

**Primary users**: individuals ("ISN ID" holders — workers/contractors) who connect to one or more companies, complete safety training and compliance requirements, and carry a digital ID card. A secondary "company" or "staff" perspective is implied by connection/visitor-management flows but wasn't independently confirmed.

## Platforms

| Repo | Platform | Role |
|---|---|---|
| `MyIsn.Android` | Android (Kotlin, Jetpack Compose) | Client app |
| `MyIsn.iOS` | iOS (Swift, SwiftUI) | Client app |
| `Mockoon` | — | Local mock backend both clients can point at for local dev (not user-facing) |

No web client exists in this workspace.

## Core domains / user journeys

Found as a distinct feature area in **both** apps (folder names in `MyIsn.Android/app/src/main/java/com/isn/empower/ui/` and `MyIsn.iOS/Empower/Screens/`), backed by matching API domains in `Mockoon`:

- **Onboarding & Login** — Azure AD B2C sign-in (MSAL on both platforms), email verification, profile match, biometric unlock.
- **Connections** — connecting to a company via an ISN ID, connection status/removal, ISN ID recovery.
- **Visits / Visitor management** — visit check-in/check-out, tied to a connection.
- **ISN ID Wallet** — a digital ID card added to the device wallet. **Diverges by platform**: Google Wallet on Android (`wallets/google-passes/isn-id-cards`) vs Apple Wallet/PassKit on iOS (`v2/wallets/apple-passes/isn-id-cards`) — see `docs/cross-platform-flows.md`.
- **Quick Check** — a site-safety compliance check flow, including a QR-code flow. The largest feature area by endpoint count on both platforms.
- **Hazard Assistant** — AI-assisted hazard scene description/analysis with a rating step.
- **Toolbox Talks** — safety briefings, PDF export, ratings.
- **Worker Forms** — dynamic forms with per-item responses and submission history.
- **Courses / LMS / Course Certificates** — training courses, certificates, and an LMS integration (iOS explicitly feature-flags a v2→v3 LMS migration; Android's course endpoints show the same v2/v3 split).
- **Acknowledgements** — required sign-offs, with history.
- **Written Programs** — regional compliance documents with opt-ins.
- **Bulletins / Notifications** — push + in-app notification center.
- **Documents / Folders** — document management, downloadable for offline access.
- **Geolocation** — location tracking (Radar SDK on both platforms).
- **Bookmarks/Favorites** — saving items for later.

## Functional documentation

Each domain above has its own functional doc — purpose, real user journey, business rules found in code, platform parity, and open questions for a PO — under [`docs/features/`](features/README.md).

## Known gaps

- No confirmed business/product documentation exists in either app repo or this hub — everything above is derived from code structure (folder names, endpoint paths, screen names), not from a PRD or design spec.
- `Mockoon/mockoon-configs/mobile/isn-mobile.json` mocks a distinct route set (`v1/sso/connections`, `v1/accounts`, `v1/permissions`, `v1/quarterly-verification`, plus duplicated `hazard-assistant`/`toolbox-talks` routes) that **no consumer was found for** in either `MyIsn.Android` or `MyIsn.iOS` as currently analyzed — see `docs/api-contracts.md`. This may be a legacy/other consumer, or functionality not yet wired up client-side.
