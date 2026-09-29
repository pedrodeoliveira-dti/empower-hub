# API Contracts

Source of truth: `Mockoon/mockoon-configs/` — this repo has no app code, only Mockoon mock-server environment exports. Real backend hostnames were not discoverable from either client repo (they come from remote config at runtime — see `docs/architecture.md`), so **Mockoon's mocked routes are the most concrete API contract available in this workspace.**

## How environment selection actually works

Not native Mockoon multi-environment selection — a **custom build-time merge**:

1. `Mockoon/scripts/merge-configs.js` reads `mockoon-configs/_base.json` for shared server settings (port, hostname, CORS, headers), then discovers every other `*.json` under `mockoon-configs/` (`default.json`, `empower/empower.json`, `mobile/isn-mobile.json`), derives a **route prefix from each file's folder path** (`empower/empower.json` → prefix `empower/`; `mobile/isn-mobile.json` → prefix `mobile/`; `default.json` at root → no prefix), and concatenates all routes into one `merged.json`.
2. The Docker image (`FROM mockoon/cli:latest`) always serves this single merged file on port 8080 (hardcoded in the `Dockerfile` `CMD` — note `.github/copilot-instructions.md` in that repo incorrectly claims the port is configurable via a `PORT` env var; it isn't, per the actual Dockerfile).
3. **Practical effect**: every route from every config file is always present simultaneously in one server, distinguished only by path prefix. A client's configured base URL must already include the right prefix (e.g. `.../empower/`) — the client's own relative request paths (e.g. `v1/hazard-assistant/config`) do **not** repeat that prefix themselves. This is exactly what `MyIsn.Android`'s `docs/LOCAL_ENVIRONMENT.md` means by "requires an `empower` prefix under Mockoon's API URL settings."
4. `_base.json` itself defines **no routes** — it's a settings template only consumed by the merge script, not a live "extends" reference.

## Environment: `default.json` (no prefix)

| Method | Path | Response | Consumed by |
|---|---|---|---|
| GET | `/health` | 200 `{"status":"ok"}` | Infra/health check — not called by either app's endpoint list |

## Environment: `empower/empower.json` (prefix `empower/`) — 133 routes, 27 folders

This is the environment both `MyIsn.Android` (`IsnService.kt`, 118 endpoints) and `MyIsn.iOS` (`Endpoint.swift`, ~90 endpoints) actually target — nearly every domain below has a same-domain match in both apps' own endpoint lists (confirmed at the domain level; not every individual route was cross-checked one-by-one).

| Domain (Mockoon folder) | Representative routes | Consumed by |
|---|---|---|
| Profile | `GET/POST/DELETE /profile`, `/profile/photo`, `/profile/push-notification-preferences`, `/profile/deletion-request`, `/profile/feedback` | Android, iOS |
| Connections (v1/v2/v2.1) | `POST/GET /v2/connections`, `PATCH /v2.1/connections/{id}`, `GET /connections/{id}/profileImage`, `GET /connections/{id}/companyLogo`, `POST /v2/connections/profile-match`, `POST /v2/connections/isn-id-recovery` | Android, iOS |
| Visitor Connections / Visits (v1) | `GET/POST /v1/visits`, `GET/POST /v1/visits/connections`, `POST /v1/visits/{id}/check-ins`, `POST /v1/visits/{id}/check-outs`, `DELETE /v1/visits/{id}`, `PATCH /v1/visits/connections/{id}` | Android, iOS |
| Quick Checks (v1–v4) | `GET /quick-checks`, `DELETE /quick-checks/{id}`, `GET /v2/quick-checks/new/initial-parameters`, `GET /v4/quick-checks/new/additional-parameters`, `POST/GET /v4/quick-checks`, `POST /v4/quick-checks/qr-ids`, `POST /v4/quick-checks/{id}/assignment`, `POST /v4/quick-checks/{id}/copy`, `GET /v3/quick-checks/{id}/share-info`, `GET /v3/quick-checks/{id}/operator-qualifications/{oqReportId}` | Android, iOS |
| Hazard Assistant (v1) | `GET /v1/hazard-assistant/config`, `GET/POST /v1/hazard-assistant/hazard-analyses`, `GET /v1/hazard-assistant/hazard-analyses/{id}/pdf`, `POST/PUT /v1/hazard-assistant/ratings`, `POST /v1/hazard-assistant/scene-descriptions` | Android, iOS |
| ToolboxTalks (v1/v2) | `GET /v2/toolbox-talks`, `/config`, `/{id}`, `GET/POST /v2/toolbox-talks/{id}/pdf`, `POST /v2/toolbox-talks`, `POST/PUT /v2/toolbox-talks/ratings` | Android, iOS |
| Courses (v2/v3) | `GET /v2/courses`, `/v2/courses/{id}`, `POST /v2/courses/{id}/launch`, `POST /v2/courses/{id}/viewed-status`, `POST/PUT /v2/courses/ratings...`, `GET /v3/courses`, `/v3/courses/lms`, `/v3/courses/lms/categories`, `POST /v3/courses/lms/enrollments`, `/requests`, `/searches` | Android, iOS — both model the same v2→v3 LMS split |
| CourseCertificates (v2) | `GET /v2/course-certificates`, `/{id}`, `/{id}/document`, `/{id}/images/preview`, `/{id}/history` | Android, iOS |
| WorkersAcknowledgement / Acknowledgements (v1) | `GET /acknowledgements`, `/summary`, `/{id}`, `/{id}/history`, `POST /acknowledgements/{id}/acknowledgement` | Android, iOS |
| WorkerForms (v1) | `GET /worker-forms`, `/summary`, `/{id}`, `/{id}/history`, `POST /{id}/category-filters`, `/items/{itemId}/responses`, `/submissions` | Android, iOS |
| Written Programs (v1) | `GET /v1/written-programs`, `/regions`, `/opt-ins`, `GET /v1/written-programs/documents/{id}` | Android, iOS |
| Bulletins (v1) | `GET /bulletins`, `/summary`, `PATCH /bulletins/{id}`, `POST /bulletins/updates`, `GET /bulletins/documents/{id}` | Android, iOS |
| Notifications (v1/v2) | `GET /v2/notifications`, `POST /v2/notifications/acknowledgments`, `POST /notifications/push-registrations`, `POST /notifications/{id}` | Android, iOS |
| Documents (v1) | `GET/PATCH/DELETE /documents/{id}`, `POST /documents`, `GET /documents/images/{id}` | Android, iOS |
| Folders | `GET/POST/PATCH/DELETE /folders`, `/folders/{id}` | Android, iOS |
| Bookmarks (v2) | `GET/POST/DELETE /v2/bookmarks` | Android confirmed; iOS not confirmed in Step 1 (see `docs/cross-platform-flows.md`) |
| Wallet | `POST/PUT /v2/wallets/apple-passes/isn-id-cards` | **iOS only, confirmed.** Android calls `wallets/google-passes/isn-id-cards` for the same feature (Google Wallet) — **no matching Mockoon route found for the Android path.** This is a real local-dev gap: add a `google-passes` route to `empower/empower.json` if Android needs to mock this flow locally. |
| WorkReadyProfile (v1) | `GET/POST/DELETE /work-ready-profile/*` (job-titles, skills, experiences) | Not independently confirmed against either app's endpoint list — worth verifying |
| Emergency Notifications | `GET /emergency/active`, `POST /emergency/{id}/status` | Not independently confirmed against either app's endpoint list — worth verifying |

## Environment: `mobile/isn-mobile.json` (prefix `mobile/`) — 21 routes, 5 folders

**No consumer was found** for this environment in either `MyIsn.Android` or `MyIsn.iOS` as analyzed — neither app's endpoint list includes `sso/connections`, `accounts`, `permissions`, or `quarterly-verification`. The `hazard-assistant`/`toolbox-talks` routes here duplicate `empower/`'s (same paths, different prefix, and without the `v2` on toolbox-talks). Flagging as an **open question** rather than guessing: this may be a legacy or different consumer, or functionality not yet wired up client-side. Route table (for completeness):

| Method | Path | Notable response codes |
|---|---|---|
| POST | `/v1/sso/connections` | 426 (upgrade required), 200 ×4, 400/404/409, 500 |
| GET | `/v1/accounts` | 426, 200 ×8, 401/409, 500 |
| GET | `/v1/permissions` | 426, 200, 401/404, 500 |
| GET | `/v1/permissions/catalog` | 426, 200, 304, 500 |
| GET/POST | `/v1/hazard-assistant/*` | mirrors `empower/`'s hazard-assistant routes |
| GET/POST/PUT | `/v1/toolbox-talks/*` | mirrors `empower/`'s toolbox-talks routes, without the `v2` prefix |
| GET/POST | `/v1/quarterly-verification` | 426, 200/204, 400/401, 500 |

The `426` (upgrade required) pattern on several routes here — not seen in `empower/`'s routes — suggests a forced-update/version-gate flow specific to this environment; worth investigating if this is a legacy API version still in use somewhere.

## Third-party contracts (non-Mockoon)

Beyond the ISN backend mocked above, both clients integrate real third-party SDKs directly (not mocked here): Firebase (Analytics/Crashlytics/Remote Config, +Performance/FCM/Dynamic Links on Android, +Performance on iOS), MSAL/Azure AD B2C, Pendo, Qualtrics, Radar (geolocation). See `docs/observability.md` and `docs/architecture.md` for what each is used for. Contract changes to the real ISN backend API (the routes above) should be treated as the primary "third-party contract" this hub's `/speckit.plan`/`/speckit.review` care about, alongside these SDKs' own breaking changes.
