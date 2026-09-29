# Written Programs

> Functional documentation — how the feature actually works, grounded in the real code on both platforms. For new developers and POs.

## Purpose

A document library for formal, company-authored safety programs (e.g. a hiring client's written HazCom or fall-protection program) that a worker can browse and open as read-only PDFs, scoped to the specific contractor company connection and geographic region the documents apply to. Solves "get the worker to the exact regional policy documents relevant to their job," rather than a single flat, unfiltered list.

## User journey

1. **Entry is gated**: the "Written Programs" folder only appears in [Documents](documents-folders.md) if at least one active contractor connection has **opted in** server-side. If none have, the folder isn't shown at all.
2. **Choose company**: auto-selected if exactly one eligible connection; a picker sheet if more than one; a "can't change company" explainer if there's genuinely only one option and the user tries to switch.
3. **Choose region**: fetched per-connection after company selection — auto-selected if exactly one region, otherwise a picker sheet; same "can't change" explainer pattern if there's only one.
4. The (company, region) selection is **persisted locally**, so reopening the tab resumes exactly where the user left off.
5. Programs load for the pair; searchable by program or document name; tapping opens a PDF viewer, blocked immediately with an error dialog if offline.
6. Switching company clears the saved region (regions are company-scoped) on both platforms.

## Business rules / validation

- **Opt-in gating**: the entire feature is invisible unless a connected company has opted in — confirmed identical on both platforms via the same opt-in/connections endpoint.
- **Region gating**: programs can't be listed without a region. Zero regions → an empty-state message asking the user to choose a region (though there's nothing to choose). Auto-selection only for exactly 1 region; 2+ forces explicit choice.
- **Single-option UX lock**: when there's only one company/region, the "change" affordance still exists but opens an explainer rather than a picker — an expectation-setting rule, not a hard block.
- **Confidentiality notice**: *"These documents may contain proprietary or confidential information. Please do not share them outside your organization."* shown alongside/near the PDF viewer.
- Document viewing is fetch-and-view of a pre-existing server document — not a client-generated PDF (unlike [Toolbox Talks](toolbox-talks.md)'s share flow).

## Screens

- **Android**: a single `WrittenProgramsFragment` with bottom sheets for company/region selection, reached from the Documents folder list.
- **iOS**: a dedicated screen nested under `Screens/Tabs/Documents/Written Programs/` — **present and fully implemented**, just nested under the Documents tab rather than a top-level Screens folder (mirrors how it's reached).

## Platform differences

No functional divergence found beyond minor UX sequencing — both platforms implement the identical connection→region→programs cascade with local persistence and identical opt-in gating.

## Key user-facing strings

- *"Choose the company whose written programs you want to see. You can switch later."*
- *"This company has written programs for more than one region. Choose the region you want to see. You can switch later."*
- *"You're currently connected to one contractor company. If you add more in the future, you'll be able to switch between them."*
- *"These documents may contain proprietary or confidential information. Please do not share them outside your organization."*

## Open questions for a PO

1. What server-side criteria determine a connection's "opt-in" to Written Programs — a contractual/subscription flag?
2. Is there any notification when a new/updated written program is published, or is it purely pull/browse?

## Related

- [Documents & Folders](documents-folders.md) — where the Written Programs folder lives.
