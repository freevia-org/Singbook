# iOS App Privacy assessment

Assessment date: 2026-10-24. This is a source and dependency review for the
current iOS app, intended to prepare App Store Connect answers. It is not a
completed App Store Connect submission or a legal determination. Apple makes
the developer responsible for describing collection by the app and integrated
third parties. Apple defines collection as data sent off device in a form that
the developer or its partners can access beyond the real-time request; data
used solely to serve a request in real time may be excluded. See [App privacy
details](https://developer.apple.com/app-store/app-privacy-details/) and
[Apple's data-type definitions](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacycollecteddatatypes/nsprivacycollecteddatatype).

## What the source shows

- Songbooks, setlists, activity, preferences, provider settings, and sync state
  are stored in the local SQLite database. No app-owned analytics, crash
  reporting, advertising, account server, or telemetry implementation was
  found in the reviewed source. Local-only storage is not, by itself, App Store
  Connect collection.
- Google sign-in is optional. When configured, on iOS the app receives Google
  account ID, email, and optional profile-photo URL and requests the
  `drive.appdata` scope. It stores account ID, email, and photo URL in SQLite.
  When shown, Flutter requests the photo URL from Google's image host. This is
  an account/URL request; the app does not upload a photo, so the fetch alone
  does not establish collection of the Photos or Videos data type. The app does
  not request phone number, contacts, or device location. See
  `lib/sync/google_auth.dart` and `lib/ui/account_avatar.dart`.
- When the user connects and syncs, song ChordPro payloads and setlists are
  uploaded to the user's Google Drive `appDataFolder` or explicitly selected visible folder; remote file metadata,
  hashes, and content are read and reconciled. Google account ID/email are also
  used locally to bind the library to the selected account. After the user
  connects, the app automatically schedules an initial sync and later syncs
  after song additions, edits, or removals; setlist-only changes do not
  trigger automatic sync. Users can also start one from the account screen.
  See
  `lib/application/app_controller.dart`, `lib/sync/drive_store.dart`, and
  `lib/sync/google_drive_sync.dart`.
- When you search, Singbook may send your query to several available song
  catalogs enabled in settings. It remembers your preferred catalog and shows
  its results first when available. Otherwise it uses the normal fallback,
  preferring Genius when configured and available. Wikisource searches
  historical texts separately and is searched only when you select it. Results
  that arrive without artwork may be looked up by artist and title in enabled
  artwork catalogs (Lyrics.ovh and YouTube Music). After
  you choose a song, Singbook may check enabled sources for lyrics, chords,
  and metadata. To check a song's key, Singbook may send the chosen
  recording's Spotify track ID or ISRC (never an account or library) to
  ReccoBeats (api.reccobeats.com), which returns a key measured from the
  recording. Providers include
  Genius, LRCLIB, YouTube Music, Songsterr, Ultimate Guitar, MusicBrainz,
  Wikidata, Wikimedia Commons, and other sources in the bundled or refreshed
  source catalog. Requests include a Singbook versioned User-Agent; no
  Singbook account ID is added by `ProviderTransport`. In release 0.2.16+30,
  the YouTube Music adapter does not read or send Google's `VISITOR_DATA` as
  `X-Goog-Visitor-Id`; some earlier builds, including 0.2.15+29, did send it.
  Both versions send search text and ordinary network data such as IP
  addresses. The catalog
  itself can refresh from GitHub. See
  `lib/providers/transport.dart`, provider adapters, and
  `lib/providers/source_catalog_client.dart`.
- File import/export is user initiated. Imported songs and setlists remain
  local unless the user later enables Drive sync. Export hands a backup file
  to the OS share sheet, where the user chooses a destination. App code does
  not send the backup to a Singbook server. A backup may contain user-created
  or imported song text, setlists, and optionally preferences.
- The reviewed app and dependency manifests contain no tracking declaration.
  The GoogleSignIn iOS SDK manifest also sets tracking false. No advertising
  SDK, ATT/IDFA access, or explicit ad measurement code was found in Singbook;
  direct provider policy uses are assessed separately below.

## Proposed App Store Connect answers

Runner's manifest now declares Search History for App Functionality (linked,
not tracking) for the active provider flows. Its app-container FileTimestamp
required reason remains `C617.1`. SDK collection declarations remain in their
own bundles. A distribution build with Google Drive or iCloud sync available needs Runner's
Other User Content declaration for account-linked library uploads. The iCloud
path is present in the release35 source and uses CloudKit private databases;
this source review does not itself verify a signed archive or live cloud records.

Apple's categories below are selected based on the user-visible data and SDK
disclosures. “Linked” means the app or provider can associate the data with an
account, device, or other identity. Tracking follows Apple's advertising/data
broker definition; Google sign-in or Drive backup alone does not meet that
definition.

| App Store Connect data type | Recommendation | Purpose | Linked to user | Tracking | Evidence and qualification |
| --- | --- | --- | --- | --- | --- |
| Name | Disclose | App Functionality | Yes | No | GoogleSignIn-iOS 9.2.0 manifest declaration; the app does not read or display the display-name field. This conservative SDK-inclusive answer follows the pinned manifest. |
| Email Address | Disclose | App Functionality | Yes | No | GoogleSignIn-iOS 9.2.0 manifest declaration; the app also receives and stores email locally for account display/binding. Local persistence alone is not off-device collection. |
| Phone Number | Disclose | App Functionality | Yes | No | GoogleSignIn-iOS 9.2.0 manifest declaration. Singbook does not request or read a phone number; include for the SDK-inclusive profile. |
| Other Data Types | Disclose | App Functionality; Analytics | Yes | No | GoogleSignIn-iOS 9.2.0 manifest declaration. This broad SDK category is included in the conservative profile as declared. |
| Coarse Location | Disclose | App Functionality | Yes | No | GoogleSignIn-iOS 9.2.0 manifest declaration. The app requests no OS location permission or GPS coordinates. |
| User ID | Disclose | App Functionality; Analytics | Yes | No | GoogleSignIn-iOS 9.2.0 manifest declaration. App uses the Google account ID for session restoration/account binding; sync state is account-derived. |
| Device ID | Disclose in the OAuth SDK profile | Analytics | Yes | No | Exact GoogleSignIn-iOS 9.2.0 manifest row. Release 0.2.16+30 does not send YouTube Music's `VISITOR_DATA`; release 0.2.15+29 did. Treating that legacy value as a device ID is an inference, not a verified device-bound identifier. |
| Other Usage Data | Disclose | Analytics | Yes | No | GoogleSignIn-iOS 9.2.0 manifest declaration. No Singbook interaction telemetry is sent. |
| Other User Content | Disclose if Google Drive or iCloud sync is enabled in the submitted build | App Functionality | Yes | No | User songs and setlists are stored in the user's Google Drive appDataFolder/selected folder or iCloud private CloudKit database for sync. Cloud copies are associated with the respective Google or Apple account. Local import/export alone does not meet Apple's off-device collection definition. |
| Search History | Disclose when search providers are enabled | App Functionality | Yes, via request IP | No, based on reviewed evidence | Searches send title/artist/query text to providers. MetaBrainz documents request-parameter logs with IP and User-Agent; Wikimedia records request data and IP; Better Lyrics/Unison says it temporarily uses IP and deletes logs within seven days. Apple's Search History type covers searches performed in the app. The visitor-identifier association inference applies to release 0.2.15+29. |

For an OAuth-enabled release, enter the eight GoogleSignIn-iOS 9.2.0 rows
above exactly as declared, plus Search History when provider searches are
available and Other User Content if Google Drive or iCloud sync is available. The checked-in
`GID_CLIENT_ID` and Dart OAuth defaults are empty, and the IPA build script
requires a local defines file. Without valid OAuth IDs, the Dart authorization flow does not call
GoogleSignIn initialization. Native plugin registration and the embedded SDK
still exist, so absence of Dart initialization alone does not prove that the
SDK never collects data. Omit the eight SDK rows in a no-OAuth profile only
with version-specific evidence that the SDK performs no collection in that
configuration; otherwise retain the conservative SDK-inclusive profile. Search
History remains applicable when providers are active. Other User Content from
Drive sync is absent when Drive authorization is not configured. iCloud sync
uses the system iCloud account without Singbook sign-in or an email address;
the app queries CloudKit account status and the signed-in account record name,
then uses the private database in container `iCloud.org.freevia.singbook`.
Synced ChordPro content, setlists, and sync metadata are stored as private
CloudKit records. The account identifier is used for account-scoped requests
and a hashed binding is stored locally. Disconnecting clears the active local
session and preserves local and cloud data. Syncing an item deletion removes its
content from the active library but CloudKit may retain a small tombstone with
the record ID and name to propagate the deletion across devices. Manage the
full app CloudKit storage through Apple Account iCloud storage controls where
available. The release owner verified the production private container is
configured, but reported no synced production records. This source review does
not establish a successful user sync or end-to-end encryption. Release
0.2.16+30 does not read or send YouTube Music's `VISITOR_DATA`; 0.2.15+29
did. The possible Device ID mapping is an inference about that older behavior,
not the current release. Email and
photo URL kept locally, and a photo URL request, do not independently
establish collection of those data types. Verify which profile the signed
archive implements.

The root manifest and GoogleSignIn SDK manifest declare tracking false. This
records the reviewed code's declaration; it does not prove that broad provider
policies cannot establish tracking for an endpoint. Search History is marked
No based on evidence reviewed: this code uses provider search responses, and no
evidence established that Singbook's requests are linked to third-party data
for ad targeting/measurement or shared with a data broker. Genius and Google
policies leave that endpoint-specific question unresolved.

The exact [GoogleSignIn-iOS 9.2.0 privacy
manifest](https://github.com/google/GoogleSignIn-iOS/blob/9.2.0/GoogleSignIn/Sources/Resources/PrivacyInfo.xcprivacy)
declares exactly these eight data types. Each is linked and marked not for
tracking. Purposes are App Functionality for Name, Email Address, Phone Number,
and Coarse Location; App Functionality and Analytics for Other Data Types and
User ID; Analytics for Device ID and Other Usage Data. The lockfile pins
GoogleSignIn-iOS 9.2.0 at revision
`08d8dcecafb575f98879ffdbb8302c1b9ad65d19`.
Google's [SDK App Store disclosure](https://developers.google.com/identity/sign-in/ios/app-privacy)
currently describes an OAuth user identifier and IP address used to estimate
general location for fraud prevention; it was updated 2025-05-19. For the
conservative SDK-inclusive profile, use the pinned 9.2.0 manifest's eight
rows, including categories not itemized on that web page. Narrowing that
profile requires version- and configuration-specific evidence from Google.
The manifest describes the SDK's declared collection, not proof that every
field is observed in this app's configured runtime.

## Main provider request and policy evidence

The checked-in catalog marks Genius, Songsterr, Ultimate Guitar, LRCLIB,
YouTube Music, Lyrics.ovh, SyncLRC, Better Lyrics, Unison, Chordie,
WorshipCommons, Open Filk Songbook, Sean McGrath Music, MusicBrainz, Wikidata,
and Wikimedia Commons active and enabled by default. Users can change provider
settings, and the catalog refreshes from the publisher, so check the release
configuration again. Evidence for the primary providers:

| Provider | Primary policy/source evidence | App Privacy implication |
| --- | --- | --- |
| Genius | MediaLab's [policy](https://www.medialab.la/privacy-policy) says it covers Genius and collects usage and device information, including IP, approximate location from IP, and search-history/website interaction categories. It also describes combining information across devices for content personalization or ad measurement. | Search text and IP can be associated. The policy is broad and does not document retention for Singbook API requests. It mentions advertising use; this review did not establish whether these specific searches are used with third-party data for ad targeting/measurement, so Tracking remains No on evidence reviewed. |
| YouTube Music | Google's [Privacy Policy](https://policies.google.com/privacy) describes collecting search/activity, IP address, and unique identifiers tied to browser, app, or device. Singbook 0.2.16+30 sends search text and ordinary request data such as IP, but does not read or send Google's `VISITOR_DATA` as `X-Goog-Visitor-Id`; 0.2.15+29 did. No signed-in cookies or Singbook account ID are sent. | Disclose Search History for app-functionality requests. The SDK-inclusive profile separately includes the SDK's declared Device ID. Whether Google's legacy visitor value maps to Apple's Device ID remains an inference. |
| MusicBrainz | MetaBrainz's [privacy policy](https://metabrainz.org/privacy) says web/API access logs include IP address, client User-Agent, and requested endpoint with parameters. Singbook sends search terms in URL parameters. | Disclose Search History, linked through request IP, for App Functionality. |
| Wikimedia Commons / Wikidata | Wikimedia Foundation's [privacy policy](https://foundation.wikimedia.org/wiki/Policy:Privacy_policy/en) covers its APIs, describes IP, user-agent, requested pages and use data, and says personal information is generally deleted, aggregated, or de-identified after at most 90 days. Search terms are sent in request parameters. | Disclose Search History, linked through request IP, for App Functionality. The policy states a typical retention limit, subject to exceptions. |
| Unison | Better Lyrics' [privacy description](https://betterlyrics.org/) says it receives song title, artist, album, video ID, temporarily uses IP, and deletes request logs within seven days. The Unison [API source](https://github.com/better-lyrics/unison) documents its search endpoint. | Disclose Search History, linked through request IP, for App Functionality. The provider states a seven-day log period. |
| LRCLIB | The [public API implementation](https://github.com/tranxuanthang/lrclib) and Singbook adapter confirm query transmission to `lrclib.net`; no authoritative LRCLIB privacy/retention statement was located. | Include Search History under the conservative release recommendation; do not claim a confirmed retention period or provider-specific linkage beyond request IP. |

Provider policies describe the provider's broader service and may not specify
how each API endpoint applies the policy. The evidence establishes that
queries and network identifiers leave the device and that some providers
retain request data beyond the immediate response. Whether Genius or Google
uses these particular app requests with third-party data for advertising
measurement remains unestablished; the observed tracking recommendation is No,
pending archive/provider evidence.

## Owner facts to resolve

1. Inspect the final signed archive and build configuration to determine
   whether Google OAuth is configured and which optional providers/Drive sync
   are available. Apply the OAuth-enabled or no-OAuth profile above accordingly.
   Use the pinned manifest's conservative data types unless Google provides
   more specific evidence for this SDK version and configuration.
2. Confirm which refreshed provider catalog/configuration ships in the release
   and whether optional providers remain available. Current bundled defaults
   are documented above; runtime sources may change.
3. Resolve whether Genius or Google uses the app's specific search requests
   with third-party data for targeted advertising or advertising measurement.
   Singbook 0.2.15+29 sent YouTube Music's visitor identifier; release
   0.2.16+30 no longer does. This review found broad provider policy language
   about ads, but no evidence establishing that these API requests are joined
   with third-party data. LRCLIB and several smaller default providers also
   publish no clear API request-retention period in the reviewed sources.
4. Confirm the public privacy policy describes Google Drive and iCloud as
   optional storage providers and explains what songs, setlists, and account
   identifiers or bindings sync.
5. Check the signed archive's privacy report and the exact transitive SDK
   manifests before finalizing the answers. An SDK manifest is a required
   privacy-manifest declaration and useful evidence, but it does not replace
   App Store Connect's separate data collection questionnaire.

## Scope and limits

Reviewed the current iOS and macOS source/configuration, provider and sync
code, including the CloudKit private-database adapter and its entitlements, local
storage paths, `pubspec.yaml`, SwiftPM lockfiles, the pinned GoogleSignIn-iOS
9.2.0 privacy manifest, Google's primary SDK App Store disclosure, and primary
provider policies available on 2026-10-18. No network capture, provider
contract audit, signed archive privacy report, or App Store Connect inspection
was performed. The source establishes what Singbook sends and stores;
published policies establish some logging and retention, but cannot determine
how every live API endpoint applies the policy or whether Genius/Google
requests from Singbook are used for cross-company ad measurement. Search text
can reveal personal interests and is transmitted with network identifiers.

## iOS parity follow-up — 2026-10-19

The new optional visible-folder/ChordPro picker uses `drive.file` alone through
the system browser. It verifies that the returned Drive user matches the
connected account before saving a separate device-only Keychain refresh grant.
Sign-out removes this grant; portable library backups do not include it. No
Singbook backend receives authorization codes or tokens. Include user-content
uploads to a selected folder in the same OAuth-enabled App Privacy review.
Live OAuth remains unverified until the iOS client and callback are configured.

## Google Drive and iCloud sync implementation profile

Release 0.2.22+36 declares account-linked Other User Content for App
Functionality in Runner's privacy manifest. Songs, setlists and
associated sync metadata may leave the device when the user connects a service.
Google Drive uses the selected Google account; iCloud uses the system Apple
Account and the app's private CloudKit database. Each service keeps a separate
account baseline. Neither service introduces advertising tracking.

The official IPA build path requires a configured iOS Google OAuth client and
matching native callback settings. This is a build-time guard, not evidence of
a successful consent or sync session. Release 35 iOS declared Other User
Content in its root manifest, while the macOS root omitted that row. Release 36
aligns the macOS root manifest with
iOS; the shared App Store privacy label must also include the category.
The iOS and macOS targets declare the
CloudKit capability for the private container
`iCloud.org.freevia.singbook`; the release35 owner verified its production
container setup, but this review did not inspect a signed archive or observe a
live sync. Retain the conservative Google SDK disclosures above for
Google-enabled builds. Final App Store Connect answers must match the exact
submitted build; earlier no-OAuth build notes do not describe this profile.

## AcousticBrainz candidate disclosure (28 October 2026)

This assessment covers PR223 at `426007ca2204646bcd0f3a389762b6e9c50a590c`,
not frozen release 45 or a confirmed installed build. When enabled (default-on
in candidate channel 10), this metadata provider receives a verified MusicBrainz
recording ID in HTTPS query parameters at `acousticbrainz.org`, along with fixed
submission positions/field names, the request IP and Singbook User-Agent. It
receives no uploaded audio/files, saved library, account identity or browser
session. Title/artist/album/duration checks use returned tags locally.

The existing Search History / App Functionality recommendation should include
this selected-recording lookup; the public recording ID is content context,
not a Singbook account identifier. The [MetaBrainz privacy policy](https://metabrainz.org/privacy)
states that web/API logs include IP, User-Agent, endpoint and parameters, but
provides no fixed retention period for these logs. Do not infer that the CC0
analysis-data license excludes request logging or establishes endpoint-specific
tracking behavior. No new tracking conclusion is established by this change.

The app exposes the ordinary Settings → Sources switch and preserves opt-out.
The in-memory provider cache holds at most 32 recordings and reuses an entry
for up to 15 minutes. TTL checks do not proactively erase expired entries;
provider-instance/process disposal releases that cache. Saved source facts and
original response metadata persist with the song in SQLite, ChordPro exports
and the user's optional chosen library sync; opt-out does not remove them.
The candidate controller test proves save/reopen/export retention. Device/cloud
qualification and privacy/source integration review remain separate gates.
