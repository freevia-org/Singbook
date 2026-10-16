# Google account sync

Singbook syncs the library through the signed-in user's own hidden Google Drive
application-data folder (`appDataFolder`), with the single scope
`https://www.googleapis.com/auth/drive.appdata`. There is no Singbook backend,
shared storage account or client secret. The app cannot see any other Drive
file, and the user can remove the data from Google account settings.

Songs work without signing in; sync is optional and only runs after an explicit
Sync now or confirmed sync action. App startup does not restore authorization,
and sign-in, local edits and app resume never start a cloud sync. There are no
background sync or retry timers. The local SQLite library is always the working
copy: signing out never deletes songs.

## OAuth client setup

Sign-in only works in builds that carry public OAuth client identifiers. Without
them `configured` is false, the account UI shows "not configured" and nothing
else happens (`not_configured`). The click-by-click Cloud Console steps are in
[`docs/google-oauth-setup.md`](../../docs/google-oauth-setup.md). What the code
needs, precisely (`google_sign_in` 7.x, Credential Manager on Android):

| Platform | Client you must create | What the app is given |
|---|---|---|
| Android | An **Android** OAuth client: package `org.freevia.singbook` + the SHA-1 of every signing certificate (debug, upload, and the Play App Signing certificate). | Nothing: Google matches package + SHA-1 itself. It must exist in the same project or sign-in is cancelled without explanation. |
| Android | A **Web application** OAuth client in the same project. | Its id as `--dart-define=VERSE_GOOGLE_SERVER_CLIENT_ID=<id>.apps.googleusercontent.com` (becomes `serverClientId`). Required: the plugin throws without it. No backend uses it. |
| iOS | An **iOS** OAuth client for the bundle id. | `--dart-define=VERSE_GOOGLE_IOS_CLIENT_ID=<id>.apps.googleusercontent.com` (`clientId`) plus the reversed client id as URL scheme in `ios/Runner/Info.plist`. Not validated on this Windows workspace. |

Also enable the **Google Drive API** and configure the OAuth consent screen
(add test users while it is in Testing). `drive.appdata` is a non-sensitive
scope, so no Google verification review is needed for it.

Android needs nothing else natively: `INTERNET` is declared, the plugin adds its
own wiring. R8/minify rules for the plugin are the Android owner's concern.

`GoogleDriveAuth` (`google_auth.dart`): silent restore on start
(`attemptLightweightAuthentication`, never throws); interactive
`authenticate` + `authorizeScopes` only from a user tap; every request takes a
token from `authorizationForScopes`; a 401 clears the rejected token and asks
the platform for a new one once; sign-out clears the token and revokes the grant
(best effort, falls back to a plain sign-out).

## Cloud layout

One file per item, updated in place, in `appDataFolder`:

* `song-<id>.cho`: the complete `x_verse` ChordPro payload (lyrics, chords,
  timing tracks, source provenance) exactly as stored locally.
* `setlist-<id>.json`: a setlist (entries reference songs by id).

`<id>` is the item id when it matches `[A-Za-z0-9_-]{1,160}`, otherwise `~` +
base64url of its UTF-8 bytes. Names are parsed strictly (canonical spelling
only); anything else in the folder is ignored and never modified. An id that
cannot be represented is skipped (`invalid_local_data`).

Every file has `appProperties`: `verseSchema=2`, `kind` (`song`|`setlist`) and
`hash` (sha-256 of the body). One paginated `files.list` with a `fields`
projection (id, name, modifiedTime, version, size, md5Checksum, headRevisionId,
appProperties) therefore shows everything that changed without downloading a
body. Bodies are verified against `hash` after download.

There are no manifests, revision logs, tombstones, device markers or
compaction. The cloud holds exactly the current state.

## Local state

Per signed-in account and item the repository keeps a **baseline** row in the
`sync_items` table (database version 2; `account, kind, item_id, cloud_hash,
local_hash`): what cloud and device agreed on at the last sync. A row means "we
had synced this item", so a later absence is a deletion, not "never existed".
`local_hash` is kept separately because applying a download normalises the
local document. Downloads write the document and its baseline in one SQLite
transaction. The `outbox` is no longer used for decisions (hashes are); a
finished sync just acknowledges the rows that existed when it started.

`sync.account` binds the library to one Google account (hash + e-mail for the
UI). `sync.google.<hash>.lastSuccess` is the time of the last good sync.

## Decision per item

`L` = local hash (or absent), `C` = cloud `hash` property (or absent),
`B` = baseline. "Local changed" is `L != B.local`, "cloud changed" is
`C != B.cloud`. Nothing is read or written for an item whose state equals its
baseline, so an unchanged library costs one listing.

| Local | Cloud | Baseline | Action |
|---|---|---|---|
| = cloud | = local | any | record baseline, no transfer |
| present | absent | none | upload (create) |
| absent | present | none | download (create locally) |
| differs | differs | none | **conflict** (first contact) |
| changed only | same | yes | upload (update in place) |
| same | changed only | yes | download |
| changed | changed, different | yes | **conflict** |
| same | absent | yes | deleted elsewhere: delete locally |
| changed | absent | yes | edited here: upload again |
| absent | same | yes | deleted here: delete the cloud file |
| absent | changed | yes | edited elsewhere: restore locally |
| absent | absent | yes | forget the baseline |

**Conflict**: the cloud version replaces the item at the original id and the
local edit is saved as a copy with the deterministic id
`conflict-<hash(id)>-<hash of the local content>` (setlist copies get a
`[xxxxxx]` name suffix), then uploaded as a normal item. Repeating the sync finds
the same copy and creates nothing; deleting a copy deletes it everywhere like
any item. If cloud and local differ only in spelling (same content after
normalisation) there is no conflict. Copy and original are written in one
transaction guarded by the local hash, so a local edit made while syncing is
never overwritten.

