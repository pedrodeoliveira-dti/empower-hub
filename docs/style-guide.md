# Style Guide

Both platforms implement a design system apparently sourced from the same Figma file — Android's `IsnColors.kt` explicitly names it **"Empower Design System"** in a comment with a node ID. Values below are each platform's own native implementation; cross-platform hex/point-value parity was **not** independently verified value-by-value — only that both sides define an equivalent token set with the same names.

## Figma source — Empower Design System

File: [Empower Design System](https://www.figma.com/design/Do6QDiBp6IRxQXXOMWC0wo/Empower-Design-System?node-id=1845-4600) (`Do6QDiBp6IRxQXXOMWC0wo`). Claude can read it through the Figma MCP (structure via `get_metadata`, verified on Spacing And Radius; `get_variable_defs` needs a layer selected in Figma desktop). Figma is the source of truth for token values; when code disagrees, flag it instead of silently matching code.

| Area | Pages (status) |
|---|---|
| Foundations | [Colors](https://www.figma.com/design/Do6QDiBp6IRxQXXOMWC0wo/Empower-Design-System?node-id=6971-25141) · [Typography](https://www.figma.com/design/Do6QDiBp6IRxQXXOMWC0wo/Empower-Design-System?node-id=11735-10563) · [Spacing And Radius](https://www.figma.com/design/Do6QDiBp6IRxQXXOMWC0wo/Empower-Design-System?node-id=12668-7474) · [Shadows](https://www.figma.com/design/Do6QDiBp6IRxQXXOMWC0wo/Empower-Design-System?node-id=12669-7615) — all Done |
| Components | [Buttons](https://www.figma.com/design/Do6QDiBp6IRxQXXOMWC0wo/Empower-Design-System?node-id=6971-29312) · [Badges](https://www.figma.com/design/Do6QDiBp6IRxQXXOMWC0wo/Empower-Design-System?node-id=6971-29982) — Done. In progress: [Slots](https://www.figma.com/design/Do6QDiBp6IRxQXXOMWC0wo/Empower-Design-System?node-id=13269-4611) · [Toasts and Banners](https://www.figma.com/design/Do6QDiBp6IRxQXXOMWC0wo/Empower-Design-System?node-id=7732-47672) · [Content Items](https://www.figma.com/design/Do6QDiBp6IRxQXXOMWC0wo/Empower-Design-System?node-id=13253-1426) · [Progress Bars](https://www.figma.com/design/Do6QDiBp6IRxQXXOMWC0wo/Empower-Design-System?node-id=13694-17314) · [Pills](https://www.figma.com/design/Do6QDiBp6IRxQXXOMWC0wo/Empower-Design-System?node-id=13288-10041) · [Search & Chat](https://www.figma.com/design/Do6QDiBp6IRxQXXOMWC0wo/Empower-Design-System?node-id=7015-34504) · [Lists](https://www.figma.com/design/Do6QDiBp6IRxQXXOMWC0wo/Empower-Design-System?node-id=7092-98779). To be developed: [Tiles](https://www.figma.com/design/Do6QDiBp6IRxQXXOMWC0wo/Empower-Design-System?node-id=12870-15293) · [Panels](https://www.figma.com/design/Do6QDiBp6IRxQXXOMWC0wo/Empower-Design-System?node-id=13191-5650) · [Cards](https://www.figma.com/design/Do6QDiBp6IRxQXXOMWC0wo/Empower-Design-System?node-id=13288-6056) |
| Index / atoms | [Components List (start here)](https://www.figma.com/design/Do6QDiBp6IRxQXXOMWC0wo/Empower-Design-System?node-id=11752-28204) · [DS Atoms](https://www.figma.com/design/Do6QDiBp6IRxQXXOMWC0wo/Empower-Design-System?node-id=11703-8848) |

Legacy/ignored: Input & Action, Navigation & Structure, Display & Feedback, Deprecated Components, Archive, Sandbox.

**Figma scale (Spacing And Radius page):** both spacing and radius are `2XSmall 4 · XSmall 8 · Small 16 · Medium 24 · Large 32` (px). This matches iOS `Radius+Additions.swift` exactly; **Android's `Radius.kt` and `Spacing.kt` do not** (they insert `small = 12` and add `xLarge 32`/`xxLarge 40`, shifting names vs. values). Confirm with design before implementing against either scale.

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

Android's `Dimens.kt` (`grid_*`, `plane_*`) is **legacy** and being phased out — don't use it in new code; use `Spacing`/`Radius` tokens instead.

## Radius (Android: `:compose` `resources/Radius.kt`; iOS: `StyleKit/.../Radius+Additions.swift`)

| Token | Android (dp) | iOS (pt) |
|---|---|---|
| xxSmall | 4 | 4 |
| xSmall | 8 | 8 |
| small | 12 | 16 |
| medium | 16 | 24 |
| large | 24 | 32 |
| xLarge | 32 | — |
| xxLarge | 40 | — |

Same token names, **different values from `small` up** — Android's scale has two extra steps (`xLarge`, `xxLarge`). Figma (see above) matches iOS, not Android. Android exposes these as `RoundedCornerShape`, not raw numbers.

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

iOS has a dedicated `ds-migration` skill (`.github/skills/ds-migration`) specifically for rolling `StyleKit` components out to replace legacy call-sites — implying the StyleKit rollout is an **active, ongoing effort**, not yet complete app-wide. Android's `:compose` design system (`designsystem/components/`) is likewise the new system and takes priority over legacy `composables/`; adoption state app-wide is not tracked here. Android has an internal **`figma-to-compose`** skill (`MyIsn.Android/.claude/skills/figma-to-compose`) for implementing Figma designs with these tokens and a component registry — use it for Android UI work from Figma.

## Known gaps

- Cross-platform color hex parity — not verified, `TBD`.
- Android `Radius.kt`/`Spacing.kt` diverge from the Figma scale (extra `12` step and `40`) — intentional extension or drift? Ask design/Android team.
- Colors, Typography, Shadows and component pages were linked but not yet compared against code.
