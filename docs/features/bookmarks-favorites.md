# Bookmarks / Favorites

> Functional documentation — how the feature actually works, grounded in the real code on both platforms. For new developers and POs.

## Purpose

Lets a worker "star" any of three item types — a custom [Document](documents-folders.md), a Worker [Acknowledgement](acknowledgements.md), or a [Training Certificate](course-certificates.md) — into a single cross-cutting "Favorites" list, so frequently-needed items don't require digging through the underlying folder structure.

**Confirmed present on both platforms** — internally called "Bookmark" in the domain model/services on both Android and iOS, surfaced as "Favorites" in the UI on both. It is nested under the Documents tab on iOS (`Screens/Tabs/Documents/Favorites/`) rather than a top-level screen, which is why it can look absent at a glance — it isn't.

## User journey

1. From a document/acknowledgement/certificate's detail or list view, the user taps a favorite icon.
2. **Add**: if not yet bookmarked, creates the bookmark immediately — no confirmation dialog.
3. **Remove**: if already bookmarked, a confirmation dialog ("Remove from Favorites?") precedes deletion.
4. The Documents hub shows a "Favorites" tile with a live item count.
5. Opening Favorites groups items into three sections (Acknowledgement/Certificate/Document), sortable by Document Type (default) or Name, and searchable.
6. Tapping a favorited item routes to its native detail screen, with the same offline+biometric gate as [Documents & Folders](documents-folders.md).
7. Each favorited item can independently be downloaded for offline access from the Favorites list itself.
8. Deleting the underlying folder or document elsewhere automatically removes the corresponding bookmark from cache — no separate user action needed.

## Business rules / validation

- **No bookmark count limit was found** on either platform — state this as **not found**, not assumed absent.
- **Optimistic cache merging**: create/delete directly patches both the bookmarks-list cache and the source document/folder cache, so a document's bookmark state and the Favorites list stay consistent without a network round-trip.
- **API version bump**: Android's bookmark repository invalidates older cached bookmark data on a version bump, discarding stale shapes automatically.
- **Sort default**: "Document Type" (grouped sections); switching to "Name" flattens into one alphabetized list.
- **Silent background refresh** unless the user pull-to-refreshes — normal load doesn't show a loading spinner.
- iOS has a dev/QA-only "simulate cache-only mode" flag on the bookmarks service that deliberately fails every live fetch when enabled — a testing lever, not a production behavior; don't mistake it for a real failure path if encountered in logs.

## Screens

| Android | iOS |
|---|---|
| `FavoritesListFragment` (package `ui/favorites`) | `Documents/Favorites/FavoritesView` — nested under the Documents tab, not a top-level screen |

Both are reached the same way: the "Favorites" tile on the Documents hub.

## Platform differences

- Naming split (internal "Bookmark," user-facing "Favorites") is **consistent across both platforms** — not a divergence.
- Composition style differs (Android combines three download-repository flows into one state stream; iOS uses three separate observers reaching the same result) — no functional divergence, just different implementation style.
- No functional divergence found in add/remove/sort/search behavior between platforms.

## Key user-facing strings

- *"Favorites"* (folder tile / screen title, both platforms).
- *"%lld favorited documents"* (iOS result count).

## Open questions for a PO

1. Confirm with product whether there's intentionally no maximum number of favorites.
2. Should removing a bookmark ever be a silent/undo-able action (swipe + snackbar undo) rather than a confirmation dialog? Current UX is dialog-gated on both platforms.
3. Confirm iOS's cache-disable "simulate failure" flag is dev/QA-only tooling before referencing it in any external-facing documentation.

## Related

- [Documents & Folders](documents-folders.md), [Acknowledgements](acknowledgements.md), [Course Certificates](course-certificates.md) — the three item types that can be bookmarked.