**Order** within a sync: songs, then setlists (so a pulled setlist finds its
songs), then local deletions of setlists, then of songs, then cloud deletions.
A setlist whose songs are missing locally is never applied (it stays `pending`
and is retried); deleting a song removes it from local setlists, which are then
uploaded by one extra round, so the setlist on every device ends consistent.

## Writes and concurrency

Drive v3 has no If-Match. Before updating or deleting a file the service reads
its metadata again and compares `version` and `hash` with the listing; on a
mismatch (or a vanished file) that item is re-read and decided again, up to
three times (`remote_changed` if it keeps changing). This narrows, but cannot
close, the window between that check and the write; Drive keeps the overwritten
body as a file revision (about 30 days), which is the documented manual safety
net (no in-app restore). Updates send the same body on every retry, so they are
idempotent. A create whose answer was lost is looked up by name and hash before
it is sent again.

If two files of one name exist (a race on create), the newest wins (modified
time, ties by id, identical on every device). An older one whose content is
already known is deleted; one with unknown content is first kept locally as a
conflict copy, then deleted.

Transport (`DriveAppDataStore`): 30 s timeouts; HTTP 429, 5xx and the 403
rate-limit reasons retry up to four attempts with exponential back-off
(honouring `Retry-After`, capped at 30 s); a 401 re-authorises silently once;
other 403 reasons are `access_denied`, quota is `storage_full`. Up to four
requests run in parallel inside one phase.

## Failure behaviour

* Anything done before a failure stays done: uploads are recorded in the
  baseline (flushed in batches and on failure), downloads are committed
  transactionally. If the process dies after an upload but before its baseline
  is stored, the next sync sees equal content on both sides and just re-links.
  The next sync converges with only the missing work.
* An unusable remote file (over 16 MiB, hash mismatch, wrong id inside, no
  valid hash property) is skipped and reported (`SyncReport.skipCodes`,
  `remote_file_too_large` / `invalid_remote_data`); it is never applied and never
  treated as a deletion, and the other items still sync.
* More than 20,000 items stops before any change (`remote_library_too_large`
  for the cloud, `library_too_large` for the device).
* Cancelling (`cancel()`, used when the app controller is disposed) stops at an
  item boundary (`cancelled`).

Error codes (stable, mapped to text by the UI): `not_configured`,
`not_signed_in`, `authorization_required`, `access_denied`, `rate_limited`,
`storage_full`, `network`, `account_changed`, `remote_library_too_large`,
`library_too_large`, `remote_file_too_large`, `invalid_remote_data`,
`local_file_too_large`, `sign_in_failed`, `sync_failed`, `cancelled`,
`sync_in_progress`, `not_initialized`.

## Accounts

The first sync binds the library to the signed-in account. Signing in with a
**different** account never merges silently: `sync()` fails with
`account_changed` before touching anything, until the user chooses
(`GoogleDriveSyncService.adoptAccount` / `AppController.adoptAccount`):

* **merge** (`mergeLocal: true`): the library is bound to the new account and
  the next sync merges (local-only items upload, same-id differences become
  conflict copies);
* **replace** (`mergeLocal: false`): the account's library replaces the local one;
  local items the account lacks are deleted and differing ones overwritten. It
  is destructive, persists across an interrupted sync, and needs a confirmation
  in the UI.

Baselines of other accounts are discarded. Signing out keeps the library, the
binding and the baseline, so signing back in with the same account continues
normally.

## On-demand sync (AppController)

Google Drive sync runs only after Sync now or an explicitly confirmed account
or cloud-deletion decision. Startup does not restore Google authorization.
Sign-in updates local account metadata without listing, downloading or uploading
Drive files. Local edits and `onAppResumed()` never start a sync.

There are no sync timers, background retries or follow-up runs. A failed or
partial sync shows its result and waits for another explicit action. Only one
sync action runs at a time. Legacy `autoSync` settings and timing arguments
cannot enable automatic sync; `setAutoSync` persists false for compatibility.

Regression coverage lives in `sync_controller_test.dart`,
`controller_hardening_test.dart` and `account_sync_test.dart`: startup skips
authorization, edits and resume leave Drive untouched, connecting uploads
nothing, and only explicit actions perform or retry a sync.

## Limits

* Dropping a write between the pre-write check and the write itself (milliseconds)
  is possible when two devices upload the same item at the same instant; the
  loser's body survives as a Drive file revision.
* Files from the earlier (unreleased) revision-log format are ignored.
* Local share/export still produces a single song file independent of sync.
* iCloud is unavailable. It would need an Apple developer team, container
  entitlements and a signed Apple build; Apple Sign-In alone gives no iCloud
  file access.

References:
- https://pub.dev/packages/google_sign_in
- https://pub.dev/packages/google_sign_in_android
- https://developers.google.com/workspace/drive/api/guides/appdata
- https://developers.google.com/workspace/drive/api/guides/manage-uploads
- https://developers.google.com/workspace/drive/api/guides/handle-errors

## Suspicious cloud listings

If a sync would delete locally at least 5 items that were agreed with the cloud
before, and more than half of them (or 3+ when the cloud lists nothing at all),
it stops with `remote_listing_suspicious` and changes nothing. Single deletions
are additionally confirmed by a second listing. The user then chooses
`confirmRemoteDeletions()` (apply the deletions) or
`keepLocalAfterRemoteDeletions()` (upload the library again). "Replace local
library" only removes items that existed when it was chosen.
