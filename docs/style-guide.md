# Style Guide

Both platforms implement a design system apparently sourced from the same Figma file — Android's `IsnColors.kt` explicitly names it **"Empower Design System"** in a comment with a node ID. Values below are each platform's own native implementation; cross-platform hex/point-value parity was **not** independently verified value-by-value — only that both sides define an equivalent token set with the same names.

## Typography

Both platforms use the **Manrope** font family (confirmed in both: Android's `Typography.kt`/`manropeFontFamily`, iOS's `UIFont+Additions.swift`/`FontManager.swift`, font registered in `Empower/Info.plist` `UIAppFonts`).

| Token | Android (`compose/.../resources/Typography.kt`) | iOS (`StyleKit/.../UIFont+Additions.swift`) |
|---|---|---|
| header1/2/3 | Yes | Yes |
| subheader (1-4 Android, 1-5 iOS) | Yes | Yes |
| button | Yes | Yes |
| bodyLarge/bodySmall | Yes | Yes |
| caption | Yes | Yes (+ `captionLimited16`, not confirmed on Android) |
| bottomNav | Yes | Yes |

iOS comments distinguish tokens "From Style Guide" vs "Not in Style Guide" (ad hoc additions) — worth checking which of the above are genuinely from the shared Figma source vs iOS-only additions before assuming full parity.

## Spacing

Confirmed matching scale and values on both platforms:

| Token | Value |
|---|---|
| xxSmall | 4 |
| xSmall | 8 |
| small | 12 (iOS) — Android's `Spacing.kt` wasn't confirmed at this exact step value, only the xxSmall/xxLarge endpoints |
| medium | 16 |
| large | 24 |
| xLarge | 32 |
| xxLarge | 40 |

Android also has a separate, finer-grained `Dimens.kt` (`grid_0_25`…`grid_24`, plus `plane_*` for elevation) with no confirmed iOS equivalent — worth checking whether iOS needs an analogous grid/elevation scale or handles it differently.

## Radius (iOS: `StyleKit/.../Radius+Additions.swift`)

| Token | Value |
|---|---|
| xxSmall | 4 |
| xSmall | 8 |
| small | 16 |
| medium | 24 |
| large | 32 |

No confirmed Android equivalent found (Android's design tokens as inspected covered colors/typography/spacing/dimens, not a named radius scale) — `TBD`.

## Colors

- **Android** (`IsnColors.kt`): Neutral/Blue/Red/Green/Yellow palettes plus custom colors, explicit Figma source reference.
- **iOS** (`Color+Additions.swift`): numeric-scale palette (`blue5`...`blue140` etc.), each documented with RGB/hex in doc comments, backed by `Colors.xcassets`.
- Exact hex values were not extracted/compared between platforms in this pass — `TBD`, verify before assuming color parity on a cross-platform UI task.

## Reusable components

| Component | Android (`:compose` `designsystem/components/`) | iOS (`StyleKit/.../Components/`) |
|---|---|---|
| Badge | `badges/` | `ISNBadge` |
| Button | `buttons/` | `ISNButton` (+ `EmpowerButtonStyle`/`FilledButtonStyle`/`BorderedButtonStyle`) |
| Tile | `tiles/` | `ISNTile` |
| Panel | `panels/` | `ISNPanelLarge`, `ISNPanelSmall` |
| Content item | `contentitem/` | `ISNContentItem`, `ISNContentItemsList` |
| Info bundle | — (not confirmed) | `ISNInfoBundle` |
| Banner | `banners/` | — (not confirmed) |
| Toast | `toasts/` | — (not confirmed) |

iOS has a dedicated `ds-migration` skill (`.github/skills/ds-migration`) specifically for rolling `StyleKit` components out to replace legacy call-sites — implying the StyleKit rollout is an **active, ongoing effort**, not yet complete app-wide. No equivalent note was found for Android's `:compose` design-system adoption state.

## Known gaps

- Cross-platform color hex parity — not verified, `TBD`.
- Android radius token equivalent to iOS's `Radius+Additions.swift` — not found, `TBD`.
- Whether Android's `Dimens.kt` grid/elevation scale has an iOS equivalent — not found, `TBD`.
- Whether iOS's StyleKit rollout (`ds-migration` skill) has an Android-side equivalent in-progress migration — not confirmed either way.
