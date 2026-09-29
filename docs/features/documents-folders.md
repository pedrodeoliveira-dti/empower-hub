# Documents & Folders

> Functional documentation — how the feature actually works, grounded in the real code on both platforms. For new developers and POs.

## Purpose

Gives a worker a personal document library: system-managed folders ([Acknowledgements](acknowledgements.md), [Course Certificates](course-certificates.md), [Written Programs](written-programs.md), [Worker Forms](worker-forms.md), [Favorites](bookmarks-favorites.md)) plus user-created **Custom Folders** for arbitrary uploaded documents. Documents can be downloaded for offline/biometric-gated access so a worker can show proof of a document without connectivity.

## User journey

1. The Documents tab fires parallel requests for every folder type on load, tracked against a fixed call counter used to detect partial failure.
2. Tapping a default folder routes to its dedicated list; tapping a Custom Folder opens its own document list, sortable/searchable.
3. **Create folder**: name validated live against a character limit/allowed-characters regex/duplicate-name check (all server/config-driven — see below), then created.
4. **Add document**: pick a folder, name it, set completion/expiration dates, attach a file, submit.
5. **Download for offline**: enqueues a background download; a progress state shows while downloading; a banner confirms completion.
6. **Offline access requires biometrics**: tapping a document/folder item while offline first verifies biometric authentication before showing cached content.
7. **Rename/Delete folder**: rename revalidates the same name rules; delete is confirmation-gated and also purges that folder's bookmarks from cache (see [Bookmarks & Favorites](bookmarks-favorites.md)).
8. Tapping "download" again on an already-downloaded item offers to remove the offline copy instead of re-downloading.

## Business rules / validation

- **Reserved folder names**: a custom folder can't be named the same as a default folder or an existing custom folder.
- **Folder name constraints are server/config-driven**, not hardcoded — character limit, allowed-character regex, and an explicit emoji block all come from remote config.
- **No local download cap or expiry was found** for offline documents on either platform — state this explicitly as **not found**, not assumed absent; worth validating against actual product intent since nothing in code enforces one.
- **Cache is merged on every mutation**, not force-refetched — create/update/delete results patch the cache directly.
- **Deleting a folder invalidates the bookmarks cache**, since any bookmarked document inside becomes stale.
- **Offline-unavailable state** is only true when offline **and** both default and custom folders are empty — cached folders still render while offline otherwise.
- **Search is disabled until at least one folder request has succeeded.**

## Screens

| Android | iOS |
|---|---|
| `DocumentsFragment` (hub) | `DocumentsView` (hub) |
| `FolderDetailsFragment` | `CFDocumentsView` |
| `AddDocumentFragment` + folder-select sheet | `AddDocumentView`, `SelectFolderView` |
| `DocumentDetailsFragment`, `DocumentViewerFragment` | `DocumentDetailsView`, `DocumentSearchView` |

## Platform differences

- iOS's Documents hub always seeds Favorites/Acknowledgements/Certificates up front, then conditionally appends Written Programs/Worker Forms; Android derives all default folders reactively with live enabled/disabled state per folder. Same end state, different reactive wiring.
- Android explicitly counts finished/successful/total API calls to compute a "some folders failed to load" dialog; iOS tracks a failed-tasks array and derives folder-enabled state from it.
- Biometric-gate parameterization differs in shape (Android: a context enum per screen; iOS: a `DocumentBiometrySource` enum) but is functionally equivalent.

## Key user-facing strings

- *"Favorites"* / *"Acknowledgements"* / *"ISN Training Certificates"* / *"Worker Forms"* / *"Written Programs"* — default folder titles.

## Open questions for a PO

1. Confirm with product whether there is intentionally no cap on the number/size of offline-downloaded documents.
2. Is there a max custom-folder count? Not found in either client.
3. Confirm that silently purging a folder's bookmark on delete (no explicit warning) matches the intended UX.

## Related

- [Bookmarks & Favorites](bookmarks-favorites.md), [Acknowledgements](acknowledgements.md), [Course Certificates](course-certificates.md), [Written Programs](written-programs.md), [Worker Forms](worker-forms.md) — the default folders this feature hosts.
