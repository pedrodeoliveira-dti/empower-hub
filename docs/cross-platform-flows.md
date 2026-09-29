# Cross-Platform Flows

Per-journey behavior on Android and iOS, as evidenced by each repo's own screens/services (see `docs/product-overview.md` for what each journey is). Only flows actually found on at least one platform are listed.

| Flow | Android | iOS | Notes on divergence |
|---|---|---|---|
| Login / Onboarding | Yes — MSAL/Azure AD B2C | Yes — MSAL/Azure AD B2C | Same auth provider both sides. |
| Connections (add/status/recovery) | Yes | Yes | — |
| Visits / visitor check-in-out | Yes (`ui/visits`, `v1/visits/*`) | Yes (`v1/visits/*` in `Endpoint.swift`) | — |
| **ISN ID Wallet** | Yes — **Google Wallet** (`wallets/google-passes/isn-id-cards`) | Yes — **Apple Wallet/PassKit** (`v2/wallets/apple-passes/isn-id-cards`) | Different endpoint paths by platform, as expected for native wallet integrations — but note `Mockoon`'s `empower.json` only mocks the `apple-passes` route (see `docs/api-contracts.md`); no `google-passes` mock route was found, a gap for Android local dev. |
| Quick Check | Yes (`v4/quick-checks/*`) | Yes (`v4/quick-checks/*`, QR reader) | Largest feature area on both platforms by endpoint count. |
| Hazard Assistant | Yes (`v1/hazard-assistant/*`) | Yes (`v1/hazard-assistant/*`) | — |
| Toolbox Talks | Yes (`v2/toolbox-talks/*`) | Yes (`v2/toolbox-talks/*` implied by service naming) | — |
| Worker Forms | Yes (`worker-forms/*`) | Yes (`worker-forms/*`) | — |
| Courses / LMS / Certificates | Yes, with v2/v3 split (`v2/courses`, `v3/courses/lms`) | Yes, with `Config.isFeatureFlagEnabled(.lmsLibrary)` gating v2 vs v3 | Both platforms model the same v2→v3 LMS migration — confirm the flag/rollout state matches on both before assuming parity. |
| Acknowledgements | Yes | Yes (own service under `Networking/Services/`) | — |
| Written Programs | Yes | Yes (`v1/written-programs/*` in `Endpoint.swift`) | — |
| Bulletins / Notifications | Yes (`bulletins/*`, `v2/notifications/*`) | Yes (own service) | — |
| Documents / Folders | Yes | Yes (`folders/*`, `documents/*`) | Both also support offline/downloaded documents locally (not network calls). |
| Geolocation | Yes (Radar SDK) | Yes (Radar SDK) | Same SDK both sides. |
| Bookmarks / Favorites | Yes (`v2/bookmarks`) | Yes — confirmed present, nested under `Screens/Tabs/Documents/Favorites/` rather than a top-level folder | Same naming split on both platforms (internal "Bookmark," UI "Favorites"). See `docs/features/bookmarks-favorites.md`. |
| Dev/debug environment switcher | Yes — Dev Options screen | Yes — Dev Sandbox (`#if !APPSTORE`) | Both gate this out of App Store/production release builds. |

## Local mock wiring (dev-only, not a user flow)

Both apps can point at `Mockoon` for local development — see `docs/architecture.md` "How the pieces fit together" and `docs/api-contracts.md` for the exact prefix mechanism. Android requires Charles Proxy SSL mapping plus an `empower`-prefixed base URL; iOS just needs the Dev Sandbox "API Environment" screen pointed at a local or remote Mockoon instance.
