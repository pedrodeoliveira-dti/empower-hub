# ISN ID Wallet

> Functional documentation — how the feature actually works, grounded in the real code on both platforms. For new developers and POs.

## Purpose

Lets a worker with at least one active company connection generate a digital "ISN-ID card" — a scannable/barcoded credential — and optionally save it to **Google Wallet** (Android) or **Apple Wallet/PassKit** (iOS) so it can be presented without opening the app. Also covers the in-app scannable card view itself (swipeable per-connection) and keeping the card's photo in sync with the profile photo on file with ISNetworld.

## User journey

1. **Scannable ISN-ID** screen loads all *active* contractor connections as a swipeable pager; per connection it fetches the ID-card photo and "updated status" metadata in parallel. If the card-specific photo 404s, it falls back to the user's Empower profile photo and flags that connection as needing a sync.
2. **Update status** is derived from who last updated the photo: if updated **via Empower** and a newer photo is available → "update available"; if via Empower with none available → shows a "next update date"; if updated **by an ISNetworld admin** → shown differently. (The literal backend field checked is `updatedBy == "empower"`, case-insensitive.)
3. If a connection needs a photo sync, the user can trigger "Add to ISNetworld," which routes to a photo-sync sheet. Both platforms apply a deliberate short delay (Android: 2000ms; iOS: ~0.5s) before re-checking metadata post-sync, and treat an immediate 404 as "not ready yet" rather than "sync failed" — an explicit anti-flicker design, documented in code comments on both platforms as intentionally kept in behavioral parity.
4. "Add to Wallet" (single card, or batch right after a fresh multi-company connection) calls the platform's wallet API and hands off to the native save-to-wallet flow.
5. **Batch add** only lists non-visitor, successfully-connected companies — visitor/VMS connections are never eligible for a wallet pass (explicitly enforced on Android; only inferable on iOS from what list it's given by the caller — worth confirming directly).
6. Wallet availability is gated by both a feature flag and a runtime device-capability check; the whole "Add to Wallet" step is skipped if unavailable or there are zero eligible connections.

## Business rules / validation

- **Photo-source precedence**: connection-specific ID-card photo (from ISNetworld) takes priority; falls back to the Empower profile photo only when unavailable — same rule both platforms.
- **Wallet eligibility exclusion**: visitor/VMS connections never get a wallet pass. Confirmed explicit on Android; not conclusively confirmed as enforced within the iOS ViewModel itself (may be enforced by its caller instead) — **verify before assuming parity.**
- **Post-sync 404 handling**: identical anti-flicker delay pattern on both platforms (see journey step 3).
- **Barcode content**: the ISN-ID's `"ISN-"` prefix is stripped before being encoded as a barcode, on both platforms.

## Screens

| Android | iOS |
|---|---|
| `ScannableIsnIDFragment` (pager of ID cards) | `ISNIDCardView` (pager) |
| `AddConnectionsToWalletFragment` (batch add) | `AddISNIDToWalletView` / `AddISNIDToWalletConnectionsView` / `MissingPhotoModalView` |

## Platform differences

- **Wallet provider**: Google Wallet (JWT-based) on Android vs. Apple Wallet/PassKit (`PKPass`/`PKPassLibrary`) on iOS — expected, given the platforms.
- **"Already added" detection**: iOS explicitly queries `PKPassLibrary` to know whether a pass is already installed for a given connection; Android has no equivalent device-side check visible in the ViewModel (it just re-issues a JWT each time).
- iOS's batch-add flow has an explicit `.nothingToAdd` state (everything already added); no equivalent explicit state was found in Android's ViewModel.
- Android's card ViewModel has extensive optimistic-update bookkeeping explicitly commented as written to *"mirror iOS's `didSyncPhotos`"* — confirming the two are intentionally kept in behavioral parity despite very different implementations.

## Key user-facing strings

- *"Added to Wallet"* toast (both platforms, exact Android string resource not traced in this pass).
- The exact "your photo needs updating on ISNetworld" banner copy was **not conclusively traced** to its string-resource value on either platform in this pass — confirm wording directly before using it elsewhere.

## Open questions for a PO

1. Is the "visitor connections never get a wallet pass" rule intended to be permanent, given VMS is a newer, actively-flagged feature?
2. Does Android need an explicit "nothing to add" empty state to match iOS, or is that acceptable to leave implicit?
3. Confirm the exact wording of the "photo needs updating" banner on both platforms.

## Related

- [Connections](connections.md) — the flow that produces the successful connections this feature turns into wallet passes.
