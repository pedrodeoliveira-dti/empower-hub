# Bulletins & Notifications

> Functional documentation — how the feature actually works, grounded in the real code on both platforms. For new developers and POs.

## Purpose

Keeps a connected worker informed via two distinct streams under one tabbed screen: (a) personal, push-driven **Notifications** (training due dates, document updates, acknowledgement requests, new connection requests, worker forms) that route straight to the relevant detail screen, and (b) **Bulletin Board** posts — broadcast announcements from a worker's Hiring Clients, grouped by client.

## User journey

1. Notifications screen has two tabs/segments: Notifications and Bulletin Board.
2. **Push arrival**: a push carries a `context` (course/document/acknowledgement/addConnection/workerForm/geofence). Tapping it deep-links straight into the matching detail screen and marks the item read in the same flow.
3. **In-app browsing**: paginated list; tapping a row acknowledges it and navigates.
4. **Push permission gating**: if OS push permission isn't granted, the list isn't even fetched — the user sees an opt-in prompt instead.
5. **Mark all as read**: confirmation dialog → bulk-acknowledge call for every currently-unread id. Confirmation copy differs if a filter is active ("filtered posts") vs. not ("for all Hiring Clients").
6. **Bulletin Board**: loads per Hiring Client, sortable (Client Name/Most Recent), filterable (Unread/High Priority), searchable. Opening a bulletin marks it read as a side effect.
7. **Bulletin attachments**: a bulletin can embed a PDF (restricted to PDF only — other file types show "not supported") and/or a Qualtrics survey link, detected by scanning the description HTML against a server-configured list of survey domains.
8. **Notification settings**: individual push categories can be toggled on/off; failed toggle requests are queued and retried.

## Business rules / validation

- **Unread tracking is client-computed, not purely server-flagged** — both the notifications and bulletins unread counts are derived client-side from whichever list is currently displayed, so badge counts react instantly to local mark-as-read actions before a refetch.
- **Optimistic unread decrement**: marking an item read decrements the locally cached unread counter regardless of the API result ("since we are marking it as 'read' on the UI").
- **First-grant auto opt-in**: the very first time OS push permission is newly granted (not on every launch), the app auto-enables the "allow all notifications" preference.
- **Bulletin attachment restricted to PDF** — a non-PDF extension shows a "file not supported" dialog.
- **Offline blocks notification navigation** — tapping a notification while offline shows an "offline" dialog instead of navigating.
- **Worker Forms notifications are feature-flag gated**, same flag as [Worker Forms](worker-forms.md) itself.
- **Badge count** = unread notifications + unread bulletins, net of this-session's manual acknowledgements — so it doesn't wait for a refetch to update.

## Screens

| Android | iOS |
|---|---|
| `NotificationsFragment`/`NotificationsScreenWrapper` (tabs) | `NotificationsListView` (segmented control) |
| `BulletinDetailsFragment` | `BulletinBoardView`, `BulletinBoardDetailsView` |
| `NotificationSettingsFragment` | (settings screen) |
| `SimpleNotificationFragment` (lightweight in-app banner) | `NotificationsOptInView`, `EmptyNotificationsView` |

## Platform differences

- Android has a distinct "simple notification" in-app banner package with no confirmed iOS equivalent under Notifications.
- Sort/filter chips are implemented independently (shared compose framework on Android vs. local structs on iOS) but functionally identical.

## Key user-facing strings

- *"Mark all filtered bulletin board posts as read. Do you want to continue?"*
- *"Welcome to your Bulletin Board! Announcements from your Hiring Clients can be found here."*
- *"Notifications Skipped — You can enable them any time. This step is snoozed for 30 days."*

## Open questions for a PO

1. What exactly triggers a "geofence" notification context — iOS explicitly no-ops navigation for it. Intentional (informational-only) or an unimplemented gap?
2. Is there a server-side TTL/expiry for bulletins, or do they persist indefinitely until read?
3. What is Android's `simplenotification` package actually for, and is it still an active pattern?
