# Toolbox Talks

> Functional documentation — how the feature actually works, grounded in the real code on both platforms. For new developers and POs.

## Purpose

Lets a field worker generate an on-demand, AI-authored safety briefing on any topic (e.g. "ladder safety"), read/listen to it, optionally record who attended, and share a PDF (with or without an attendee sign-off list) to a connected contractor company. Replaces a static library of pre-written talks with a personalized, location- and language-aware generator.

## User journey

1. Home screen fetches config: suggested topics, disclaimer, supported locations/languages, rating config.
2. If no location is saved yet, a location sheet is force-shown before proceeding (Android has a documented workaround for a back-button bug here, tracked as issue #257868).
3. User picks a suggested topic chip or types free text, validated live against a server-supplied allow-list regex and character limit.
4. Selecting/creating a topic generates the talk, opening a Chat/Details screen with AI content plus "References and Regulations."
5. User can Read Aloud (TTS), open references, or answer "Was this content helpful?" — No opens a 2-slide feedback flow (common-problem chips + free text).
6. **Share**: no attendee list → shares a plain PDF; with an attendee list → PDF includes the attendee list appended.
7. "Create an Attendee List" ties attendees to a connected contractor company; the list can be resumed/generated/shared as its own PDF.
8. A History/Recents screen lists previously generated talks (~30 days per UI copy).

## Business rules / validation

- **Free-text topic validation**: allow-list regex + character limit come from server config, not hardcoded.
- **Special location display rule**: two hardcoded location IDs must display their parent region name ("United States"/"Australia") instead of the literal option — confirmed identical on both platforms, explicitly must-not-change across environments.
- **Share gating**: enabled only when online and the talk has content sections; iOS additionally requires at least one active connection before sharing.
- **Attendee-list gating**: requires an active contractor connection — zero connections prompts to connect; exactly one auto-selects; multiple requires a picker.
- **Exit-without-losing-work guard**: navigating back while an unshared attendee list exists warns it will be lost.
- **Rating gating**: "Not helpful" send requires at least one selected chip or non-blank text, plus regex/length validation, plus online.

## Screens

| Android | iOS |
|---|---|
| `ToolboxTalksFragment` (home/search) | `Portal` (home/search + location/language sheets) |
| `ToolboxTalksChatFragment` (talk + feedback + share) | `Details` (chat/generated talk) |
| `AddAttendeeFragment`/`AttendeeListFragment`/company-selector sheet | `AttendeeList` (+ `RecentList`, PDF generate/viewer) |
| `ToolboxTalkRecentsFragment` | `Archived` |
| location/language bottom sheets | folded into `Portal` |

## Platform differences

- Android has a documented back-button workaround (#257868) for the forced location sheet; no equivalent caveat found in the iOS code — worth confirming if the underlying bug is Android-specific or already handled differently.
- iOS names history "Archived" internally though the UI says "Recents"; Android calls both the code and UI "Recents."
- Android supports a legacy Fragment-navigation path alongside Compose-navigation behind `ComposeNavigationFlag`; iOS has a single SwiftUI navigation stack.

## Key user-facing strings

- *"Try these Toolbox Talk topics"* / *"Enter your topic here"* / *"Invalid topic. Please try again."*
- *"To share this Toolbox Talk, you need to connect with a Contractor company. To connect, tap the '+' icon..."*
- *"You don't have any recent Toolbox Talks. Once generated, you can access them here for 30 days."*
- *"Are you sure you want to exit Toolbox Talks and go back to Home?"*

## Open questions for a PO

1. What server-side rule governs the "30 days" recents retention mentioned in the copy?
2. Is Android's back-button workaround (#257868) still open, and does iOS have an equivalent unresolved issue?

## Related

- [Hazard Assistant](hazard-assistant.md) — can suggest a Toolbox Talk topic from its results.
