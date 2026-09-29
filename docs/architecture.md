# Architecture

## MyIsn.Android

- **Language/build**: Kotlin 2.1.20, AGP 8.13.2, Gradle Kotlin DSL with a composite `build-logic/` convention-plugin build (`settings.gradle.kts`, `build-logic/convention/`). compileSdk/targetSdk 36, minSdk 30.
- **UI**: Jetpack Compose (Material3) is the forward path; legacy XML/DataBinding (`BaseFragment`) is being phased out in favor of `BaseFragmentCompose`.
- **Pattern**: Clean Architecture + MVVM (per the repo's own `CLAUDE.md`).
- **Modules** (`settings.gradle.kts`):
  - `:app` — Activities/Fragments, ViewModels, Navigation, app-level DI. Depends on `:data` and `:compose`.
  - `:data` — Repositories, UseCases, network layer (Retrofit/Moshi/OkHttp), models, data-level DI. No dependency on `:app`/`:compose`.
  - `:compose` — reusable composables, design system, feature screens, theme. No dependency on `:app`/`:data`. Excluded from the coverage requirement (see Testing below).
  - `build-logic/` — composite build, convention plugins `isn.android.application` / `isn.android.library` / `isn.android.library.compose`.
- **DI**: Koin (4.x) — `AppModule`, `DataModules`, `UseCasesModules`, `IsnServiceFactory` registered via `startKoin` in `KoinStartupInitializer`. Not Hilt/Dagger.
- **Data flow contract**: `IsnService` (Retrofit interface, DTOs) → `IsnApi`/`IsnApiImpl` (token refresh, retry, DTO→Domain mapping) → Repository → ViewModel. Reads (GET) return `Flow<ApiResult<T>>` via `BaseCachingRepository.getApiCall()` (cache-first, disk cache, network fallback); mutations (POST/PUT/PATCH/DELETE) return `suspend fun ...: ApiResult<T>` directly, no cache layer. UseCases are query-only (`operator fun invoke(...)`), registered as Koin `factory`.
- **~40 feature areas** under `app/.../ui/` (mirrored in `:compose`'s ~42 screen folders) — see `docs/product-overview.md` for the user-facing list.

## MyIsn.iOS

- **Language/build**: Swift/SwiftUI, single app target `Empower` (`Empower.xcodeproj`), min iOS 17 (app target; the `StyleKit` subproject target itself targets iOS 16). Xcode 26.3 per README.
- **Pattern**: MVVM (per the repo's own `AGENTS.md`). Each screen under `Empower/Screens/<Feature>/` follows a fixed file split: `{Name}ViewModel.swift`, `{Name}ViewModel+Requests.swift` (always present), `{Name}ViewModel+Alerts.swift`, `Views/{Name}View.swift`.
- **Navigation**: centralized in `Empower/Shared/Environment/Navigation/` (`NavigationState`, `AppRoute`, `AppRouteViewBuilder`) — push-navigated screens register in both files; sheet-presented screens don't.
- **Targets**: `Empower` (app), `EmpowerTests` (Swift Testing), `StyleKit` — **a local Xcode subproject** (`StyleKit/StyleKit.xcodeproj`, built as `StyleKit.framework`, referenced via `ProjectRef`), not an SPM package despite being called a "design system package" in `AGENTS.md`.
- **DI**: no formal DI container — composition happens through `AppSession`/`AppSessionConfiguration`, built per `.production`/`.nonProduction` in `AppDelegate` (`#if !APPSTORE`), with dependencies passed via constructor injection.
- **~15 feature areas** under `Empower/Screens/` (App Update, Connection, Geolocation, Hazard Assistant, ISN ID Card, Launch, Login and Onboarding, MyCompanies, Quick Check, Tabs, WAck, Worker Forms) plus a dev-only `Empower/Dev Sandbox/` menu (`#if !APPSTORE`).

## How the pieces fit together

- **Clients**: `MyIsn.Android` and `MyIsn.iOS` are independent codebases with no shared module between them — every cross-platform consistency point (API shape, design tokens, business rules) is enforced by convention/Figma, not by shared code.
- **Mock backend**: `Mockoon` has no app code — it holds Mockoon environment JSON under `mockoon-configs/`, merged at build time by `scripts/merge-configs.js` into one `merged.json` served by a Docker container (`mockoon/cli`) on port 8080. See `docs/api-contracts.md` for the merge/prefix mechanism and the full route inventory.
- **Local dev wiring to Mockoon**:
  - **Android**: `EnvironmentRepository` exposes a `MOCKING` `EnvironmentType` with a user-overridable base URL (Dev Options screen), used together with Charles Proxy (SSL Map Remote `*apim.isnetworld.com` → `localhost:3000`) — the app's Mockoon base URL must include an `empower` prefix per `docs/LOCAL_ENVIRONMENT.md` (matching Mockoon's `empower/` route prefix — see `docs/api-contracts.md`). A self-signed cert (`R.raw.mock_server_cert`, internal build flavor only) is loaded when the mock server is active.
  - **iOS**: `ApiEnvironment.remoteMock` — its base URL (`Config.baseUrlMock`, from Firebase Remote Config) is editable in-app via the Dev Sandbox "API Environment" screen, defaulting to `http://localhost:3000` with a "Use localhost URL" shortcut, or a custom remote Mockoon URL.
  - Both clients' dev/staging/prod base URLs (non-mock) come from a remote source, not from source-controlled config: Android from `EnvironmentConfig` (per-environment `baseUrl`), iOS from Firebase Remote Config (`Config.baseUrlDev/Stg/Prod`) — the actual hostnames were not discoverable from either repo alone.
- **Auth**: both clients use MSAL against Azure AD B2C. Android stores the resulting JWT in `EncryptedSharedPreferences`; iOS stores session/biometric-gated credentials in the Keychain.
- **Design system**: both clients implement a design system apparently sourced from the same Figma file ("Empower Design System" — named explicitly in Android's `IsnColors.kt`), each in their own native form — see `docs/style-guide.md`.
