# Observability

## Android (`MyIsn.Android`)

- **Logging**: Timber, planted only when `buildConfigProvider.isDebugOrInternalBuild` is true (`TimberStartupInitializer.kt`) — no tree planted in `productionRelease`, so Timber calls are silent there.
- **Crash reporting**: Firebase Crashlytics (`recordException`/`setCustomKey` in `MigrationTelemetryImpl.kt`).
- **Performance**: Firebase Performance plugin.
- **Analytics**: Firebase Analytics `logEvent`; Pendo and Qualtrics also function partly as analytics/engagement SDKs.
- **HTTP inspection**: Chucker, enabled in `debug` and `internalRelease` (the QA-distributed variant) builds; no-op in `productionRelease`. `Authorization`/`Bearer` headers are explicitly redacted (`IsnServiceFactory.kt`) — **response bodies are not redacted**.

### PII / secret logging risks — flagged, not fixed

- `B2CUtils.kt` (`IAuthenticationResult.log()`) builds a log message containing the **raw MSAL access token** and logs it via `Timber.v`. Called from `LoginViewModel`, `ProfileViewModel`, `TroubleVerifyingFragment`, `HomePhaseThreeViewModel`.
- `ScannableIsnIDViewModel.kt` and `AddConnectionsToWalletViewModel.kt` log a **raw JWT** (`Timber.d("JWT Data for Google Wallet: $jwtToken")`).
- `CloudMessagingService.kt` / `CloudMessagingHelper.kt` log the **raw FCM push token** and Firebase Installation ID.
- Mitigation in place: these are `Timber.v`/`Timber.d` calls, silent in `productionRelease`. But they **do** log in `internalRelease` (QA build), and Chucker is also active in that same variant with unredacted response bodies — together these mean auth tokens are recoverable from an `internalRelease` build via on-device logs or Chucker's HTTP inspector. Worth a security/PO review; not fixed by this analysis.

## iOS (`MyIsn.iOS`)

- **Logging**: `PersistentLogger` wraps `os.Logger` and additionally writes to an on-device `PersistentLogStore` file for non-App-Store builds (`#if !APPSTORE`), viewable in-app via the Dev Sandbox "Logs" screen. Max file count/size configurable via Firebase Remote Config.
- **API request logging**: `APIBackendService.issueRequest` logs `urlRequest.debugDescription` (method+URL, not headers/body) and HTTP status at `.debug` for every call.
- **Crash reporting**: Firebase Crashlytics (`FirebaseInterface.recordNonFatal`), forwarding both raw errors and typed `ServiceError`s with contextual metadata (no bodies).
- **Analytics**: `Analytics.trackEvent` sends to Firebase Analytics **and** logs the full event + properties dictionary via `logger.debug` — many events include `isnId`/`companyId`/`connectionId` (business identifiers), persisted to on-device logs in non-App-Store builds.

### PII / secret logging risks — flagged, not fixed

- **Wormholy SDK** — the biggest flag on iOS. Initialized `#if !APPSTORE`, it intercepts and stores **full HTTP traffic including `Authorization: Bearer` tokens and the APIM subscription-key header** for any host not in its `ignoredHosts` list. `isnetworld.com` is **not** in that exclusion list, so real API traffic (headers + bodies) is captured on-device in Dev/AdHoc/internal builds. Mitigated only by App Store exclusion and requiring physical device access.
- `AppHelper.processPushNotification` logs the **full push notification payload** via `logger.info` — could include identifiers depending on payload content; persisted in non-App-Store builds.
- `AppDelegate` logs the raw APNs device token via `logger.debug`, but wrapped `#if DEBUG` only (doesn't reach TestFlight/internal builds' persistent store) — lower risk.
- **Already mitigated**: MSAL logging sets `logMaskingLevel = .settingsMaskAllPII` and only prints to console (not persisted) under `#if DEBUG || ADHOC`, with an explicit code comment warning against ever using `NSLog`/`print` for MSAL logs — the team is already aware and has handled this one.

## Secrets handling (iOS)

`secrets.txt` (gitignored) → `Empower/Keys.swift` (gitignored, generated) via `build.py`. Values (`apimSubscriptionKeyDev/Staging/Prod`, `pendoKey`, `qualtricsProjectId`, `radarTestKey`/`radarLiveKey`) are base64-encoded into the generated source — **this is obfuscation, not encryption**. Worth a security review; not a logging issue per se but adjacent.

## Cross-platform summary

Both platforms have the same shape of risk: verbose/debug logging that includes raw tokens or full API traffic, gated to non-production build variants but still reachable in the QA-distributed build (`internalRelease` on Android, any non-`#if !APPSTORE` build on iOS — which includes TestFlight/AdHoc). Before adding a new log statement on either platform, check it doesn't log a token, password, or full request/response body — neither app has an enforced masking layer for ad hoc `Timber`/`os.Logger` calls the way MSAL's own logging does.
