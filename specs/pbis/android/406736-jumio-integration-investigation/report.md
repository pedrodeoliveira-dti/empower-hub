# Spike Report — [406736] Android: Investigate Jumio Integration for Empower

- **ADO Link:** https://dev.azure.com/isnsoftware/ISN/_workitems/edit/406736
- **Status:** Spike complete — investigation + working POC scaffold in `MyIsn.Android` (uncommitted, local only)

## TL;DR

Jumio's Android Mobile SDK (v4, `com.jumio.android:*`) is a real, resolvable Gradle dependency and integrates cleanly with this app's existing architecture (Koin DI, Retrofit/IsnApi layering, devOptions pattern). A working code scaffold exists behind a local dev flag in devOptions — **it compiles, passes ktlint/detekt, the app assembles (`assembleInternalDebug`), and was installed and driven live both on an emulator (Pixel 8 AVD) and on a physical device (Motorola moto g84 5G, Android 15)**, with the full network path (devOptions button → `IsnApi`/`IsnService` → TLS → mocked backend) **verified working end-to-end** against a local Charles + Mockoon setup (see "Live emulator test" below), and the Jumio SDK itself **confirmed reachable and responding** on the physical device (see "Live physical device test" below).

What's still outstanding before a real verification is possible:

1. There is no backend endpoint to exchange for a Jumio SDK token (the app must never hold Jumio's `apiToken`/`apiSecret` directly — Jumio requires the token exchange happen server-side).
2. This environment has no Jumio Portal / KYX Workflow account, so no real SDK token could be tested — both the emulator and physical-device tests used a mock token, which gets Jumio's SDK invoked but not a real scan. On the physical device, Jumio's SDK responded to the mock token with a real, structured rejection (`onError code=C010401 message=Authentication failed`) — proof the SDK call itself (network reachability, token plumbing, callback wiring) works; a real Jumio Portal account is needed to get past this point.


Everything below the POC's token-fetch step (the actual scan UI, camera flow, and result content) is provided entirely by Jumio's SDK — Empower does not build that UI.

## What was investigated

- Jumio's public integration docs and the [`Jumio/mobile-sdk-android`](https://github.com/Jumio/mobile-sdk-android) sample app (`docs/integration_guide.md`, `README_Android`).
- The actual compiled SDK classes (decompiled from the resolved AAR in this sandbox — see "How this was verified" below), since the docs alone didn't fully specify method/property names.
- This app's existing patterns for devOptions, Koin DI, Retrofit/`IsnApi` layering, and feature flags (`MyIsn.Android/CLAUDE.md` and `.claude/rules/*`).
- The Figma reference linked from the work item (`ID Verification`) — reviewed on 2026-10-01 (second pass, Figma connector now available); see "Flow from Figma" below. Reviewed at overview level (frame names, copy, screenshot); pixel-level specs were not extracted.

## Flow from Figma (added 2026-10-01)

1. **Quick Check Details → requirements list:** user drills from the Quick Check into a requirement list; a new **"ID Verification"** requirement appears under *Available in Empower* (alongside existing ones such as site orientation / confined space).
2. **Info screen** ("ID Verification"): *"Empower uses a secure third-party partner to confirm your identity with a government ID and a selfie."* with a "What to expect" list and a **"Verify My Identity"** CTA.
3. **"Connecting to Jumio"** interstitial (Empower-owned): *"Securely transferring you to our verification partner. Please don't close the app."* — this is where the sdk-token fetch happens.
4. **Jumio screens** (Jumio-owned UI): **Front of ID → Back of ID → Take a selfie**.
5. **"Finishing Verification"** interstitial (Empower-owned) → back to the requirements list with ID Verification shown as completed.
6. An **alternative entry** is also drawn: a full-screen "Identity Verification Process" explainer with a "Continue" button (labelled "Option 2 based on Meredith's Prototype") — product must pick one.

Implications: the **selfie step means the `liveness` module is required** (not optional as the POC assumed), and back-of-ID capture is expected. No error/retry/cancel/failure screens are drawn in the Figma — a design gap. Requirement completion state (step 5) depends on the backend outcome, not the SDK result (see open question 4).

## Proposed architecture

```
Empower Android app                          Empower backend (proposed, NOT built)         Jumio
─────────────────────                        ───────────────────────────────────            ─────
DevOptions "Launch Jumio POC"
  → JumioVerificationRepository
      .getJumioSdkToken()
      → IsnApi → IsnService
        POST v1/identity-verification/  ───→  Calls Jumio Account/Workflow API        ───→  Jumio Account/
             jumio/sdk-token                  using apiToken+apiSecret (server-side          Workflow API
                                               only — never shipped to the app)
                                        ←───  { sdkToken, datacenter,                  ←───
                                                workflowExecutionId }
  ← ApiResult<JumioSdkTokenResult>
  → JumioPocLauncher.launch(activity, sdkToken, datacenter)
      → JumioSDK(activity).apply { token; dataCenter }.start(activity, controller)
          → Jumio's own SDK UI runs the full scan/capture flow
          → controller.onFinished(JumioResult) / .onError(JumioError)
```

This mirrors the exact layering `MyIsn.Android/.claude/rules/networking.md` already prescribes (`IsnService` → `IsnApi` → mapper → Repository) — Jumio integration adds one endpoint to that pipeline, not a parallel system.

## What was built (POC scaffold)

All local/uncommitted changes in `MyIsn.Android`. Nothing was pushed, committed, or run against a real Jumio account.

**Data layer** (`:data`) — proposed backend contract, ready for the real endpoint once it exists:
- `data/.../model/dto/response/identityverification/JumioSdkTokenResponse.kt`
- `data/.../model/domain/identityverification/JumioSdkTokenResult.kt`
- `data/.../mapper/identityverification/IdentityVerificationDtoMapper.kt`
- `data/.../repository/identityverification/JumioVerificationRepository.kt`
- `IsnService.kt` / `IsnApi.kt` — new `getJumioSdkToken()` endpoint (`POST v1/identity-verification/jumio/sdk-token`, marked `TODO` — **doesn't exist on the backend**)
- `DataModules.kt` — Koin registration

**App layer** (`:app`):
- `ui/devoptions/jumio/JumioPocLauncher.kt` — wraps `JumioSDK.start(activity, JumioControllerInterface)` using the real, decompiled SDK API
- `DevOptionsViewModel.kt` / `DevOptionsState.kt` / `DevOptionsStateConverter.kt` / `DevOptionsFragment.kt` / `DevOptionsScreen.kt` / `MiscFunctionalityCard.kt` / `DevOptionsMocks.kt` — new **"Launch Jumio POC (Spike 406736)"** button in the Misc Functionality card. `DevOptionsScreen.kt` calls `jumioPocLauncher.launch(...)` directly (via `Context.findActivity()`) alongside the pre-existing `DevOptionsFragment` handling — see "Live physical device test" below for why both paths are needed.
- `FeatureFlag.kt` / `FlagCategory.kt` — new local-only `JumioPocFlag` (`key_jumio_poc`), listed under devOptions → Development Flags, gates the button so it's inert by default
- `AppModule.kt` — Koin registration of `JumioPocLauncher`

**Build config:**
- `gradle/libs.versions.toml`, `settings.gradle.kts` (new `exclusiveContent` repo for `repo.mobile.jumio.ai`), `app/build.gradle.kts` — `com.jumio.android:core` + `:docfinder` added as `debugImplementation`/`internalReleaseImplementation` only (mirrors how Chucker is scoped) — **not shipped in `productionRelease`** until a real integration decision is made
- `app/src/test/AndroidManifest.xml` — new file; see "Issue found" below

**How to try it (once a real backend/token exists):** DevOptions → enable "Jumio POC (Spike 406736)" under Development Flags → restart app → Misc Functionality → "Launch Jumio POC (Spike 406736)". Today it will fail with a network error at the token-fetch step, since the backend endpoint doesn't exist.

## How this was verified

Ran in this environment (not just written and assumed correct):
- `:data:compileInternalDebugKotlin`, `:app:compileInternalDebugKotlin` — clean
- `:app:ktlintCheck`, `:data:ktlintCheck`, `:compose:ktlintCheck`, `detekt` (whole project) — clean
- `:app:testInternalDebugUnitTest`, `:data:testInternalDebugUnitTest` (full existing suites) — all pass, nothing broken
- `:app:assembleInternalDebug` — **succeeds**, producing a real installable APK with the Jumio SDK linked in

This also means the Gradle dependency coordinates, the `repo.mobile.jumio.ai` Maven repo, and the exact SDK class/method names below are **confirmed real**, not guessed from docs — the initial pass (written from Jumio's public docs) failed to compile against the actual resolved AAR on three points (`dataCenter` vs `datacenter`, `JumioSDK.isSupportedPlatform(context)` being a static/companion function rather than an instance property, and a third required `JumioControllerInterface.onInitialized(...)` callback the docs excerpt didn't mention); all three were fixed by decompiling the real `core-4.19.1.aar` and are reflected in the code above.

## Live emulator test

Beyond the static checks above, the POC was actually installed and driven on a running emulator (`Pixel_8` AVD) to see the real request go out and come back:

1. Added a mock route to the hub's Mockoon config (`Mockoon/mockoon-configs/empower/empower.json`) for `POST v1/identity-verification/jumio/sdk-token`, returning a fabricated (clearly non-real) token payload matching the DTO shape above.
2. Started a real Mockoon server from that exact config via `npx @mockoon/cli` (the Mockoon desktop app itself hit a first-run Gatekeeper prompt in this environment that needed a manual click — the CLI serves the identical config file, so this is a faithful substitute, not a shortcut).
3. Launched Charles Proxy — this machine already had `SSL Proxying` + a `Map Remote` (`https://*apim.isnetworld.com` → `http://localhost:3000`) configured from prior use, confirmed working with a direct `curl` through Charles before touching the emulator at all.
4. Pointed the emulator at Charles via `adb shell settings put global http_proxy 10.0.2.2:8888` (no Wi-Fi UI needed).
5. Extracted Charles's root CA directly from a live TLS handshake through the proxy (`openssl s_client -proxy localhost:8888 -showcerts`) and installed it as a trusted user CA on the emulator via Settings → Security & privacy → More security & privacy → Encryption & credentials → Install a certificate → CA certificate (confirmed present afterward under Trusted credentials → User).
6. Installed the built APK, opened the app (already signed in from prior use), enabled "Jumio POC (Spike 406736)" under DevOptions → Development Flags, and tapped "Launch Jumio POC (Spike 406736)" under Misc Functionality.

Result, confirmed via `adb logcat`:

```
IsnApiImpl: [getJumioSdkToken]
IsnApiImpl: [getJumioSdkToken] result=Success(data=JumioSdkTokenResponse(message=JumioSdkTokenResponseMessage(
    sdkToken=mock-sdk-token-not-a-real-jumio-token, datacenter=US, workflowExecutionId=mock-workflow-execution-id)))
```

This is a real HTTPS request from the app, through Charles, to a locally-running mock server, parsed correctly through the full `IsnService → IsnApi → mapper → Repository → ViewModel` chain — proving the proposed backend contract and client-side wiring both work mechanically. Before the CA cert was trusted, the identical flow failed with `SSLHandshakeException: Trust anchor for certification path not found`, confirming the test setup (not just the code) was the thing being validated.

What happened next (handing the mock token to the real Jumio SDK via `JumioSDK.start()`) produced no visible UI and no Jumio-side log output — on this software-rendered AVD specifically (visible `MESA: Failed to open rendernode` errors throughout its logs, a known limitation of GPU-less emulator configs), which is consistent with — but not confirmed as — Jumio's CameraX-based capture UI failing to initialize silently. No crash, no ANR, no exception anywhere in logcat; the app remained fully responsive. This should be re-tested on a GPU-backed emulator or a physical device before drawing conclusions about the SDK call itself.

## Live physical device test

Retested later the same day on a physical device (Motorola moto g84 5G, Android 15 / API 35, arm64-v8a) connected via `adb`, after the emulator test above left the "does the SDK's own UI render" question open. Reproduced the exact same symptom as the emulator — devOptions button tapped, `getJumioSdkToken` logs success, and then **nothing visibly happens** — but this time on real hardware with no GPU-less-emulator explanation available, so it needed a real root cause.

**Root cause found:** this app reaches devOptions through **Compose Navigation** in this environment (confirmed via `ComposeNavigationViewModel navigating to devOptions` in logcat, and `SettingsNavigationScreen.kt` mounting `composable(SettingsScreen.DevOptions.route) { DevOptionsScreen() }` directly inside a Compose `NavHost`). The POC's actual `jumioPocLauncher.launch(...)` call lived only in `DevOptionsFragment` — the legacy Fragment-based nav destination — which is never instantiated when Compose Navigation is active for Settings. `DevOptionsScreen()` (the Composable that's actually on screen) already collects the same `eventFlow` and had an intentional no-op for this event:

```kotlin
is DevOptionsViewModel.DevOptionsEvent.LaunchJumioPocIntent -> Unit // handled in DevOptionsFragment — needs an Activity, not just a Context
```

So the token fetch succeeded, the event was emitted correctly, but the only code path that called the Jumio SDK was dead in this navigation mode — no crash, no log, nothing to point at, since it wasn't an exception, just a silently-correct no-op that assumed a code path that wasn't active. Confirmed by temporarily adding a `Timber.d` at the very first line of `JumioPocLauncherImpl.launch()` — it never fired until this was fixed, which also ruled out any Jumio SDK / hardware cause.

**Fix applied** (in `DevOptionsScreen.kt`): mirrored the Fragment's handling directly in the Composable's collector, using the existing `Context.findActivity()` helper (already used the same way by `RadarSettingsBottomSheet.kt` in the same package) to obtain an `Activity` from the Compose `Context`, then calling `jumioPocLauncher.launch(...)` with the same `onFinished`/`onError` Toast handling the Fragment already had. This mirrors the dual Fragment+Compose handling this file already does for `MessageToUserEvent` and `ShowChuckerNotificationIntent` — not a new pattern, just applying the existing one consistently to the third event type. `DevOptionsFragment`'s own handling was left untouched, since `main_nav_graph.xml` still routes to it when the Compose Navigation flag is off.

Result after the fix, confirmed via `adb logcat` on the same physical device:

```
D/JumioPocLauncherImpl: [JumioPocLauncher] launch() called, sdkToken.length=37 datacenter=US
W/JumioPocLauncherImpl$launch: [JumioPocLauncher] onError code=C010401 message=Authentication failed
```

This is Jumio's own SDK rejecting the mock token — a real response from Jumio's backend, not a local/app-side failure. It confirms: `isSupportedPlatform()` passes on this device, `sdk.start()` runs, the SDK reaches Jumio's servers over the network, and the `JumioControllerInterface.onError` callback fires and is wired correctly back to the UI. The only remaining blocker to seeing the actual scan/capture UI is a real (non-mock) SDK token, which needs a real Jumio Portal account — item 2 under "What's still outstanding" above.

## Issue found: manifest merge conflict (fixed)

Jumio's `core` AAR declares `android:allowBackup="false"` in its manifest. This app's own `AndroidManifest.xml` already declares `allowBackup="false"` with `tools:replace="android:allowBackup"` (pre-existing, for a conflict with the Qualtrics SDK) — that already covers real app builds fine. But Robolectric's synthetic unit-test manifest doesn't inherit that override, so adding Jumio broke `testInternalDebugUnitTest` manifest merging specifically. Fixed by adding `app/src/test/AndroidManifest.xml` with the same override, scoped to test builds only. Worth knowing: **any future dependency that declares an explicit manifest value already in conflict will hit this same gap** until/unless it's addressed more generally.

## SDK footprint / dependencies

- `com.jumio.android:core` + `com.jumio.android:docfinder` (ID document scanning — the primary use case per the work item). Not added: `nfc`, `barcode-mlkit`, `liveness` (selfie/face match) — add these later if the product flow needs NFC chip reading or a liveness/selfie step; Jumio ships them as separate opt-in artifacts.
- `defaultui` was pulled in **transitively** even though not declared directly — worth confirming during implementation whether that's intended (Custom UI mode, which this POC uses, is meant to let you skip `defaultui`) or whether `docfinder` requires it.
- Min compile SDK for the SDK is 34 (per Jumio's docs) — this app's `compileSdk`/`targetSdk` are already 36, so no conflict.
- Real debug-APK size impact wasn't cleanly measurable here (the local debug APK is 267MB unstripped/multi-ABI, not representative) — measure via a proper release/App Bundle build before estimating user-facing impact.

## Open questions (for the implementation PBIs)

1. **Backend endpoint** — Who builds `POST v1/identity-verification/jumio/sdk-token` (or whatever contract is agreed) and holds the Jumio `apiToken`/`apiSecret`? This is entirely unscoped today; the spike proposes a shape (see DTO above) but this needs backend team sign-off, not just an Android-side decision.
2. **Jumio Portal account** — no sandbox/test credentials exist for this investigation. Needed before any real token can be minted or a scan can be end-to-end tested.
3. **Consent / terms-of-use UX** — `JumioControllerInterface.onInitialized(credentials, consentItems, termsOfUse)` is the hook for showing Jumio's required consent/ToU content before the scan starts; this POC no-ops it. The Figma flow has **no consent/ToU screen** between "Connecting to Jumio" and the capture screens — confirm with design/legal whether Jumio's default consent UI is acceptable or a custom one is needed.
4. **Result handling** — `JumioResult` returns `accountId`, `workflowExecutionId`, and per-credential results (ID doc, face match, etc.), but says nothing about verification *outcome* (approved/rejected) — that's fetched separately from Jumio's backend/webhook after the SDK flow finishes. The Empower backend needs to own polling/receiving that outcome; the app can't determine pass/fail from the SDK alone.
5. **NFC / liveness** — Figma shows a **selfie step, so add `com.jumio.android:liveness`** (not in the POC; verify it works with the Custom UI setup). NFC chip reading is not shown in the flow — confirm it's out of scope.
8. **Failure / cancel / retry UX** — not designed in Figma (user cancels, `onError`, rejected document, backend outcome still pending after "Finishing Verification"). Needs design before implementation PBIs can be estimated.
9. **Entry point** — two alternative entry designs exist in Figma (requirement-row info screen vs. "Identity Verification Process" explainer); product must choose.
10. **Not yet assessed (needs follow-up before implementation, can't be settled from this environment):** R8/ProGuard rules for the Jumio modules in a minified release build, runtime camera-permission handling and its interaction with Empower's existing permission flows, Jumio's SDK support/maintenance policy and minimum-version cadence, and measured APK/AAB size impact.
6. **Data residency** — `JumioDataCenter` (`US`/`EU`/`SG`) must match wherever Jumio processes/stores Empower's verification data contractually; confirm with whoever owns the Jumio vendor relationship.
7. **iOS parity** — sibling spike 406739 needs the equivalent investigation; the backend contract above should be designed once for both platforms, not twice.

## Suggested scope for follow-up implementation PBIs

- **Backend:** Jumio account/workflow setup in Jumio Portal + the SDK-token exchange endpoint (holds real secrets, never the app).
- **Android:** replace the devOptions POC gate with a real entry point (ID Verification requirement → info screen → "Connecting to Jumio" → SDK → "Finishing Verification"); add the `liveness` module; build the consent/ToU screen if Jumio's default doesn't cover it; add failure/cancel handling; wire result handling to the backend outcome; add R8 rules and promote the dependency from `debugImplementation`/`internalReleaseImplementation` to all release variants.
- **iOS:** equivalent work, informed by spike 406739.
- **Cross-cutting:** decide before implementation planning whether this needs `/orchestrate-feature` given it touches Android, iOS, and backend simultaneously.
